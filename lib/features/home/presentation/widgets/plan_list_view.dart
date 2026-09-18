import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/series_plan_card_widgets.dart';
import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/enrolled_plan_status_indicator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/plan_date_range_label.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_item_chip.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Series-scoped enrollment derived from `GET /users/me/series` only.
/// When enrolled, every plan in the series is treated as enrolled.
@immutable
class SeriesListEnrollmentState {
  const SeriesListEnrollmentState({
    required this.isSeriesEnrolled,
    this.isLoading = false,
  });

  final bool isSeriesEnrolled;
  final bool isLoading;

  static const none = SeriesListEnrollmentState(isSeriesEnrolled: false);
}

SeriesListEnrollmentState _watchSeriesListEnrollment(
  WidgetRef ref,
  String? seriesId,
) {
  if (seriesId == null) return SeriesListEnrollmentState.none;

  final auth = ref.watch(authProvider);
  if (auth.isGuest || !auth.isLoggedIn) {
    return SeriesListEnrollmentState.none;
  }

  final enrollmentsAsync = ref.watch(userSeriesEnrollmentsProvider);
  return SeriesListEnrollmentState(
    isSeriesEnrolled: enrollmentsAsync.valueOrNull?.contains(seriesId) ?? false,
    isLoading: enrollmentsAsync.isLoading,
  );
}

/// Renders a non-empty list of [Plan]s as a featured card on top and a scrolling
/// list below — used by both `PlanListScreen` (tag-filtered) and
/// `SeriesDetailScreen` (series-filtered). Caller must guard against empty input.
///
/// When [groupId] is provided (navigated from a group profile), the featured
/// card shows "Practice with us" until the user enrolls through that group.
class PlanListView extends ConsumerWidget {
  final List<Plan> plans;
  final String? seriesId;
  final Series? series;
  final String? groupId;
  final GroupType? groupType;
  final bool isGroupEnrolled;

