import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_comment_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_action_menu.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day_engagement.dart';
import 'package:flutter_pecha/features/home/presentation/providers/verse_of_day_engagement_providers.dart';
import 'package:flutter_pecha/features/home/presentation/utils/verse_comment_threading.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_sheet_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Comments on the verse of the day, with a composer at the bottom.
class VerseCommentsSheet extends ConsumerStatefulWidget {
  const VerseCommentsSheet({super.key, required this.verseId});

  final String verseId;

  static const double _initialSize = 0.88;
  static const double _minSize = 0.45;
  static const double _maxSize = 0.96;

  static Future<void> show(BuildContext context, {required String verseId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => VerseCommentsSheet(verseId: verseId),
    );
  }

  @override
  ConsumerState<VerseCommentsSheet> createState() => _VerseCommentsSheetState();
}

class _VerseCommentsSheetState extends ConsumerState<VerseCommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  ScrollController? _scrollController;
  VerseOfDayComment? _replyTarget;

  @override
  void initState() {
    super.initState();
    // The card keeps this provider alive, so reload on open to pick up
    // comments from others. Deferred: providers can't change mid-build.
    // A first load still in flight makes this a no-op.
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(verseOfDayCommentsProvider(widget.verseId).notifier)
          .loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _attachScrollController(ScrollController controller) {
    if (identical(_scrollController, controller)) return;
    _scrollController?.removeListener(_onScroll);
    _scrollController = controller..addListener(_onScroll);
  }

  void _onScroll() {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients) return;
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 200) {
      ref.read(verseOfDayCommentsProvider(widget.verseId).notifier).loadMore();
    }
  }

  void _startReply(VerseOfDayComment comment) {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() => _replyTarget = comment);
    _focusNode.requestFocus();
  }

  Future<void> _submit() async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final replyTarget = _replyTarget;
    final error = await ref
        .read(verseOfDayCommentsProvider(widget.verseId).notifier)
        .submitComment(text, parentCommentId: replyTarget?.id);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.verse_comment_failed)),
      );
      return;
    }

    _controller.clear();
    _focusNode.unfocus();
    setState(() => _replyTarget = null);
    // A reply lands under its parent, not at the top.
    if (replyTarget != null) return;
    _scrollController?.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _confirmDelete(VerseOfDayComment comment) async {
    final success = await showDestructiveConfirmationDialog(
      context,
      title: context.l10n.connect_comment_delete_title,
      message: context.l10n.connect_comment_delete_message,
      onConfirmed:
          () => ref
              .read(verseOfDayCommentsProvider(widget.verseId).notifier)
              .deleteComment(comment.id),
    );

    if (!mounted) return;
    // Deleting a parent takes its replies, so the target may be gone too.
    final target = _replyTarget;
    if (success == true &&
        target != null &&
        !ref
            .read(verseOfDayCommentsProvider(widget.verseId))
            .comments
            .any((c) => c.id == target.id)) {
      setState(() => _replyTarget = null);
    }
    if (success != false) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.connect_comment_delete_failed)),
    );
  }

  Future<void> _toggleLike(VerseOfDayComment comment) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final error = await ref
        .read(verseOfDayCommentsProvider(widget.verseId).notifier)
        .toggleCommentLike(comment.id);
    if (error == null || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.verse_like_failed)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(verseOfDayCommentsProvider(widget.verseId));

    return DraggableScrollableSheet(
      initialChildSize: VerseCommentsSheet._initialSize,
      minChildSize: VerseCommentsSheet._minSize,
      maxChildSize: VerseCommentsSheet._maxSize,
      snap: true,
      snapSizes: const [
        VerseCommentsSheet._minSize,
        VerseCommentsSheet._initialSize,
        VerseCommentsSheet._maxSize,
      ],
      snapAnimationDuration: const Duration(milliseconds: 180),
      builder: (context, scrollController) {
        _attachScrollController(scrollController);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            elevation: 12,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            child: Column(
              children: [
                VerseSheetHeader(
                  title: context.l10n.verse_comments_title(state.total),
                ),
                Expanded(
                  child: MediaQuery.removeViewInsets(
                    context: context,
                    removeBottom: true,
                    child: _buildBody(
                      context,
                      isDark,
                      state,
                      scrollController,
                    ),
                  ),
                ),
                if (_replyTarget != null)
                  _ReplyingToBanner(
                    name: _replyTarget!.user.displayName,
                    isDark: isDark,
                    onClear: () => setState(() => _replyTarget = null),
                  ),
                _VerseCommentComposer(
                  controller: _controller,
                  focusNode: _focusNode,
                  isSubmitting: state.isSubmitting,
                  onSubmit: _submit,
                  isReplying: _replyTarget != null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    VerseOfDayCommentsState state,
    ScrollController scrollController,
  ) {
    if (state.isLoading && state.comments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.comments.isEmpty) {
      return ErrorStateWidget(
        error: state.error!,
        onRetry:
            () =>
                ref
                    .read(verseOfDayCommentsProvider(widget.verseId).notifier)
                    .retry(),
      );
    }

    final currentUserId = ref.watch(
      userProvider.select((state) => state.user?.id),
    );

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      children: [
        if (state.comments.isEmpty && state.hasLoaded)
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
          for (final item in threadVerseComments(state.comments))
            _VerseCommentTile(
              comment: item.comment,
              isDark: isDark,
              isReply: item.isReply,
              isOwn:
                  currentUserId != null &&
                  item.comment.userId == currentUserId,
              onLike: () => _toggleLike(item.comment),
              onReply: () => _startReply(item.comment),
              onDelete: () => _confirmDelete(item.comment),
            ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.error != null)
          _LoadMoreError(
            isDark: isDark,
            onRetry:
                () =>
                    ref
                        .read(
                          verseOfDayCommentsProvider(widget.verseId).notifier,
                        )
                        .retry(),
          ),
      ],
    );
  }
}

class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.isDark, required this.onRetry});

  final bool isDark;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            context.l10n.unableToLoad,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color:
                  isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(context.l10n.tryAgain)),
        ],
      ),
    );
  }
}

