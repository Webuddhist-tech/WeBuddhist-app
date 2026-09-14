import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_hero_card.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_member_lists.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_more_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_session_complete_sheet.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class GroupAccumulatorScreen extends ConsumerStatefulWidget {
  final String accumulatorId;
  final String? groupTitle;

  const GroupAccumulatorScreen({
    super.key,
    required this.accumulatorId,
    this.groupTitle,
  });

  @override
  ConsumerState<GroupAccumulatorScreen> createState() =>
      _GroupAccumulatorScreenState();
}

class _GroupAccumulatorScreenState extends ConsumerState<GroupAccumulatorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      groupAccumulatorDetailProvider(widget.accumulatorId),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(groupAccumulatorDetailProvider(widget.accumulatorId), (
      previous,
      next,
    ) {
      next.whenData((either) {
        either.fold((_) {}, (detail) {
          final cacheNotifier = ref.read(
            groupAccumulatorJoinCacheProvider(detail.groupId).notifier,
          );
          if (detail.isJoined == true) {
            cacheNotifier.markJoined(detail.id);
          } else if (detail.isJoined == false) {
            cacheNotifier.markUnjoined(detail.id);
          }
        });
      });
    });

    final resolvedDetail = detailAsync.whenOrNull(
      data: (either) => either.fold((_) => null, (detail) => detail),
    );
    if (resolvedDetail != null) {
      // Warm the bookmark state so the more-sheet opens with the right icon.
      ref.watch(
        prefetchBookmarkExistsProvider(
          BookmarkTarget(
            type: BookmarkType.groupAccumulator,
            sourceId: resolvedDetail.id,
          ),
        ),
      );
      ref.listen(
        groupFollowProvider(
          GroupFollowKey(
            groupId: resolvedDetail.groupId,
            groupType: _resolveGroupType(ref, resolvedDetail.groupId),
          ),
        ),
        (previous, next) {
          if (next case GroupFollowSuccess(isFollowing: false)) {
            ref
                .read(
                  groupAccumulatorJoinCacheProvider(
                    resolvedDetail.groupId,
                  ).notifier,
                )
                .clear();
            ref.invalidate(
              groupAccumulatorDetailProvider(widget.accumulatorId),
            );
            refreshGroupPractices(ref, resolvedDetail.groupId);
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(context, resolvedDetail),
            Expanded(
              child: detailAsync.when(
                data:
                    (either) => either.fold(
                      (failure) => Center(
                        child: ErrorStateWidget(
                          error: failure,
                          onRetry:
                              () => ref.invalidate(
                                groupAccumulatorDetailProvider(
                                  widget.accumulatorId,
                                ),
                              ),
                        ),
                      ),
                      (detail) => _buildContent(context, detail, isDark),
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => Center(
                      child: ErrorStateWidget(
                        error: error,
                        onRetry:
                            () => ref.invalidate(
                              groupAccumulatorDetailProvider(
                                widget.accumulatorId,
                              ),
                            ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header text: the group title from the route extra when present, else the
  /// group profile (fetched on demand for routine/bookmark/notification entry
  /// points, which pass only the accumulator id), else the accumulation title.
  String _appBarTitle(GroupAccumulatorDetail? detail) {
    final title = widget.groupTitle?.trim();
    if (title != null && title.isNotEmpty) return title;
    if (detail == null) return '';
    final groupName = ref
        .watch(groupProfileProvider(detail.groupId))
        .whenOrNull(
          data:
              (either) => either.fold((_) => null, (profile) => profile.title),
        );
    return groupName ?? detail.title;
  }

  Widget _buildAppBar(BuildContext context, GroupAccumulatorDetail? detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              _appBarTitle(detail),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (detail == null)
            const SizedBox(width: 48, height: 48)
          else
            IconButton(
              icon: const Icon(AppAssets.dotsThreeVertical),
              onPressed: () => _openMoreSheet(detail),
            ),
        ],
      ),
    );
  }

  void _openMoreSheet(GroupAccumulatorDetail detail) {
    showGroupAccumulatorMoreSheet(
      context,
      accumulatorId: detail.id,
      accumulatorTitle: detail.title,
      onAddToPractices: () => _onAddToPractices(detail),
      onShare: () => _onShareTap(detail),
    );
  }

  /// The routine API never auto-joins, so the user must join here first.
  void _onAddToPractices(GroupAccumulatorDetail detail) {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final localJoinedIds = ref.read(
      groupAccumulatorJoinCacheProvider(detail.groupId),
    );
    if (!accumulatorHasJoined(detail, localJoinedIds: localJoinedIds)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.group_accumulator_join_before_practice),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    context.pushNamed(
      'edit-routine',
      extra: {'initialGroupAccumulator': detail},
    );
  }

  Widget _buildContent(
    BuildContext context,
    GroupAccumulatorDetail detail,
    bool isDark,
  ) {
    final localJoinedIds = ref.watch(
      groupAccumulatorJoinCacheProvider(detail.groupId),
    );
    final hasJoined = accumulatorHasJoined(
      detail,
      localJoinedIds: localJoinedIds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _AccumulatorHeroCard(
            detail: detail,
            hasJoined: hasJoined,
            isDark: isDark,
            isJoining: _isJoining,
            onJoinTap: () => _onJoinTap(detail),
            onReciteTap: () => _onReciteTap(context, detail),
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
          unselectedLabelColor:
              isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
          indicatorColor:
              isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
          indicatorWeight: 2,
          dividerHeight: 1,
          dividerColor: isDark ? AppColors.cardBorderDark : AppColors.grey300,
          tabs: [
            Tab(text: context.l10n.group_accumulator_leaderboard),
            Tab(text: context.l10n.group_accumulator_my_contributions),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              GroupAccumulatorLeaderboardList(
                accumulatorId: widget.accumulatorId,
                isDark: isDark,
              ),
              GroupAccumulatorMyContributionsList(
                detail: detail,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onJoinTap(GroupAccumulatorDetail detail) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() => _isJoining = true);
    final ok = await joinGroupAccumulator(
      ref: ref,
      accumulatorId: detail.id,
      groupId: detail.groupId,
    );

    if (!mounted) return;
    setState(() {
      _isJoining = false;
      if (ok) {
        ref
            .read(groupAccumulatorJoinCacheProvider(detail.groupId).notifier)
            .markJoined(detail.id);
      }
    });

    if (ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.group_accumulator_join_error),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _onReciteTap(
    BuildContext context,
    GroupAccumulatorDetail detail,
  ) async {
    if (!detail.hasTextContent) {
      final presetId = detail.presetAccumulatorId;
      if (presetId.isEmpty) return;
      await context.push(
        '/mala',
        extra: {'presetId': presetId, 'groupAccumulatorId': detail.id},
      );
      if (!context.mounted) return;
      await _refreshAfterPractice(detail);
      return;
    }

    final textId = detail.textId;
    if (textId == null || textId.isEmpty) return;

    final sessionCount = await context.push<int>(
      '/reader/$textId',
      extra: NavigationContext(
        source: NavigationSource.groupAccumulatorChant,
        groupAccumulatorId: detail.id,
        presetAccumulatorId: detail.presetAccumulatorId,
        groupId: detail.groupId,
        groupTitle:
            _resolveGroupName(detail.groupId)?.trim().isNotEmpty == true
                ? _resolveGroupName(detail.groupId)!.trim()
                : null,
        groupAccumulatorSessionCount: detail.user?.totalCount ?? 0,
      ),
    );

    if (!context.mounted) return;

    await _refreshAfterPractice(detail);

    if (sessionCount == null) return;

    showGroupAccumulatorSessionCompleteSheet(
      context,
      sessionCount: sessionCount,
      accumulationTitle: detail.title,
      accumulatorId: detail.id,
      groupId: detail.groupId,
      groupName: _resolveGroupName(detail.groupId),
    );
  }

  Future<void> _refreshAfterPractice(GroupAccumulatorDetail detail) async {
    try {
      await ref.read(malaSyncManagerProvider).flush(SyncReason.screenLeave);
    } catch (_) {}

    refreshGroupAccumulatorData(
      ref,
      accumulatorId: detail.id,
      groupId: detail.groupId,
    );
  }

  Future<void> _onShareTap(GroupAccumulatorDetail detail) async {
    final groupName = _resolveGroupName(detail.groupId);
    final shareMessage =
        groupName == null
            ? context.l10n.group_accumulator_share_message_no_group(
              detail.title,
            )
            : context.l10n.group_accumulator_share_message(
              detail.title,
              groupName,
            );
    final longUrl =
        DeepLinkUrlBuilder.groupAccumulatorLink(
          accumulatorId: detail.id,
          groupId: detail.groupId,
        ).toString();
    final shareUrl = await resolveShareUrlRef(ref, longUrl);
    if (!mounted) return;

    final sharePositionOrigin = getSharePositionOrigin(context: context);

    await SharePlus.instance.share(
      ShareParams(
        text: '$shareMessage\n\n$shareUrl',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// The group title normally arrives via the route extra; when the screen is
  /// opened from a deep link it is absent, so fall back to the cached group
  /// profile if it has already loaded.
  String? _resolveGroupName(String groupId) {
    final title = widget.groupTitle?.trim();
    if (title != null && title.isNotEmpty) return title;
    return ref
        .read(groupProfileProvider(groupId))
        .whenOrNull(
          data:
              (either) => either.fold((_) => null, (profile) => profile.title),
        );
  }
}

GroupType _resolveGroupType(WidgetRef ref, String groupId) {
  final profileAsync = ref.read(groupProfileProvider(groupId));
  return profileAsync.maybeWhen(
    data:
        (either) => either.fold(
          (_) => GroupType.community,
          (profile) => profile.groupType,
        ),
    orElse: () => GroupType.community,
  );
}

class _AccumulatorHeroCard extends StatelessWidget {
  final GroupAccumulatorDetail detail;
  final bool hasJoined;
  final bool isDark;
  final bool isJoining;
  final VoidCallback? onJoinTap;
  final VoidCallback? onReciteTap;

  const _AccumulatorHeroCard({
    required this.detail,
    required this.hasJoined,
    required this.isDark,
    this.isJoining = false,
    this.onJoinTap,
    this.onReciteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GroupAccumulatorHeroCard(
      detail: detail,
      hasJoined: hasJoined,
      isDark: isDark,
      isJoining: isJoining,
      onJoinTap: onJoinTap,
      onActionTap: hasJoined ? onReciteTap : null,
    );
  }
}
