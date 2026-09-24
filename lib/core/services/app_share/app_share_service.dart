library;

import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppShareService {
  AppShareService({required ShareUrlService shareUrlService})
    : _shareUrlService = shareUrlService;

  final ShareUrlService _shareUrlService;

  Future<String> buildShareMessage(String localizedMessage) async {
    final link = await _shareUrlService.shorten(AppConfig.airbridgeTrackingLink);
    return '$localizedMessage\n\n$link';
  }
}

final appShareServiceProvider = Provider<AppShareService>((ref) {
  return AppShareService(shareUrlService: ref.watch(shareUrlServiceProvider));
});
