import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/connect_post_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectPostDetailDrawer extends ConsumerWidget {
  const ConnectPostDetailDrawer({
    super.key,
    required this.postId,
    this.initialPost,
    this.includeUnfollowed = false,
    this.groupId,
  });

  final String postId;
  final ConnectPost? initialPost;
  final bool includeUnfollowed;
  final String? groupId;

  static const double _initialSize = 0.88;
  static const double _minSize = 0.45;
  static const double _maxSize = 0.96;

  static Future<void> show(
    BuildContext context, {
    required String postId,
    ConnectPost? initialPost,
    bool includeUnfollowed = false,
    String? groupId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder:
          (_) => ConnectPostDetailDrawer(
            postId: postId,
            initialPost: initialPost,
            includeUnfollowed: includeUnfollowed,
            groupId: groupId,
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: _initialSize,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      snap: true,
      snapSizes: const [_minSize, _initialSize, _maxSize],
      snapAnimationDuration: const Duration(milliseconds: 180),
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            elevation: 12,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ConnectPostDetailPanel(
                    postId: postId,
                    initialPost: initialPost,
                    includeUnfollowed: includeUnfollowed,
                    groupId: groupId,
                    scrollController: scrollController,
                    showPostPreview: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Semantics(
            label: context.l10n.drag_to_resize,
            child: Center(
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
          Positioned(
            right: 4,
            child: IconButton(
              icon: const Icon(AppAssets.x),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
