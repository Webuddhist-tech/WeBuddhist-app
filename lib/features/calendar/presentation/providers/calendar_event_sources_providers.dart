import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/calendar/data/datasource/personal_calendar_remote_datasource.dart';
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

  /// Applies to every date.
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
    return result.fold((failure) => failure, (_) {
      _refreshFeed();
      return null;
    });
  }

  /// Removes the event and all of its dates. The API has no way to remove a
  /// single date of a repeating event.
  Future<Failure?> delete(String eventId) async {
    final result = await _repository.deleteEvent(eventId);
    return result.fold((failure) => failure, (_) {
      _refreshFeed();
      return null;
    });
  }
}

final personalCalendarControllerProvider = Provider<PersonalCalendarController>(
  PersonalCalendarController.new,
);
