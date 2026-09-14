import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post_comment.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_post_comments_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_post_like_actions.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_like_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_comment_tile.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_comment_composer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class ConnectPostDetailScreen extends ConsumerWidget {
  const ConnectPostDetailScreen({
    super.key,
    required this.postId,
    this.initialPost,
    this.includeUnfollowed = false,
  });

  final String postId;
  final ConnectPost? initialPost;
  final bool includeUnfollowed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor:
          isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: ConnectPostDetailPanel(
          postId: postId,
          initialPost: initialPost,
          includeUnfollowed: includeUnfollowed,
          showTopBar: true,
        ),
      ),
    );
  }
}

class ConnectPostDetailPanel extends ConsumerStatefulWidget {
  const ConnectPostDetailPanel({
    super.key,
    required this.postId,
    this.initialPost,
    this.includeUnfollowed = false,
    this.groupId,
    this.scrollController,
    this.showTopBar = false,
    this.showPostPreview = true,
  });

  final String postId;
  final ConnectPost? initialPost;
  final bool includeUnfollowed;
  final String? groupId;
  final ScrollController? scrollController;
  final bool showTopBar;
  final bool showPostPreview;

  @override
  ConsumerState<ConnectPostDetailPanel> createState() =>
      _ConnectPostDetailPanelState();
}

class _ConnectPostDetailPanelState extends ConsumerState<ConnectPostDetailPanel> {
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;
  late ConnectPost _post;
  final ConnectOptimisticLikeState _likeState = ConnectOptimisticLikeState();
  ConnectPostComment? _replyTarget;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost ?? _emptyPost(widget.postId);
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  ConnectPost _emptyPost(String postId) {
    return ConnectPost(
      id: postId,
      groupId: '',
      caption: '',
      status: '',
      creatorName: '',
    );
  }

  bool get _isLiked => _likeState.isLiked(_post.likedByMe);

