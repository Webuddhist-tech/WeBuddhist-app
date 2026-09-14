import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_accumulator_practice_launcher.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_live_utils.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_live_player.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_live_toggles.dart';
import 'package:flutter_pecha/features/home/presentation/providers/routine_info_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/data/utils/series_plan_utils.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/plan_day_share.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_embedded_host.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_embedded_panel.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../day_completion_bottom_sheet.dart';
import '../plan_cover_image.dart';
import '../day_carousel.dart';
import 'activity_list.dart';
import 'missed_days_badge.dart';

final _logger = AppLogger('PlanDetails');

enum _LiveStatus { loading, live, none, failed }

class PlanDetails extends ConsumerStatefulWidget {
  const PlanDetails({
    super.key,
    required this.plan,
    required this.selectedDay,
    required this.startDate,
    this.seriesId,
    this.eventId,
  });
  final UserPlansModel plan;
  final int selectedDay;
  final DateTime startDate;
  final String? seriesId;

  /// Set when opened from an event, to show its live stream above the days.
  final String? eventId;

  @override
  ConsumerState<PlanDetails> createState() => _PlanDetailsState();
}

class _PlanDetailsState extends ConsumerState<PlanDetails> {
  late int selectedDay;
  final Set<String> _togglingTaskIds = {};
  final Map<int, bool> _dayCompletionTracker = {};
  final Map<String, bool> _optimisticCompletions = {};
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _isSharing = false;
  late String _liveLanguage;
  bool _liveAudioOnly = false;
  bool _liveStreamSeen = false;
  final _embedded = PlanEmbeddedController();

