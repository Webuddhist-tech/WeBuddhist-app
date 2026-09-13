import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_accumulator_practice_launcher.dart';
import 'package:flutter_pecha/features/plans/data/models/author/author_dto_model.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/plans/plans.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_shorts_section.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Activity list for the *enrolled* plan flow. Each row is one task; the row
/// is enabled iff at least one subtask is navigable. Tapping the title opens
/// the task without auto-playing audio; tapping the play icon opens it with
/// auto-play (only shown when the task has an audio segment).
class ActivityList extends ConsumerWidget {
  final String language;
  final List<UserTasksDto> tasks;
  final List<PlanVideoModel> videos;
  final int today;
  final int totalDays;
  final Function(String taskId) onActivityToggled;
  final Function(String taskId)? onGroupAccumulationPracticed;
  final VoidCallback? onReaderClosed;
  final AuthorDtoModel? author;
  final String? planId;
  final int? dayNumber;
  final String? dayAudioUrl;

  const ActivityList({
    super.key,
    required this.language,
    required this.tasks,
    this.videos = const [],
    required this.today,
    required this.totalDays,
    required this.onActivityToggled,
    this.onGroupAccumulationPracticed,
    this.onReaderClosed,
    this.author,
    this.planId,
    this.dayNumber,
    this.dayAudioUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedTasks = List<UserTasksDto>.from(tasks)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedTasks.length,
          itemBuilder: (context, index) {
            final task = sortedTasks[index];
            final isNavigable = PlanSubtaskNavigation.isUserTaskNavigable(task);
            final isGroupAccumulation =
                PlanSubtaskNavigation.groupAccumulationIdForUserTask(task) !=
                null;
            final hasAudio = !isGroupAccumulation && _taskHasAudio(task);
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  _TaskCheckbox(
                    isCompleted: task.isCompleted,
                    onTap: () => onActivityToggled(task.id),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TaskTitleButton(
                      language: language,
                      title: task.title,
                      hasNavigableContent: isNavigable,
                      hasAudio: hasAudio,
                      onTap:
                          () => _handleActivityTap(
                            context,
                            ref,
                            task,
                            autoPlay: false,
                          ),
                    ),
                  ),
                  if (isNavigable && hasAudio) ...[
                    const SizedBox(width: 8),
                    _PlayButton(
                      onTap:
                          () => _handleActivityTap(
                            context,
                            ref,
                            task,
                            autoPlay: true,
                          ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        PlanShortsSection(videos: videos),
      ],
    );
  }

  bool _taskHasAudio(UserTasksDto task) {
    // A subtask plays audio when it has its own audio file, or the day-level
    // track is available as a fallback. Subtask audio takes precedence.
    if (dayAudioUrl != null) return true;
    return task.subTasks.any((s) => s.hasOwnAudio);
  }

  void _handleActivityTap(
    BuildContext context,
    WidgetRef ref,
    UserTasksDto task, {
    required bool autoPlay,
  }) {
    final accumulatorId = PlanSubtaskNavigation.groupAccumulationIdForUserTask(
      task,
    );
    if (accumulatorId != null) {
      openGroupAccumulatorPractice(
        context,
        ref,
        accumulatorId: accumulatorId,
      ).then((practiced) {
        if (practiced) onGroupAccumulationPracticed?.call(task.id);
        onReaderClosed?.call();
      });
      return;
    }

    final planTextItems = PlanSubtaskNavigation.fromUserTasks(tasks);
    if (planTextItems.isEmpty) return;

    final index = planTextItems.indexWhere(
      (item) =>
          item.subtaskId != null &&
          task.subTasks.any((s) => s.id == item.subtaskId),
    );
    if (index < 0) return;

    final target = planTextItems[index];
    final effectiveAudioUrl = dayAudioUrl;

    final navigationContext = NavigationContext(
      source: NavigationSource.plan,
      planId: planId,
      dayNumber: dayNumber,
      targetSegmentId: target.firstSegmentId,
      planTextItems: planTextItems,
      currentTextIndex: index,
      autoPlay: autoPlay,
      dayAudioUrl: effectiveAudioUrl,
    );

    PlanNavigator.push(
      context,
      target,
      navigationContext,
    ).then((_) => onReaderClosed?.call());
  }
}

/// Checkbox widget for task completion with ripple effect
class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({required this.isCompleted, required this.onTap});

  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 24,
          height: 24,
          decoration:
              isCompleted
                  ? null
                  : BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).iconTheme.color!,
                      width: 1,
                    ),
                    color: Colors.transparent,
                  ),
          child: isCompleted ? Icon(AppAssets.check, size: 20) : null,
        ),
      ),
    );
  }
}

/// Task title button — tapping opens the task without audio auto-play.
/// Shows the original chevron when the task is navigable but has no audio.
class _TaskTitleButton extends StatelessWidget {
  const _TaskTitleButton({
    required this.title,
    required this.onTap,
    required this.language,
    required this.hasNavigableContent,
    required this.hasAudio,
  });

  final String title;
  final VoidCallback onTap;
  final String language;
  final bool hasNavigableContent;
  final bool hasAudio;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasNavigableContent ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (hasNavigableContent && !hasAudio) ...[
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(100), width: 1),
                ),
                child: Icon(AppAssets.caretRight, size: 16, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Circular play button shown on tasks that have an audio segment.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withAlpha(100), width: 1),
          ),
          child: Icon(Icons.play_arrow, size: 22, color: color),
        ),
      ),
    );
  }
}
