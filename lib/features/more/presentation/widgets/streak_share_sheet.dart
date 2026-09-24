import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/app_theme.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_of_day_content.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/streak_share_content.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Shareable streak preview rendered for screenshot capture.
class StreakSharePreview extends StatelessWidget {
  const StreakSharePreview({
    super.key,
    required this.streak,
    required this.locale,
  });

  final StreakStats streak;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final lightTheme = AppTheme.lightTheme(locale);

    return Theme(
      data: lightTheme,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          color: AppColors.goldLight,
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                child: StreakShareContent(streak: streak),
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

/// Captures and shares a streak image.
Future<void> shareStreakQuote(
  BuildContext context, {
  required StreakStats streak,
  GlobalKey? shareOriginKey,
  ScreenshotController? screenshotController,
}) async {
  File? tempFile;
  try {
    final Uint8List? imageBytes =
        screenshotController != null
            ? await screenshotController.capture(
              delay: const Duration(milliseconds: 100),
              pixelRatio: 3.0,
            )
            : await _captureStreakShareImage(context, streak);

    if (imageBytes == null || !context.mounted) return;

    final directory = await getTemporaryDirectory();
    final imagePath =
        '${directory.path}/streak_share_${DateTime.now().millisecondsSinceEpoch}.png';
    tempFile = File(imagePath);
    await tempFile.writeAsBytes(imageBytes);

    if (!context.mounted) return;

    final sharePositionOrigin = getSharePositionOrigin(
      context: context,
      globalKey: shareOriginKey,
    );

    final longUrl = DeepLinkUrlBuilder.moreLink().toString();
    final shareMessage = AppLocalizations.of(context)!.share_streak_message;
    final moreLink = await resolveShareUrl(context, longUrl);
    if (!context.mounted) return;

    final shareAnalytics = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(shareAnalyticsProvider);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path)],
        text: '$shareMessage\n\n$moreLink',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    if (ShareAnalytics.wasUsed(result)) {
      shareAnalytics.contentShared(
        surface: ShareSurface.streak,
        format: 'image',
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.me_streak_share_error),
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

Future<Uint8List?> _captureStreakShareImage(
  BuildContext context,
  StreakStats streak,
) async {
  final screenshotController = ScreenshotController();
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
            child: StreakSharePreview(streak: streak, locale: locale),
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

class StreakShareSheet extends StatefulWidget {
  const StreakShareSheet({super.key, required this.streak});

  final StreakStats streak;

  @override
  State<StreakShareSheet> createState() => _StreakShareSheetState();
}

class _StreakShareSheetState extends State<StreakShareSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareStreak() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);
    await shareStreakQuote(
      context,
      streak: widget.streak,
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
    final locale = Localizations.localeOf(context);

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
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Screenshot(
                controller: _screenshotController,
                child: StreakSharePreview(
                  streak: widget.streak,
                  locale: locale,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  key: _shareButtonKey,
                  onPressed: _isSharing ? null : _shareStreak,
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
                    localizations.share_this_streak,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

bool _isStreakShareSheetVisible = false;

void showStreakShareSheet(BuildContext context, StreakStats streak) {
  if (_isStreakShareSheetVisible) return;

  _isStreakShareSheetVisible = true;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => StreakShareSheet(streak: streak),
  ).whenComplete(() => _isStreakShareSheetVisible = false);
}
