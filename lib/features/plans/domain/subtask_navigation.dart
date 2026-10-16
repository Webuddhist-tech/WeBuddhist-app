import 'package:flutter_pecha/core/utils/audio_url.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_subtasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/task_settings.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// Single source of truth for converting plan subtasks into the unified
/// [PlanTextItem] list used by the reader / plan-text navigation strip.
///
/// Each task yields at most one item:
/// - First navigable subtask is SOURCE_REFERENCE → one reader item whose
///   sources are every source subtask of the task, read in turn.
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
  /// `displayOrder`. [withCompletion] false leaves `subtaskId` and
  /// `isCompleted` off, as [fromPlanTasks] does, for a read-only page that
  /// must not call completion APIs.
  static List<PlanTextItem> fromUserTasks(
    List<UserTasksDto> tasks, {
    bool withCompletion = true,
  }) {
    final sorted = List<UserTasksDto>.from(tasks)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final items = <PlanTextItem>[];
    for (final task in sorted) {
      final item = _itemForTask(
        subtasks: _sortedByDisplayOrder(task.subTasks, (s) => s.displayOrder),
        title: task.title,
        taskId: task.id,
        settings: task.settings,
        contentTypeOf: (s) => s.contentType,
        sourceOf: (s) => _toSourceRefFromUser(s, withCompletion: withCompletion),
        blockOf: (s) => _toBlockFromUser(s, withCompletion: withCompletion),
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
        settings: task.settings,
        contentTypeOf: (s) => s.contentType,
        sourceOf: _toSourceRefFromPlan,
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

  /// One item per task: the first navigable subtask decides the kind. A
  /// source item reads every source subtask of the task in turn; an inline
  /// item has one audio control, fed by the first inline subtask with its
  /// own playable audio, else the first inline subtask's day-audio window.
  /// Blank audio URLs count as absent so day audio still wins.
  static PlanTextItem? _itemForTask<S>({
    required List<S> subtasks,
    required String title,
    required String taskId,
    required TaskSettings? settings,
    required String? Function(S) contentTypeOf,
    required PlanSourceRef? Function(S) sourceOf,
    required PlanInlineBlock? Function(S) blockOf,
    required (String? url, int? startMs, int? endMs) Function(S) audioOf,
  }) {
    final isLive = settings?.isLive ?? false;
    for (final subtask in subtasks) {
      final type = PlanContentTypes.parse(contentTypeOf(subtask));
      if (type == null) continue;
      if (type == PlanItemContentType.sourceReference) {
        if (sourceOf(subtask) == null) continue;
        return PlanTextItem.sources(
          sources: subtasks.map(sourceOf).whereType<PlanSourceRef>().toList(),
          title: title,
          taskId: taskId,
          autoOpenCommentary: settings?.isCommentaryOpen ?? false,
          commentaryTextId: settings?.commentaryTextId,
          autoOpenTranslation: settings?.isTranslationOpen ?? false,
          translationTextId: settings?.translationTextId,
          isLive: isLive,
        );
      }
      if (blockOf(subtask) == null) continue;
      final inline = subtasks.where((s) => blockOf(s) != null).toList();
      final audioSource = inline.firstWhere(
        (s) => hasPlayableAudio(audioOf(s).$1),
        orElse: () => subtask,
      );
      final (audioUrl, startMs, endMs) = audioOf(audioSource);
      return PlanTextItem.inline(
        blocks: inline.map(blockOf).whereType<PlanInlineBlock>().toList(),
        title: title,
        taskId: taskId,
        audioUrl: normalizeAudioUrl(audioUrl),
        startMs: startMs,
        endMs: endMs,
        isLive: isLive,
      );
    }
    return null;
  }

  /// Stable sort by `displayOrder`. If any subtask lacks one, the API order
  /// is kept as is.
  static List<T> _sortedByDisplayOrder<T>(
    List<T> subtasks,
    int? Function(T) orderOf,
  ) {
    if (subtasks.any((s) => orderOf(s) == null)) return subtasks;
    final indexed = subtasks.asMap().entries.toList()..sort((a, b) {
      final byOrder = orderOf(a.value)!.compareTo(orderOf(b.value)!);
      return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  static bool _isUserSubtaskNavigable(UserSubtasksDto s) =>
      _toSourceRefFromUser(s) != null || _toBlockFromUser(s) != null;

  static bool _isPlanSubtaskNavigable(PlanSubtasksModel s) =>
      _toSourceRefFromPlan(s) != null || _toBlockFromPlan(s) != null;

  static PlanSourceRef? _toSourceRefFromUser(
    UserSubtasksDto subtask, {
    bool withCompletion = true,
  }) {
    if (PlanContentTypes.parse(subtask.contentType) !=
        PlanItemContentType.sourceReference) {
      return null;
    }
    if (!_hasSourceText(subtask.sourceTextId)) return null;
    return PlanSourceRef(
      textId: subtask.sourceTextId!,
      segmentIds: subtask.segmentIds,
      subtaskId: withCompletion ? subtask.id : null,
      isCompleted: withCompletion && subtask.isCompleted,
      audioUrl: normalizeAudioUrl(subtask.audioUrl),
      startMs: subtask.startMs,
      endMs: subtask.endMs,
    );
  }

  static PlanSourceRef? _toSourceRefFromPlan(PlanSubtasksModel subtask) {
    if (PlanContentTypes.parse(subtask.contentType) !=
        PlanItemContentType.sourceReference) {
      return null;
    }
    if (!_hasSourceText(subtask.sourceTextId)) return null;
    return PlanSourceRef(
      textId: subtask.sourceTextId!,
      segmentIds: subtask.segmentIds,
      audioUrl: normalizeAudioUrl(subtask.audioUrl),
      startMs: subtask.startMs,
      endMs: subtask.endMs,
    );
  }

  static PlanInlineBlock? _toBlockFromUser(
    UserSubtasksDto subtask, {
    bool withCompletion = true,
  }) {
    final type = PlanContentTypes.parse(subtask.contentType);
    if (type == null || !type.isInline) return null;
    if (!_hasInlineContent(subtask.content)) return null;
    return PlanInlineBlock(
      contentType: type,
      content: subtask.content,
      subtaskId: withCompletion ? subtask.id : null,
      isCompleted: withCompletion && subtask.isCompleted,
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
