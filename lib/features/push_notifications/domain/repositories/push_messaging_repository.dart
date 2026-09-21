import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:fpdart/fpdart.dart';

/// Contract for the push-messaging subsystem.
///
/// Abstracts Firebase Cloud Messaging (token lifecycle + message streams) and
/// the backend device-token registration behind a single domain interface.
abstract class PushMessagingRepository {
  /// Requests OS permission to display notifications (iOS + Android 13+).
  /// Returns `true` when the user has authorised notifications.
  Future<bool> requestPermission();

  /// Current FCM registration token for this device/install, or `null` if it
  /// could not be resolved yet (e.g. APNs token not ready on iOS).
  Future<String?> getToken();

  /// Emits whenever FCM rotates the token (reinstall, restore, expiry).
  Stream<String> get onTokenRefresh;

  /// Emits messages received while the app is in the foreground.
  Stream<PushMessage> get onForegroundMessage;

  /// Emits when a notification is tapped and the app moves from background to
  /// foreground.
  Stream<PushMessage> get onMessageOpenedApp;

  /// The notification that launched the app from a terminated state, if any.
  Future<PushMessage?> getInitialMessage();

  /// Registers (upserts) [token] for the signed-in user with the backend so it
  /// can target this device. The platform (`ANDROID`/`IOS`) is derived in the
  /// data layer. [deviceId] is an optional stable device identifier that lets
  /// token refreshes update the same record instead of creating duplicates.
  ///
  /// [preferences] carries the notification toggles relevant to push. Only
  /// plan/series is delivered via FCM, gated by the `routine` flag; the other
  /// categories (recitation/mala/timer) are local-only and never sent. The
  /// backend must honour this — background/terminated notification messages are
  /// rendered by the OS before the app can filter locally.
  ///
  /// Resolves to the backend's id for the registration (the `id` field of the
  /// response), or null if the backend did not return one. The id is what
  /// [unregisterDeviceToken] needs later.
  Future<Either<Failure, String?>> registerDeviceToken(
    String token, {
    String? deviceId,
    Map<String, bool>? preferences,
  });

  /// Removes the registration [pushDeviceId] (an id returned by
  /// [registerDeviceToken]) so the backend stops targeting this device. This
  /// is how the master notification switch turns server pushes off: every
  /// push type is resolved against the device table, so one delete covers
  /// them all. A registration the backend no longer has counts as removed.
  Future<Either<Failure, Unit>> unregisterDeviceToken(String pushDeviceId);
}
