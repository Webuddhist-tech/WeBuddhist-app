import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/data/utils/series_plan_utils.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../day_carousel.dart';
import '../plan_cover_image.dart';
import 'preview_activity_list.dart';

/// A preview screen for viewing plan content before enrollment.
/// Unlike PlanDetails, this screen:
/// - Uses Plan domain entity
/// - Has no completion status tracking
/// - Has no task toggle functionality (read-only preview)
/// - Has "Start Reading" button to begin reading without enrolling
class PlanPreviewDetails extends ConsumerStatefulWidget {
  const PlanPreviewDetails({
    super.key,
    required this.plan,
    this.seriesId,
    this.initialDay,
    this.eventId,
    this.showLiveStream = false,
  });

  final Plan plan;
  final String? seriesId;

  /// The group event this preview was opened from, so the reader follows
  /// its live recitation.
  final String? eventId;

  /// Online attendees watch the stream, so the reader must not follow the
  /// live recitation.
  final bool showLiveStream;

  /// When non-null, the day carousel opens on this day instead of computing
  /// a default from the plan start date. Used by deep links so the recipient
  /// lands on the same day that was shared.
  final int? initialDay;

  @override
  ConsumerState<PlanPreviewDetails> createState() => _PlanPreviewDetailsState();
}

final _logger = AppLogger('PlanPreviewDetails');

class _PlanPreviewDetailsState extends ConsumerState<PlanPreviewDetails> {
  late int selectedDay;

  @override
  void initState() {
    super.initState();
    // Use the explicit initial day when provided (e.g. from a plan-day deep
    // link), otherwise fall back to computing today's day from the start date.
    selectedDay =
        widget.initialDay?.clamp(1, widget.plan.totalDays) ??
        _defaultSelectedDay();
  }

  /// For fixed-date plans that have already started, default the carousel
  /// to today's plan day so an unenrolled visitor sees they'd be joining
  /// mid-stream. Before the start date (or for flexible plans without a
  /// start date), default to Day 1. After the plan has ended, clamp to the
  /// final day.
  int _defaultSelectedDay() {
    final startDate = widget.plan.startDate;
    if (startDate == null) return 1;
    final day = PlanUtils.dayNumberFor(
      startDate,
      DateTime.now(),
      widget.plan.totalDays,
    );
    final selected = day < 1 ? 1 : day;
    _logger.info(
      '[ENROLL-DAY] preview ${widget.plan.id} '
      'startDate=${startDate.toIso8601String()} '
      'totalDays=${widget.plan.totalDays} default=$selected',
    );
    return selected;
  }

  bool _isPlanInRoutine(RoutineData routineData) {
    return routineData.blocks.any(
      (block) => block.items.any(
        (item) => item.representsStandalonePlan(widget.plan.id),
      ),
    );
  }

  /// True when the plan has a fixed start date that is strictly after today's
  /// local calendar date. The backend blocks enrolling in future-dated plans,
  /// so the bottom "Add to Routine" button is hidden in that case to avoid a
  /// guaranteed-failure tap and the downstream "Plan not found" snackbar in
  /// the routine screen. Flexible plans (`startDate == null`) are unaffected.
  bool _isFuturePlan() {
    final startDate = widget.plan.startDate;
    if (startDate == null) return false;
    final today = DateUtils.dateOnly(DateTime.now());
    final start = DateUtils.dateOnly(startDate.toLocal());
    return start.isAfter(today);
  }

