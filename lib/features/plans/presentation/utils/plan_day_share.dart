import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';

/// Downloads the plan day's shareable image and shares it together with the
/// day completion message and the plan day deep link. Returns false when the
/// share sheet never opened or was dismissed.
Future<bool> sharePlanDayImage({
  required BuildContext context,
  required String shareableImageUrl,
  required int dayNumber,
  required String planId,
  required String planLanguage,
  GlobalKey? shareButtonKey,
}) async {
  final url = shareableImageUrl.trim();
  if (url.isEmpty) return false;

  File? tempFile;
  try {
    final uri = Uri.parse(url);
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to download share image (${response.statusCode})',
        uri: uri,
      );
    }

    final directory = await getTemporaryDirectory();
    final extension = _imageExtensionFromUrl(uri);
    tempFile = File(
      '${directory.path}/plan_day_${dayNumber}_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await tempFile.writeAsBytes(response.bodyBytes);

    if (!context.mounted) return false;

    final sharePositionOrigin = getSharePositionOrigin(
      context: context,
      globalKey: shareButtonKey,
    );

    final shareMessage = context.l10n.day_completion_share_message;
    final longUrl =
        DeepLinkUrlBuilder.planDayLink(
          planId: planId,
          dayNumber: dayNumber,
          language: planLanguage,
        ).toString();
    final planLink = await resolveShareUrl(context, longUrl);
    if (!context.mounted) return false;

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path)],
        text: '$shareMessage\n\n$planLink',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    return ShareAnalytics.wasUsed(result);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.create_image_share_error),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  } finally {
    if (tempFile != null && await tempFile.exists()) {
      try {
        await tempFile.delete();
      } catch (_) {
        // Best-effort temp cleanup.
      }
    }
  }
}

String _imageExtensionFromUrl(Uri uri) {
  final lastSegment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
  final extension =
      lastSegment.contains('.')
          ? lastSegment.split('.').last.toLowerCase()
          : '';
  switch (extension) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'webp':
      return extension;
    default:
      return 'png';
  }
}
