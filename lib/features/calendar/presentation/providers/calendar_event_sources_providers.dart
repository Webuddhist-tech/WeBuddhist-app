import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/calendar/data/datasource/personal_calendar_remote_datasource.dart';
import 'package:flutter_pecha/features/calendar/data/repositories/personal_calendar_repository_impl.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/personal_calendar_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

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

// ============ Changing personal events ============

/// Saves to the server, then re-reads the feed. Each call returns the failure,
/// or null when it worked.
class PersonalCalendarController {
  PersonalCalendarController(this._ref);

  final Ref _ref;

  PersonalCalendarRepository get _repository =>
      _ref.read(personalCalendarRepositoryProvider);

  Failure? _finish<T>(Either<Failure, T> result) {
    return result.fold((failure) => failure, (_) {
      _ref.invalidate(calendarFeedProvider);
      return null;
    });
  }

  Future<Failure?> add({
    required String title,
    required DateTime startDate,
  }) async => _finish(
    await _repository.createEvent(title: title, startDate: startDate),
  );

  Future<Failure?> edit(String id, {required String title}) async =>
      _finish(await _repository.updateEvent(id, title: title));

  Future<Failure?> delete(String id) async =>
      _finish(await _repository.deleteEvent(id));
}

final personalCalendarControllerProvider = Provider<PersonalCalendarController>(
  PersonalCalendarController.new,
);
