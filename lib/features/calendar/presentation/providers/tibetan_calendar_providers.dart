import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/calendar/data/datasource/calendar_remote_datasource.dart';
import 'package:flutter_pecha/features/calendar/data/kharag_tibetan_calendar_service.dart';
import 'package:flutter_pecha/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:flutter_pecha/features/calendar/domain/entities/tibetan_calendar_day.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/models/moon_phase.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:flutter_pecha/features/calendar/domain/tibetan_calendar_service.dart';
import 'package:flutter_pecha/features/calendar/domain/usecases/get_calendar_month_usecase.dart';
import 'package:flutter_pecha/features/calendar/domain/usecases/get_today_calendar_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

// ============ Engine (offline fallback + lunar-month mapping) ============

/// The local Tibetan-calendar engine. Used as the offline fallback and to
/// translate Gregorian dates → the lunar months the backend is keyed by.
final tibetanCalendarServiceProvider = Provider<TibetanCalendarService>(
  (ref) => const KharagTibetanCalendarService(),
);

// ============ Backend data layer ============

final calendarRemoteDatasourceProvider = Provider<CalendarRemoteDatasource>(
  (ref) => CalendarRemoteDatasource(dio: ref.watch(dioProvider)),
);

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepositoryImpl(
    datasource: ref.watch(calendarRemoteDatasourceProvider),
    store: ref.watch(screenCacheStoreProvider),
  ),
);

final getCalendarMonthUseCaseProvider = Provider<GetCalendarMonthUseCase>(
  (ref) => GetCalendarMonthUseCase(ref.watch(calendarRepositoryProvider)),
);

final getTodayCalendarUseCaseProvider = Provider<GetTodayCalendarUseCase>(
  (ref) => GetTodayCalendarUseCase(ref.watch(calendarRepositoryProvider)),
);

// ============ Selection / navigation state ============

/// Returns [date] with the time component stripped (midnight local).
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Day selected in the grid; drives the header card. Defaults to today.
final selectedCalendarDayProvider = StateProvider<DateTime>(
  (ref) => dateOnly(DateTime.now()),
);

/// Month shown in the grid (normalized to the 1st). Defaults to this month.
final focusedCalendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

// ============ Hybrid day resolution (backend-primary, engine fallback) ============

/// The backend is keyed by Gregorian year + month — `/calendar/{year}/{month}`
/// returns that Gregorian month's days, each carrying its Tibetan lunar data.
typedef _GregorianMonthKey = ({int year, int month});

/// The padded Gregorian range the grid renders for [month] — the month plus a
/// week on each side to cover table_calendar's leading/trailing days.
({DateTime start, DateTime end}) _visibleRange(DateTime month) => (
  start: DateTime(month.year, month.month, 1).subtract(const Duration(days: 7)),
  end: DateTime(month.year, month.month + 1, 0).add(const Duration(days: 7)),
);

/// Synchronous engine-computed days for the visible range of [month]. Always
/// available (offline-safe) and rendered instantly; the backend overlay refines
/// it when it arrives.
final engineMonthDaysProvider =
    Provider.family<Map<DateTime, TibetanCalendarDay>, DateTime>((ref, month) {
      final service = ref.watch(tibetanCalendarServiceProvider);
      final range = _visibleRange(month);
      final map = <DateTime, TibetanCalendarDay>{};
      for (
        var d = range.start;
        !d.isAfter(range.end);
        d = d.add(const Duration(days: 1))
      ) {
        final key = dateOnly(d);
        map[key] = TibetanCalendarDay.fromEngine(key, service);
      }
      return map;
    });

/// One authoritative Gregorian month from the backend: the stored month shows
/// first, the server month replaces it if changed. Emits an empty list on
/// failure so the caller silently falls back to the engine.
final calendarMonthProvider = AsyncNotifierProvider.family<
  ScreenCacheFamilyNotifier<
    List<TibetanCalendarDay>,
    List<TibetanCalendarDay>,
    _GregorianMonthKey
  >,
  List<TibetanCalendarDay>,
  _GregorianMonthKey
>(() {
  return ScreenCacheFamilyNotifier((ref, key, bind) {
    final repository = ref.watch(calendarRepositoryProvider);
    List<TibetanCalendarDay> orEmpty(
      Either<Failure, List<TibetanCalendarDay>> result,
    ) => result.fold((_) => const <TibetanCalendarDay>[], (days) => days);

    final source = repository.monthSource(key.year, key.month);
    if (source == null) {
      return bind.stream(
        null,
        repository.watchMonth(key.year, key.month).map(orEmpty),
      );
    }
    return bind.source(source, select: orEmpty);
  });
});

