import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/models/notification_nav.dart';
import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_item_display.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_chant_list_tile.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_item_card.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<UserPlansModel?> resolveRoutineUserPlan(
  WidgetRef ref,
  String planId, {
  String? language,
}) async {
  if (planId.isEmpty) return null;
  final contentLanguage = ref.read(contentLanguageProvider);
  final hasLanguageHint = language != null && language.isNotEmpty;
  final isSameLanguage =
      !hasLanguageHint ||
      language.toLowerCase() == contentLanguage.toLowerCase();
  if (isSameLanguage) {
    var plans = ref.read(myPlansPaginatedProvider).plans;
    var userPlan = plans.where((p) => p.id == planId).firstOrNull;
    if (userPlan == null) {
      await ref.read(myPlansPaginatedProvider.notifier).refresh();
      plans = ref.read(myPlansPaginatedProvider).plans;
      userPlan = plans.where((p) => p.id == planId).firstOrNull;
    }
    return userPlan;
  }
  final repo = ref.read(userPlansDomainRepositoryProvider);
  final result = await repo.getUserPlans(language: language);
  return result.fold(
    (_) => null,
    (response) => response.userPlans.where((p) => p.id == planId).firstOrNull,
  );
}

final _logger = AppLogger('RoutineFilledState');

class RoutineFilledState extends ConsumerStatefulWidget {
  final RoutineData routineData;
  final VoidCallback onEdit;

  /// Shows a back arrow in the header row when set.
  final VoidCallback? onBack;
  final bool showTitle;

  const RoutineFilledState({
    super.key,
    required this.routineData,
    required this.onEdit,
    this.onBack,
    this.showTitle = true,
  });

  @override
  ConsumerState<RoutineFilledState> createState() => _RoutineFilledStateState();
}

class _RoutineFilledStateState extends ConsumerState<RoutineFilledState> {
  /// Ids of blocks currently expanded; owned here so one control can drive all.
  final Set<String> _expandedBlockIds = {};

  Iterable<RoutineBlock> get _expandableBlocks =>
      widget.routineData.blocks.where((b) => b.items.isNotEmpty);

  bool get _allExpanded =>
      _expandableBlocks.isNotEmpty &&
      _expandableBlocks.every((b) => _expandedBlockIds.contains(b.id));

  void _toggleBlock(String id) {
    setState(() {
      if (!_expandedBlockIds.remove(id)) _expandedBlockIds.add(id);
    });
  }