  int get _likeCount => _likeState.likeCount(
    serverLikeCount: _post.likeCount,
    serverLikedByMe: _post.likedByMe,
  );

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(connectPostCommentsProvider(widget.postId).notifier).loadMore();
    }
  }

  void _startReply(ConnectPostComment comment) {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() {
      _replyTarget = comment;
      _commentController.text = '@${comment.user.mentionHandle} ';
      _commentController.selection = TextSelection.collapsed(
        offset: _commentController.text.length,
      );
    });
    _commentFocusNode.requestFocus();
  }

  void _clearReply() {
    setState(() => _replyTarget = null);
  }

  Future<void> _submitComment() async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final success = await ref
        .read(connectPostCommentsProvider(widget.postId).notifier)
        .submitComment(text: text, parentCommentId: _replyTarget?.id);

    if (!mounted || !success) return;

    _commentController.clear();
    _clearReply();
    _updatePostCommentCount(_post.commentCount + 1);
    _commentFocusNode.unfocus();
  }

  void _updatePostCommentCount(int count) {
    setState(() {
      _post = _post.copyWith(commentCount: count);
    });
    ref
        .read(connectPostLikeActionsProvider)
        .syncPost(
          _post,
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
          post: _post,
          wasLiked: wasLiked,
          optimisticLikeCount: _likeCount,
          includeUnfollowed: widget.includeUnfollowed,
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

    setState(() {
      _likeState.commitSuccess(
        serverLikeCount: _post.likeCount,
        serverLikedByMe: _post.likedByMe,
      );
      _post = result.updatedPost!;
    });
  }

  Future<void> _sharePost() async {
    final caption = _post.caption.trim();
    final longUrl =
        _post.groupId.isNotEmpty
            ? DeepLinkUrlBuilder.groupLink(groupId: _post.groupId).toString()
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final commentsState = ref.watch(connectPostCommentsProvider(widget.postId));
    final isSubmittingComment = ref.watch(
      connectPostCommentsProvider(
        widget.postId,
      ).select((state) => state.isSubmitting),
    );
    final commentCount =
        commentsState.total > 0 ? commentsState.total : _post.commentCount;

    return Column(
      children: [
        if (widget.showTopBar) _buildTopBar(context),
        Expanded(
          child: MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: _buildBody(context, isDark, commentsState, commentCount),
          ),
        ),
        ConnectCommentComposer(
          controller: _commentController,
          focusNode: _commentFocusNode,
          isSubmitting: isSubmittingComment,
          onSubmit: _submitComment,
          replyHandle: _replyTarget?.user.mentionHandle,
          onClearReply: _clearReply,
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            icon: const Icon(AppAssets.x),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    ConnectPostCommentsState commentsState,
    int commentCount,
  ) {
    if (commentsState.isLoading && commentsState.comments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (commentsState.error != null && commentsState.comments.isEmpty) {
      return ErrorStateWidget(
        error: commentsState.error!,
        onRetry:
            () =>
                ref
                    .read(connectPostCommentsProvider(widget.postId).notifier)
                    .retry(),
      );
    }

    final orderedComments = commentsState.orderedComments;

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        20,
        widget.showPostPreview ? 0 : 8,
        20,
        16,
      ),
      children: [
        if (widget.showPostPreview) ...[
          _buildPostCard(context, isDark, commentCount),
          const SizedBox(height: 24),
        ],
        Text(
          context.l10n.connect_post_comments_count(commentCount),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        if (orderedComments.isEmpty && !commentsState.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              context.l10n.connect_post_comments_empty,
              style: TextStyle(
                fontSize: 15,
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary,
              ),
            ),
          )
        else
          ...orderedComments.map(
            (comment) => ConnectPostCommentTile(
              comment: comment,
              postId: widget.postId,
              onReply: _startReply,
            ),
          ),
        if (commentsState.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildPostCard(BuildContext context, bool isDark, int commentCount) {
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final caption = _post.caption.trim();
    final imageMedia =
        _post.media
            .where((item) => item.isImage && item.url.isNotEmpty)
            .toList();
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostAuthorRow(
            name: _post.groupName,
            avatarUrl: _post.groupAvatarUrl,
            isDark: isDark,
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              caption,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ],
          if (imageMedia.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PostMediaGallery(media: imageMedia, isDark: isDark),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _PostActionButton(
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
              const SizedBox(width: 20),
              _PostActionButton(
                icon: AppAssets.chatCircle,
                count: commentCount,
                onTap: () => _commentFocusNode.requestFocus(),
              ),
              const Spacer(),
              _PostActionButton(icon: AppAssets.readerShare, onTap: _sharePost),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostAuthorRow extends StatelessWidget {
  const _PostAuthorRow({
    required this.name,
    this.avatarUrl,
    required this.isDark,
  });

  final String name;
  final String? avatarUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final displayName =
        name.trim().isNotEmpty ? name.trim() : context.l10n.connect_group_fallback_title;

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor:
              isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
          backgroundImage:
              avatarUrl != null && avatarUrl!.isNotEmpty
                  ? avatarUrl!.cachedNetworkImageProvider
                  : null,
          child:
              avatarUrl == null || avatarUrl!.isEmpty
                  ? Icon(
                    AppAssets.profile,
                    size: 16,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textSecondary,
                  )
                  : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PostMediaGallery extends StatelessWidget {
  const _PostMediaGallery({required this.media, required this.isDark});

  final List<ConnectPostMedia> media;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (media.length == 1) {
      return _PostMediaTile(media: media.first, isDark: isDark);
    }

    final visibleMedia = media.take(2).toList();
    return Row(
      children: [
        for (var i = 0; i < visibleMedia.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _PostMediaTile(
              media: visibleMedia[i],
              isDark: isDark,
              compact: true,
            ),
          ),
        ],
      ],
    );
  }
}

class _PostMediaTile extends StatelessWidget {
  const _PostMediaTile({
    required this.media,
    required this.isDark,
    this.compact = false,
  });

  final ConnectPostMedia media;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final errorWidget = ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.photoLibrary,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );

    if (compact) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: CachedNetworkImageWidget(
            imageUrl: media.url,
            fit: BoxFit.cover,
            errorWidget: errorWidget,
          ),
        ),
      );
    }

    final width = media.width;
    final height = media.height;
    if (width != null && height != null && width > 0 && height > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: width / height,
          child: CachedNetworkImageWidget(
            imageUrl: media.url,
            fit: BoxFit.cover,
            errorWidget: errorWidget,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImageWidget(
        imageUrl: media.url,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorWidget: errorWidget,
      ),
    );
  }
}

class _PostActionButton extends StatelessWidget {
  const _PostActionButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.count,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final int? count;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor ?? defaultColor,
                ),
              )
            else
              Icon(icon, size: 20, color: iconColor ?? defaultColor),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: defaultColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