/// Backend days overlaying the visible range of [month], keyed by Gregorian
/// date. Empty while nothing has arrived. Watches the Gregorian months the grid
/// spans (the focused month plus the neighbours its leading/trailing days fall
/// into) and rebuilds as each one lands or refreshes.
final backendMonthOverlayProvider =
    Provider.family<Map<DateTime, TibetanCalendarDay>, DateTime>((ref, month) {
      final range = _visibleRange(month);

      final keys = <_GregorianMonthKey>{};
      for (
        var d = range.start;
        !d.isAfter(range.end);
        d = d.add(const Duration(days: 1))
      ) {
        keys.add((year: d.year, month: d.month));
      }

      final overlay = <DateTime, TibetanCalendarDay>{};
      for (final key in keys) {
        final days =
            ref.watch(calendarMonthProvider(key)).valueOrNull ??
            const <TibetanCalendarDay>[];
        for (final day in days) {
          final g = day.gregorianDate;
          if (g == null) continue; // omitted day — no grid cell
          final k = dateOnly(g);
          if (!k.isBefore(range.start) && !k.isAfter(range.end)) {
            overlay[k] = day;
          }
        }
      }
      return overlay;
    });

/// Resolved days for [month]: engine values overlaid with backend values where
/// available. Synchronous (engine is always present); updates when the backend
/// overlay changes. This is what the UI reads.
final resolvedMonthDaysProvider =
    Provider.family<Map<DateTime, TibetanCalendarDay>, DateTime>((ref, month) {
      final engine = ref.watch(engineMonthDaysProvider(month));
      final overlay = ref.watch(backendMonthOverlayProvider(month));
      if (overlay.isEmpty) return engine;
      return {...engine, ...overlay};
    });

/// The lunar day for [date] resolved through [resolvedMonthDaysProvider] of its
/// own month — used by the header card for the selected day.
final resolvedDayProvider = Provider.family<TibetanCalendarDay, DateTime>((
  ref,
  date,
) {
  final month = DateTime(date.year, date.month, 1);
  final days = ref.watch(resolvedMonthDaysProvider(month));
  return days[dateOnly(date)] ??
      TibetanCalendarDay.fromEngine(
        dateOnly(date),
        ref.watch(tibetanCalendarServiceProvider),
      );
});

/// Today's Tibetan calendar day from `GET /calendar/today`, with a silent
/// engine fallback on failure. Used by the home-screen summary card. While the
/// request is in flight the card can show the engine value (see the card's
/// `asData ?? engine` pattern) so there's no spinner.
final todayCalendarDayProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<TibetanCalendarDay, TibetanCalendarDay>,
  TibetanCalendarDay
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final repository = ref.watch(calendarRepositoryProvider);
    TibetanCalendarDay orEngine(Either<Failure, TibetanCalendarDay> result) =>
        result.fold(
          (_) => TibetanCalendarDay.fromEngine(
            dateOnly(DateTime.now()),
            ref.read(tibetanCalendarServiceProvider),
          ),
          (day) => day,
        );

    final source = repository.todaySource();
    if (source == null) {
      return bind.stream(null, repository.watchToday().map(orEngine));
    }
    return bind.source(source, select: orEngine);
  });
});

// ============ Events (moon phases only, derived from resolved days) ============

/// Lunar days that mark new moon, first quarter, and full moon.
const _phaseDays = <int>{1, 8, 15, 30};

/// Moon-phase events within the Gregorian [month], derived from the resolved
/// days so they always match what the grid shows. (Festival/custom events will
/// be added here when a backend events endpoint exists.)
final monthEventsProvider = Provider.family<List<CalendarEvent>, DateTime>((
  ref,
  month,
) {
  final days = ref.watch(resolvedMonthDaysProvider(month));
  final lastDay = DateTime(month.year, month.month + 1, 0).day;

  final events = <CalendarEvent>[];
  for (var d = 1; d <= lastDay; d++) {
    final date = DateTime(month.year, month.month, d);
    final day = days[dateOnly(date)];
    if (day == null || !_phaseDays.contains(day.lunarDay)) continue;
    events.add(
      CalendarEvent(
        date: date,
        lunarDay: day.lunarDay,
        title: '',
        kind: CalendarEventKind.lunarPhase,
        phase: moonPhaseForLunarDay(day.lunarDay),
      ),
    );
  }
  events.sort((a, b) => a.date.compareTo(b.date));
  return events;
});