  void _handleAddToRoutine() {
    final isGuest = ref.read(authProvider).isGuest;
    if (isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }
    context.pushNamed('edit-routine', extra: {'initialPlan': widget.plan});
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.plan.language;
    final authState = ref.watch(authProvider);
    final isGuest = authState.isGuest;
    final alreadyInRoutine = _isCurrentlyInRoutine();
    final isFuturePlan = _isFuturePlan();

    return Scaffold(
      appBar: _buildAppBar(context, alreadyInRoutine),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlanCoverImage(image: widget.plan.coverImage),
                  _buildDayCarouselSection(language),
                  _buildDayContentSection(context, language),
                ],
              ),
            ),
          ),
          if (!alreadyInRoutine && !isFuturePlan)
            _buildBottomButton(context, isGuest),
        ],
      ),
    );
  }

  bool _isCurrentlyInRoutine() {
    final routineAsync = ref.watch(userRoutineProvider);
    final routineData = routineAsync.valueOrNull;
    if (routineData == null) return false;
    return _isPlanInRoutine(routineData);
  }

  AppBar _buildAppBar(BuildContext context, bool alreadyInRoutine) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(AppAssets.arrowLeft),
        onPressed: () => context.pop(),
      ),
      title: Text(widget.plan.title, style: const TextStyle(fontSize: 20)),
      elevation: 0,
      actions: const [],
    );
  }

  Widget _buildDayCarouselSection(String language) {
    final planDays = ref.watch(planDaysByPlanIdFutureProvider(widget.plan.id));

    return planDays.when(
      data: (daysEither) {
        return daysEither.fold(
          (failure) => _buildEmptyDayCarouselState(context),
          (days) {
            if (days.isEmpty) {
              return _buildEmptyDayCarouselState(context);
            }
            return _buildDayCarousel(language, days);
          },
        );
      },
      loading: () => const DayCarouselSkeleton(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildDayCarousel(String language, List<PlanDaysModel> days) {
    return DayCarousel(
      language: language,
      days: days,
      selectedDay: selectedDay,
      lockFutureDays: true,
      previewUnlockDayCount: _firstPlanPreviewUnlockDayCount(ref),
      startDate: widget.plan.startDate ?? DateTime.now(),
      dayCompletionStatus: null, // No completion status in preview mode
      onDaySelected: (day) {
        setState(() {
          selectedDay = day;
        });
      },
    );
  }

  int _firstPlanPreviewUnlockDayCount(WidgetRef ref) {
    final seriesId = widget.seriesId;
    if (seriesId != null) {
      final seriesAsync = ref.watch(seriesByIdProvider(seriesId));
      return seriesAsync.when(
        data:
            (either) => either.fold(
              (_) => _previewUnlockDayCountFromSeriesList(ref),
              (series) => SeriesPlanUtils.previewUnlockDayCountForPlan(
                widget.plan.id,
                series: series,
              ),
            ),
        loading: () => 0,
        error: (_, __) => _previewUnlockDayCountFromSeriesList(ref),
      );
    }
    return _previewUnlockDayCountFromSeriesList(ref);
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
    final dayContent = ref.watch(
      planDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayTitle(context, language, selectedDay),
          dayContent.when(
            data: (contentEither) {
              return contentEither.fold(
                (failure) => _buildDayContentError(context),
                (content) => PreviewActivityList(
                  language: language,
                  tasks: content.tasks ?? [],
                  videos: content.videos,
                  today: selectedDay,
                  totalDays: widget.plan.totalDays,
                  planId: widget.plan.id,
                  dayNumber: selectedDay,
                  dayAudioUrl: content.audioUrl,
                  eventId: widget.eventId,
                  isOnlineAttendee: widget.showLiveStream,
                ),
              );
            },
            loading: () => const DayContentSkeleton(),
            error: (error, stackTrace) => _buildDayContentError(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDayContentError(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.plan_day_tasks_load_error,
          style: TextStyle(color: Colors.red[600]),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            ref.invalidate(planDayContentFutureProvider);
          },
          child: Text(context.l10n.retry),
        ),
      ],
    );
  }

  Widget _buildEmptyDayCarouselState(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(child: Text(context.l10n.no_days_available)),
    );
  }

  Widget _buildDayTitle(BuildContext context, String language, int day) {
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        context.l10n.plan_day_of(day, widget.plan.totalDays),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: "Inter",
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, bool isGuest) {
    return _AddToRoutineButton(
      label: context.l10n.routine_add_plan_to_routine,
      onPressed: _handleAddToRoutine,
    );
  }
}

class _AddToRoutineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _AddToRoutineButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.surfaceWhite : AppColors.scaffoldBackgroundDark;
    final foregroundColor =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryDark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
              disabledForegroundColor: foregroundColor.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
