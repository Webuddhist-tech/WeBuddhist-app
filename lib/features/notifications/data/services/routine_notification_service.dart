import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/data/notification_id_scheme.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:path_provider/path_provider.dart';

final _logger = AppLogger('RoutineNotificationService');

/// Thin wrapper around `flutter_local_notifications` plus the per-block
/// "cancel everything I scheduled for this block" lever used by the
/// edit-routine screen for local edits before the user taps Done.
///
/// Full reconciliation lives in `NotificationSyncEngine`. This service is
/// limited to:
///   1. Plugin / readiness accessors.
///   2. Image-loading helpers shared with the engine.
///   3. `cancelBlockNotification` — fast cancel for screen-local edits.
class RoutineNotificationService {
  static final RoutineNotificationService _instance =
      RoutineNotificationService._internal();

  factory RoutineNotificationService() => _instance;
  RoutineNotificationService._internal();

  FlutterLocalNotificationsPlugin? _testPlugin;

  @visibleForTesting
  factory RoutineNotificationService.withPlugin(
    FlutterLocalNotificationsPlugin plugin,
  ) {
    final svc = RoutineNotificationService._internal();
    svc._testPlugin = plugin;
    return svc;
  }

  FlutterLocalNotificationsPlugin get _plugin =>
      _testPlugin ?? NotificationService().notificationsPlugin;

  bool get _isReady => NotificationService().isInitialized;

  // ─── Cancellation ────────────────────────────────────────────────────────

  /// Cancels every daily-repeat the app scheduled for [block] (recitation,
  /// mala, timer and recitation collections), each in its own ID range.
  ///
  /// Used by the edit-routine screen on local delete (before Done is
  /// pressed). The full sync engine handles reconciliation otherwise.
  Future<void> cancelBlockNotification(RoutineBlock block) async {
    if (!_isReady) return;
    try {
      // Recitation daily-repeat keeps the block's own notification ID.
      await _plugin.cancel(block.notificationId);
      // The mala (accumulator) daily-repeat lives in a parallel ID range, so
      // cancel it too — otherwise a deleted mala block keeps firing until the
      // next full reconciliation sync.
      await _plugin
          .cancel(NotificationIdScheme.accumulatorBlockId(block.notificationId));
      // Timer blocks fire one daily-repeat (start reminder) in its own parallel
      // range — cancel it too for the same reason.
      await _plugin
          .cancel(NotificationIdScheme.timerStartId(block.notificationId));
      // Group-recitation-collection (chants list) daily-repeat lives in its
      // own parallel range too — cancel it for the same reason.
      await _plugin.cancel(
        NotificationIdScheme.groupCollectionId(block.notificationId),
      );
      // Personal recitation collections use a separate parallel range from
      // group collections.
      await _plugin.cancel(
        NotificationIdScheme.myCollectionId(block.notificationId),
      );
    } catch (e) {
      _logger.warning(
        'cancelBlockNotification failed for ${block.notificationId}: $e',
      );
    }
  }

  /// Cancels every pending notification owned by the plugin. Used on
  /// logout to ensure a different signing-in user does not inherit the
  /// previous user's schedule.
  Future<void> cancelAll() async {
    if (!_isReady) return;
    try {
      await _plugin.cancelAll();
      _logger.info('[NOTIFICATION_NEW_FLOW] cancelled all pending notifications');
    } catch (e) {
      _logger.warning('cancelAll failed: $e');
    }
  }

  // ─── Public helpers (used by NotificationSyncEngine) ─────────────────────

  /// Builds the Android big-picture / big-text style for a [DesiredNotification].
  Future<StyleInformation> buildBigPictureStyle(
    RoutineItem? item, {
    String? overrideTitle,
    String? overrideBody,
  }) =>
      _buildBigPictureStyle(item, overrideTitle: overrideTitle, overrideBody: overrideBody);

  /// Builds iOS notification details with optional image attachment.
  Future<DarwinNotificationDetails> buildIOSNotificationDetails(RoutineItem? item) =>
      _buildIOSNotificationDetails(item);

