import 'package:flutter_pecha/features/plans/data/models/plan_subtasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// Single source of truth for converting plan subtasks into the unified
/// [PlanTextItem] list used by the reader / plan-text navigation strip.
///
/// Validation rules (kept in one place):
/// - SOURCE_REFERENCE → valid iff `sourceTextId` is non-null and non-empty.
/// - TEXT             → valid iff `content.trim()` is non-empty.
/// - IMAGE            → valid iff `content.trim()` is non-empty.
/// - GROUP_ACCUMULATION → not a reader item; opens the group accumulator screen.
/// - Anything else (unknown content type, missing fields) is silently dropped.
///
/// Both task models (`UserTasksDto` for enrolled users, `PlanTasksModel` for
/// preview) are normalised through the same code path, so navigation behaves
/// identically regardless of which screen the user came from.
class PlanSubtaskNavigation {
  PlanSubtaskNavigation._();

  /// Build the unified item list for an enrolled user.
  /// Tasks are sorted by `displayOrder`; the first navigable subtask of each
  /// task is included.
  static List<PlanTextItem> fromUserTasks(List<UserTasksDto> tasks) {
    final sorted = List<UserTasksDto>.from(tasks)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final items = <PlanTextItem>[];
    for (final task in sorted) {
      final item = _firstNavigableUserSubtask(task);
      if (item != null) items.add(item);
    }
    return items;
  }

  /// Build the unified item list for the preview (unenrolled) flow.
  /// `subtaskId` and `isCompleted` are intentionally omitted — preview must
  /// not call completion APIs.
  static List<PlanTextItem> fromPlanTasks(List<PlanTasksModel> tasks) {
    final sorted = List<PlanTasksModel>.from(tasks)..sort((a, b) {
      final orderA = a.displayOrder ?? 0;
      final orderB = b.displayOrder ?? 0;
      return orderA.compareTo(orderB);
    });

    final items = <PlanTextItem>[];
    for (final task in sorted) {
      final item = _firstNavigablePlanSubtask(task);
      if (item != null) items.add(item);
    }
    return items;
  }

  /// True if the given task has at least one navigable subtask
  /// (SOURCE_REFERENCE, TEXT, IMAGE, or GROUP_ACCUMULATION).
  static bool isUserTaskNavigable(UserTasksDto task) {
    return task.subTasks.any(_isUserSubtaskNavigable) ||
        groupAccumulationIdForUserTask(task) != null;
  }

  /// Same as [isUserTaskNavigable] for the preview model.
  static bool isPlanTaskNavigable(PlanTasksModel task) {
    return task.subtasks.any(_isPlanSubtaskNavigable) ||
        groupAccumulationIdForPlanTask(task) != null;
  }

  /// Accumulator id of the task's first GROUP_ACCUMULATION subtask, or null.
  static String? groupAccumulationIdForUserTask(UserTasksDto task) {
    for (final subtask in task.subTasks) {
      final id = subtask.groupAccumulationId;
      if (id != null) return id;
    }
    return null;
  }

  /// Same as [groupAccumulationIdForUserTask] for the preview model.
  static String? groupAccumulationIdForPlanTask(PlanTasksModel task) {
    for (final subtask in task.subtasks) {
      final id = subtask.groupAccumulationId;
      if (id != null) return id;
    }
    return null;
  }

  // ─── Internal helpers ───────────────────────────────────────────────

  static PlanTextItem? _firstNavigableUserSubtask(UserTasksDto task) {
    for (final subtask in task.subTasks) {
      final item = _toItemFromUserSubtask(subtask, task.title);
      if (item != null) return item;
    }
    return null;
  }

  static PlanTextItem? _firstNavigablePlanSubtask(PlanTasksModel task) {
    for (final subtask in task.subtasks) {
      final item = _toItemFromPlanSubtask(subtask, task.title);
      if (item != null) return item;
    }
    return null;
  }

  static bool _isUserSubtaskNavigable(UserSubtasksDto s) =>
      _toItemFromUserSubtask(s, '') != null;

  static bool _isPlanSubtaskNavigable(PlanSubtasksModel s) =>
      _toItemFromPlanSubtask(s, '') != null;

  static PlanTextItem? _toItemFromUserSubtask(
    UserSubtasksDto subtask,
    String title,
  ) {
    final type = PlanContentTypes.parse(subtask.contentType);
    switch (type) {
      case PlanItemContentType.sourceReference:
        if (!_hasSourceText(subtask.sourceTextId)) return null;
        return PlanTextItem.sourceReference(
          textId: subtask.sourceTextId!,
          title: title,
          segmentIds: subtask.segmentIds,
          subtaskId: subtask.id,
          isCompleted: subtask.isCompleted,
          audioUrl: subtask.audioUrl,
          startMs: subtask.startMs,
          endMs: subtask.endMs,
        );
      case PlanItemContentType.inlineText:
        if (!_hasInlineContent(subtask.content)) return null;
        return PlanTextItem.inlineText(
          content: subtask.content,
          title: title,
          subtaskId: subtask.id,
          isCompleted: subtask.isCompleted,
          audioUrl: subtask.audioUrl,
          startMs: subtask.startMs,
          endMs: subtask.endMs,
        );
      case PlanItemContentType.inlineImage:
        if (!_hasInlineContent(subtask.content)) return null;
        return PlanTextItem.inlineImage(
          imageUrl: subtask.content,
          title: title,
          subtaskId: subtask.id,
          isCompleted: subtask.isCompleted,
          audioUrl: subtask.audioUrl,
          startMs: subtask.startMs,
          endMs: subtask.endMs,
        );
      case null:
        return null;
    }
  }

  static PlanTextItem? _toItemFromPlanSubtask(
    PlanSubtasksModel subtask,
    String title,
  ) {
    final type = PlanContentTypes.parse(subtask.contentType);
    switch (type) {
      case PlanItemContentType.sourceReference:
        if (!_hasSourceText(subtask.sourceTextId)) return null;
        return PlanTextItem.sourceReference(
          textId: subtask.sourceTextId!,
          title: title,
          segmentIds: subtask.segmentIds,
          audioUrl: subtask.audioUrl,
          startMs: subtask.startMs,
          endMs: subtask.endMs,
        );
      case PlanItemContentType.inlineText:
        if (!_hasInlineContent(subtask.content)) return null;
        return PlanTextItem.inlineText(
          content: subtask.content!,
          title: title,
          audioUrl: subtask.audioUrl,
          startMs: subtask.startMs,
          endMs: subtask.endMs,
        );
      case PlanItemContentType.inlineImage:
        if (!_hasInlineContent(subtask.content)) return null;
        return PlanTextItem.inlineImage(
          imageUrl: subtask.content!,
          title: title,
          audioUrl: subtask.audioUrl,
          startMs: subtask.startMs,
          endMs: subtask.endMs,
        );
      case null:
        return null;
    }
  }

  static bool _hasSourceText(String? sourceTextId) =>
      sourceTextId != null && sourceTextId.isNotEmpty;

  static bool _hasInlineContent(String? content) =>
      content != null && content.trim().isNotEmpty;
}
