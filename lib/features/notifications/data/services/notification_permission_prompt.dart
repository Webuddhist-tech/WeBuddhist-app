import 'dart:io';

import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = AppLogger('NotificationPermissionPrompt');

/// Whether requesting the notification permission now can show the OS dialog,
/// so the permission events count real dialogs only.
///
/// Decides what gets logged and nothing else: callers request either way. It
/// never throws, because a failure here must not cost a user the dialog or
/// abort push setup.
///
/// iOS needs `PERMISSION_NOTIFICATIONS=1` (see `ios/Podfile`); without it the
/// plugin reports `denied` for everyone.
Future<bool> canShowNotificationPrompt() async {
  try {
    // permission_handler has no macOS implementation.
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    final status = await Permission.notification.status;
    if (!status.isDenied) return false;
    if (Platform.isIOS) return true;

    // Android also reports `denied` for someone blocked before the plugin ever
    // read this status, and it cannot learn otherwise: the rationale is false
    // both before the first ask and after a block. Our own flag tells them
    // apart, so they log one last prompt after updating and then stop.
    if (await Permission.notification.shouldShowRequestRationale) return true;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(StorageKeys.notificationPermissionAsked) ?? false);
  } catch (e) {
    _logger.warning('Could not read the notification permission status: $e');
    return false;
  }
}

/// Records that this install has requested the notification permission. Never
/// throws, for the same reason as [canShowNotificationPrompt].
Future<void> markNotificationPromptAsked() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.notificationPermissionAsked, true);
  } catch (e) {
    _logger.warning('Could not record the notification permission ask: $e');
  }
}
