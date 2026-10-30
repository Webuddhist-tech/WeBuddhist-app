import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_ended_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class GroupAccumulatorHeroCard extends StatelessWidget {
  final GroupAccumulatorDetail detail;
  final bool hasJoined;
  final bool isDark;
  final bool isJoining;
  final VoidCallback? onJoinTap;
  final VoidCallback? onActionTap;

  /// Opens the reader for [GroupAccumulator.textId]. Null when there is no text.
  final VoidCallback? onTextTap;

  const GroupAccumulatorHeroCard({
    super.key,
    required this.detail,
    required this.hasJoined,
    required this.isDark,
    this.isJoining = false,
    this.onJoinTap,
    this.onActionTap,
    this.onTextTap,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern(
      intlFormatLocaleOf(context),
    );
    final progressText =
        '${numberFormat.format(detail.totalCount)} / ${numberFormat.format(detail.targetCount)}';
    final showJoinButton = !hasJoined;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final primaryTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final progressTrackColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey50;

    return Material(
      color: cardColor,
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child:
                detail.image != null && !detail.image!.isEmpty
                    ? ResponsiveCoverImage(
                      image: detail.image,
                      fit: BoxFit.cover,
                    )
                    : ColoredBox(
                      color:
                          isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.grey100,
                      child: Icon(
                        AppAssets.bookOpenText,
                        size: 40,
                        color: isDark ? AppColors.grey500 : AppColors.grey600,
                      ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _AccumulatorSourceRow(
                  detail: detail,
                  isDark: isDark,
                  primaryTextColor: primaryTextColor,
                  secondaryColor: secondaryColor,
                  onTextTap: onTextTap,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        progressText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                    Text(
                      '${detail.progressPercent}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: detail.progressFraction,
                    minHeight: 8,
                    backgroundColor:
                        isDark ? AppColors.cardBorderDark : progressTrackColor,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                if (showJoinButton)
                  _JoinButton(
                    isDark: isDark,
                    isJoining: isJoining,
                    onTap: onJoinTap,
                  )
                else
                  _ActionButton(
                    isDark: isDark,
                    ended: isPastEndDate(detail.endDate, DateTime.now()),
                    onTap: onActionTap,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isDark;
  final bool ended;
  final VoidCallback? onTap;

  const _ActionButton({required this.isDark, required this.ended, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBorderDark : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          ended
              ? context.l10n.group_accumulator_view_practice
              : context.l10n.group_accumulator_recite_now,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final bool isDark;
  final bool isJoining;
  final VoidCallback? onTap;

  const _JoinButton({
    required this.isDark,
    required this.isJoining,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isJoining ? null : onTap,
      child: Container(
        height: 44,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBorderDark : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            isJoining
                ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                )
                : Text(
                  context.l10n.group_join_to_contribute,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
      ),
    );
  }
}

/// Title row under the accumulation title: the linked text, or the mantra
/// line, with the participant count beside it.
class _AccumulatorSourceRow extends ConsumerWidget {
  final GroupAccumulatorDetail detail;
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryColor;
  final VoidCallback? onTextTap;

  const _AccumulatorSourceRow({
    required this.detail,
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryColor,
    required this.onTextTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leading =
        detail.hasTextContent ? _textLeading(ref) : _mantraLeading(ref);

    return Row(
      children: [
        if (leading != null) ...[
          Flexible(child: leading),
          const SizedBox(width: 12),
        ],
        Text(
          context.l10n.group_accumulator_participants(detail.memberCount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget? _textLeading(WidgetRef ref) {
    final textId = detail.textId;
    if (textId == null || textId.isEmpty) return null;

    final async = ref.watch(
      textDetailsFutureProvider(TextDetailsParams(textId: textId, size: 1)),
    );
    if (async.isLoading && !async.hasValue) {
      return _LabelSkeleton(isDark: isDark);
    }
    final loaded = async.valueOrNull?.fold<(String, bool)?>((_) => null, (
      response,
    ) {
      final value = response.textDetail.title.trim();
      if (value.isEmpty) return null;
      return (
        value,
        AppFontConfig.isTibetanLanguage(response.textDetail.language),
      );
    });
    if (loaded == null) return null;

    return _TextPill(
      title: loaded.$1,
      isTibetan: loaded.$2,
      textColor: primaryTextColor,
      isDark: isDark,
      onTap: onTextTap,
    );
  }

  /// A mantra accumulation has no text. The line is the pronunciation shown
  /// on the mala counter, or the mantra script when that line is empty.
  Widget? _mantraLeading(WidgetRef ref) {
    if (detail.hasTextContent) return null;
    if (!detail.hasMantraContent && detail.presetAccumulatorId.isEmpty) {
      return null;
    }

    final async = ref.watch(malaCatalogueProvider);
    if (async.isLoading && !async.hasValue) {
      return _LabelSkeleton(isDark: isDark, height: 16, radius: 4);
    }
    final mantras = async.valueOrNull?.fold((_) => null, (list) => list);
    final mantra = mantras == null ? null : _matchingMantra(mantras);
    if (mantra == null) return null;

    final pronunciation = mantra.mantra?.pronunciation?.trim();
    final hasPronunciation = pronunciation != null && pronunciation.isNotEmpty;
    final script = mantra.tibetan?.trim();
    final label = hasPronunciation ? pronunciation : script;
    if (label == null || label.isEmpty) return null;

    return _MantraLine(
      label: label,
      isScript: !hasPronunciation,
      textColor: primaryTextColor,
    );
  }

  Mantra? _matchingMantra(List<Mantra> mantras) {
    final presetId = detail.presetAccumulatorId;
    if (presetId.isNotEmpty) {
      for (final mantra in mantras) {
        if (mantra.presetId == presetId) return mantra;
      }
    }
    final mantraId = detail.mantraId;
    if (mantraId == null || mantraId.isEmpty) return null;
    for (final mantra in mantras) {
      if (mantra.mantraId == mantraId) return mantra;
    }
    return null;
  }
}

class _TextPill extends StatelessWidget {
  final String title;
  final bool isTibetan;
  final Color textColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _TextPill({
    required this.title,
    required this.isTibetan,
    required this.textColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        isDark
            ? AppColors.blueDark.withValues(alpha: 0.18)
            : const Color(0xFFE7EEFB);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppAssets.bookOpenText, size: 16, color: textColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  strutStyle:
                      isTibetan
                          ? AppFontConfig.tibetanStrutStyle(
                            AppConfig.tibetanLanguageCode,
                            14,
                            compact: true,
                          )
                          : null,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: isTibetan ? AppConfig.tibetanContentFont : null,
                    height: isTibetan ? 1.4 : null,
                  ),
                ),
              ),
              Icon(AppAssets.caretRight, size: 16, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _MantraLine extends StatelessWidget {
  final String label;
  final bool isScript;
  final Color textColor;

  const _MantraLine({
    required this.label,
    required this.isScript,
    required this.textColor,
  });

  static const _fontSize = 15.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppAssets.homeMalaIcon,
          width: 16,
          height: 16,
          color: textColor,
          colorBlendMode: BlendMode.srcIn,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            strutStyle:
                isScript
                    ? AppFontConfig.tibetanStrutStyle(
                      AppConfig.tibetanLanguageCode,
                      _fontSize,
                      compact: true,
                    )
                    : null,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: isScript ? AppConfig.tibetanContentFont : null,
              height: isScript ? 1.4 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabelSkeleton extends StatelessWidget {
  final bool isDark;
  final double height;
  final double radius;

  const _LabelSkeleton({
    required this.isDark,
    this.height = 32,
    this.radius = 999,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
