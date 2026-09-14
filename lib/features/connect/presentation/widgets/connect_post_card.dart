import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_post_like_actions.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_like_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_action_menu.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_action_bar.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_card_header.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_card_layout.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_detail_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_link_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class ConnectPostCard extends ConsumerStatefulWidget {
  const ConnectPostCard({
    super.key,
    required this.post,
    this.includeUnfollowed = false,
    this.syncFeedProvider = false,
    this.showGroupLink = true,
    this.groupId,
    this.onEdit,
    this.onDelete,
  });

  final ConnectPost post;
  final bool includeUnfollowed;
  final bool syncFeedProvider;

  /// False when the card is already shown inside the group's own profile.
  final bool showGroupLink;

  /// Group whose post list to keep in sync, set inside that group's profile.
  final String? groupId;

  /// Header menu entries; the menu is hidden when both are null.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  ConsumerState<ConnectPostCard> createState() => _ConnectPostCardState();
}

class _ConnectPostCardState extends ConsumerState<ConnectPostCard> {
  final ConnectOptimisticLikeState _likeState = ConnectOptimisticLikeState();

  bool get _isLiked => _likeState.isLiked(widget.post.likedByMe);

  int get _likeCount => _likeState.likeCount(
    serverLikeCount: widget.post.likeCount,
    serverLikedByMe: widget.post.likedByMe,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final post = widget.post;
    final caption = post.caption.trim();
    final imageMedia =
        post.media
            .where((item) => item.isImage && item.url.isNotEmpty)
            .toList();
    final links =
        post.links.where((link) => link.url.trim().isNotEmpty).toList();
    final timestamp = post.publishedAt ?? post.createdAt;

    return Material(
      color: isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite,
      child: InkWell(
        onTap: _openDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConnectFeedCardHeader(
              groupName: post.groupName,
              groupAvatarUrl: post.groupAvatarUrl,
              groupId: widget.showGroupLink ? post.groupId : null,
              timestamp: timestamp,
              stackTimestamp: true,
              trailing: _buildHeaderActions(post, isDark),
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ConnectFeedCardLayout.horizontalPadding,
                  ConnectFeedCardLayout.bodyTopSpacing,
                  ConnectFeedCardLayout.horizontalPadding,
                  0,
                ),
                child: Text(
                  caption,
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
                child: _PostMediaGallery(
                  media: imageMedia,
                  isDark: isDark,
                  onDoubleTapLike: _toggleLike,
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
                  isLoading: _likeState.isSubmitting,
                  onTap: _toggleLike,
                ),
                (
                  icon: AppAssets.chatCircle,
                  iconColor: null,
                  count: post.commentCount,
                  isLoading: false,
                  onTap: _openDetail,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActions(ConnectPost post, bool isDark) {
    final iconColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final share = IconButton(
      onPressed: () => _sharePost(post),
      icon: Icon(AppAssets.readerShare, size: 20, color: iconColor),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
    if (widget.onEdit == null && widget.onDelete == null) return share;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        share,
        ConnectActionMenu(
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
          iconColor: iconColor,
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(36, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  void _openDetail() {
    ConnectPostDetailDrawer.show(
      context,
      postId: widget.post.id,
      initialPost: widget.post,
      includeUnfollowed: widget.includeUnfollowed,
      groupId: widget.groupId,
    );
  }

  Future<void> _toggleLike() async {
    if (_likeState.isSubmitting) return;

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
          syncFeed: widget.syncFeedProvider,
          groupId: widget.groupId,
        );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _likeState.revert(wasLiked));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.errorMessage!)));
      return;
    }

    setState(
      () => _likeState.commitSuccess(
        serverLikeCount: widget.post.likeCount,
        serverLikedByMe: widget.post.likedByMe,
      ),
    );
  }

  Future<void> _sharePost(ConnectPost post) async {
    final caption = post.caption.trim();
    final longUrl =
        post.groupId.isNotEmpty
            ? DeepLinkUrlBuilder.groupLink(groupId: post.groupId).toString()
            : '';
    final shareUrl =
        longUrl.isNotEmpty ? await resolveShareUrlRef(ref, longUrl) : '';
    if (!mounted) return;

    final message =
        caption.isNotEmpty && shareUrl.isNotEmpty
            ? '$caption\n\n$shareUrl'
            : caption.isNotEmpty
            ? caption
            : shareUrl;
    if (message.isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: message));
  }
}

class _PostMediaGallery extends StatefulWidget {
  const _PostMediaGallery({
    required this.media,
    required this.isDark,
    required this.onDoubleTapLike,
  });

  final List<ConnectPostMedia> media;
  final bool isDark;
  final VoidCallback onDoubleTapLike;

  @override
  State<_PostMediaGallery> createState() => _PostMediaGalleryState();
}

class _PostMediaGalleryState extends State<_PostMediaGallery> {
  int _page = 0;

  /// Carousel frame follows the first image, kept between portrait 4:5 and
  /// landscape 1.91:1 so one tall photo cannot take over the feed.
  double get _aspectRatio {
    final first = widget.media.first;
    final width = first.width;
    final height = first.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return 1;
    }
    return (width / height).clamp(0.8, 1.91).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    if (media.length == 1) {
      return _PostMediaTile(
        media: media.first,
        isDark: widget.isDark,
        onDoubleTapLike: widget.onDoubleTapLike,
      );
    }

    final errorWidget = ColoredBox(
      color: widget.isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.photoLibrary,
        color: widget.isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );

    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: media.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              return GestureDetector(
                onDoubleTap: widget.onDoubleTapLike,
                child: CachedNetworkImageWidget(
                  imageUrl: media[index].url,
                  fit: BoxFit.cover,
                  errorWidget: errorWidget,
                ),
              );
            },
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_page + 1}/${media.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostMediaTile extends StatelessWidget {
  const _PostMediaTile({
    required this.media,
    required this.isDark,
    required this.onDoubleTapLike,
  });

  final ConnectPostMedia media;
  final bool isDark;
  final VoidCallback onDoubleTapLike;

  @override
  Widget build(BuildContext context) {
    final errorWidget = ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.photoLibrary,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );

    final width = media.width;
    final height = media.height;
    final Widget image;
    if (width != null && height != null && width > 0 && height > 0) {
      image = ClipRect(
        child: AspectRatio(
          aspectRatio: width / height,
          child: CachedNetworkImageWidget(
            imageUrl: media.url,
            fit: BoxFit.cover,
            errorWidget: errorWidget,
          ),
        ),
      );
    } else {
      image = CachedNetworkImageWidget(
        imageUrl: media.url,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorWidget: errorWidget,
      );
    }

    return GestureDetector(onDoubleTap: onDoubleTapLike, child: image);
  }
}