  @override
  void initState() {
    super.initState();
    selectedDay = widget.selectedDay;
    _embedded.addListener(_onEmbeddedChanged);
    _liveLanguage = GroupEventLiveUtils.initialLanguage(
      ref.read(contentLanguageProvider),
    );
    _logger.info(
      'PlanDetails opened — id: ${widget.plan.id} | title: "${widget.plan.title}"',
    );
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(
            AnalyticsEvents.planViewed,
            properties: {
              AnalyticsProperties.planId: widget.plan.id,
              AnalyticsProperties.planName: widget.plan.title,
              AnalyticsProperties.totalDays: widget.plan.totalDays,
            },
          ),
    );
  }

  @override
  void dispose() {
    _embedded.removeListener(_onEmbeddedChanged);
    _embedded.dispose();
    super.dispose();
  }

  void _onEmbeddedChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.plan.language;
    final localizations = context.l10n;

    _listenForDayCompletion();
    final live = _liveStatus();

    return PopScope(
      canPop: !_embedded.isOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _embedded.close();
      },
      child: Scaffold(
        appBar: _buildAppBar(context, language, localizations, live: live),
        // Only the live layout hosts the embedded panel, so a task opened
        // while the stream was still loading stays put even if the request
        // then fails or finds no stream; the plain layout takes over once the
        // user closes it. Nothing is lost on a retryable network error.
        body:
            _embedded.isOpen
                ? _buildLiveEventBody(language, localizations)
                : switch (live) {
                  _LiveStatus.none => _buildPlanBody(language, localizations),
                  _LiveStatus.failed => _buildPlanBody(
                    language,
                    localizations,
                    retryLive: _retryLiveEvent,
                  ),
                  _LiveStatus.loading ||
                  _LiveStatus.live => _buildLiveEventBody(
                    language,
                    localizations,
                  ),
                },
      ),
    );
  }

  GroupEventLanguageKey get _liveKey => (
    eventId: widget.eventId!,
    language: _liveLanguage,
  );

  /// Sticky once a stream was seen, so a language without one keeps the
  /// toggles reachable. A failed request is `failed`, never `none`, so a
  /// network blip cannot hide an active stream.
  _LiveStatus _liveStatus() {
    if (widget.eventId == null) return _LiveStatus.none;
    final eventAsync = ref.watch(groupEventInLanguageProvider(_liveKey));
    final either = eventAsync.valueOrNull;
    if (either == null) {
      if (_liveStreamSeen) return _LiveStatus.live;
      return eventAsync.hasError ? _LiveStatus.failed : _LiveStatus.loading;
    }
    final status = either.fold(
      (failure) =>
          failure is NotFoundFailure ? _LiveStatus.none : _LiveStatus.failed,
      (event) =>
          GroupEventLiveUtils.videoIdOf(event) != null
              ? _LiveStatus.live
              : _LiveStatus.none,
    );
    if (status == _LiveStatus.live) _liveStreamSeen = true;
    return _liveStreamSeen ? _LiveStatus.live : status;
  }

  void _retryLiveEvent() {
    ref.invalidate(groupEventInLanguageProvider(_liveKey));
  }

  Widget _buildPlanBody(
    String language,
    AppLocalizations localizations, {
    VoidCallback? retryLive,
  }) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (retryLive != null) _buildLiveEventError(retryLive),
                // The edge-to-edge event cover has no margin of its own.
                if (widget.eventId != null) const SizedBox(height: 12),
                _buildDayCarouselSection(language),
                _buildDayContentSection(context, language),
              ],
            ),
          ),
        ),
        _buildStartReadingButton(context, localizations),
      ],
    );
  }

  /// The stream stays pinned; a tapped task opens below it, not as a route.
  Widget _buildLiveEventBody(
    String language,
    AppLocalizations localizations,
  ) {
    return PlanEmbeddedScope(
      controller: _embedded,
      child: Column(
        children: [
          _buildHeader(),
          if (_embedded.isOpen)
            Expanded(child: PlanEmbeddedPanel(controller: _embedded))
          else ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildDayCarouselSection(language),
                    _buildDayContentSection(context, language),
                  ],
                ),
              ),
            ),
            _buildStartReadingButton(context, localizations),
          ],
        ],
      ),
    );
  }

  void _listenForDayCompletion() {
    ref.listen(
      userPlanDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
      ),
      (previous, next) {
        // Handle Either type
        final dayContentEither = next.valueOrNull;
        if (dayContentEither == null) return;

        dayContentEither.fold(
          (failure) {
            _logger.error('Error loading day content: ${failure.message}');
          },
          (dayContent) {
            final day = dayContent.dayNumber;
            if (_dayCompletionTracker.containsKey(day)) {
              final wasCompleted = _dayCompletionTracker[day]!;
              if (!wasCompleted && dayContent.isCompleted) {
                _onDayCompleted(dayContent);
              }
            }
            _dayCompletionTracker[day] = dayContent.isCompleted;
          },
        );
      },
    );
  }

  void _onReaderClosed() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref.invalidate(
        userPlanDayContentFutureProvider(
          PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
        ),
      );
      ref.invalidate(userPlanDaysCompletionStatusProvider(widget.plan.id));
    });
  }

  Future<void> _onDayCompleted(UserPlanDayDetailResponse dayContent) async {
    try {
      final completionStatusEither = await ref.read(
        userPlanDaysCompletionStatusProvider(widget.plan.id).future,
      );

      completionStatusEither.fold(
        (failure) {
          _logger.error('Error fetching completion status: ${failure.message}');
        },
        (completionStatus) {
          final completedDays = completionStatus.values.where((v) => v).length;

          unawaited(
            ref
                .read(analyticsServiceProvider)
                .track(
                  AnalyticsEvents.planDayCompleted,
                  properties: {
                    AnalyticsProperties.planId: widget.plan.id,
                    AnalyticsProperties.planName: widget.plan.title,
                    AnalyticsProperties.dayNumber: dayContent.dayNumber,
                    AnalyticsProperties.totalDays: widget.plan.totalDays,
                    AnalyticsProperties.completedDays: completedDays,
                  },
                ),
          );

          if (!mounted) return;

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder:
                (_) => DayCompletionBottomSheet(
                  dayNumber: dayContent.dayNumber,
                  totalDays: widget.plan.totalDays,
                  completedDays: completedDays,
                  fallbackImageUrl: widget.plan.imageUrl,
                  thumbnailUrl: dayContent.thumbnailUrl,
                  shareableImageUrl: dayContent.shareableImageUrl,
                  planTitle: widget.plan.title,
                  planId: widget.plan.id,
                  planLanguage: widget.plan.language,
                ),
          );
        },
      );
    } catch (e) {
      _logger.error('Error showing day completion', e);
    }
  }

  AppBar _buildAppBar(
    BuildContext context,
    String language,
    AppLocalizations localizations, {
    required _LiveStatus live,
  }) {
    final isLiveEvent = live == _LiveStatus.live;
    return AppBar(
      leading: IconButton(
        icon: const Icon(AppAssets.arrowLeft),
        onPressed: () {
          if (_embedded.isOpen) {
            _embedded.close();
          } else if (context.canPop()) {
            context.pop();
          } else {
            // Opened via deep link with no route beneath — go home.
            context.go(AppRoutes.home);
          }
        },
      ),
      title: switch (live) {
        _LiveStatus.loading => Skeletonizer(
          child: Bone(
            width: 180,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        _LiveStatus.live => null,
        _LiveStatus.none || _LiveStatus.failed => Text(
          widget.plan.title,
          style: TextStyle(fontSize: 20),
        ),
      },
      actions:
          isLiveEvent
              ? [
                GroupEventMediaToggle(
                  audioOnly: _liveAudioOnly,
                  onChanged:
                      (audioOnly) =>
                          setState(() => _liveAudioOnly = audioOnly),
                ),
                const SizedBox(width: 8),
                GroupEventLanguageToggle(
                  language: _liveLanguage,
                  onChanged:
                      (language) => setState(() => _liveLanguage = language),
                ),
                const SizedBox(width: 12),
              ]
              : null,
      elevation: 0,
    );
  }

  Widget _buildHeader() {
    final eventId = widget.eventId;
    if (eventId == null) return PlanCoverImage(image: widget.plan.coverImage);
    return GroupEventLiveHeader(
      eventId: eventId,
      language: _liveLanguage,
      audioOnly: _liveAudioOnly,
      fallbackTitle: widget.plan.title,
      fallback: LayoutBuilder(
        builder:
            (context, constraints) => PlanCoverImage(
              image: widget.plan.coverImage,
              height: constraints.maxWidth * 9 / 16,
              edgeToEdge: true,
            ),
      ),
    );
  }

  Widget _buildDayCarouselSection(String language) {
    final planDays = ref.watch(planDaysByPlanIdFutureProvider(widget.plan.id));

    return planDays.when(
      data: (daysEither) {
        return daysEither.fold(
          (failure) {
            _logger.error('Error loading plan days: ${failure.message}');
            return _buildEmptyDayCarouselState(context);
          },
          (days) {
            if (days.isEmpty) {
              return _buildEmptyDayCarouselState(context);
            }
            return _buildDayCarouselWithStatus(language, days);
          },
        );
      },
      loading: () => DayCarouselSkeleton(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildDayCarouselWithStatus(
    String language,
    List<PlanDaysModel> days,
  ) {
    final dayCompletionStatus = ref.watch(
      userPlanDaysCompletionStatusProvider(widget.plan.id),
    );

    return dayCompletionStatus.when(
      data: (completionStatusEither) {
        return completionStatusEither.fold(
          (failure) {
            _logger.error(
              'Error loading completion status: ${failure.message}',
            );
            return _buildDayCarousel(language, days, null);
          },
          (completionStatus) {
            return _buildDayCarousel(language, days, completionStatus);
          },
        );
      },
      loading: () => _buildDayCarousel(language, days, null),
      error: (error, stackTrace) => _buildDayCarousel(language, days, null),
    );
  }

  Widget _buildDayCarousel(
    String language,
    List<PlanDaysModel> days,
    Map<int, bool>? completionStatus,
  ) {
    return DayCarousel(
      language: language,
      days: days,
      selectedDay: selectedDay,
      startDate: widget.startDate,
      dayCompletionStatus: completionStatus,
      lockFutureDays: true,
      previewUnlockDayCount: _firstPlanPreviewUnlockDayCount(ref),
      onDaySelected: (day) {
        setState(() {
          selectedDay = day;
        });
      },
    );
  }

  int _firstPlanPreviewUnlockDayCount(WidgetRef ref) {
    final fromList = _previewUnlockDayCountFromSeriesList(ref);
    if (fromList > 0) return fromList;

    if (widget.seriesId != null) {
      final fromExplicit = _previewUnlockFromSeriesById(ref, widget.seriesId!);
      if (fromExplicit > 0) return fromExplicit;
    }

    return _previewUnlockFromEnrolledSeries(ref);
  }

  int _previewUnlockFromSeriesById(WidgetRef ref, String seriesId) {
    final seriesAsync = ref.watch(seriesByIdProvider(seriesId));
    return seriesAsync.when(
      data:
          (either) => either.fold(
            (_) => 0,
            (series) => SeriesPlanUtils.previewUnlockDayCountForPlan(
              widget.plan.id,
              series: series,
            ),
          ),
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  int _previewUnlockFromEnrolledSeries(WidgetRef ref) {
    final enrollments =
        ref.watch(userSeriesEnrollmentsProvider).valueOrNull ?? {};
    for (final seriesId in enrollments) {
      final count = _previewUnlockFromSeriesById(ref, seriesId);
      if (count > 0) return count;
    }
    return 0;
  }

  int _previewUnlockDayCountFromSeriesList(WidgetRef ref) {
    final seriesAsync = ref.watch(seriesListFutureProvider);
    return seriesAsync.when(
      data:
          (either) => either.fold(
            (_) => 0,
            (seriesList) => SeriesPlanUtils.previewUnlockDayCountForPlan(
              widget.plan.id,
              seriesList: seriesList,
            ),
          ),
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  Widget _buildDayContentSection(BuildContext context, String language) {
    final userPlanDayContent = ref.watch(
      userPlanDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
      ),
    );
    final completionStatus = ref.watch(
      userPlanDaysCompletionStatusProvider(widget.plan.id),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayTitle(
            context,
            language,
            selectedDay,
            completionStatus.valueOrNull,
          ),
          userPlanDayContent.when(
            data: (dayContentEither) {
              return dayContentEither.fold(
                (failure) => _buildDayContentError(),
                (dayContent) {
                  final tasks = _applyOptimisticState(dayContent.tasks);
                  return ActivityList(
                    language: language,
                    tasks: tasks,
                    videos: dayContent.videos,
                    today: selectedDay,
                    totalDays: tasks.length,
                    planId: widget.plan.id,
                    dayNumber: selectedDay,
                    dayAudioUrl: dayContent.audioUrl,
                    onActivityToggled:
                        (taskId) => _handleTaskToggle(taskId, dayContent.tasks),
                    onGroupAccumulationPracticed:
                        (taskId) => _completeTask(taskId, dayContent.tasks),
                    onReaderClosed: _onReaderClosed,
                  );
                },
              );
            },
            loading: () => const DayContentSkeleton(),
            error: (error, stackTrace) => _buildDayContentError(),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveEventError(VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.something_went_wrong,
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }

  Widget _buildDayContentError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.plan_no_tasks_error,
          style: TextStyle(color: Colors.red[600]),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            ref.invalidate(userPlanDayContentFutureProvider);
          },
          child: Text(context.l10n.retry),
        ),
      ],
    );
  }

  Widget _buildEmptyDayCarouselState(BuildContext context) {
    final localizations = context.l10n;
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(child: Text(localizations.no_days_available)),
    );
  }

  Widget _buildDayTitle(
    BuildContext context,
    String language,
    int day,
    Either<Failure, Map<int, bool>>? completionStatusEither,
  ) {
    // Extract Map from Either, or null if not available
    final completionStatus = completionStatusEither?.fold(
      (failure) => null,
      (status) => status,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.plan_day_of(day, widget.plan.totalDays),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: "Inter",
          ),
        ),
        if (completionStatus != null)
          MissedDaysBadge(
            planStartDate: widget.startDate,
            totalDays: widget.plan.totalDays,
            completionStatus: completionStatus,
            onTap: (firstMissedDay) {
              HapticFeedback.lightImpact();
              setState(() {
                selectedDay = firstMissedDay;
              });
            },
          ),
      ],
    );
  }

  // Marks a task complete after a group accumulation session, never unticks.
  Future<void> _completeTask(String taskId, List<UserTasksDto> tasks) async {
    final task = tasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null) return;
    final isCompleted = _optimisticCompletions[taskId] ?? task.isCompleted;
    if (isCompleted) return;
    await _handleTaskToggle(taskId, tasks);
  }

  Future<void> _handleTaskToggle(
    String taskId,
    List<UserTasksDto> tasks,
  ) async {
    if (_togglingTaskIds.contains(taskId)) return;

    if (tasks.isEmpty) {
      _showErrorSnackbar(context.l10n.noTasks);
      return;
    }

    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) {
      _showErrorSnackbar(context.l10n.taskNotFound);
      return;
    }

    final task = tasks[taskIndex];
    final newValue = !task.isCompleted;

    setState(() {
      _togglingTaskIds.add(taskId);
      _optimisticCompletions[taskId] = newValue;
    });

    try {
      final resultEither =
          newValue
              ? await ref.read(completeTaskFutureProvider(taskId).future)
              : await ref.read(deleteTaskFutureProvider(taskId).future);

      resultEither.fold(
        (failure) {
          _logger.error('Error toggling task: ${failure.message}');
          if (mounted) {
            setState(() => _optimisticCompletions.remove(taskId));
            _showErrorSnackbar(context.l10n.updateTaskError);
          }
        },
        (success) {
          if (success && mounted) {
            ref.invalidate(
              userPlanDayContentFutureProvider(
                PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
              ),
            );
            ref.invalidate(
              userPlanDaysCompletionStatusProvider(widget.plan.id),
            );
          } else if (!success && mounted) {
            setState(() => _optimisticCompletions.remove(taskId));
            _showErrorSnackbar(context.l10n.updateTaskError);
          }
        },
      );
    } catch (e) {
      _logger.error('Error toggling task', e);
      if (mounted) {
        setState(() => _optimisticCompletions.remove(taskId));
        _showErrorSnackbar(context.l10n.errorDetail(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _togglingTaskIds.remove(taskId));
      }
    }
  }

  List<UserTasksDto> _applyOptimisticState(List<UserTasksDto> tasks) {
    if (_optimisticCompletions.isEmpty) return tasks;
    final keysToRemove = <String>[];
    final result =
        tasks.map((task) {
          if (_optimisticCompletions.containsKey(task.id)) {
            if (task.isCompleted == _optimisticCompletions[task.id]) {
              keysToRemove.add(task.id);
              return task;
            }
            return task.copyWith(isCompleted: _optimisticCompletions[task.id]!);
          }
          return task;
        }).toList();
    if (keysToRemove.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            for (final key in keysToRemove) {
              _optimisticCompletions.remove(key);
            }
          });
        }
      });
    }
    return result;
  }

  // TODO: Wire up this dialog to a menu button in the AppBar
  // ignore: unused_element
  void _showUnenrollDialog(BuildContext context) {
    final localizations = context.l10n;
    final locale = ref.watch(localeProvider);
    final language = locale.languageCode;
    final isTibetan = AppFontConfig.isTibetanLanguage(language);
    final fontSize = getLocalizedFontSize(AppTextSize.label);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(localizations.plan_unenroll),
          content: Text(
            isTibetan
                ? '${widget.plan.title} ${localizations.unenroll_confirmation}\n\n ${localizations.unenroll_message}'
                : '${localizations.unenroll_confirmation} "${widget.plan.title}"?\n\n ${localizations.unenroll_message}',
            style: TextStyle(fontSize: fontSize),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                localizations.cancel,
                style: TextStyle(fontSize: fontSize),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleUnenroll();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(
                localizations.plan_unenroll,
                style: TextStyle(fontSize: fontSize),
              ),
            ),
          ],
        );
      },
    );
  }

  // ignore: unused_element
  Future<void> _handleUnenroll() async {
    try {
      final resultEither = await ref.read(
        userPlanUnsubscribeFutureProvider(widget.plan.id).future,
      );

      resultEither.fold(
        (failure) {
          _logger.error('Error unenrolling: ${failure.message}');
          if (mounted) {
            _showErrorSnackbar(context.l10n.unenrollError);
          }
        },
        (success) {
          if (success) {
            // Invalidate plans to refresh the list and home stats
            ref.invalidate(myPlansPaginatedProvider);
            ref.invalidate(findPlansPaginatedProvider);
            ref.invalidate(userPlansFutureProvider);
            ref.invalidate(routineInfoFutureProvider);

            if (mounted) {
              // Pop back to plans list
              Navigator.of(context).pop();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.l10n.unenrollSuccess(widget.plan.title),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            if (mounted) {
              _showErrorSnackbar(context.l10n.unenrollError);
            }
          }
        },
      );
    } catch (e) {
      _logger.error('Error unenrolling from plan', e);
      if (mounted) {
        _showErrorSnackbar(context.l10n.unenrollGenericError);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _startReading(
    BuildContext context,
    List<UserTasksDto> tasks, {
    String? audioUrl,
  }) {
    final accumulationTask = _nextGroupAccumulationTask(tasks);
    final accumulatorId =
        accumulationTask == null
            ? null
            : PlanSubtaskNavigation.groupAccumulationIdForUserTask(
              accumulationTask,
            );
    if (accumulationTask != null && accumulatorId != null) {
      openGroupAccumulatorPractice(
        context,
        ref,
        accumulatorId: accumulatorId,
      ).then((practiced) {
        if (practiced) _completeTask(accumulationTask.id, tasks);
        _onReaderClosed();
      });
      return;
    }

    final planTextItems = PlanSubtaskNavigation.fromUserTasks(tasks);
    if (planTextItems.isEmpty) return;

    // Find first uncompleted item of any content type; fall back to first.
    final targetIndex = planTextItems.indexWhere((item) => !item.isCompleted);
    final index = targetIndex >= 0 ? targetIndex : 0;
    final target = planTextItems[index];

    final navigationContext = NavigationContext(
      source: NavigationSource.plan,
      planId: widget.plan.id,
      dayNumber: selectedDay,
      targetSegmentId: target.firstSegmentId,
      planTextItems: planTextItems,
      currentTextIndex: index,
      dayAudioUrl: audioUrl,
    );

    PlanNavigator.push(
      context,
      target,
      navigationContext,
    ).then((_) => _onReaderClosed());
  }

  // The next open task when it is a group accumulation, else null.
  UserTasksDto? _nextGroupAccumulationTask(List<UserTasksDto> tasks) {
    final sorted = List<UserTasksDto>.from(tasks)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final navigable = sorted.where(PlanSubtaskNavigation.isUserTaskNavigable);
    if (navigable.isEmpty) return null;
    final next = navigable.firstWhere(
      (t) => !t.isCompleted,
      orElse: () => navigable.first,
    );
    if (PlanSubtaskNavigation.groupAccumulationIdForUserTask(next) == null) {
      return null;
    }
    return next;
  }

  Widget _buildStartReadingButton(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final dayContent = ref.watch(
      userPlanDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
      ),
    );

    // Extract tasks and audioUrl from Either type
    final dayData = dayContent.valueOrNull?.fold((failure) => null, (d) => d);
    final tasks = dayData?.tasks ?? <UserTasksDto>[];
    final audioUrl = dayData?.audioUrl;

    final hasReadableContent =
        tasks.isNotEmpty &&
        tasks.any(PlanSubtaskNavigation.isUserTaskNavigable);

    final shareableImageUrl = dayData?.shareableImageUrl?.trim();
    final showShareButton =
        dayData != null &&
        dayData.isCompleted &&
        shareableImageUrl != null &&
        shareableImageUrl.isNotEmpty;

    // From an event the user is already practicing; only Share remains.
    if (!showShareButton && widget.eventId != null) {
      return const SizedBox.shrink();
    }

    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      foregroundColor: Theme.of(context).colorScheme.surface,
      disabledBackgroundColor: Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.5),
      disabledForegroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child:
              showShareButton
                  ? FilledButton.icon(
                    key: _shareButtonKey,
                    onPressed:
                        _isSharing
                            ? null
                            : () =>
                                _shareDay(shareableImageUrl, dayData.dayNumber),
                    style: buttonStyle,
                    icon:
                        _isSharing
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0.85),
                              ),
                            )
                            : const Icon(AppAssets.readerShare, size: 22),
                    label: Text(
                      localizations.share,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  )
                  : FilledButton(
                    onPressed:
                        hasReadableContent
                            ? () => _startReading(
                              context,
                              tasks,
                              audioUrl: audioUrl,
                            )
                            : null,
                    style: buttonStyle,
                    child: Text(
                      localizations.start_reading,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  Future<void> _shareDay(String shareableImageUrl, int dayNumber) async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      await sharePlanDayImage(
        context: context,
        shareableImageUrl: shareableImageUrl,
        dayNumber: dayNumber,
        planId: widget.plan.id,
        planLanguage: widget.plan.language,
        shareButtonKey: _shareButtonKey,
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
}
