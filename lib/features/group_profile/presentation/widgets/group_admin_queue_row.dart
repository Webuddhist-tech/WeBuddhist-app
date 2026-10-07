import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Admin-only entry under the profile actions that opens a queue such as
/// join requests or reports, with its pending count as a badge.
class GroupAdminQueueRow extends StatelessWidget {
  const GroupAdminQueueRow({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.isDark,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool isDark;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    const fontSize = 16.0;
    final locale = Localizations.localeOf(context);
    final isTibetan = context.isTibetanLocale;
    final rowHeight = isTibetan ? 60.0 : 56.0;
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final chevronColor = isDark ? AppColors.grey500 : AppColors.grey800;
    final countLabel = count > 99 ? '99+' : '$count';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Material(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: rowHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppColors.chipBackgroundDark
                              : AppColors.grey100,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 20,
                      color:
                          iconColor ??
                          (isDark ? AppColors.grey400 : AppColors.grey800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      strutStyle: context.tibetanStrutStyle(fontSize),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                        fontFamily: getSystemFontFamily(locale.languageCode),
                      ),
                    ),
                  ),
                  if (count > 0) ...[
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.surfaceWhite
                                : AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isTibetan ? toTibetanDigits(countLabel) : countLabel,
                        strutStyle: context.tibetanStrutStyle(
                          12,
                          compact: true,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark
                                  ? AppColors.textPrimary
                                  : AppColors.surfaceWhite,
                          fontFamily: getSystemFontFamily(locale.languageCode),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(AppAssets.caretRight, size: 18, color: chevronColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