  /// Resolves the large-icon path for [item]'s image, if any.
  Future<FilePathAndroidBitmap?> getLargeIcon(RoutineItem? item) =>
      _getLargeIcon(item);

  // ─── Image styling (private impls) ───────────────────────────────────────

  Future<StyleInformation> _buildBigPictureStyle(
    RoutineItem? item, {
    String? overrideTitle,
    String? overrideBody,
  }) async {
    final title = overrideTitle ?? item?.title ?? 'Time for your practice';
    final body = overrideBody ?? item?.title ?? 'Time for your practice';

    if (item?.imageUrl case final String url when url.isNotEmpty) {
      try {
        final imagePath = await _downloadAndCacheImage(url);
        if (imagePath != null) {
          return BigPictureStyleInformation(
            FilePathAndroidBitmap(imagePath),
            largeIcon: await _getLargeIcon(item),
            contentTitle: title,
            summaryText: body,
            htmlFormatContentTitle: true,
            htmlFormatSummaryText: true,
          );
        }
      } catch (e) {
        _logger.warning('_buildBigPictureStyle: image load failed: $e');
      }
    }

    return BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );
  }

  Future<DarwinNotificationDetails> _buildIOSNotificationDetails(
    RoutineItem? item,
  ) async {
    if (item?.imageUrl case final String url when url.isNotEmpty) {
      try {
        final imagePath = await _downloadAndCacheImage(url);
        if (imagePath != null) {
          // iOS MOVES the attachment file into its own data store when the
          // request is scheduled. Attaching the cache file directly destroys
          // the cache, forcing a fresh network download for every entry in a
          // series (~0.5s each — the source of multi-second syncs). Attach a
          // throwaway copy; iOS taking ownership of the copy leaves the
          // cache intact.
          final attachPath = await _copyForAttachment(imagePath);
          return DarwinNotificationDetails(
            attachments: [DarwinNotificationAttachment(attachPath)],
            threadIdentifier: 'routine_notifications',
            sound: NotificationChannels.routineIosSoundFile,
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );
        }
      } catch (e) {
        _logger.warning('_buildIOSNotificationDetails: image attach failed: $e');
      }
    }
    return const DarwinNotificationDetails(
      threadIdentifier: 'routine_notifications',
      sound: NotificationChannels.routineIosSoundFile,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
  }

  /// Copies a cached image to a unique path for a single iOS attachment.
  /// The system moves the attached file when the notification is scheduled,
  /// so each request needs its own expendable copy.
  Future<String> _copyForAttachment(String cachedPath) async {
    final file = File(cachedPath);
    final dot = cachedPath.lastIndexOf('.');
    final ext = dot < 0 ? '' : cachedPath.substring(dot);
    final copyPath =
        '${file.parent.path}/attach_${DateTime.now().microsecondsSinceEpoch}$ext';
    await file.copy(copyPath);
    return copyPath;
  }

  Future<String?> _downloadAndCacheImage(String imageUrl) async {
    try {
      final hash = imageUrl.hashCode.toString();
      final ext = imageUrl.contains('.png') ? '.png' : '.jpg';
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/notification_images/notif_$hash$ext';
      final file = File(filePath);

      if (await file.exists()) return filePath;

      await file.parent.create(recursive: true);
      final request = await HttpClient().getUrl(Uri.parse(imageUrl));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.toList();
        await file.writeAsBytes(bytes.expand((b) => b).toList());
        return filePath;
      }
    } catch (e) {
      _logger.warning('_downloadAndCacheImage: failed for $imageUrl: $e');
    }
    return null;
  }

  Future<FilePathAndroidBitmap?> _getLargeIcon(RoutineItem? item) async {
    if (item?.imageUrl case final String url when url.isNotEmpty) {
      try {
        final path = await _downloadAndCacheImage(url);
        if (path != null) return FilePathAndroidBitmap(path);
      } catch (e) {
        _logger.warning('_getLargeIcon: failed: $e');
      }
    }
    return null;
  }
}
