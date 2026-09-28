import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Looks like the composer pill but only opens the new-request sheet.
class PrayerRequestPrompt extends StatelessWidget {
  const PrayerRequestPrompt({
    super.key,
    required this.hintText,
    required this.onTap,
  });

  final String hintText;
  final VoidCallback? onTap;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final fillColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite;
    final foreground =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Semantics(
      button: true,
      label: hintText,
      child: Material(
        color: fillColor,
        shape: StadiumBorder(side: BorderSide(color: borderColor)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(AppAssets.plus, size: 18, color: foreground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hintText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      strutStyle: context.tibetanStrutStyle(15, compact: true),
                      style: TextStyle(fontSize: 15, color: foreground),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
