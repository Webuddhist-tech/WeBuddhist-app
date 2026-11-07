import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/utils/url_opener.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_post_like_actions.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_analytics.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_like_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_post_share.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_action_menu.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_expandable_caption.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_action_bar.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_card_header.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_card_layout.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_detail_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_link_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_media_grid.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_media_viewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

bool _containsTibetan(String value) {
  return RegExp(r'[\u0F00-\u0FFF]').hasMatch(value);
}

class ConnectPostCard extends ConsumerStatefulWidget {
  const ConnectPostCard({
    super.key,
    required this.post,
    this.includeUnfollowed = false,
    this.showGroupLink = true,
    this.groupId,
    this.onEdit,
    this.onDelete,
    this.placement,
  });

  final ConnectPost post;
  final bool includeUnfollowed;

  /// False when the card is already shown inside the group's own profile.
  final bool showGroupLink;

  /// Group whose post list to keep in sync, set inside that group's profile.
  final String? groupId;

  /// Header menu entries; the menu is hidden when both are null.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Where this card sits in a feed; the card is only tracked when set.
  final ConnectPostPlacement? placement;

  @override
  ConsumerState<ConnectPostCard> createState() => _ConnectPostCardState();
}

class _ConnectPostCardState extends ConsumerState<ConnectPostCard> {
  static const _collapsedCaptionLines = 2;
  static const _viewedVisibleFraction = 0.5;
  static const _viewedAfter = Duration(seconds: 1);

  final ConnectOptimisticLikeState _likeState = ConnectOptimisticLikeState();
  bool _captionExpanded = false;
  Timer? _viewTimer;

  bool get _isLiked => _likeState.isLiked(widget.post.likedByMe);

  int get _likeCount => _likeState.likeCount(
    serverLikeCount: widget.post.likeCount,
    serverLikedByMe: widget.post.likedByMe,
  );

  @override
  void didUpdateWidget(ConnectPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Feed cards have no keys, so a reorder can hand this state another post.
    if (widget.post.id != oldWidget.post.id) {
      _captionExpanded = false;
      _cancelViewTimer();
    }
  }

  @override
  void dispose() {
    _cancelViewTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placement = widget.placement;
    if (placement == null) return _buildCard(context);
    return VisibilityDetector(
      key: ValueKey(
        'connect-post-${placement.surface.key}-${placement.visitId}-'
        '${widget.post.id}',
      ),
      onVisibilityChanged: _onVisibilityChanged,
      child: _buildCard(context),
    );
  }

  /// A card taller than twice the screen can never be half visible, so filling
  /// half the screen counts too.
  void _onVisibilityChanged(VisibilityInfo info) {
    // The detector can report once more after this card has gone.
    if (!mounted) return;
    final isViewable =
        info.visibleFraction >= _viewedVisibleFraction ||
        info.visibleBounds.height >=
            MediaQuery.sizeOf(context).height * _viewedVisibleFraction;
    if (isViewable) {
      _viewTimer ??= Timer(_viewedAfter, _reportViewed);
    } else {
      _cancelViewTimer();
    }
  }

  void _cancelViewTimer() {
    _viewTimer?.cancel();
    _viewTimer = null;
  }

  void _reportViewed() {
    _viewTimer = null;
    final placement = widget.placement;
    if (!mounted || placement == null) return;
    final isFirstView = ref
        .read(connectPostViewTrackerProvider(placement.viewScope))
        .markViewed(widget.post.id);
    if (!isFirstView) return;
    ref
        .read(connectAnalyticsProvider)
        .postViewed(post: widget.post, placement: placement);
  }

  void _trackOpened() {
    final placement = widget.placement;
    if (placement == null) return;
    ref
        .read(connectAnalyticsProvider)
        .postOpened(post: widget.post, placement: placement);
  }

