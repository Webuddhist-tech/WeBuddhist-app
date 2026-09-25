import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class QrCodeBottomSheet extends StatefulWidget {
  const QrCodeBottomSheet({super.key});

  static const String _iosAppStoreUrl =
      'https://apps.apple.com/app/webuddhist/id6745810914';
  static const String _androidPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=org.pecha.app';

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const QrCodeBottomSheet(),
    );
  }

  @override
  State<QrCodeBottomSheet> createState() => _QrCodeBottomSheetState();
}

class _QrCodeBottomSheetState extends State<QrCodeBottomSheet>
    with SingleTickerProviderStateMixin {
  final _logger = AppLogger('QrCodeBottomSheet');
  late TabController _tabController;
  final ScreenshotController _androidQrController = ScreenshotController();
  final ScreenshotController _iosQrController = ScreenshotController();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getShareText(String platform) {
    final url = platform == 'Android'
        ? QrCodeBottomSheet._androidPlayStoreUrl
        : QrCodeBottomSheet._iosAppStoreUrl;
    return '''I'm using WeBuddhist to learn and practice Buddhism. Join me!

📲 Scan the QR code to download on $platform
Or visit: $url''';
  }

  Future<void> _shareQrCode() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    File? tempFile;
    try {
      // Get the appropriate screenshot controller based on current tab
      final controller = _tabController.index == 0
          ? _androidQrController
          : _iosQrController;
      final platform = _tabController.index == 0 ? 'Android' : 'iOS';

      // Capture the QR code image
      final imageBytes = await controller.capture();
      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.captureError),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/qr_code_${platform.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.png';
      tempFile = File(imagePath);
      await tempFile.writeAsBytes(imageBytes);

      if (!mounted) return;

      // Share the image with text
      final shareText = _getShareText(platform);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          text: shareText,
          subject: 'Download WeBuddhist on $platform',
        ),
      );
      if (mounted && ShareAnalytics.wasUsed(result)) {
        ProviderScope.containerOf(context, listen: false)
            .read(shareAnalyticsProvider)
            .contentShared(surface: ShareSurface.app, method: 'qr');
      }
    } catch (e) {
      _logger.error('Error sharing QR code', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.qrShareError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Clean up temp file
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          _logger.error('Error deleting temp file', e);
        }
      }

      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Android'),
                Tab(text: 'IOS'),
              ],
              labelColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              unselectedLabelColor: isDark ? AppColors.textTertiaryDark : Colors.grey,
              indicatorColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            const SizedBox(height: 24),

            // Tab Bar View
            SizedBox(
              height: 350,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQrCodeTab(
                    context,
                    url: QrCodeBottomSheet._androidPlayStoreUrl,
                    platform: 'Android',
                    controller: _androidQrController,
                  ),
                  _buildQrCodeTab(
                    context,
                    url: QrCodeBottomSheet._iosAppStoreUrl,
                    platform: 'iOS',
                    controller: _iosQrController,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Share button
            OutlinedButton.icon(
              onPressed: _isSharing ? null : _shareQrCode,
              icon: _isSharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.share, color: textColor),
              label: Text(
                _isSharing ? 'Sharing...' : 'Share QR Code',
                style: TextStyle(color: textColor),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Done button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                context.l10n.done,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeTab(
    BuildContext context, {
    required String url,
    required String platform,
    required ScreenshotController controller,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Screenshot(
      controller: controller,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: url,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              embeddedImage: const AssetImage(AppAssets.weBuddhistLogo),
              embeddedImageStyle: const QrEmbeddedImageStyle(
                size: Size(40, 40),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Instructions
          Text(
            'Scan to download on $platform',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
