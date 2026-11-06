import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/home/presentation/providers/verse_of_day_engagement_providers.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_likers_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Like and comment on the left of the verse card, share on the right.
class VerseOfDayEngagementBar extends ConsumerWidget {
  const VerseOfDayEngagementBar({
    super.key,
    required this.verseId,
    required this.onCommentTap,
    required this.trailing,
  });

  final String verseId;
  final VoidCallback onCommentTap;
  final Widget trailing;

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final error =
        await ref.read(verseOfDayLikesProvider(verseId).notifier).toggle();
    if (error == null || !context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.verse_like_failed)));
  }

  void _showLikers(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    VerseLikersSheet.show(context, verseId: verseId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final likes = ref.watch(verseOfDayLikesProvider(verseId));
    // Only the count matters here, so posting or paging comments does not
    // rebuild the bar.
    final commentCount = ref.watch(
      verseOfDayCommentsProvider(verseId).select(
        (state) => state.hasLoaded && state.total > 0 ? state.total : null,
      ),
    );
    final likeCount =
        likes.isLoaded && likes.likeCount > 0 ? likes.likeCount : null;

    return Row(
      children: [
        _ActionButton(
          icon: likes.likedByMe ? AppAssets.heartFill : AppAssets.heart,
          iconColor: likes.likedByMe ? AppColors.error : defaultColor,
          countColor: defaultColor,
          count: likeCount,
          onTap: () => _toggleLike(context, ref),
          onCountTap: () => _showLikers(context, ref),
        ),
        const SizedBox(width: 16),
        _ActionButton(
          icon: AppAssets.chatCircle,
          iconColor: defaultColor,
          countColor: defaultColor,
          count: commentCount,
          onTap: onCommentTap,
        ),
        const Spacer(),
        trailing,
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.countColor,
    required this.count,
    required this.onTap,
    this.onCountTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color countColor;
  final int? count;
  final VoidCallback onTap;

  /// When set, the count gets its own tap target beside the icon.
  final VoidCallback? onCountTap;

  /// Kept even while the count is still loading or zero, so Comment and
  /// Share do not slide when the number appears. Larger counts grow the
  /// slot on one line instead of wrapping.
  static const _minCountWidth = 24.0;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    final countLabel = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _minCountWidth),
      child:
          count == null
              ? null
              : Align(
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  offset: const Offset(0, 1),
                  child: Text(
                    '$count',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: countColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
              ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 2, 4),
            child: Icon(icon, size: 22, color: iconColor),
          ),
        ),
        InkWell(
          onTap: count == null ? null : (onCountTap ?? onTap),
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: countLabel,
          ),
        ),
      ],
    );
  }
}
