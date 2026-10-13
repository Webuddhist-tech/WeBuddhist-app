import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/app_theme.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_of_day_content.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Shareable session-complete preview rendered for screenshot capture.
class GroupAccumulatorSessionSharePreview extends StatelessWidget {
  const GroupAccumulatorSessionSharePreview({
    super.key,
    required this.sessionCount,
    required this.accumulationTitle,
    required this.locale,
  });

  final int sessionCount;
  final String accumulationTitle;
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
                child: GroupAccumulatorSessionCompleteContent(
                  sessionCount: sessionCount,
                  accumulationTitle: accumulationTitle,
                  accentColor: AppColors.primary,
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

class GroupAccumulatorSessionCompleteContent extends StatelessWidget {
  const GroupAccumulatorSessionCompleteContent({
    super.key,
    required this.sessionCount,
    required this.accumulationTitle,
    required this.accentColor,
    this.showTitle = true,
  });

  final int sessionCount;
  final String accumulationTitle;
  final Color accentColor;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle) ...[
          Text(
            accumulationTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: bodyColor,
            ),
          ),
          const SizedBox(height: 24),
        ],
        _SessionCompleteCheckmark(accentColor: accentColor),
        const SizedBox(height: 20),
        Text(
          l10n.group_accumulator_session_complete,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 12),
        _SessionRecitationSummary(
          sessionCount: sessionCount,
          accentColor: accentColor,
          bodyColor: bodyColor,
        ),
      ],
    );
  }
}

class _SessionCompleteCheckmark extends StatelessWidget {
  const _SessionCompleteCheckmark({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.85),
            accentColor,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: const Icon(AppAssets.check, color: Colors.white, size: 32),
    );
  }
}

class _SessionRecitationSummary extends StatelessWidget {
  const _SessionRecitationSummary({
    required this.sessionCount,
    required this.accentColor,
    required this.bodyColor,
  });

  final int sessionCount;
  final Color accentColor;
  final Color bodyColor;

  @override
  Widget build(BuildContext context) {
    final message = context.l10n.group_accumulator_session_recitations(
      sessionCount,
    );
    final countText = sessionCount.toString();
    final parts = message.split(countText);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: bodyColor,
          height: 1.4,
        ),
        children: [
          if (parts.isNotEmpty) TextSpan(text: parts.first),
          TextSpan(
            text: countText,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts.sublist(1).join(countText)),
        ],
      ),
    );
  }
}

Future<void> shareGroupAccumulatorSession(
  BuildContext context, {
  required int sessionCount,
  required String accumulationTitle,
  required String accumulatorId,
  required String groupId,
  String? groupName,
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
            : await _captureSessionShareImage(
              context,
              sessionCount: sessionCount,
              accumulationTitle: accumulationTitle,
            );

    if (imageBytes == null || !context.mounted) return;

    final directory = await getTemporaryDirectory();
    final imagePath =
        '${directory.path}/group_session_share_${DateTime.now().millisecondsSinceEpoch}.png';
    tempFile = File(imagePath);
    await tempFile.writeAsBytes(imageBytes);

    if (!context.mounted) return;

    final sharePositionOrigin = getSharePositionOrigin(
      context: context,
      globalKey: shareOriginKey,
    );
    final shareText = await _sessionShareText(
      context,
      sessionCount: sessionCount,
      accumulationTitle: accumulationTitle,
      groupName: groupName,
      accumulatorId: accumulatorId,
      groupId: groupId,
    );
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
        surface: ShareSurface.accumulator,
        targetId: accumulatorId,
        format: 'image',
        groupId: groupId,
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.group_accumulator_session_share_error,
          ),
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

Future<String> _sessionShareText(
  BuildContext context, {
  required int sessionCount,
  required String accumulationTitle,
  required String accumulatorId,
  required String groupId,
  String? groupName,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final longUrl =
      DeepLinkUrlBuilder.groupAccumulatorLink(
        accumulatorId: accumulatorId,
        groupId: groupId,
      ).toString();
  final shareUrl = await resolveShareUrl(context, longUrl);
  final message =
      groupName == null
          ? l10n.group_accumulator_session_share_message_no_group(
            sessionCount,
            accumulationTitle,
          )
          : l10n.group_accumulator_session_share_message(
            sessionCount,
            accumulationTitle,
            groupName,
          );
  return '$message\n\n$shareUrl';
}

Future<Uint8List?> _captureSessionShareImage(
  BuildContext context, {
  required int sessionCount,
  required String accumulationTitle,
}) async {
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
            child: GroupAccumulatorSessionSharePreview(
              sessionCount: sessionCount,
              accumulationTitle: accumulationTitle,
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

class GroupAccumulatorSessionCompleteSheet extends StatefulWidget {
  const GroupAccumulatorSessionCompleteSheet({
    super.key,
    required this.sessionCount,
    required this.accumulationTitle,
    required this.accumulatorId,
    required this.groupId,
    this.groupName,
  });

  final int sessionCount;
  final String accumulationTitle;
  final String accumulatorId;
  final String groupId;
  final String? groupName;

  @override
  State<GroupAccumulatorSessionCompleteSheet> createState() =>
      _GroupAccumulatorSessionCompleteSheetState();
}

class _GroupAccumulatorSessionCompleteSheetState
    extends State<GroupAccumulatorSessionCompleteSheet> {
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareSession() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);
    await shareGroupAccumulatorSession(
      context,
      sessionCount: widget.sessionCount,
      accumulationTitle: widget.accumulationTitle,
      accumulatorId: widget.accumulatorId,
      groupId: widget.groupId,
      groupName: widget.groupName,
      shareOriginKey: _shareButtonKey,
    );
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? AppColors.primaryLight : AppColors.primary;

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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GroupAccumulatorSessionCompleteContent(
                sessionCount: widget.sessionCount,
                accumulationTitle: widget.accumulationTitle,
                accentColor: accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  key: _shareButtonKey,
                  onPressed: _isSharing ? null : _shareSession,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isDark
                            ? AppColors.cardBorderDark
                            : AppColors.textPrimary,
                    foregroundColor:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.surfaceWhite,
                    disabledBackgroundColor:
                        AppColors.textPrimary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon:
                      _isSharing
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.surfaceWhite,
                            ),
                          )
                          : Icon(
                            AppAssets.readerShare,
                            size: 22,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.surfaceWhite,
                          ),
                  label: Text(
                    l10n.share,
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

bool _isSessionCompleteSheetVisible = false;

void showGroupAccumulatorSessionCompleteSheet(
  BuildContext context, {
  required int sessionCount,
  required String accumulationTitle,
  required String accumulatorId,
  required String groupId,
  String? groupName,
}) {
  if (_isSessionCompleteSheetVisible) return;

  _isSessionCompleteSheetVisible = true;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder:
        (_) => GroupAccumulatorSessionCompleteSheet(
          sessionCount: sessionCount,
          accumulationTitle: accumulationTitle,
          accumulatorId: accumulatorId,
          groupId: groupId,
          groupName: groupName,
        ),
  ).whenComplete(() => _isSessionCompleteSheetVisible = false);
}
