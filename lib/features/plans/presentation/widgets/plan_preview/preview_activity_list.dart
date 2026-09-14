import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_accumulator_practice_launcher.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/plans/plans.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_shorts_section.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A read-only activity list for previewing plan tasks before enrollment.
/// Mirrors `ActivityList` but works with `PlanTasksModel` (non-enrolled
/// data) and never tracks subtask completion.
///
/// Tapping a row opens the appropriate screen (ReaderScreen for
/// SOURCE_REFERENCE, PlanTextScreen for TEXT/IMAGE) with the unified
/// [PlanTextItem] list, so the bottom-bar progress works the same as in
/// the enrolled flow.
class PreviewActivityList extends ConsumerWidget {
  final String language;
  final List<PlanTasksModel> tasks;
  final List<PlanVideoModel> videos;
  final int today;
  final int totalDays;
  final String? planId;
  final int? dayNumber;
  final String? dayAudioUrl;

  const PreviewActivityList({
    super.key,
    required this.language,
    required this.tasks,
    this.videos = const [],
    required this.today,
    required this.totalDays,
    this.planId,
    this.dayNumber,
    this.dayAudioUrl,
  });

  List<PlanTasksModel> get _sortedTasks {
    return List<PlanTasksModel>.from(tasks)..sort((a, b) {
      final orderA = a.displayOrder ?? 0;
      final orderB = b.displayOrder ?? 0;
      return orderA.compareTo(orderB);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty && videos.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedTasks = _sortedTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedTasks.length,
          itemBuilder: (context, index) {
            final task = sortedTasks[index];
            final isNavigable = PlanSubtaskNavigation.isPlanTaskNavigable(task);
            final isGroupAccumulation =
                PlanSubtaskNavigation.groupAccumulationIdForPlanTask(task) !=
                null;
            final hasAudio = !isGroupAccumulation && _taskHasAudio(task);
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _PreviewTaskItem(
                      language: language,
                      task: task,
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

  bool _taskHasAudio(PlanTasksModel task) {
    if (dayAudioUrl != null) return true;
    return task.subtasks.any((s) => s.hasOwnAudio);
  }

  void _handleActivityTap(
    BuildContext context,
    WidgetRef ref,
    PlanTasksModel task, {
    required bool autoPlay,
  }) {
    final accumulatorId = PlanSubtaskNavigation.groupAccumulationIdForPlanTask(
      task,
    );
    if (accumulatorId != null) {
      openGroupAccumulatorPractice(context, ref, accumulatorId: accumulatorId);
      return;
    }

    final planTextItems = PlanSubtaskNavigation.fromPlanTasks(tasks);
    if (planTextItems.isEmpty) return;

    // Find this task's position in the unified list. Without subtaskId
    // (preview mode) we match on title — task titles are unique within
    // a day in practice, and a stale match still navigates somewhere
    // reasonable in the same list.
    final index = planTextItems.indexWhere((item) => item.title == task.title);
    if (index < 0) return;

    final target = planTextItems[index];
    final navigationContext = NavigationContext(
      source: NavigationSource.plan,
      planId: planId,
      dayNumber: dayNumber,
      targetSegmentId: target.firstSegmentId,
      planTextItems: planTextItems,
      currentTextIndex: index,
      autoPlay: autoPlay,
      dayAudioUrl: dayAudioUrl,
    );

    PlanNavigator.push(context, target, navigationContext);
  }
}

/// Task item widget for preview mode (read-only, no checkbox)
class _PreviewTaskItem extends StatelessWidget {
  const _PreviewTaskItem({
    required this.language,
    required this.task,
    required this.hasNavigableContent,
    required this.hasAudio,
    required this.onTap,
  });

  final String language;
  final PlanTasksModel task;
  final bool hasNavigableContent;
  final bool hasAudio;
  final VoidCallback onTap;

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
                task.title,
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