  const PlanListView({
    super.key,
    required this.plans,
    this.seriesId,
    this.series,
    this.groupId,
    this.groupType,
    this.isGroupEnrolled = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesEnrollment = _watchSeriesListEnrollment(ref, seriesId);
    final sorted = [...plans]..sort((a, b) {
      if (a.displayOrder != null && b.displayOrder != null) {
        return a.displayOrder!.compareTo(b.displayOrder!);
      }
      if (a.displayOrder != null) return -1;
      if (b.displayOrder != null) return 1;
      return 0;
    });

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FeaturedPlanCard(
              plan: sorted.first,
              seriesId: seriesId,
              series: series,
              groupId: groupId,
              groupType: groupType,
              isGroupEnrolled: isGroupEnrolled,
              seriesEnrollment: seriesEnrollment,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => PlanListItem(
                plan: sorted[index],
                seriesId: seriesId,
                seriesEnrollment: seriesEnrollment,
              ),
              childCount: sorted.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class FeaturedPlanCard extends ConsumerWidget {
  final Plan plan;

  /// When provided, the Enroll button enrolls the user in this series
  /// (single API call covers every plan in the series). When null, the
  /// button falls back to the per-plan preview navigation.
  final String? seriesId;

  /// When provided, the card displays the series-level title, description
  /// and cover image instead of the first plan's data.
  final Series? series;

  /// When set, enrollment uses group-scoped "Practice with us" flow.
  final String? groupId;
  final GroupType? groupType;
  final bool isGroupEnrolled;
  final SeriesListEnrollmentState seriesEnrollment;

  const FeaturedPlanCard({
    super.key,
    required this.plan,
    this.seriesId,
    this.series,
    this.groupId,
    this.groupType,
    this.isGroupEnrolled = false,
    this.seriesEnrollment = SeriesListEnrollmentState.none,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lineHeight = getLineHeight(locale.languageCode);
    final subtitleFontSize = getLocalizedFontSize(AppTextSize.label);

    final displayDescription = series?.subTitle ?? plan.description;
    final displayImage = series?.coverImage ?? plan.coverImage;
    final localizations = AppLocalizations.of(context)!;

    final isGuest = ref.watch(authProvider).isGuest;
    final isSeriesContext = seriesId != null;
    final isSeriesEnrolled =
        isSeriesContext && !isGuest && seriesEnrollment.isSeriesEnrolled;

    final myPlansState =
        isSeriesContext ? null : ref.watch(myPlansPaginatedProvider);
    final isPlanEnrolled =
        isSeriesContext
            ? isSeriesEnrolled
            : (!isGuest && _isPlanEnrolledFromMyData(ref, plan.id));

    final enrolledInfo =
        !isSeriesContext && isPlanEnrolled
            ? _getEnrolledInfoFromMyPlans(ref, plan.id)
            : null;
    final isEnrolledInfoPending =
        !isSeriesContext &&
        isPlanEnrolled &&
        enrolledInfo == null &&
        myPlansState!.isLoading;
    final hasDescription = displayDescription.trim().isNotEmpty;

    final enrollmentState =
        seriesId != null
            ? ref.watch(seriesEnrollmentProvider(seriesId!))
            : null;
    final isEnrolling = enrollmentState is SeriesEnrollmentLoading;

    final isGroupPracticeFlow = groupId != null && !isGroupEnrolled;

    final isLoadingEnrollmentData =
        isSeriesContext
            ? (!isGroupPracticeFlow && seriesEnrollment.isLoading)
            : myPlansState!.isLoading;

    final hideEnrollButton =
        isGroupEnrolled ||
        isLoadingEnrollmentData ||
        (isGroupPracticeFlow ? false : isPlanEnrolled);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enrollBackgroundColor =
        isDark ? AppColors.surfaceWhite : AppColors.scaffoldBackgroundDark;
    final enrollForegroundColor =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryDark;

    return InkWell(
      onTap: () => _navigateToSeriesInfo(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _PlanCoverImage(
                  image: displayImage,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (series != null)
                    Text(
                      localizations.series_stats(
                        series!.plans.length,
                        series!.totalDays,
                      ),
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        height: lineHeight,
                      ),
                    ),
                  if (series?.partner != null) ...[
                    if (series != null) const SizedBox(height: 8),
                    SeriesPlanPartnerRow(
                      partner: series!.partner!,
                      fontSize: subtitleFontSize,
                      avatarSize: 28,
                    ),
                  ],
                  if (hasDescription) ...[
                    if (series != null)
                      const SizedBox(height: 6),
                    Text(
                      displayDescription,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        height: lineHeight,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (!hideEnrollButton) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (isEnrolledInfoPending || isEnrolling)
                                ? null
                                : () => _onEnrollTap(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: enrollBackgroundColor,
                          foregroundColor: enrollForegroundColor,
                          disabledBackgroundColor: enrollBackgroundColor
                              .withValues(alpha: 0.5),
                          disabledForegroundColor: enrollForegroundColor
                              .withValues(alpha: 0.5),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            isEnrolling
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      enrollForegroundColor,
                                    ),
                                  ),
                                )
                                : Text(
                                  isGroupPracticeFlow
                                      ? context.l10n.group_practice_with_us
                                      : context.l10n.plan_enroll,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles a tap on the Enroll / Practice with us button.
  /// - Guests: opens login drawer (same guard as Add to Routine).
  /// - When [groupId] is set: enrolls through the group, then edit-routine.
  /// - When [seriesId] is null: navigates to the per-plan preview screen.
  /// - When [seriesId] is set: enrolls in the series via API, then navigates
  ///   to edit-routine with the series id so all newly enrolled plans are
  ///   prefilled at the default 8:00 AM block.
  Future<void> _onEnrollTap(BuildContext context, WidgetRef ref) async {
    final isGuest = ref.read(authProvider).isGuest;
    if (isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }

    final id = seriesId;
    if (id == null) {
      _navigateToPlan(
        context,
        plan: plan,
        isEnrolled: _isPlanEnrolledFromMyData(ref, plan.id),
        enrolledInfo: _getEnrolledInfoFromMyPlans(ref, plan.id),
      );
      return;
    }

    final groupId = this.groupId;
    if (groupId != null && !isGroupEnrolled) {
      final groupType = this.groupType ?? GroupType.community;
      final profileResult = await ref.read(
        groupProfileProvider(groupId).future,
      );
      if (!context.mounted) return;

      final enrollmentStatus = profileResult.fold(
        (_) => null,
        (profile) => seriesGroupEnrollmentStatusFromProfile(profile, id),
      );
      final confirmed = await confirmGroupPracticeChangeIfNeeded(
        context,
        enrollmentStatus,
      );
      if (!confirmed || !context.mounted) return;

      final ok = await enrollSeriesThroughGroup(
        ref: ref,
        seriesId: id,
        groupId: groupId,
        groupType: groupType,
      );
      if (!context.mounted) return;

      if (ok) {
        await ref.read(groupProfileProvider(groupId).future);
        if (!context.mounted) return;
        await context.pushNamed('edit-routine', extra: {'enrollSeriesId': id});
        if (!context.mounted) return;
        await completeGroupPracticeEnrollmentFlow(
          ref: ref,
          groupId: groupId,
          groupType: groupType,
        );
      } else {
        final state = ref.read(seriesEnrollmentProvider(id));
        final message =
            state is SeriesEnrollmentFailure
                ? state.failure.message
                : context.l10n.series_enroll_error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final enrollments = await ref.read(userSeriesEnrollmentsProvider.future);
    if (!context.mounted) return;
    if (enrollments.contains(id)) return;

    final notifier = ref.read(seriesEnrollmentProvider(id).notifier);
    final ok = await notifier.enroll();
    if (!context.mounted) return;

    if (ok) {
      context.pushNamed('edit-routine', extra: {'enrollSeriesId': id});
    } else {
      final state = ref.read(seriesEnrollmentProvider(id));
      final message =
          state is SeriesEnrollmentFailure
              ? state.failure.message
              : context.l10n.series_enroll_error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToSeriesInfo(BuildContext context) {
    if (series == null) return;
    context.push('/home/series/${series!.id}/info');
  }
}

class PlanListItem extends ConsumerWidget {
  final Plan plan;
  final String? seriesId;
  final SeriesListEnrollmentState seriesEnrollment;

  const PlanListItem({
    super.key,
    required this.plan,
    this.seriesId,
    this.seriesEnrollment = SeriesListEnrollmentState.none,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lineHeight = getLineHeight(locale.languageCode);
    final titleFontSize = getLocalizedFontSize(AppTextSize.body);

    final isGuest = ref.watch(authProvider).isGuest;
    final isSeriesContext = seriesId != null;
    final isSeriesEnrolled =
        isSeriesContext && !isGuest && seriesEnrollment.isSeriesEnrolled;

    final myPlansState =
        isSeriesContext ? null : ref.watch(myPlansPaginatedProvider);
    final isPlanEnrolled =
        isSeriesContext
            ? isSeriesEnrolled
            : (!isGuest && _isPlanEnrolledFromMyData(ref, plan.id));

    final enrolledInfo =
        !isSeriesContext && isPlanEnrolled
            ? _getEnrolledInfoFromMyPlans(ref, plan.id)
            : null;
    final isEnrolledInfoPending =
        !isSeriesContext &&
        isPlanEnrolled &&
        enrolledInfo == null &&
        myPlansState!.isLoading;
    final dateRange = PlanDateRange.tryCreate(
      startDate: plan.startDate,
      totalDays: plan.totalDays,
      includeYear: seriesId == null,
    );
    final canShowStatus = isPlanEnrolled && dateRange != null;

    final isLocked =
        plan.startDate != null && plan.startDate!.isAfter(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Opacity(
        opacity: isLocked ? 0.45 : 1.0,
        child: InkWell(
          onTap:
              (isLocked || isEnrolledInfoPending)
                  ? null
                  : () => _navigateToPlan(
                    context,
                    plan: plan,
                    isEnrolled: isPlanEnrolled,
                    seriesId: seriesId,
                    enrolledInfo: enrolledInfo,
                  ),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                clipBehavior: Clip.antiAlias,
                child: _PlanCoverImage(
                  image: plan.coverImage,
                  placeholderIconSize: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        height: lineHeight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildDateLine(
                            context,
                            plan: plan,
                            dateRange: dateRange,
                            isEnrolled: isPlanEnrolled,
                            lineHeight: lineHeight,
                          ),
                        ),
                        if (isLocked)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(AppAssets.lock, size: 20),
                          )
                        else if (canShowStatus)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: EnrolledPlanStatusIndicator(
                              planId: plan.id,
                              dateRange: dateRange,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the left-side date display for the row.
  ///
  /// - Flexible plans without enrollment: keeps the existing "Start now" chip.
  /// - Fixed-date plans: delegates to the shared [PlanDateRangeLabel] which
  ///   picks the active black pill or the muted text variant based on whether
  ///   today falls inside the range.
  Widget _buildDateLine(
    BuildContext context, {
    required Plan plan,
    required PlanDateRange? dateRange,
    required bool isEnrolled,
    required double? lineHeight,
  }) {
    if (dateRange == null) {
      if (!isEnrolled) {
        return Align(
          alignment: Alignment.centerLeft,
          child: RoutineItemChip(label: context.l10n.start_now),
        );
      }
      return const SizedBox.shrink();
    }

    return PlanDateRangeLabel(dateRange: dateRange, lineHeight: lineHeight);
  }
}

class _EnrolledPlanInfo {
  final UserPlansModel userPlan;
  final int selectedDay;
  final DateTime startDate;

  const _EnrolledPlanInfo({
    required this.userPlan,
    required this.selectedDay,
    required this.startDate,
  });
}

/// Navigates to practice details when enrolled, otherwise plan preview.
///
/// On series screens enrollment comes from `GET /users/me/series`; catalog
/// [Plan] data from `GET /series/{id}` is enough to open practice details.
/// Tag-filtered lists still hydrate navigation from [myPlansPaginatedProvider].
void _navigateToPlan(
  BuildContext context, {
  required Plan plan,
  required bool isEnrolled,
  String? seriesId,
  _EnrolledPlanInfo? enrolledInfo,
}) {
  if (isEnrolled) {
    final userPlan = enrolledInfo?.userPlan ?? userPlanFromCatalogPlan(plan);
    final startDate = enrolledInfo?.startDate ?? userPlan.effectiveStartDate;
    final selectedDay =
        enrolledInfo?.selectedDay ??
        selectedDayForStart(startDate, userPlan.totalDays);

    context.push(
      '/practice/details',
      extra: {
        'plan': userPlan,
        'selectedDay': selectedDay,
        'startDate': startDate,
        if (seriesId != null) 'seriesId': seriesId,
      },
    );
    return;
  }

  context.push(
    '/practice/plans/preview',
    extra: {'plan': plan, if (seriesId != null) 'seriesId': seriesId},
  );
}

UserPlansModel userPlanFromCatalogPlan(Plan plan) {
  return UserPlansModel(
    id: plan.id,
    title: plan.title,
    description: plan.description,
    language: plan.language,
    difficultyLevel: plan.difficulty.name,
    image:
        plan.coverImage != null
            ? ImageModel.fromResponsiveImage(plan.coverImage!)
            : null,
    startedAt: plan.startDate ?? DateTime.now(),
    totalDays: plan.totalDays,
    tags: null,
    startDate: plan.startDate,
  );
}

int selectedDayForStart(DateTime startDate, int totalDays) {
  final daysSinceStart =
      DateTime.now().difference(DateUtils.dateOnly(startDate)).inDays;
  return (daysSinceStart + 1).clamp(1, totalDays);
}

/// Tag-filtered plan lists only — checks my plans and routine membership.
bool _isPlanEnrolledFromMyData(WidgetRef ref, String planId) {
  final myPlansState = ref.watch(myPlansPaginatedProvider);
  if (myPlansState.plans.any((p) => p.id == planId)) return true;

  final routineData = ref.watch(userRoutineProvider).valueOrNull;
  if (routineData == null) return false;
  return routineData.blocks.any(
    (block) => block.items.any(
      (item) => item.representsStandalonePlan(planId),
    ),
  );
}

_EnrolledPlanInfo? _getEnrolledInfoFromMyPlans(WidgetRef ref, String planId) {
  final myPlansState = ref.watch(myPlansPaginatedProvider);
  UserPlansModel? userPlan;
  for (final p in myPlansState.plans) {
    if (p.id == planId) {
      userPlan = p;
      break;
    }
  }
  if (userPlan == null) return null;

  final startDate = userPlan.startDate ?? userPlan.startedAt;
  return _EnrolledPlanInfo(
    userPlan: userPlan,
    selectedDay: selectedDayForStart(startDate, userPlan.totalDays),
    startDate: startDate,
  );
}

class _PlanCoverImage extends StatelessWidget {
  final ResponsiveImage? image;
  final double placeholderIconSize;

  const _PlanCoverImage({
    required this.image,
    this.placeholderIconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCoverImage(
      image: image,
      fit: BoxFit.cover,
      placeholder: _buildPlaceholder(context),
      errorWidget: _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.surfaceDark : AppColors.greyLight;
    final highlightColor = isDark ? AppColors.grey900 : AppColors.grey300;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, highlightColor],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: placeholderIconSize,
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : AppColors.grey800.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