  /// Reads everything first: a first-party link can navigate away from here.
  Future<void> _openPostLink(ConnectPostLink link) async {
    final analytics = ref.read(connectAnalyticsProvider);
    final post = widget.post;
    final placement = widget.placement;
    final opened = await openLink(link.url);
    if (opened && placement != null) {
      analytics.postLinkOpened(post: post, placement: placement, link: link);
    }
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final post = widget.post;
    final caption = post.caption.trim();
    final hasTibetanCaption = _containsTibetan(caption);
    final imageMedia =
        post.media
            .where((item) => item.isImage && item.url.isNotEmpty)
            .toList();
    final links =
        post.links.where((link) => link.url.trim().isNotEmpty).toList();
    final timestamp = post.publishedAt ?? post.createdAt;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleCaption,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConnectFeedCardHeader(
            groupName: post.groupName,
            groupAvatarUrl: post.groupAvatarUrl,
            groupId: widget.showGroupLink ? post.groupId : null,
            timestamp: timestamp,
            stackTimestamp: true,
            trailing: _buildHeaderMenu(isDark),
          ),
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ConnectFeedCardLayout.horizontalPadding,
                ConnectFeedCardLayout.bodyTopSpacing,
                ConnectFeedCardLayout.horizontalPadding,
                0,
              ),
              child: ConnectExpandableCaption(
                text: caption,
                expanded: _captionExpanded,
                onToggle: _toggleCaption,
                maxLines: _collapsedCaptionLines,
                strutStyle:
                    hasTibetanCaption
                        ? AppFontConfig.tibetanStrutStyle(
                          AppConfig.tibetanLanguageCode,
                          15,
                        )
                        : null,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ),
          if (imageMedia.isNotEmpty) ...[
            const SizedBox(height: ConnectFeedCardLayout.bodyToMediaSpacing),
            ConnectFeedCardMediaFrame(
              bottomSpacing:
                  links.isNotEmpty
                      ? ConnectFeedCardLayout.bodyToMediaSpacing
                      : ConnectFeedCardLayout.actionBarTopSpacing,
              child: ConnectPostMediaGrid(
                media: imageMedia,
                isDark: isDark,
                onTapImage: (index) => _openMediaViewer(imageMedia, index),
                onDoubleTap: _toggleLike,
              ),
            ),
          ],
          if (links.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                ConnectFeedCardLayout.horizontalPadding,
                imageMedia.isNotEmpty
                    ? 0
                    : ConnectFeedCardLayout.bodyToMediaSpacing,
                ConnectFeedCardLayout.horizontalPadding,
                ConnectFeedCardLayout.mediaBottomSpacing,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < links.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    ConnectPostLinkCard(
                      url: links[i].url,
                      label: links[i].label,
                      onTap: () => _openPostLink(links[i]),
                    ),
                  ],
                ],
              ),
            ),
          ConnectFeedActionBar(
            actions: [
              (
                icon: _isLiked ? AppAssets.heartFill : AppAssets.heart,
                iconColor:
                    _isLiked
                        ? AppColors.error
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                count: _likeCount,
                onTap: _toggleLike,
              ),
              (
                icon: AppAssets.chatCircle,
                iconColor: null,
                count: post.commentCount,
                onTap: _openDetail,
              ),
              (
                icon: AppAssets.readerShare,
                iconColor: null,
                count: null,
                onTap: () => _sharePost(post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildHeaderMenu(bool isDark) {
    if (widget.onEdit == null && widget.onDelete == null) return null;

    return ConnectActionMenu(
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _toggleCaption() {
    setState(() => _captionExpanded = !_captionExpanded);
  }

  void _openDetail() {
    _trackOpened();
    ConnectPostDetailDrawer.show(
      context,
      postId: widget.post.id,
      initialPost: widget.post,
      includeUnfollowed: widget.includeUnfollowed,
      groupId: widget.groupId,
    );
  }

  void _openMediaViewer(List<ConnectPostMedia> media, int index) {
    _trackOpened();
    ConnectPostMediaViewer.show(
      context,
      media: media,
      initialIndex: index,
      title: widget.post.groupName,
      actions: ConnectPostMediaViewerActions(
        post: widget.post.copyWith(likedByMe: _isLiked, likeCount: _likeCount),
        includeUnfollowed: widget.includeUnfollowed,
        groupId: widget.groupId,
        onLikeChanged: _onViewerLikeChanged,
      ),
    );
  }

  /// The feed already holds the viewer's result; only drop stale overrides.
  void _onViewerLikeChanged(ConnectPost updated) {
    if (!mounted || widget.post.id != updated.id) return;
    setState(_likeState.clearOverrides);
  }

  Future<void> _toggleLike() async {
    if (_likeState.isSubmitting ||
        ref.read(connectPostLikeActionsProvider).pendingLike(widget.post.id) !=
            null) {
      return;
    }

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final wasLiked = _isLiked;
    setState(() => _likeState.beginToggle(wasLiked));

    final result = await ref
        .read(connectPostLikeActionsProvider)
        .toggleLike(
          post: widget.post,
          wasLiked: wasLiked,
          optimisticLikeCount: _likeCount,
          includeUnfollowed: widget.includeUnfollowed,
          groupId: widget.groupId,
        );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _likeState.revert(wasLiked));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasLiked
                ? context.l10n.connect_failed_unlike_post_error
                : context.l10n.connect_failed_like_post_error,
          ),
        ),
      );
      return;
    }

    setState(
      () => _likeState.commitSuccess(
        serverLikeCount: widget.post.likeCount,
        serverLikedByMe: widget.post.likedByMe,
      ),
    );
  }

  Future<void> _sharePost(ConnectPost post) =>
      shareConnectPost(context, ref, post);
}
