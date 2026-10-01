import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_comment_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_action_menu.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day_engagement.dart';
import 'package:flutter_pecha/features/home/presentation/providers/verse_of_day_engagement_providers.dart';
import 'package:flutter_pecha/features/home/presentation/utils/verse_comment_utils.dart';
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

  Future<void> _submit() async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final error = await ref
        .read(verseOfDayCommentsProvider(widget.verseId).notifier)
        .submitComment(text);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.verse_comment_failed)),
      );
      return;
    }

    _controller.clear();
    _focusNode.unfocus();
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

    if (!mounted || success != false) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.connect_comment_delete_failed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(verseOfDayCommentsProvider(widget.verseId));
    final currentUser = ref.watch(userProvider).user;

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
                _buildHeader(context, isDark, state.total),
                Expanded(
                  child: MediaQuery.removeViewInsets(
                    context: context,
                    removeBottom: true,
                    child: _buildBody(
                      context,
                      isDark,
                      state,
                      currentUser,
                      scrollController,
                    ),
                  ),
                ),
                _VerseCommentComposer(
                  controller: _controller,
                  focusNode: _focusNode,
                  isSubmitting: state.isSubmitting,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, int count) {
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: context.l10n.drag_to_resize,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 16, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(AppAssets.arrowLeft),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  context.l10n.verse_comments_title(count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  strutStyle: context.tibetanStrutStyle(17, compact: true),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    VerseOfDayCommentsState state,
    User? currentUser,
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
          ...state.comments.map(
            (comment) => _VerseCommentTile(
              comment: comment,
              isDark: isDark,
              isOwn: isVerseCommentOwnedBy(
                comment: comment,
                currentUser: currentUser,
                ownCommentIds: state.ownCommentIds,
              ),
              onDelete: () => _confirmDelete(comment),
            ),
          ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _VerseCommentTile extends StatelessWidget {
  const _VerseCommentTile({
    required this.comment,
    required this.isDark,
    required this.isOwn,
    required this.onDelete,
  });

  final VerseOfDayComment comment;
  final bool isDark;
  final bool isOwn;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final displayName = comment.user.displayName;
    final relativeTime = connectCommentRelativeTime(comment.createdAt);
    final primary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentAvatar(
            name: displayName,
            avatarUrl: comment.user.avatarUrl,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: primary, height: 1.3),
                    children: [
                      TextSpan(
                        text: displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
                const SizedBox(height: 2),
                Text(
                  comment.text,
                  style: TextStyle(fontSize: 14, height: 1.45, color: primary),
                ),
              ],
            ),
          ),
          if (isOwn)
            ConnectActionMenu(
              iconSize: 18,
              iconColor: muted,
              onDelete: onDelete,
            ),
        ],
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({
    required this.name,
    required this.avatarUrl,
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

/// Current user's avatar beside a rounded field; the send button appears
/// once there is text, as in the Connect composer.
class _VerseCommentComposer extends ConsumerWidget {
  const _VerseCommentComposer({
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final VoidCallback onSubmit;

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
          _CommentAvatar(
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
                hintText: context.l10n.connect_comment_hint,
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
