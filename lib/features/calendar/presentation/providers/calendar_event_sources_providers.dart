import 'dart:convert';

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/calendar/data/datasource/personal_calendar_remote_datasource.dart';
import 'package:flutter_pecha/features/calendar/data/models/personal_calendar_models.dart';
import 'package:flutter_pecha/features/calendar/data/repositories/personal_calendar_repository_impl.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/personal_calendar_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============ Who is viewing ============

/// The name and avatar on the viewer's own event cards. Null id = no account.
typedef CalendarViewer = ({String? id, String? name, String? avatarUrl});

final calendarViewerProvider = Provider<CalendarViewer>((ref) {
  final user = ref.watch(userProvider).user;
  return (
    id: user?.id,
    name: user?.visibleNameOrNull,
    avatarUrl: user?.avatarUrl,
  );
});

// ============ The feed: personal and joined-space events ============

final personalCalendarRepositoryProvider = Provider<PersonalCalendarRepository>(
  (ref) => PersonalCalendarRepositoryImpl(
    PersonalCalendarRemoteDatasource(dio: ref.watch(dioProvider)),
  ),
);

/// Most rows the feed serves in one call.
const _feedPageSize = 100;

/// Every personal and joined-space event in the month starting at [month].
/// Empty for guests. A failure throws, so a refresh keeps the events already
/// shown (`valueOrNull`) and the calendar still works without any.
final calendarFeedProvider =
    FutureProvider.family<List<CalendarEvent>, DateTime>((ref, month) async {
      final userId = ref.watch(calendarViewerProvider.select((v) => v.id));
      if (userId == null) return const [];
      final language = ref.watch(contentLanguageProvider);
      final repository = ref.watch(personalCalendarRepositoryProvider);

      final from = DateTime(month.year, month.month, 1);
      final to = DateTime(month.year, month.month + 1, 0);
      final events = <CalendarEvent>[];
      var skip = 0;
      while (true) {
        final result = await repository.getFeed(
          from: from,
          to: to,
          language: language,
          skip: skip,
          limit: _feedPageSize,
        );
        final page = result.fold<CalendarFeedPage>((f) => throw f, (p) => p);
        events.addAll(page.events);
        if (!page.hasMore || page.rowCount == 0) return events;
        skip += page.rowCount;
      }
    });

/// The Repeats sheet's choices for an event first on [date].
final personalRepeatOptionsProvider = FutureProvider.autoDispose
    .family<List<PersonalRepeatOption>, DateTime>((ref, date) async {
      final result = await ref
          .watch(personalCalendarRepositoryProvider)
          .getRepeatOptions(date);
      return result.fold((f) => throw f, (options) => options);
    });

// ============ Dates hidden on this device ============

/// Dates hidden with "This event", per event. The API can only delete a whole
/// event, so these stay on this device until it can skip one date.
class PersonalEventSkipsNotifier
    extends StateNotifier<Map<String, Set<DateTime>>> {
  PersonalEventSkipsNotifier(this._storage, this._userId) : super(const {}) {
    _loaded = _load();
  }

  final StorageService _storage;
  final String? _userId;
  final _logger = AppLogger('PersonalEventSkipsNotifier');
  late final Future<void> _loaded;

  String get _key => 'personal_calendar_skipped_dates_$_userId';

  Future<void> _load() async {
    if (_userId == null) return;
    try {
      final raw = await _storage.get<String>(_key);
      if (raw == null || !mounted) return;
      state = {
        for (final entry in (jsonDecode(raw) as Map<String, dynamic>).entries)
          entry.key: {
            for (final date in entry.value as List)
              DateTime.parse(date as String),
          },
      };
    } catch (e) {
      _logger.error('Failed to load skipped dates', e);
    }
  }

  Future<void> _commit(Map<String, Set<DateTime>> next) async {
    if (_userId == null || !mounted) return;
    state = next;
    try {
      await _storage.set<String>(
        _key,
        jsonEncode({
          for (final entry in next.entries)
            entry.key: entry.value.map(formatApiDate).toList(),
        }),
      );
    } catch (e) {
      _logger.error('Failed to save skipped dates', e);
    }
  }

  Future<void> skip(String eventId, DateTime date) async {
    await _loaded;
    await _commit({
      ...state,
      eventId: {...?state[eventId], date},
    });
  }

  Future<void> clear(String eventId) async {
    await _loaded;
    if (!state.containsKey(eventId)) return;
    await _commit({...state}..remove(eventId));
  }
}

final personalEventSkipsProvider = StateNotifierProvider<
  PersonalEventSkipsNotifier,
  Map<String, Set<DateTime>>
>((ref) {
  return PersonalEventSkipsNotifier(
    ref.watch(storageServiceProvider),
    ref.watch(calendarViewerProvider.select((v) => v.id)),
  );
});

// ============ Changing personal events ============

/// Saves to the server, then re-reads the feed. Each call returns the failure,
/// or null when it worked.
class PersonalCalendarController {
  PersonalCalendarController(this._ref);

  final Ref _ref;

  PersonalCalendarRepository get _repository =>
      _ref.read(personalCalendarRepositoryProvider);

  void _refreshFeed() => _ref.invalidate(calendarFeedProvider);

  Future<Failure?> add({
    required String title,
    required DateTime startDate,
    required PersonalRepeat repeat,
  }) async {
    final result = await _repository.createEvent(
      title: title,
      startDate: startDate,
      repeat: repeat,
    );
    return result.fold((failure) => failure, (_) {
      _refreshFeed();
      return null;
    });
  }

  /// Applies to every date. A changed repeat starts over, so dates hidden under
  /// the old one can't hide dates of the new one.
  Future<Failure?> edit(
    PersonalCalendarEvent event, {
    required String title,
    required PersonalRepeat repeat,
  }) async {
    final result = await _repository.updateEvent(
      event.id,
      title: title,
      repeat: repeat,
    );
    return result.fold((failure) => failure, (_) async {
      if (repeat != event.repeat) {
        await _ref.read(personalEventSkipsProvider.notifier).clear(event.id);
      }
      _refreshFeed();
      return null;
    });
  }

  /// Removes the event and all of its dates.
  Future<Failure?> delete(String eventId) async {
    final result = await _repository.deleteEvent(eventId);
    return result.fold((failure) => failure, (_) async {
      await _ref.read(personalEventSkipsProvider.notifier).clear(eventId);
      _refreshFeed();
      return null;
    });
  }

  /// Hides one date of a repeating event; the rest stay.
  Future<void> skipDate(String eventId, DateTime date) =>
      _ref.read(personalEventSkipsProvider.notifier).skip(eventId, date);
}

final personalCalendarControllerProvider = Provider<PersonalCalendarController>(
  PersonalCalendarController.new,
);
