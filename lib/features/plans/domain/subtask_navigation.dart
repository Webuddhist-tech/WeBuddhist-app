import 'package:flutter_pecha/features/plans/data/models/plan_subtasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// Single source of truth for converting plan subtasks into the unified
/// [PlanTextItem] list used by the reader / plan-text navigation strip.
///
/// Each task yields at most one item:
/// - First navigable subtask is SOURCE_REFERENCE → a reader item for it.
/// - First navigable subtask is TEXT / IMAGE / VIDEO → one inline item whose
///   blocks are every inline subtask of the task, shown on a single page.
/// - GROUP_ACCUMULATION → not a reader item; opens the group accumulator.
/// - Anything else (unknown content type, missing fields) is silently dropped.
///
/// Both task models (`UserTasksDto` for enrolled users, `PlanTasksModel` for
/// preview) are normalised through the same code path, so navigation behaves
/// identically regardless of which screen the user came from.
class PlanSubtaskNavigation {
  PlanSubtaskNavigation._();

  /// Build the unified item list for an enrolled user, sorted by task
  /// `displayOrder`.
  static List<PlanTextItem> fromUserTasks(List<UserTasksDto> tasks) {
    final sorted = List<UserTasksDto>.from(tasks)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final items = <PlanTextItem>[];
    for (final task in sorted) {
      final item = _itemForTask(
        subtasks: _sortedByDisplayOrder(task.subTasks, (s) => s.displayOrder),
        title: task.title,
        taskId: task.id,
        contentTypeOf: (s) => s.contentType,
        sourceOf: (s) => _toSourceItemFromUser(s, task.title, task.id),
        blockOf: _toBlockFromUser,
        audioOf: (s) => (s.audioUrl, s.startMs, s.endMs),
      );
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
      final item = _itemForTask(
        subtasks: _sortedByDisplayOrder(task.subtasks, (s) => s.displayOrder),
        title: task.title,
        taskId: task.id,
        contentTypeOf: (s) => s.contentType,
        sourceOf: (s) => _toSourceItemFromPlan(s, task.title, task.id),
        blockOf: _toBlockFromPlan,
        audioOf: (s) => (s.audioUrl, s.startMs, s.endMs),
      );
      if (item != null) items.add(item);
    }
    return items;
  }

  /// True if the given task has at least one navigable subtask
  /// (SOURCE_REFERENCE, TEXT, IMAGE, VIDEO, or GROUP_ACCUMULATION).
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

  /// One item per task: the first navigable subtask decides the kind. An
  /// inline item takes its audio from its first inline subtask.
  static PlanTextItem? _itemForTask<S>({
    required List<S> subtasks,
    required String title,
    required String taskId,
    required String? Function(S) contentTypeOf,
    required PlanTextItem? Function(S) sourceOf,
    required PlanInlineBlock? Function(S) blockOf,
    required (String? url, int? startMs, int? endMs) Function(S) audioOf,
  }) {
    for (final subtask in subtasks) {
      final type = PlanContentTypes.parse(contentTypeOf(subtask));
      if (type == null) continue;
      if (type == PlanItemContentType.sourceReference) {
        final item = sourceOf(subtask);
        if (item != null) return item;
        continue;
      }
      if (blockOf(subtask) == null) continue;
      final blocks = subtasks.map(blockOf).whereType<PlanInlineBlock>();
      final (audioUrl, startMs, endMs) = audioOf(subtask);
      return PlanTextItem.inline(
        blocks: blocks.toList(),
        title: title,
        taskId: taskId,
        audioUrl: audioUrl,
        startMs: startMs,
        endMs: endMs,
      );
    }
    return null;
  }

  /// Stable sort by `displayOrder`; items without one keep their position.
  static List<T> _sortedByDisplayOrder<T>(
    List<T> subtasks,
    int? Function(T) orderOf,
  ) {
    final indexed = subtasks.asMap().entries.toList()..sort((a, b) {
      final byOrder = (orderOf(a.value) ?? a.key).compareTo(
        orderOf(b.value) ?? b.key,
      );
      return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  static bool _isUserSubtaskNavigable(UserSubtasksDto s) =>
      _toSourceItemFromUser(s, '', null) != null || _toBlockFromUser(s) != null;

  static bool _isPlanSubtaskNavigable(PlanSubtasksModel s) =>
      _toSourceItemFromPlan(s, '', null) != null || _toBlockFromPlan(s) != null;

  static PlanTextItem? _toSourceItemFromUser(
    UserSubtasksDto subtask,
    String title,
    String? taskId,
  ) {
    if (PlanContentTypes.parse(subtask.contentType) !=
        PlanItemContentType.sourceReference) {
      return null;
    }
    if (!_hasSourceText(subtask.sourceTextId)) return null;
    return PlanTextItem.sourceReference(
      textId: subtask.sourceTextId!,
      title: title,
      segmentIds: subtask.segmentIds,
      subtaskId: subtask.id,
      taskId: taskId,
      isCompleted: subtask.isCompleted,
      audioUrl: subtask.audioUrl,
      startMs: subtask.startMs,
      endMs: subtask.endMs,
    );
  }

  static PlanTextItem? _toSourceItemFromPlan(
    PlanSubtasksModel subtask,
    String title,
    String? taskId,
  ) {
    if (PlanContentTypes.parse(subtask.contentType) !=
        PlanItemContentType.sourceReference) {
      return null;
    }
    if (!_hasSourceText(subtask.sourceTextId)) return null;
    return PlanTextItem.sourceReference(
      textId: subtask.sourceTextId!,
      title: title,
      segmentIds: subtask.segmentIds,
      taskId: taskId,
      audioUrl: subtask.audioUrl,
      startMs: subtask.startMs,
      endMs: subtask.endMs,
    );
  }

  static PlanInlineBlock? _toBlockFromUser(UserSubtasksDto subtask) {
    final type = PlanContentTypes.parse(subtask.contentType);
    if (type == null || !type.isInline) return null;
    if (!_hasInlineContent(subtask.content)) return null;
    return PlanInlineBlock(
      contentType: type,
      content: subtask.content,
      subtaskId: subtask.id,
      isCompleted: subtask.isCompleted,
    );
  }

  static PlanInlineBlock? _toBlockFromPlan(PlanSubtasksModel subtask) {
    final type = PlanContentTypes.parse(subtask.contentType);
    if (type == null || !type.isInline) return null;
    if (!_hasInlineContent(subtask.content)) return null;
    return PlanInlineBlock(contentType: type, content: subtask.content!);
  }

  static bool _hasSourceText(String? sourceTextId) =>
      sourceTextId != null && sourceTextId.isNotEmpty;

  static bool _hasInlineContent(String? content) =>
      content != null && content.trim().isNotEmpty;
}
