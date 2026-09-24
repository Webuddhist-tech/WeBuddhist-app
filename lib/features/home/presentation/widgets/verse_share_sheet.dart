import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/app_theme.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_of_day_content.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Shareable verse preview rendered for screenshot capture.
class VerseSharePreview extends StatelessWidget {
  const VerseSharePreview({
    super.key,
    required this.verseOfDay,
    required this.languageCode,
    required this.locale,
  });

  final VerseOfDay verseOfDay;
  final String languageCode;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final typography = VerseOfDayTypography.forShare(languageCode);
    final lightTheme = AppTheme.lightTheme(locale);

    return Theme(
      data: lightTheme,
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: AppColors.goldLight,
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: VerseOfDayContent(
                  verseOfDay: verseOfDay,
                  typography: typography,
                  verseColor: Colors.black87,
                  attributionColor: Colors.black87,
                  imageAspectRatio: 1.15,
                  useContentFontForAttribution:
                      typography.useContentFontForAttribution,
                  textPadding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
                ),
              ),
              const SizedBox(height: 24),
              const VerseShareBranding(
                logoSize: 32,
                sharedFromFontSize: 12,
                appTitleFontSize: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Captures and shares a verse-of-day quote image.
Future<void> shareVerseOfDayQuote(
  BuildContext context, {
  required VerseOfDay verseOfDay,
  GlobalKey? shareOriginKey,
  ScreenshotController? screenshotController,
}) async {
  File? tempFile;
  try {
    final Uint8List? imageBytes;
    if (screenshotController != null) {
      imageBytes = await screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );
    } else {
      if (!context.mounted) return;
      imageBytes = await _captureVerseShareImage(context, verseOfDay);
    }

    if (imageBytes == null || !context.mounted) return;

    final directory = await getTemporaryDirectory();
    final imagePath =
        '${directory.path}/verse_share_${DateTime.now().millisecondsSinceEpoch}.png';
    tempFile = File(imagePath);
    await tempFile.writeAsBytes(imageBytes);

    if (!context.mounted) return;

    final sharePositionOrigin = getSharePositionOrigin(
      context: context,
      globalKey: shareOriginKey,
    );
    final shareText = await _verseOfDayShareText(context);
    if (!context.mounted) return;

    final shareAnalytics = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(shareAnalyticsProvider);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path)],
        text: shareText,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    if (ShareAnalytics.wasUsed(result)) {
      shareAnalytics.contentShared(
        surface: ShareSurface.verse,
        targetId: verseOfDay.id,
        format: 'image',
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.verse_share_error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red[700],
        ),
      );
    }
  } finally {
    if (tempFile != null && await tempFile.exists()) {
      try {
        await tempFile.delete();
      } catch (_) {}
    }
  }
}

Future<String> _verseOfDayShareText(BuildContext context) async {
  final shareQuoteMessage =
      AppLocalizations.of(context)!.share_quote_message;
  final longUrl = DeepLinkUrlBuilder.homeLink().toString();
  final homeLink = await resolveShareUrl(context, longUrl);
  if (!context.mounted) return shareQuoteMessage;

  return '$shareQuoteMessage\n\n$homeLink';
}

Future<Uint8List?> _captureVerseShareImage(
  BuildContext context,
  VerseOfDay verseOfDay,
) async {
  final screenshotController = ScreenshotController();
  final languageCode = Localizations.localeOf(context).languageCode;
  final locale = Localizations.localeOf(context);
  final previewWidth = MediaQuery.sizeOf(context).width - 24;

  final overlayState = Overlay.of(context, rootOverlay: true);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (_) {
      return Positioned(
        left: -previewWidth * 2,
        top: 0,
        width: previewWidth,
        child: IgnorePointer(
          child: Screenshot(
            controller: screenshotController,
            child: VerseSharePreview(
              verseOfDay: verseOfDay,
              languageCode: languageCode,
              locale: locale,
            ),
          ),
        ),
      );
    },
  );

  overlayState.insert(overlayEntry);

  try {
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 300));

    return await screenshotController.capture(
      delay: const Duration(milliseconds: 100),
      pixelRatio: 3.0,
    );
  } finally {
    overlayEntry.remove();
  }
}

class VerseShareSheet extends StatefulWidget {
  const VerseShareSheet({super.key, required this.verseOfDay});

  final VerseOfDay verseOfDay;

  @override
  State<VerseShareSheet> createState() => _VerseShareSheetState();
}

class _VerseShareSheetState extends State<VerseShareSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareQuote() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);
    await shareVerseOfDayQuote(
      context,
      verseOfDay: widget.verseOfDay,
      shareOriginKey: _shareButtonKey,
      screenshotController: _screenshotController,
    );
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final locale = Localizations.localeOf(context);
    final shareLabelFontSize = getLocalizedFontSize(AppTextSize.body);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.goldLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Screenshot(
                controller: _screenshotController,
                child: VerseSharePreview(
                  verseOfDay: widget.verseOfDay,
                  languageCode: languageCode,
                  locale: locale,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  key: _shareButtonKey,
                  onPressed: _isSharing ? null : _shareQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark
                            ? AppColors.cardBorderDark
                            : AppColors.surfaceWhite,
                    foregroundColor: colorScheme.onSurface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: colorScheme.onSurface.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                  ),

                  icon:
                      _isSharing
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onSurface,
                            ),
                          )
                          : Icon(AppAssets.readerShare, size: 22),
                  label: Text(
                    localizations.share_this_quote,
                    strutStyle: AppFontConfig.tibetanStrutStyle(
                      languageCode,
                      shareLabelFontSize,
                      compact: true,
                    ),
                    style: TextStyle(
                      fontFamily: getSystemFontFamily(languageCode),
                      fontWeight: FontWeight.w700,
                      fontSize: shareLabelFontSize,
                      height: getLineHeight(languageCode),
                      leadingDistribution:
                          AppFontConfig.tibetanLeadingDistribution,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Shows the verse share bottom sheet.
void showVerseShareSheet(BuildContext context, VerseOfDay verseOfDay) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => VerseShareSheet(verseOfDay: verseOfDay),
  );
}