class _VerseCommentTile extends StatelessWidget {
  const _VerseCommentTile({
    required this.comment,
    required this.isDark,
    required this.isReply,
    required this.isOwn,
    required this.onLike,
    required this.onReply,
    required this.onDelete,
  });

  final VerseOfDayComment comment;
  final bool isDark;
  final bool isReply;
  final bool isOwn;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final displayName = comment.user.displayName;
    final relativeTime = connectCommentRelativeTime(comment.createdAt);
    final primary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 42 : 0, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VerseUserAvatar(
            name: displayName,
            avatarUrl: comment.user.avatarUrl,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: primary,
                            height: 1.3,
                          ),
                          children: [
                            TextSpan(
                              text: displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (relativeTime.isNotEmpty)
                              TextSpan(
                                text: ' · $relativeTime',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CommentLikeButton(
                      isLiked: comment.likedByMe,
                      likeCount: comment.likeCount,
                      isDark: isDark,
                      onTap: onLike,
                    ),
                    if (isOwn)
                      ConnectActionMenu(
                        iconSize: 18,
                        iconColor: muted,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(28, 22),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onDelete: onDelete,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.text,
                  style: TextStyle(fontSize: 14, height: 1.45, color: primary),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onReply,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: muted,
                  ),
                  child: Text(
                    context.l10n.connect_comment_reply,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentLikeButton extends StatelessWidget {
  const _CommentLikeButton({
    required this.isLiked,
    required this.likeCount,
    required this.isDark,
    required this.onTap,
  });

  final bool isLiked;
  final int likeCount;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final defaultColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? AppAssets.heartFill : AppAssets.heart,
              size: 18,
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

class _ReplyingToBanner extends StatelessWidget {
  const _ReplyingToBanner({
    required this.name,
    required this.isDark,
    required this.onClear,
  });

  final String name;
  final bool isDark;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.verse_comment_replying_to(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(AppAssets.x, size: 18),
            onPressed: onClear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Current user's avatar beside a rounded field; the send button appears
/// once there is text, as in the Connect composer.
class _VerseCommentComposer extends ConsumerWidget {
  const _VerseCommentComposer({
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.onSubmit,
    required this.isReplying,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final bool isReplying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;
    final user = ref.watch(userProvider).user;
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final fillColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: color),
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        keyboardInset > 0 ? keyboardInset + 8 : bottomSafePadding + 8,
      ),
      child: Row(
        children: [
          VerseUserAvatar(
            name: user?.firstName ?? user?.username ?? '',
            avatarUrl: user?.avatarUrl,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              style: TextStyle(
                fontSize: 15,
                height: 1.2,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText:
                    isReplying
                        ? context.l10n.connect_comment_reply_hint
                        : context.l10n.connect_comment_hint,
                hintStyle: TextStyle(
                  fontSize: 15,
                  height: 1.2,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textSecondary,
                ),
                filled: true,
                fillColor: fillColor,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: border(borderColor),
                enabledBorder: border(borderColor),
                focusedBorder: border(
                  isDark ? AppColors.grey600 : AppColors.grey400,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              if (!hasText && !isSubmitting) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: _SendButton(
                  isSubmitting: isSubmitting,
                  isDark: isDark,
                  onPressed: hasText && !isSubmitting ? onSubmit : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.isSubmitting,
    required this.isDark,
    required this.onPressed,
  });

  final bool isSubmitting;
  final bool isDark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final foregroundColor =
        isDark ? AppColors.textPrimary : AppColors.surfaceWhite;

    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child:
                isSubmitting
                    ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foregroundColor,
                      ),
                    )
                    : Icon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color: foregroundColor,
                    ),
          ),
        ),
      ),
    );
  }
}
