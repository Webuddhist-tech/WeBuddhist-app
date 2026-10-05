import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography for verse-of-day content, derived from the active locale.
class VerseOfDayTypography {
  const VerseOfDayTypography({
    required this.contentFont,
    required this.systemFont,
    required this.verseFontSize,
    required this.attributionFontSize,
    this.useContentFontForAttribution = false,
    this.useGoogleJomolhari = false,
  });

  final String? contentFont;
  final String? systemFont;
  final double verseFontSize;
  final double attributionFontSize;
  final bool useContentFontForAttribution;
  final bool useGoogleJomolhari;

  factory VerseOfDayTypography.fromLanguageCode(String languageCode) {
    return VerseOfDayTypography(
      contentFont: getFontFamily(languageCode),
      systemFont: getSystemFontFamily(languageCode),
      verseFontSize: getLocalizedFontSize(AppTextSize.bodyLarge),
      attributionFontSize: getLocalizedFontSize(AppTextSize.label),
    );
  }

  /// Home card typography: source one step under the verse, in the sans
  /// system font. Tibetan uses Google Jomolhari for both.
  factory VerseOfDayTypography.forCard(
    String languageCode, {
    double? verseFontSize,
    double? attributionFontSize,
  }) {
    final base = VerseOfDayTypography.fromLanguageCode(languageCode);
    final isTibetan = AppFontConfig.isTibetanLanguage(languageCode);

    return VerseOfDayTypography(
      contentFont: base.contentFont,
      systemFont: base.systemFont,
      verseFontSize: verseFontSize ?? base.verseFontSize,
      attributionFontSize:
          attributionFontSize ?? getLocalizedFontSize(AppTextSize.body),
      useContentFontForAttribution: isTibetan,
      useGoogleJomolhari: isTibetan,
    );
  }

  /// Share preview typography. Larger sizes, same sans source as the card;
  /// Tibetan uses Google Jomolhari.
  factory VerseOfDayTypography.forShare(String languageCode) {
    final base = VerseOfDayTypography.fromLanguageCode(languageCode);
    final isTibetan = AppFontConfig.isTibetanLanguage(languageCode);

    return VerseOfDayTypography(
      contentFont: base.contentFont,
      systemFont: base.systemFont,
      verseFontSize: getLocalizedFontSize(AppTextSize.title),
      attributionFontSize: getLocalizedFontSize(AppTextSize.bodyLarge),
      useContentFontForAttribution: isTibetan,
      useGoogleJomolhari: isTibetan,
    );
  }

  TextStyle verseTextStyle({required Color color}) {
    final baseStyle = TextStyle(
      fontSize: verseFontSize,
      fontWeight: FontWeight.w400,
      height:
          useGoogleJomolhari
              ? getLineHeight(AppConfig.tibetanLanguageCode)
              : null,
      color: color,
      leadingDistribution:
          useGoogleJomolhari ? AppFontConfig.tibetanLeadingDistribution : null,
    );

    if (useGoogleJomolhari) {
      return GoogleFonts.jomolhari(textStyle: baseStyle);
    }

    return baseStyle.copyWith(fontFamily: contentFont);
  }

  TextStyle attributionTextStyle({
    required Color color,
    required bool useContentFontForAttribution,
  }) {
    final baseStyle = TextStyle(
      fontSize: attributionFontSize,
      fontWeight: FontWeight.w400,
      height:
          useGoogleJomolhari && useContentFontForAttribution
              ? getLineHeight(AppConfig.tibetanLanguageCode)
              : null,
      color: color,
      leadingDistribution:
          useGoogleJomolhari && useContentFontForAttribution
              ? AppFontConfig.tibetanLeadingDistribution
              : null,
    );

    if (useGoogleJomolhari && useContentFontForAttribution) {
      return GoogleFonts.jomolhari(textStyle: baseStyle);
    }

    return baseStyle.copyWith(
      fontFamily: useContentFontForAttribution ? contentFont : systemFont,
    );
  }
}

/// Shared verse image, quote, source, and optional WeBuddhist branding.
class VerseOfDayContent extends StatelessWidget {
  const VerseOfDayContent({
    super.key,
    required this.verseOfDay,
    required this.typography,
    required this.verseColor,
    required this.attributionColor,
    this.imageAspectRatio = 1.65,
    this.showBranding = false,
    this.useContentFontForAttribution = false,
    this.textPadding = const EdgeInsets.fromLTRB(24, 24, 24, 16),
    this.brandingBottomPadding = 0,
    this.textAlign = TextAlign.center,
    this.attributionSpacing = 16,
    this.footer,
  });

  final VerseOfDay verseOfDay;
  final VerseOfDayTypography typography;
  final Color verseColor;
  final Color attributionColor;
  final double imageAspectRatio;
  final bool showBranding;
  final bool useContentFontForAttribution;
  final EdgeInsets textPadding;
  final double brandingBottomPadding;
  final TextAlign textAlign;
  final double attributionSpacing;

  /// Row rendered under the source (likes, comments, share).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final verseText = withTibetanLineBreakOpportunities(verseOfDay.verse);
    final verseStrutStyle = context.tibetanStrutStyle(typography.verseFontSize);
    final attributionStrutStyle = context.tibetanStrutStyle(
      typography.attributionFontSize,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: imageAspectRatio,
          child: CachedNetworkImageWidget(
            imageUrl: verseOfDay.imageUrl,
            fallbackAsset: AppAssets.verseOfDayFallback,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
        Padding(
          padding: textPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                verseText,
                textAlign: textAlign,
                strutStyle: verseStrutStyle,
                style: typography.verseTextStyle(color: verseColor),
              ),
              if (verseOfDay.source.isNotEmpty) ...[
                SizedBox(height: attributionSpacing),
                Row(
                  mainAxisAlignment:
                      textAlign == TextAlign.center
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                  children: [
                    Icon(
                      AppAssets.bookOpen,
                      size: typography.attributionFontSize + 4,
                      color: attributionColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        withTibetanLineBreakOpportunities(verseOfDay.source),
                        strutStyle: attributionStrutStyle,
                        style: typography.attributionTextStyle(
                          color: attributionColor,
                          useContentFontForAttribution:
                              useContentFontForAttribution,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (footer != null) ...[
                const SizedBox(height: 4),
                footer!,
              ],
              if (showBranding) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.only(bottom: brandingBottomPadding),
                  child: const VerseShareBranding(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// WeBuddhist logo and "Shared from" label used in shareable verse images.
class VerseShareBranding extends StatelessWidget {
  const VerseShareBranding({
    super.key,
    this.logoSize = 28,
    this.sharedFromFontSize = 11,
    this.appTitleFontSize = 13,
    this.sharedFromColor = Colors.black45,
    this.appTitleColor = Colors.black87,
  });

  final double logoSize;
  final double sharedFromFontSize;
  final double appTitleFontSize;
  final Color sharedFromColor;
  final Color appTitleColor;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          AppAssets.weBuddhistLogo,
          width: logoSize,
          height: logoSize,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.shared_from,
              style: TextStyle(
                fontSize: sharedFromFontSize,
                color: sharedFromColor,
              ),
            ),
            Text(
              localizations.appTitle,
              style: TextStyle(
                fontSize: appTitleFontSize,
                fontWeight: FontWeight.w700,
                color: appTitleColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