  void _toggleAll() {
    setState(() {
      if (_allExpanded) {
        _expandedBlockIds.clear();
      } else {
        _expandedBlockIds.addAll(_expandableBlocks.map((b) => b.id));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(pendingNotificationNavProvider, (previous, next) {
      if (next != null) {
        // fireImmediately can run this synchronously during initState, and
        // _handlePendingNotificationNav may refresh providers (illegal during
        // build). Defer to the next microtask so the mutation happens after
        // this build completes.
        Future.microtask(() {
          if (mounted) _handlePendingNotificationNav(next);
        });
      }
    }, fireImmediately: true);
  }

  Future<void> _handlePendingNotificationNav(NotificationNav pendingNav) async {
    if (!mounted) return;

    final itemType = RoutineItemType.values.firstWhere(
      (e) => e.name == pendingNav.itemType,
      orElse: () => RoutineItemType.series,
    );
    if (itemType == RoutineItemType.recitation) {
      ref.read(pendingNotificationNavProvider.notifier).state = null;
      context.push(
        '/reader/${pendingNav.itemId}',
        extra: NavigationContext(source: NavigationSource.normal),
      );
      return;
    }

    if (itemType == RoutineItemType.accumulator) {
      ref.read(pendingNotificationNavProvider.notifier).state = null;
      context.push('/mala', extra: {'presetId': pendingNav.itemId});
      return;
    }

    if (itemType == RoutineItemType.groupAccumulator) {
      ref.read(pendingNotificationNavProvider.notifier).state = null;
      context.pushNamed(
        'home-group-accumulator',
        pathParameters: {'accumulatorId': pendingNav.itemId},
      );
      return;
    }

    if (itemType == RoutineItemType.groupRecitationCollection ||
        itemType == RoutineItemType.myRecitationCollection) {
      ref.read(pendingNotificationNavProvider.notifier).state = null;
      final item = _findRoutineItem(widget.routineData, pendingNav.itemId);
      context.pushNamed(
        itemType == RoutineItemType.myRecitationCollection
            ? 'my-recitation-collection'
            : 'recitation-collection',
        pathParameters: {'collectionId': pendingNav.itemId},
        extra: {'title': item?.title},
      );
      return;
    }

    if (itemType == RoutineItemType.timer) {
      // Open the timer screen — same destination as tapping the timer item in
      // the routine. `/home/timers/active` is a root-navigator route, so it is
      // safe to push from this out-of-shell (My Practices) location.
      ref.read(pendingNotificationNavProvider.notifier).state = null;
      final item = _findRoutineItem(widget.routineData, pendingNav.itemId);
      // Prefer the routine item's duration; fall back to the value embedded in
      // the notification payload so the tap still works when the item is not
      // found or lost its durationMs on a server round-trip.
      final durationMs = item?.durationMs ?? pendingNav.durationMs;
      if (durationMs != null && durationMs > 0) {
        final name =
            (item != null && item.title.isNotEmpty)
                ? item.title
                : '${durationMs ~/ 60000} min session';
        context.push(
          '/home/timers/active',
          extra: PresetTimer(
            id: pendingNav.itemId,
            name: name,
            durationMs: durationMs,
          ),
        );
      }
      return;
    }

    final planId = pendingNav.planId ?? pendingNav.itemId;
    final routineItem = _findRoutineItem(widget.routineData, pendingNav.itemId);

    // Prefer the language hint baked into the deep link; fall back to the
    // routine item's language (push notifications) then null (same-language).
    final hintLanguage = pendingNav.planLanguage ?? routineItem?.language;

    var userPlan =
        ref
            .read(myPlansPaginatedProvider)
            .plans
            .where((p) => p.id == planId)
            .firstOrNull;
    userPlan ??= await resolveRoutineUserPlan(
      ref,
      planId,
      language: hintLanguage,
    );
    if (!mounted) return;

    // Not enrolled — fetch the public plan model and show the preview screen.
    if (userPlan == null) {
      final planEither = await ref.read(planByIdFutureProvider(planId).future);
      final plan = planEither.fold((_) => null, (p) => p);
      if (!mounted || plan == null) return;
      ref.read(pendingNotificationNavProvider.notifier).state = null;
      context.push(
        AppRoutes.practicePlanPreview,
        extra: {
          'plan': plan,
          'seriesId': null,
          // Pass the shared day so preview opens on the correct day rather
          // than defaulting to day 1.
          if (pendingNav.dayNumber != null) 'selectedDay': pendingNav.dayNumber,
        },
      );
      return;
    }

    ref.read(pendingNotificationNavProvider.notifier).state = null;
    final startDate = userPlan.effectiveStartDate;
    // Use the specific day embedded in the deep link when available; otherwise
    // fall back to computing today's day from the plan start date.
    final selectedDay =
        pendingNav.dayNumber != null
            ? pendingNav.dayNumber!.clamp(1, userPlan.totalDays)
            : PlanUtils.dayNumberFor(
              startDate,
              DateTime.now(),
              userPlan.totalDays,
            ).clamp(1, userPlan.totalDays);
    _logger.info(
      '[ENROLL-NAV] notification open ${userPlan.id} '
      'seriesId=${pendingNav.itemId} selectedDay=$selectedDay/${userPlan.totalDays}',
    );
    context.push(
      '/practice/details',
      extra: {
        'plan': userPlan,
        'selectedDay': selectedDay,
        'startDate': startDate,
        if (itemType == RoutineItemType.series) 'seriesId': pendingNav.itemId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                if (widget.onBack != null)
                  IconButton(
                    onPressed: widget.onBack,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: Icon(
                      AppAssets.arrowLeft,
                      size: 24,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                const Spacer(),
                _EditButton(
                  label: localizations.routine_edit,
                  onTap: widget.onEdit,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              localizations.routine_title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(height: 1),
          ),
        ],
        if (_expandableBlocks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: _ExpandAllButton(
                allExpanded: _allExpanded,
                label:
                    _allExpanded
                        ? localizations.routine_collapse_all
                        : localizations.routine_expand_all,
                onTap: _toggleAll,
                isDark: isDark,
              ),
            ),
          ),
        // Routine blocks
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userRoutineProvider);
              await ref.read(userRoutineProvider.future);
              await ref.read(myPlansPaginatedProvider.notifier).refresh();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12,
              ),
              itemCount: widget.routineData.blocks.length,
              itemBuilder: (context, index) {
                final block = widget.routineData.blocks[index];
                return _RoutineBlockSection(
                  key: ValueKey(block.id),
                  block: block,
                  expanded: _expandedBlockIds.contains(block.id),
                  onToggleExpanded: () => _toggleBlock(block.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandAllButton extends StatelessWidget {
  final bool allExpanded;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ExpandAllButton({
    required this.allExpanded,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              allExpanded ? AppAssets.caretUp : AppAssets.caretDown,
              size: 18,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill-shaped Edit action, styled like the Done button on the edit screen.
class _EditButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _EditButton({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _RoutineBlockSection extends ConsumerStatefulWidget {
  final RoutineBlock block;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  const _RoutineBlockSection({
    super.key,
    required this.block,
    required this.expanded,
    required this.onToggleExpanded,
  });

  @override
  ConsumerState<_RoutineBlockSection> createState() =>
      _RoutineBlockSectionState();
}

class _RoutineBlockSectionState extends ConsumerState<_RoutineBlockSection> {
  RoutineBlock get block => widget.block;

  bool get _expanded => widget.expanded;

  Future<void> _onItemTap(
    BuildContext context,
    WidgetRef ref,
    RoutineItem item,
  ) async {
    switch (item.type) {
      case RoutineItemType.recitation:
        _navigateToReader(context, item.id);
      case RoutineItemType.plan:
        await _openPlanDetails(context, ref, item, planId: item.id);
      case RoutineItemType.series:
        if (!context.mounted) return;
        context.pushNamed(
          'home-series-detail',
          pathParameters: {'id': item.id},
        );
      case RoutineItemType.timer:
        _navigateToTimer(context, item);
      case RoutineItemType.accumulator:
        context.push('/mala', extra: {'presetId': item.id});
      case RoutineItemType.groupAccumulator:
        context.pushNamed(
          'home-group-accumulator',
          pathParameters: {'accumulatorId': item.id},
        );
      case RoutineItemType.groupRecitationCollection:
        context.pushNamed(
          'recitation-collection',
          pathParameters: {'collectionId': item.id},
          extra: {'title': item.title},
        );
      case RoutineItemType.myRecitationCollection:
        context.pushNamed(
          'my-recitation-collection',
          pathParameters: {'collectionId': item.id},
          extra: {'title': item.title},
        );
      case RoutineItemType.unknown:
        // Written by a newer app version — nothing here knows how to open it.
        break;
    }
  }

  Future<void> _onPlanArrowTap(
    BuildContext context,
    WidgetRef ref,
    RoutineItem item,
  ) async {
    final planId = item.currentPlanId;
    if (planId == null || planId.isEmpty) return;
    await _openPlanDetails(context, ref, item, planId: planId);
  }

  void _navigateToReader(BuildContext context, String textId) {
    final navigationContext = NavigationContext(
      source: NavigationSource.routine,
    );
    context.push('/reader/$textId', extra: navigationContext);
  }

  void _navigateToTimer(BuildContext context, RoutineItem item) {
    final durationMs = item.durationMs;
    if (durationMs == null || durationMs <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.notFound)));
      return;
    }

    final name = routineItemDisplayTitle(item, context.l10n);
    context.push(
      '/home/timers/active',
      extra: PresetTimer(id: item.id, name: name, durationMs: durationMs),
    );
  }

  /// Opens plan details for [planId]. For PLAN sessions that id is
  /// `source_id` from GET /users/me/routine. Does not search My Plans.
  Future<void> _openPlanDetails(
    BuildContext context,
    WidgetRef ref,
    RoutineItem item, {
    required String planId,
  }) async {
    final catalogEither = await ref.read(planByIdFutureProvider(planId).future);
    final catalogPlan = catalogEither.fold((_) => null, (plan) => plan);
    if (catalogPlan == null) {
      _logger.warning('[ENROLL-NAV] plan $planId not found');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.notFound)));
      }
      return;
    }
    if (!context.mounted) return;
    final userPlan = _userPlanFromCatalogPlan(catalogPlan, item);
    final startDate =
        item.startDate ?? item.enrolledAt ?? userPlan.startedAt;
    final daysSinceEnrollment =
        DateTime.now().difference(DateUtils.dateOnly(startDate)).inDays;
    final selectedDay = (daysSinceEnrollment + 1).clamp(1, userPlan.totalDays);
    _logger.info(
      '[ENROLL-NAV] open plan ${userPlan.id} selectedDay=$selectedDay/${userPlan.totalDays}',
    );
    context.push(
      '/practice/details',
      extra: {
        'plan': userPlan,
        'selectedDay': selectedDay,
        'startDate': startDate,
        if (item.type == RoutineItemType.series) 'seriesId': item.id,
      },
    );
  }

  void _toggleExpanded() {
    if (block.items.isEmpty) return;
    widget.onToggleExpanded();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasItems = block.items.isNotEmpty;
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final title = block.title;
    final timeStyle = TextStyle(
      fontSize: title == null ? 15 : 13,
      fontWeight: title == null ? FontWeight.w500 : FontWeight.w400,
      color:
          title == null
              ? labelColor
              : (isDark ? AppColors.textTertiaryDark : AppColors.textSecondary),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        InkWell(
          onTap: hasItems ? _toggleExpanded : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(block.formattedTime, style: timeStyle),
                      if (title != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasItems)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _expanded ? AppAssets.caretUp : AppAssets.caretDown,
                      size: 18,
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child:
              _expanded && hasItems
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      for (int i = 0; i < block.items.length; i++) ...[
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i < block.items.length - 1 ? 8.0 : 0,
                          ),
                          child: _buildItemCard(context, ref, block.items[i]),
                        ),
                      ],
                    ],
                  )
                  : const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, WidgetRef ref, RoutineItem item) {
    if (item.type == RoutineItemType.recitation) {
      return PracticeChantListTile(
        recitation: recitationModelFromRoutineItem(item),
        includeOuterPadding: false,
        onTap: () => _onItemTap(context, ref, item),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCollection =
        item.type == RoutineItemType.groupRecitationCollection ||
        item.type == RoutineItemType.myRecitationCollection;
    final itemCount = item.itemCount;

    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.cardBackgroundDark
                : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: RoutineItemCard(
          title: routineItemDisplayTitle(item, context.l10n),
          coverImage: item.coverImage,
          type: item.type,
          planTitle:
              isCollection && itemCount != null && itemCount > 0
                  ? context.l10n.my_recitation_collection_chant_count(itemCount)
                  : item.currentPlanTitle,
          imageSize: 56,
          onTap: () => _onItemTap(context, ref, item),
          onPlanTap:
              item.type == RoutineItemType.series && item.currentPlanId != null
                  ? () => _onPlanArrowTap(context, ref, item)
                  : null,
        ),
      ),
    );
  }
}

RoutineItem? _findRoutineItem(RoutineData routineData, String itemId) {
  for (final block in routineData.blocks) {
    for (final item in block.items) {
      if (item.id == itemId) return item;
    }
  }
  return null;
}

UserPlansModel _userPlanFromCatalogPlan(Plan plan, RoutineItem item) {
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
    startedAt: item.enrolledAt ?? item.startDate ?? plan.startDate ?? DateTime.now(),
    totalDays: plan.totalDays,
    tags: null,
    startDate: item.startDate ?? plan.startDate,
  );
}
