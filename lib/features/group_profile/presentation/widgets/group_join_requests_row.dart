import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Admin-only entry on a private group: pending join requests, shown under
/// the messages / joined / invite row when `role` is `ADMIN`.
class GroupJoinRequestsRow extends StatelessWidget {
  const GroupJoinRequestsRow({
    super.key,
    required this.isDark,
    this.requestCount = 0,
    this.onTap,
  });

  final bool isDark;
  final int requestCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const fontSize = 16.0;
    final locale = Localizations.localeOf(context);
    final isTibetan = context.isTibetanLocale;
    final rowHeight = isTibetan ? 60.0 : 56.0;
    final labelColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final chevronColor = isDark ? AppColors.grey500 : AppColors.grey800;
    final countLabel = requestCount > 99 ? '99+' : '$requestCount';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Material(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                          isDark ? AppColors.chipBackgroundDark : AppColors.grey100,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      AppAssets.usercard,
                      size: 20,
                      color: isDark ? AppColors.grey400 : AppColors.grey800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Join requests',
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
                  if (requestCount > 0) ...[
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
                        strutStyle: context.tibetanStrutStyle(12, compact: true),
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
