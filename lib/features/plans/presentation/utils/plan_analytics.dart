import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where a plan preview was opened from, carried on `plan_previewed`.
enum PlanPreviewSource { catalog, series, event }

/// Where a plan was enrolled in or opened from, carried as `source`.
enum PlanSource { browse, onboarding, event, series }

/// Product analytics for plans: one method per tracked action, so the event
/// names and their property keys live in one place. Every call fires and
/// forgets; callers fire after the server confirms, never optimistically.
class PlanAnalytics {
  const PlanAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// The content type shared by a task's subtasks, `mixed` when they differ.
  static String? taskTypeOf(UserTasksDto task) {
    final types = {
      for (final subtask in task.subTasks)
        subtask.contentType.trim().toLowerCase(),
    };
    if (types.isEmpty) return null;
    return types.length == 1 ? types.first : 'mixed';
  }

  /// An unenrolled plan was opened for preview.
  void planPreviewed({
    required String planId,
    required String planName,
    required int totalDays,
    required PlanPreviewSource source,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.planPreviewed, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.planName: planName,
      AnalyticsProperties.totalDays: totalDays,
      AnalyticsProperties.source: source.name,
    });
  }

  /// The user chose to add the plan to their routine; enrollment itself
  /// happens when that routine is saved.
  void planAddedToPractices({
    required String planId,
    required String planName,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.planAddedToPractices, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.planName: planName,
    });
  }

  /// The server confirmed a new enrolment; name and length when at hand.
  void planEnrolled({
    required String planId,
    required PlanSource source,
    String? planName,
    int? totalDays,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.planEnrolled, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.planName: planName,
      AnalyticsProperties.totalDays: totalDays,
      AnalyticsProperties.source: source.name,
    });
  }

  /// A plan's detail screen opened; [source] only when the route says.
  void planViewed({
    required String planId,
    required String planName,
    required int totalDays,
    required bool isEnrolled,
    PlanSource? source,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.planViewed, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.planName: planName,
      AnalyticsProperties.totalDays: totalDays,
      AnalyticsProperties.isEnrolled: isEnrolled,
      AnalyticsProperties.source: source?.name,
    });
  }

  /// The day carousel settled on a day. [isMissed] is null until the
  /// completion status has loaded.
  void planDayViewed({
    required String planId,
    required int dayNumber,
    required bool isToday,
    required bool? isMissed,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.planDayViewed, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.dayNumber: dayNumber,
      AnalyticsProperties.isToday: isToday,
      AnalyticsProperties.isMissed: isMissed,
    });
  }

  /// A task checkbox toggle the server confirmed.
  void planTaskToggled({
    required String planId,
    required int dayNumber,
    required String taskId,
    required String? taskType,
    required bool completed,
  }) {
    final event =
        completed
            ? AnalyticsEvents.planTaskCompleted
            : AnalyticsEvents.planTaskUncompleted;
    _analytics.trackInBackground(event, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.dayNumber: dayNumber,
      AnalyticsProperties.taskId: taskId,
      AnalyticsProperties.taskType: taskType,
    });
  }

  /// A day's last task was completed; [isOnTime] on its scheduled date.
  void planDayCompleted({
    required String planId,
    required String planName,
    required int dayNumber,
    required int totalDays,
    required int completedDays,
    required bool isOnTime,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.planDayCompleted, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.planName: planName,
      AnalyticsProperties.dayNumber: dayNumber,
      AnalyticsProperties.totalDays: totalDays,
      AnalyticsProperties.completedDays: completedDays,
      AnalyticsProperties.isOnTime: isOnTime,
    });
  }

  /// Every day is complete; [daysElapsed] counts from the plan's start.
  void planCompleted({
    required String planId,
    required int totalDays,
    required int daysElapsed,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.planCompleted, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.totalDays: totalDays,
      AnalyticsProperties.daysElapsed: daysElapsed,
    });
  }

  /// Progress fields are sent when the caller has them loaded.
  void planUnenrolled({
    required String planId,
    required String planName,
    int? daysCompleted,
    int? daysSinceEnrolled,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.planUnenrolled, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.planName: planName,
      AnalyticsProperties.daysCompleted: daysCompleted,
      AnalyticsProperties.daysSinceEnrolled: daysSinceEnrolled,
    });
  }

  /// A debounced catalog search returned its first page. Only the length of
  /// the query is sent: the text itself could be personal.
  void planSearched({required int queryLength, required int resultCount}) {
    _analytics.trackInBackground(AnalyticsEvents.planSearched, {
      AnalyticsProperties.queryLength: queryLength,
      AnalyticsProperties.resultCount: resultCount,
    });
  }
}

final planAnalyticsProvider = Provider<PlanAnalytics>((ref) {
  return PlanAnalytics(ref.watch(analyticsServiceProvider));
});
