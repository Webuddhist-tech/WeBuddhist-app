import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post_comment.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_post_comments_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_comment_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_like_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_action_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectPostCommentTile extends ConsumerStatefulWidget {
  const ConnectPostCommentTile({
    super.key,
    required this.comment,
    required this.postId,
    this.onReply,
  });

  final ConnectPostComment comment;
  final String postId;
  final ValueChanged<ConnectPostComment>? onReply;

  @override
  ConsumerState<ConnectPostCommentTile> createState() =>
      _ConnectPostCommentTileState();
}

class _ConnectPostCommentTileState
    extends ConsumerState<ConnectPostCommentTile> {
  final ConnectOptimisticLikeState _likeState = ConnectOptimisticLikeState();

  bool get _isLiked => _likeState.isLiked(widget.comment.likedByMe);

  int get _likeCount => _likeState.likeCount(
    serverLikeCount: widget.comment.likeCount,
    serverLikedByMe: widget.comment.likedByMe,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final comment = widget.comment;
    final displayName = comment.user.displayName;
    final relativeTime = connectCommentRelativeTime(comment.createdAt);
    final currentUserEmail = ref.watch(userProvider).user?.email;
    final isOwnComment = isConnectCommentOwnedByEmail(
      comment: comment,
      currentUserEmail: currentUserEmail,
    );
    final indent = comment.isReply ? 44.0 : 0.0;

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CommentAvatar(
                name: displayName,
                avatarUrl: comment.user.avatarUrl,
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (relativeTime.isNotEmpty) ...[
                        TextSpan(
                          text: ' · $relativeTime',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color:
                                isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isOwnComment)
                ConnectActionMenu(
                  iconSize: 18,
                  iconColor:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textSecondary,
                  onDelete: () => _confirmDelete(comment),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                _CommentText(text: comment.text, isDark: isDark),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TextButton(
                      onPressed:
                          widget.onReply == null
                              ? null
                              : () => widget.onReply!(comment),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textSecondary,
                      ),
                      child: Text(
                        context.l10n.connect_comment_reply,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _CommentLikeButton(
                      isLiked: _isLiked,
                      likeCount: _likeCount,
                      isLoading: _likeState.isSubmitting,
                      isDark: isDark,
                      onTap: () => _toggleLike(comment),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(ConnectPostComment comment) async {
    if (_likeState.isSubmitting) return;

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final wasLiked = _isLiked;
    setState(() => _likeState.beginToggle(wasLiked));

    final success = await ref
        .read(connectPostCommentsProvider(widget.postId).notifier)
        .toggleCommentLike(comment, wasLiked: wasLiked);

    if (!mounted) return;

    if (!success) {
      setState(() => _likeState.revert(wasLiked));
      return;
    }

    setState(
      () => _likeState.commitSuccess(
        serverLikeCount: comment.likeCount,
        serverLikedByMe: comment.likedByMe,
      ),
    );
  }

  Future<void> _confirmDelete(ConnectPostComment comment) async {
    final success = await showDestructiveConfirmationDialog(
      context,
      title: context.l10n.connect_comment_delete_title,
      message: context.l10n.connect_comment_delete_message,
      onConfirmed:
          () => ref
              .read(connectPostCommentsProvider(widget.postId).notifier)
              .deleteComment(comment.id),
    );

    if (!mounted || success != false) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.connect_comment_delete_failed)),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({
    required this.name,
    this.avatarUrl,
    required this.isDark,
  });

  final String name;
  final String? avatarUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return CircleAvatar(
      radius: 16,
      backgroundColor:
          isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      backgroundImage: hasAvatar ? avatarUrl!.cachedNetworkImageProvider : null,
      child:
          hasAvatar
              ? null
              : Text(
                initial,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
    );
  }
}

class _CommentText extends StatelessWidget {
  const _CommentText({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mentionMatch = RegExp(r'^@([A-Za-z0-9._-]+)\s*').firstMatch(text);
    if (mentionMatch == null) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      );
    }

    final mention = mentionMatch.group(0) ?? '';
    final rest = text.substring(mention.length);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        children: [
          TextSpan(
            text: mention,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer(),
          ),
          TextSpan(text: rest),
        ],
      ),
    );
  }
}

class _CommentLikeButton extends StatelessWidget {
  const _CommentLikeButton({
    required this.isLiked,
    required this.likeCount,
    required this.isLoading,
    required this.isDark,
    required this.onTap,
  });

  final bool isLiked;
  final int likeCount;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final defaultColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isLiked ? AppColors.error : defaultColor,
                ),
              )
            else
              Icon(
                isLiked ? AppAssets.heartFill : AppAssets.heart,
                size: 16,
                color: isLiked ? AppColors.error : defaultColor,
              ),
            if (likeCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$likeCount',
                style: TextStyle(
                  fontSize: 13,
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
