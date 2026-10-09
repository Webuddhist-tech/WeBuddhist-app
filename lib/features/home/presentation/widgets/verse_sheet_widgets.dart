import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';

/// Drag handle, back button and title shared by the verse bottom sheets.
class VerseSheetHeader extends StatelessWidget {
  const VerseSheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  title,
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
}

class VerseUserAvatar extends StatelessWidget {
  const VerseUserAvatar({
    super.key,
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

/// Closes a modal verse sheet when the dimmed area above it is tapped.
///
/// `showModalBottomSheet` wraps its builder output in a canvas [Material]
/// that absorbs hit tests over the full route height, so with a
/// [DraggableScrollableSheet] inside it taps above the sheet never reach the
/// modal barrier. The outer detector catches those taps and pops; the inner
/// one wins the gesture arena for taps on the sheet itself so they are
/// ignored. Both are hidden from semantics so screen readers keep the
/// barrier's own "dismiss" action.
class VerseSheetTapToDismiss extends StatelessWidget {
  const VerseSheetTapToDismiss({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: () => Navigator.of(context).pop(),
      child: child,
    );
  }
}

/// Swallows taps on the sheet body so [VerseSheetTapToDismiss] above it does
/// not close the sheet.
class VerseSheetTapShield extends StatelessWidget {
  const VerseSheetTapShield({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      excludeFromSemantics: true,
      onTap: () {},
      child: child,
    );
  }
}
