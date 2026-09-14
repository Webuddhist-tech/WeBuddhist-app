import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_practices_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_card_header.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_card_layout.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_date_format.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';

class ConnectPracticeCard extends ConsumerStatefulWidget {
  const ConnectPracticeCard({super.key, required this.practice});

  final GroupPractice practice;

  @override
  ConsumerState<ConnectPracticeCard> createState() =>
      _ConnectPracticeCardState();
}

class _ConnectPracticeCardState extends ConsumerState<ConnectPracticeCard> {
  bool _isEnrollingSeries = false;
  String? _joiningAccumulatorId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lineHeight = theme.textTheme.bodyMedium?.height;
    final practice = widget.practice;

    return switch (practice.type) {
      GroupPracticeType.series when practice.series != null => _buildSeriesCard(
        practice,
        practice.series!,
        isDark,
        lineHeight,
      ),
      GroupPracticeType.accumulator when practice.accumulator != null =>
        _buildAccumulatorCard(
          practice,
          practice.accumulator!,
          isDark,
          lineHeight,
        ),
      GroupPracticeType.plan when practice.plan != null => _buildPlanCard(
        practice,
        practice.plan!,
        isDark,
        lineHeight,
      ),
      GroupPracticeType.collection when practice.collection != null =>
        _buildCollectionCard(
          practice,
          practice.collection!,
          isDark,
          lineHeight,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildSeriesCard(
    GroupPractice practice,
    GroupProfileSeries series,
    bool isDark,
    double? lineHeight,
  ) {
    final dateRange = PlanDateFormat.formatRangeOrNull(
      series.startDate,
      series.endDate,
    );
    final isEnrolled = practice.isJoined || series.isGroupEnrolled == true;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;

    return Material(
      color: cardColor,
      child: InkWell(
        onTap:
            _isEnrollingSeries
                ? null
                : () => _navigateToSeriesDetail(practice, series, isEnrolled),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConnectFeedCardHeader(
              groupName: practice.groupName ?? '',
              groupAvatarUrl: practice.groupAvatarUrl,
              groupId: practice.groupId,
              timestamp: practice.practiceAt,
              stackTimestamp: true,
              subtitle:
                  series.enrolledCount > 0 ? '${series.enrolledCount}' : null,
              subtitleIcon:
                  series.enrolledCount > 0 ? AppAssets.usercard : null,
              trailing: _buildShareButton(
                isDark: isDark,
                title: series.title,
                link: DeepLinkUrlBuilder.seriesLink(seriesId: series.id),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ConnectFeedCardLayout.horizontalPadding,
                ConnectFeedCardLayout.bodyTopSpacing,
                ConnectFeedCardLayout.horizontalPadding,
                ConnectFeedCardLayout.bodyToMediaSpacing,
              ),
              child: Text(
                series.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: lineHeight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ConnectFeedCardMediaFrame(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    series.image != null && !series.image!.isEmpty
                        ? ResponsiveCoverImage(
                          image: series.image,
                          fit: BoxFit.cover,
                        )
                        : ColoredBox(
                          color:
                              isDark
                                  ? AppColors.surfaceVariantDark
                                  : AppColors.grey100,
                          child: Icon(
                            AppAssets.bookOpenText,
                            size: 40,
                            color:
                                isDark ? AppColors.grey500 : AppColors.grey600,
                          ),
                        ),
                    _PracticeImageOverlayBar(
                      leading:
                          !isEnrolled
                              ? _PracticeJoinButton(
                                label: context.l10n.group_practice_with_us,
                                isLoading: _isEnrollingSeries,
                                isDark: isDark,
                                onImage: true,
                                onTap:
                                    () =>
                                        _onPracticeWithUsTap(practice, series),
                              )
                              : null,
                      trailing:
                          dateRange != null
                              ? _PracticeImageBadge(label: dateRange)
                              : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccumulatorCard(
    GroupPractice practice,
    GroupAccumulator accumulator,
    bool isDark,
    double? lineHeight,
  ) {
    final groupId = practice.groupId ?? accumulator.groupId;
    final localJoinedIds = ref.watch(
      groupAccumulatorJoinCacheProvider(groupId),
    );
    final hasJoined =
        practice.isJoined ||
        accumulatorHasJoined(accumulator, localJoinedIds: localJoinedIds);
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final dateRange = PlanDateFormat.formatRangeOrNull(
      accumulator.startDate,
      accumulator.endDate,
    );
    final isJoining = _joiningAccumulatorId == accumulator.id;

    return Material(
      color: cardColor,
      child: InkWell(
        onTap:
            isJoining
                ? null
                : () => _navigateToAccumulatorDetail(accumulator.id, practice),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConnectFeedCardHeader(
              groupName: practice.groupName ?? '',
              groupAvatarUrl: practice.groupAvatarUrl,
              groupId: practice.groupId,
              timestamp: practice.practiceAt,
              stackTimestamp: true,
              subtitle:
                  accumulator.memberCount > 0
                      ? '${accumulator.memberCount}'
                      : null,
              subtitleIcon:
                  accumulator.memberCount > 0 ? AppAssets.usercard : null,
              trailing: _buildShareButton(
                isDark: isDark,
                title: accumulator.title,
                link: DeepLinkUrlBuilder.groupAccumulatorLink(
                  accumulatorId: accumulator.id,
                  groupId: groupId,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ConnectFeedCardLayout.horizontalPadding,
                ConnectFeedCardLayout.bodyTopSpacing,
                ConnectFeedCardLayout.horizontalPadding,
                ConnectFeedCardLayout.bodyToMediaSpacing,
              ),
              child: Text(
                accumulator.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: lineHeight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ConnectFeedCardMediaFrame(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    accumulator.image != null && !accumulator.image!.isEmpty
                        ? ResponsiveCoverImage(
                          image: accumulator.image,
                          fit: BoxFit.cover,
                        )
                        : ColoredBox(
                          color:
                              isDark
                                  ? AppColors.surfaceVariantDark
                                  : AppColors.grey100,
                          child: Icon(
                            AppAssets.bookOpenText,
                            size: 40,
                            color:
                                isDark ? AppColors.grey500 : AppColors.grey600,
                          ),
                        ),
                    _PracticeImageOverlayBar(
                      leading:
                          !hasJoined
                              ? _PracticeJoinButton(
                                label: context.l10n.group_join_to_contribute,
                                isLoading: isJoining,
                                isDark: isDark,
                                onImage: true,
                                onTap:
                                    () => _onJoinAccumulatorTap(
                                      practice,
                                      accumulator,
                                    ),
                              )
                              : null,
                      trailing:
                          dateRange != null
                              ? _PracticeImageBadge(label: dateRange)
                              : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    GroupPractice practice,
    GroupPracticePlan plan,
    bool isDark,
    double? lineHeight,
  ) {
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final dateRange = PlanDateFormat.formatRangeOrNull(plan.startDate, null);
    final details = [
      if (dateRange != null) dateRange,
      if (plan.totalDays > 0) context.l10n.days_count(plan.totalDays),
    ].join(' · ');

    return Material(
      color: cardColor,
      child: InkWell(
        onTap: () => _navigateToPlanDetail(practice, plan),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConnectFeedCardHeader(
              groupName: practice.groupName ?? '',
              groupAvatarUrl: practice.groupAvatarUrl,
              groupId: practice.groupId,
              subtitle: details.isNotEmpty ? details : null,
              trailing: _buildShareButton(
                isDark: isDark,
                title: plan.title,
                link: DeepLinkUrlBuilder.planLink(planId: plan.id),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ConnectFeedCardLayout.horizontalPadding,
                ConnectFeedCardLayout.bodyTopSpacing,
                ConnectFeedCardLayout.horizontalPadding,
                ConnectFeedCardLayout.bodyToMediaSpacing,
              ),
              child: Text(
                plan.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: lineHeight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ConnectFeedCardMediaFrame(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child:
                    plan.imageUrl != null && plan.imageUrl!.isNotEmpty
                        ? CachedNetworkImageWidget(
                          imageUrl: plan.imageUrl!,
                          fit: BoxFit.cover,
                        )
                        : ColoredBox(
                          color:
                              isDark
                                  ? AppColors.surfaceVariantDark
                                  : AppColors.grey100,
                          child: Icon(
                            AppAssets.bookOpenText,
                            size: 40,
                            color:
                                isDark ? AppColors.grey500 : AppColors.grey600,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard(
    GroupPractice practice,
    GroupRecitationCollection collection,
    bool isDark,
    double? lineHeight,
  ) {
    final groupId =
        practice.groupId?.trim().isNotEmpty == true
            ? practice.groupId!
            : collection.groupId;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final itemCountLabel =
        collection.itemCount > 0
            ? context.l10n.my_recitation_collection_chant_count(
              collection.itemCount,
            )
            : null;

    return Material(
      color: cardColor,
      child: InkWell(
        onTap: () => _navigateToCollectionDetail(practice, collection),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConnectFeedCardHeader(
              groupName: practice.groupName ?? '',
              groupAvatarUrl: practice.groupAvatarUrl,
              groupId: practice.groupId,
              timestamp: practice.practiceAt,
              stackTimestamp: true,
              trailing: _buildShareButton(
                isDark: isDark,
                title: collection.name,
                link: DeepLinkUrlBuilder.groupRecitationCollectionLink(
                  groupId: groupId,
                  collectionId: collection.id,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ConnectFeedCardLayout.horizontalPadding,
                ConnectFeedCardLayout.bodyTopSpacing,
                ConnectFeedCardLayout.horizontalPadding,
                ConnectFeedCardLayout.bodyToMediaSpacing,
              ),
              child: Text(
                collection.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: lineHeight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ConnectFeedCardMediaFrame(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    collection.imageUrl != null &&
                            collection.imageUrl!.isNotEmpty
                        ? CachedNetworkImageWidget(
                          imageUrl: collection.imageUrl!,
                          fit: BoxFit.cover,
                        )
                        : ColoredBox(
                          color:
                              isDark
                                  ? AppColors.surfaceVariantDark
                                  : AppColors.grey100,
                          child: Icon(
                            AppAssets.bookOpenText,
                            size: 40,
                            color:
                                isDark ? AppColors.grey500 : AppColors.grey600,
                          ),
                        ),
                    if (itemCountLabel != null)
                      _PracticeImageOverlayBar(
                        trailing: _PracticeImageBadge(label: itemCountLabel),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton({
    required bool isDark,
    required String title,
    required Uri link,
  }) {
    return IconButton(
      onPressed: () => _sharePractice(title, link),
      icon: Icon(
        AppAssets.readerShare,
        size: 20,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  Future<void> _sharePractice(String title, Uri link) async {
    final shareUrl = await resolveShareUrlRef(ref, link.toString());
    if (!mounted) return;

    final message =
        shareUrl.isNotEmpty ? '${title.trim()}\n\n$shareUrl' : title.trim();
    if (message.isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: message));
  }

  void _navigateToPlanDetail(GroupPractice practice, GroupPracticePlan plan) {
    final planEntity = plan.toPlan();
    context.push(
      '/practice/plans/preview',
      extra: {
        'plan': planEntity,
        if (plan.seriesId != null) 'seriesId': plan.seriesId,
      },
    );
  }

  void _navigateToSeriesDetail(
    GroupPractice practice,
    GroupProfileSeries series,
    bool isEnrolled,
  ) {
    if (isEnrolled) {
      context.push('/home/series/${series.id}');
      return;
    }

    context.push(
      '/home/series/${series.id}',
      extra: {
        if (practice.groupId != null) 'groupId': practice.groupId,
        'groupType': GroupType.community,
        'isGroupEnrolled': false,
      },
    );
  }

  Future<void> _onPracticeWithUsTap(
    GroupPractice practice,
    GroupProfileSeries series,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final groupId = practice.groupId;
    if (groupId == null) return;

    setState(() => _isEnrollingSeries = true);
    final ok = await enrollSeriesThroughGroup(
      ref: ref,
      seriesId: series.id,
      groupId: groupId,
      groupType: GroupType.community,
    );

    if (!mounted) return;
    setState(() => _isEnrollingSeries = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.series_enroll_error),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(myConnectPracticesProvider.notifier).refresh();
    ref.read(discoverConnectPracticesProvider.notifier).refresh();
    context.push('/home/series/${series.id}');
  }

  void _navigateToAccumulatorDetail(
    String accumulatorId,
    GroupPractice practice,
  ) {
    context.push(
      '/home/group-accumulator/$accumulatorId',
      extra: {
        'groupTitle':
            practice.groupName?.trim().isNotEmpty == true
                ? practice.groupName
                : null,
      },
    );
  }

  Future<void> _onJoinAccumulatorTap(
    GroupPractice practice,
    GroupAccumulator accumulator,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final groupId = practice.groupId ?? accumulator.groupId;
    if (groupId.isEmpty) return;

    setState(() => _joiningAccumulatorId = accumulator.id);
    final ok = await joinGroupAccumulator(
      ref: ref,
      accumulatorId: accumulator.id,
      groupId: groupId,
      awaitRefresh: false,
    );

    if (!mounted) return;
    setState(() => _joiningAccumulatorId = null);

    if (ok) {
      ref.read(myConnectPracticesProvider.notifier).refresh();
      ref.read(discoverConnectPracticesProvider.notifier).refresh();
      _navigateToAccumulatorDetail(accumulator.id, practice);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.group_accumulator_join_error),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToCollectionDetail(
    GroupPractice practice,
    GroupRecitationCollection collection,
  ) {
    final groupId =
        practice.groupId?.trim().isNotEmpty == true
            ? practice.groupId!
            : collection.groupId;
    if (groupId.trim().isEmpty || collection.id.trim().isEmpty) return;

    context.push(
      '/home/group/$groupId/recitation-collections/${collection.id}',
      extra: {'title': collection.name},
    );
  }
}

class _PracticeImageOverlayBar extends StatelessWidget {
  const _PracticeImageOverlayBar({this.leading, this.trailing});

  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (leading == null && trailing == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Row(
        children: [
          if (leading != null) leading!,
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _PracticeImageBadge extends StatelessWidget {
  const _PracticeImageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PracticeJoinButton extends StatelessWidget {
  const _PracticeJoinButton({
    required this.label,
    required this.isLoading,
    required this.isDark,
    required this.onTap,
    this.onImage = false,
  });

  final String label;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onTap;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final imageOverlayFill = Colors.black.withValues(alpha: 0.55);
    final fill =
        onImage
            ? imageOverlayFill
            : (isDark ? AppColors.surfaceWhite : AppColors.textPrimary);
    final textColor =
        onImage
            ? Colors.white
            : (isDark ? AppColors.textPrimary : AppColors.surfaceWhite);

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child:
              isLoading
                  ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                  : Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
        ),
      ),
    );
  }
}
