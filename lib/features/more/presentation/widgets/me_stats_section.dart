import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/presentation/utils/me_analytics.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/me_streak_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/accumulation_sheet.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/practice_days_sheet.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/streak_share_sheet.dart';

class MeStatsSection extends ConsumerWidget {
  const MeStatsSection({super.key, required this.stats});

  final UserStats stats;

  static const _horizontalPadding = 20.0;
  static const _cardSpacing = 12.0;
  static const _borderRadius = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = intlFormatLocaleOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.surfaceWhite;
    void trackTap(MeItem item) =>
        ref.read(meAnalyticsProvider).itemTapped(item);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        24,
        _horizontalPadding,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.me_my_stats,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 12),
          MeStreakCard(
            streak: stats.streak,
            onTap: () {
              trackTap(MeItem.streak);
              showStreakShareSheet(context, stats.streak);
            },
          ),
          const SizedBox(height: _cardSpacing),
          _PracticeDaysCard(
            days: stats.totalPracticeDays,
            cardColor: cardColor,
            onTap: () {
              trackTap(MeItem.practiceDays);
              showPracticeDaysSheet(
                context,
                totalDays: stats.totalPracticeDays,
              );
            },
          ),
          const SizedBox(height: _cardSpacing),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: l10n.me_accumulation,
                  icon: Image.asset(
                    AppAssets.homeMalaIcon,
                    width: 22,
                    height: 22,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  value: _formatCompactCount(stats.totalAccumulated, locale),
                  cardColor: cardColor,
                  onTap: () {
                    trackTap(MeItem.accumulation);
                    showAccumulationSheet(
                      context,
                      formattedTotal: _formatCompactCount(
                        stats.totalAccumulated,
                        locale,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: _cardSpacing),
              Expanded(
                child: _StatCard(
                  label: l10n.me_total_meditation_time,
                  icon: Icon(
                    AppAssets.homeTimer,
                    size: 22,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  value: _formatDuration(
                    stats.totalTimer,
                    isTibetan: context.isTibetanLocale,
                    minuteLabel: l10n.me_minutes,
                    hourLabel: l10n.me_hours,
                  ),
                  cardColor: cardColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCompactCount(int count, String locale) {
    if (count >= 1000000) {
      final value = count / 1000000;
      return '${_trimTrailingZero(value.toStringAsFixed(1))}M';
    }
    if (count >= 1000) {
      final value = count / 1000;
      return '${_trimTrailingZero(value.toStringAsFixed(1))}k';
    }
    return NumberFormat.decimalPattern(locale).format(count);
  }

  String _formatDuration(
    int milliseconds, {
    required bool isTibetan,
    required String minuteLabel,
    required String hourLabel,
  }) {
    final totalMinutes = (milliseconds / 60000).round();
    if (totalMinutes < 60) {
      if (isTibetan) {
        return '$minuteLabel ${toTibetanDigits(totalMinutes)}';
      }
      return '${totalMinutes}m';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (isTibetan) {
      if (minutes == 0) {
        return '$hourLabel ${toTibetanDigits(hours)}';
      }
      return '$hourLabel ${toTibetanDigits(hours)} '
          '$minuteLabel ${toTibetanDigits(minutes)}';
    }
    if (minutes == 0) return '${hours}hr';
    return '${hours}hr ${minutes}m';
  }

  String _trimTrailingZero(String value) {
    return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.cardColor,
    this.onTap,
  });

  final String label;
  final Widget icon;
  final String value;
  final Color cardColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTibetan = context.isTibetanLocale;
    final valueStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeStatsSection._borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MeStatsSection._borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                strutStyle: context.tibetanStrutStyle(12),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.grey300 : AppColors.grey900,
                  fontSize: 12,
                  height: isTibetan ? 1.4 : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 4),
                  Expanded(
                    child:
                        isTibetan
                            ? FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                value,
                                maxLines: 1,
                                softWrap: false,
                                strutStyle: context.tibetanStrutStyle(
                                  valueStyle?.fontSize ?? 22,
                                ),
                                style: valueStyle,
                              ),
                            )
                            : Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                              style: valueStyle,
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeDaysCard extends StatelessWidget {
  const _PracticeDaysCard({
    required this.days,
    required this.cardColor,
    this.onTap,
  });

  final int days;
  final Color cardColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTibetan = AppFontConfig.isTibetanLanguage(
      Localizations.localeOf(context).languageCode,
    );
    final daysStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);
    final suffixStyle = Theme.of(context).textTheme.titleMedium;

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeStatsSection._borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MeStatsSection._borderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(
                AppAssets.homeList,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    isTibetan
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return SizedBox(
                                  width: constraints.maxWidth,
                                  child: FittedBox(
                                    alignment: Alignment.centerLeft,
                                    fit: BoxFit.scaleDown,
                                    child: Text.rich(
                                      TextSpan(
                                        style: suffixStyle,
                                        children: [
                                          TextSpan(
                                            text:
                                                ' ${l10n.me_days_plan_practiced_suffix} ',
                                          ),
                                          TextSpan(
                                            text: '$days',
                                            style: suffixStyle?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize:
                                                  (suffixStyle.fontSize ?? 16) *
                                                  1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                        : Text.rich(
                          TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(text: '$days', style: daysStyle),
                              TextSpan(
                                text: ' ${l10n.me_days_plan_practiced_suffix}',
                                style: suffixStyle,
                              ),
                            ],
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
