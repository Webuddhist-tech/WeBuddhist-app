import 'package:flutter_pecha/core/utils/app_logger.dart';

final _logger = AppLogger('PlanUtils');

class PlanUtils {
  static final _calendarDatePrefix = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');

  /// Parses a backend calendar-date string (e.g. `2026-05-14T00:00:00.000Z`)
  /// into a local-midnight DateTime preserving the calendar day.
  ///
  /// Backend sends plan start dates as UTC midnight, but these represent
  /// **calendar dates**, not instants. A naive `.toLocal()` shifts the day
  /// in negative-offset zones (e.g. May 14 UTC midnight → May 13 20:00 in
  /// Toronto), producing off-by-one day-N calculations. This helper extracts
  /// the `YYYY-MM-DD` prefix and rebuilds at local midnight so the calendar
  /// day is preserved everywhere downstream — including after Hive cache
  /// round-trips that drop the timezone suffix via [DateTime.toIso8601String].
  static DateTime? parseCalendarDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final match = _calendarDatePrefix.firstMatch(iso);
    if (match == null) {
      _logger.warning('[CAL-DATE] failed to parse: $iso');
      return null;
    }
    final normalized = DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    _logger.info(
      '[CAL-DATE] raw=$iso localMidnight=${normalized.toIso8601String()}',
    );
    return normalized;
  }

  /// Normalizes a [DateTime] to local midnight for calendar-date display and
  /// comparisons. For UTC instants (API `…Z` values), uses the UTC
  /// year/month/day; for local values (from [parseCalendarDate]), uses local
  /// components — both preserve the backend calendar day.
  static DateTime calendarDateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Calendar days from [from] to [to]; UTC dates so DST cannot shift it.
  static int daysBetween(DateTime from, DateTime to) {
    final start = from.toLocal();
    final end = to.toLocal();
    return DateTime.utc(end.year, end.month, end.day)
        .difference(DateTime.utc(start.year, start.month, start.day))
        .inDays;
  }

  static int calculateSelectedDay(DateTime startedAt, int totalDays) {
    final today = DateTime.now();
    final localStartedAt = startedAt.toLocal();

    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedStartedAt = DateTime(
      localStartedAt.year,
      localStartedAt.month,
      localStartedAt.day,
    );

    if (normalizedToday.isAtSameMomentAs(normalizedStartedAt)) {
      return 1;
    } else if (normalizedToday.isAfter(normalizedStartedAt)) {
      final difference =
          normalizedToday.difference(normalizedStartedAt).inDays + 1;
      if (difference > totalDays) {
        return totalDays;
      } else {
        return difference;
      }
    }

    return 1;
  }

  /// Returns the plan day-number (1-based) for [forDate], using
  /// [planStartDate] as the anchor for Day 1. Clamped to `[1, totalDays]`.
  /// Returns 0 if [forDate] is before the plan started.
  static int dayNumberFor(
    DateTime planStartDate,
    DateTime forDate,
    int totalDays,
  ) {
    final start = planStartDate.toLocal();
    final target = forDate.toLocal();
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedTarget = DateTime(target.year, target.month, target.day);
    if (normalizedTarget.isBefore(normalizedStart)) return 0;
    final diff = normalizedTarget.difference(normalizedStart).inDays + 1;
    if (diff > totalDays) return totalDays;
    return diff;
  }

  /// Counts past scheduled days (from Day 1) the user has not completed.
  ///
  /// Always counts from Day 1 regardless of when the user enrolled, so late
  /// joiners see the full backlog they need to catch up on. Excludes today
  /// while the plan is still active (the user still has time to finish it),
  /// but includes the last day once the plan has fully ended.
  ///
  /// [planStartDate]: Day 1 anchor (= `plan.startDate ?? plan.startedAt`).
  static int calculateMissedDays(
    DateTime planStartDate,
    int totalDays,
    Map<int, bool> completionStatus,
  ) {
    final now = DateTime.now();
    final normalizedToday = DateTime(now.year, now.month, now.day);
    final todayDayNumber = dayNumberFor(planStartDate, now, totalDays);

    final start = planStartDate.toLocal();
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final lastPlanDay = normalizedStart.add(Duration(days: totalDays - 1));

    // When today is past the plan's last day, every incomplete day is missed.
    // While the plan is active, today is excluded (user still has time).
    final isPlanOver = normalizedToday.isAfter(lastPlanDay);
    final upperBound = isPlanOver ? totalDays : todayDayNumber - 1;

    int missedCount = 0;
    for (int day = 1; day <= upperBound; day++) {
      if (completionStatus[day] != true) missedCount++;
    }

    _logger.info(
      '[ENROLL-MISSED] planStart=${planStartDate.toIso8601String()} '
      'todayDay=$todayDayNumber isPlanOver=$isPlanOver missed=$missedCount',
    );
    return missedCount;
  }
}
