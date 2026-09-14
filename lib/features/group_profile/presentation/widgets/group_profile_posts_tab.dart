import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_card.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_post_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_nested_tab_scroll_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupProfilePostsTab extends ConsumerWidget {
  final String groupId;
  final bool isDark;
  final double? lineHeight;
  final String pageStorageKey;

  /// True when the signed-in user may publish in this group.
  final bool canPost;
  final VoidCallback onCreatePost;
  final ValueChanged<ConnectPost> onEditPost;

  const GroupProfilePostsTab({
    super.key,
    required this.groupId,
    required this.isDark,
    required this.pageStorageKey,
    required this.canPost,
    required this.onCreatePost,
    required this.onEditPost,
    this.lineHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupPostsProvider(groupId));
    final notifier = ref.read(groupPostsProvider(groupId).notifier);

    if (state.posts.isEmpty) {
      if (!state.hasLoaded) {
        return GroupProfileNestedTabScrollView.centered(
          pageStorageKey: pageStorageKey,
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      if (state.error != null) {
        return GroupProfileNestedTabScrollView.centered(
          pageStorageKey: pageStorageKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ErrorStateWidget(
              error: state.error!,
              customMessage: context.l10n.group_posts_load_error,
              onRetry: notifier.retry,
            ),
          ),
        );
      }

      return GroupProfileNestedTabScrollView.centered(
        pageStorageKey: pageStorageKey,
        child: _EmptyPosts(
          isDark: isDark,
          lineHeight: lineHeight,
          canPost: canPost,
          onCreatePost: onCreatePost,
        ),
      );
    }

    final itemCount = state.posts.length + (state.isLoadingMore ? 1 : 0);
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
              notifier.loadMore();
            }
            return false;
          },
          child: GroupProfileNestedTabScrollView(
            pageStorageKey: pageStorageKey,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, canPost ? 96 : 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= state.posts.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final post = state.posts[index];
                    final isLast = index == state.posts.length - 1;

                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Material(
                        color: cardColor,
                        elevation: isDark ? 0 : 1,
                        shadowColor: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ConnectPostCard(
                          key: ValueKey(post.id),
                          post: post,
                          includeUnfollowed: true,
                          showGroupLink: false,
                          groupId: groupId,
                          onEdit: canPost ? () => onEditPost(post) : null,
                          onDelete:
                              canPost
                                  ? () => _confirmDelete(context, ref, post)
                                  : null,
                        ),
                      ),
                    );
                  }, childCount: itemCount),
                ),
              ),
            ],
          ),
        ),
        if (canPost)
          Positioned(
            right: 16,
            bottom: 24,
            child: _CreatePostFab(isDark: isDark, onTap: onCreatePost),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ConnectPost post,
  ) async {
    final l10n = context.l10n;
    final success = await showDestructiveConfirmationDialog(
      context,
      title: l10n.group_post_delete_title,
      message: l10n.group_post_delete_message,
      onConfirmed:
          () => ref
              .read(groupPostsProvider(groupId).notifier)
              .deletePost(post.id),
    );

    if (success != false || !context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.group_post_delete_failed)));
  }
}

class _EmptyPosts extends StatelessWidget {
  const _EmptyPosts({
    required this.isDark,
    required this.lineHeight,
    required this.canPost,
    required this.onCreatePost,
  });

  final bool isDark;
  final double? lineHeight;
  final bool canPost;
  final VoidCallback onCreatePost;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.group_posts_empty_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: titleColor,
                height: lineHeight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.group_posts_empty_message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
                height: lineHeight,
              ),
            ),
            if (canPost) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onCreatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                  foregroundColor:
                      isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  l10n.group_post_button,
                  strutStyle: context.tibetanStrutStyle(15),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreatePostFab extends StatelessWidget {
  const _CreatePostFab({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: context.l10n.group_post_new_title,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              AppAssets.plus,
              size: 26,
              color: isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
            ),
          ),
        ),
      ),
    );
  }
}
