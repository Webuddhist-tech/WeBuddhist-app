import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// One topic pill. A pick shows filled with a check; tapping it again clears
/// it, since the topic is optional.
class HelpTopicChip extends StatelessWidget {
  const HelpTopicChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isDark,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;

  /// Null draws the chip without a tap target, as the "Message sent" sheet
  /// shows the picked topic.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final inverse = isDark ? AppColors.textPrimary : AppColors.textPrimaryDark;
    final border = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final onTap = this.onTap;

    final pill = Material(
      color: isSelected ? ink : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: isSelected ? ink : border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected && onTap != null) ...[
                Icon(AppAssets.check, size: 14, color: inverse),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  strutStyle: context.tibetanStrutStyle(13, compact: true),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? inverse : ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return pill;

    // Drawn at the design's height, but like a Material chip its tap area is
    // padded to kMinInteractiveDimension; a tap on the padding counts too.
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: pill),
        ),
      ),
    );
  }
}
