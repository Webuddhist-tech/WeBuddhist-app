import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/push_notifications/application/foreground_push_filter.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:uuid/uuid.dart';

/// Background / terminated-state FCM handler. Must be a top-level function with
/// `@pragma` so it survives AOT and runs in its own isolate. Notification
/// messages are displayed by the OS automatically in this state, so this only
/// re-initialises Firebase and logs.
@pragma('vm:entry-point')
Future<void> pushNotificationBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  AppLogger('PushBackground').info('Background message: ${message.messageId}');
}

/// Drives the push-notification lifecycle:
///   1. Requests permission + creates the Android channel.
///   2. Captures the FCM token (install) and listens for rotations (refresh).
///   3. Registers the token with the backend once a user signs in.
///   4. Shows foreground messages and handles notification taps.
///
/// Depends only on [PushMessagingRepository], so Firebase stays out of this
/// layer and the service is unit-testable.
class PushNotificationService {
  PushNotificationService({
    required PushMessagingRepository repository,
    required LocalStorageService storage,
    required ForegroundPushFilter foregroundFilter,
    Duration reconcileRetryBaseDelay = const Duration(seconds: 5),
    Duration signOutTimeout = const Duration(seconds: 4),
  }) : _repository = repository,
       _storage = storage,
       _foregroundFilter = foregroundFilter,
       _reconcileRetryBaseDelay = reconcileRetryBaseDelay,
       _signOutTimeout = signOutTimeout;

  final PushMessagingRepository _repository;
  final LocalStorageService _storage;

  /// Screens claim the pushes they already show, so the banner is skipped
  /// for a message the member is looking at. Only the foreground path asks:
  /// background and terminated pushes are displayed by the OS before the
  /// app runs.
  final ForegroundPushFilter _foregroundFilter;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _logger = AppLogger('PushNotificationService');
  final _subscriptions = <StreamSubscription<dynamic>>[];

  /// Invoked when a notification is opened from the background or terminated
  /// state. Set by the bootstrap layer to route via [PushMessageNavigator].
  /// Foreground taps reach the navigator separately (through the shared
  /// flutter_local_notifications callback), so they don't pass through here.
  void Function(PushMessage message)? onOpenMessage;

  String? _token;
  bool _loggedIn = false;

  /// False until the first settled auth snapshot arrives. While the stored
  /// session is still being restored, [_loggedIn] is not yet meaningful, so
  /// foreground pushes wait in [_pendingForeground] instead of being dropped.
  bool _authKnown = false;
  final _pendingForeground = <PushMessage>[];

  /// Mirrors the app's master notification switch. While false the device is
  /// kept unregistered on the backend so no server push of any kind reaches
  /// it; the OS shows background pushes before the app can filter them, so
  /// this has to be enforced server-side. Fed by [setMasterEnabled].
  bool _masterEnabled = true;
  bool _initialized = false;
  Future<void>? _initializing;
  int _initRetryCount = 0;
  Timer? _initRetryTimer;

  /// Max automatic retries after a failed init (bootstrap + scheduled backoff).
  static const maxInitRetries = 3;

  static const _initRetryBaseDelay = Duration(seconds: 5);

  /// One-time setup. Concurrent calls share the in-flight attempt, and calls
  /// after a successful run are ignored. A failed attempt does NOT latch — it
  /// tears down any partial wiring, schedules a backoff retry, and leaves the
  /// service ready for resume-triggered retries too.
  Future<void> initialize() {
    if (_initialized) return Future.value();
    return _initializing ??= _runInitialize();
  }

  Future<void> _runInitialize() async {
    try {
      await _createAndroidChannel();
      final granted = await _repository.requestPermission();
      _logger.info('Notification permission granted: $granted');

      _subscriptions
        ..add(_repository.onForegroundMessage.listen(_showNotification))
        ..add(_repository.onMessageOpenedApp.listen(_onNotificationTapped))
        ..add(_repository.onTokenRefresh.listen(_onToken));

      // Terminated-state launch via a notification tap.
      final launchMessage = await _repository.getInitialMessage();
      if (launchMessage != null) _onNotificationTapped(launchMessage);

      // Token for this install.
      final token = await _repository.getToken();
      if (token != null) await _onToken(token);

      // Only latch once the full setup has succeeded.
      _initialized = true;
      _initRetryCount = 0;
      _initRetryTimer?.cancel();
      _initRetryTimer = null;
    } catch (e, st) {
      _logger.warning('Push initialization failed: $e', e, st);
      // Drop any listeners added before the failure so a retry starts clean
      // and we don't double-subscribe.
      for (final sub in _subscriptions) {
        unawaited(sub.cancel());
      }
      _subscriptions.clear();
      _scheduleInitRetry();
    } finally {
      _initializing = null;
    }
  }

  /// Backoff retry so a transient cold-start failure doesn't require backgrounding.
  void _scheduleInitRetry() {
    if (_initialized || _initRetryCount >= maxInitRetries) return;

    _initRetryCount++;
    final delay = _initRetryBaseDelay * _initRetryCount;
    _initRetryTimer?.cancel();
    _initRetryTimer = Timer(delay, () {
      if (_initialized) return;
      _logger.info(
        'Retrying push initialization (attempt $_initRetryCount/$maxInitRetries)',
      );
      unawaited(initialize());
    });
  }

  /// Feeds in the latest auth snapshot. Registers the token with the backend on
  /// sign-in (the backend keys the device on the JWT, so no profile data is
  /// needed). Guests are treated as signed out for push targeting. Signing in
  /// with master off removes the registration left from an earlier session
  /// now that the JWT is available.
  ///
  /// Any signed-out snapshot (logout, expired session, guest) also detaches
  /// the install from the account it was registered under. See
  /// [_detachFromAccount].
  void onAuthChanged({required bool loggedIn}) {
    final signedIn = loggedIn && !_loggedIn;
    _loggedIn = loggedIn;
    if (!_authKnown) {
      _authKnown = true;
      _flushPendingForeground();
    }
    if (signedIn) _requestReconcile();
    if (!loggedIn) {
      _detaching ??= _detachFromAccount().whenComplete(
        () => _detaching = null,
      );
    }
  }

  /// Upper bound on how long sign-out waits for the backend, across every
  /// step. Logging out must never hang on a slow network;
  /// [_detachFromAccount] still kills the token.
  final Duration _signOutTimeout;

  Future<void>? _signOutUnregister;
  Future<void>? _detaching;

  /// Removes this device's backend registration for the user who is signing
  /// out. Call it before the local credentials are cleared, since the endpoint
  /// needs that user's JWT, and before auth state flips, so the detach that
  /// the flip triggers waits for it. Best effort: never throws, and gives up
  /// after [_signOutTimeout].
  Future<void> unregisterForSignOut() {
    return _signOutUnregister ??= _runSignOutUnregister().whenComplete(
      () => _signOutUnregister = null,
    );
  }

  Future<void> _runSignOutUnregister() async {
    try {
      // One deadline for the whole sequence: separate ones on the quiesce and
      // the request would add up past [_signOutTimeout].
      await _unregisterStoredDevice().timeout(_signOutTimeout);
    } catch (e, st) {
      _logger.warning('Sign-out unregister failed: $e', e, st);
    }
  }

  Future<void> _unregisterStoredDevice() async {
    await _quiesceReconcile();
    final serverId = await _storage.get<String>(StorageKeys.pushDeviceServerId);
    if (serverId == null || serverId.isEmpty) return;
    final result = await _repository.unregisterDeviceToken(serverId);
    result.fold(
      (failure) =>
          _logger.warning('Sign-out unregister failed: ${failure.message}'),
      (_) => _logger.info('Device unregistered for sign-out'),
    );
  }

  /// Makes sure pushes for the last signed-in account stop reaching this
  /// install once nobody is signed in.
  ///
  /// The backend keeps a registration until told otherwise, and the OS shows
  /// background pushes before the app can filter them. So a device that
  /// signed out, lost its session or switched to guest would keep receiving
  /// that account's chat pushes. Deleting the FCM token fixes this without a
  /// JWT: the backend row may linger, but its token no longer delivers.
  ///
  /// Only runs while a registration id is stored. That also covers installs
  /// that signed out before this existed and are still receiving pushes. On
  /// failure the id is kept, so the next signed-out snapshot tries again.
  Future<void> _detachFromAccount() async {
    try {
      final pending = _signOutUnregister;
      if (pending != null) await pending;
      await _quiesceReconcile();
      // Signed back in meanwhile: the registration belongs to them now.
      if (_loggedIn) return;

      final serverId = await _storage.get<String>(
        StorageKeys.pushDeviceServerId,
      );
      if (serverId == null || serverId.isEmpty) return;

      await _repository.deleteToken();
      await _storage.remove(StorageKeys.pushDeviceServerId);
      await _storage.remove(StorageKeys.fcmToken);
      _token = null;
      _logger.info('Push token deleted after sign-out');

      // Mint the replacement now so the next sign-in has a token to register.
      final fresh = await _repository.getToken();
      if (fresh != null) await _onToken(fresh);
    } catch (e, st) {
      _logger.warning('Push detach after sign-out failed: $e', e, st);
    }
  }

  /// Waits, within [_signOutTimeout], for a reconcile pass already in flight,
  /// so a sign-out never races a register call.
  ///
  /// Queued work is deliberately left alone. A pass that runs while signed
  /// out is already a no-op — both [_register] and [_unregister] bail out on
  /// [_loggedIn] — whereas cancelling it would drop a request belonging to a
  /// session that signed back in while the sign-out was still unwinding,
  /// leaving that session unregistered until some unrelated event.
  Future<void> _quiesceReconcile() async {
    final running = _reconciling;
    if (running != null) {
      await running.timeout(_signOutTimeout, onTimeout: () {});
    }
  }

  /// Re-sends the device registration so the backend picks up the latest
  /// notification-category preferences. Called when the user flips a
  /// notification toggle. No-op until a token is captured, the user is
  /// signed in and the master switch is on.
  void refreshRegistration() => _requestReconcile();

  /// Applies the master notification switch. OFF unregisters the device from
  /// the backend so every server push stops; ON registers it again. Safe to
  /// call with the same value repeatedly.
  void setMasterEnabled(bool enabled) {
    if (_masterEnabled == enabled) return;
    _masterEnabled = enabled;
    _requestReconcile();
  }

  /// Resolves once the backend registration matches the current state, for
  /// callers that need to wait on it (tests, teardown). Never throws.
  Future<void> get registrationSettled => _reconciling ?? Future.value();

  Future<void>? _reconciling;
  bool _reconcileRequested = false;
  Timer? _reconcileRetryTimer;
  int _reconcileRetryCount = 0;
  final Duration _reconcileRetryBaseDelay;

  /// Max automatic retries after a register or unregister call fails. Beyond
  /// this the next auth, token or toggle event tries again.
  static const maxReconcileRetries = 5;

  /// Brings the backend registration in line with the current token, login
  /// and master-switch state.
  ///
  /// Register and unregister are serialized through one loop, and the loop
  /// re-reads the desired state after every pass. That closes two races that
  /// independent fire-and-forget calls leave open: master switched off while
  /// a register is awaiting the backend (the unregister finds no stored id,
  /// then the register lands and stays), and master switched back on while
  /// an unregister is in flight (the unregister wipes the id of the fresh
  /// registration, which then can never be removed).
  ///
  /// A pass that fails (backend down, offline) is retried with linear backoff
  /// up to [maxReconcileRetries] times. Without that, master OFF on a bad
  /// connection would leave the device registered, and background pushes
  /// flowing, until some unrelated event happened to reconcile again.
  void _requestReconcile() {
    // An explicit request supersedes any pending retry.
    _reconcileRetryTimer?.cancel();
    _reconcileRetryTimer = null;
    _reconcileRequested = true;
    _reconciling ??= _runReconcile();
  }

  Future<void> _runReconcile() async {
    var succeeded = true;
    try {
      while (_reconcileRequested) {
        _reconcileRequested = false;
        succeeded = _masterEnabled ? await _register() : await _unregister();
      }
    } catch (e, st) {
      succeeded = false;
      _logger.warning('Push registration reconcile failed: $e', e, st);
    } finally {
      _reconciling = null;
      if (_reconcileRequested) {
        // A request that arrived while the loop was unwinding starts a new one.
        _requestReconcile();
      } else if (succeeded) {
        _reconcileRetryCount = 0;
      } else {
        _scheduleReconcileRetry();
      }
    }
  }

  void _scheduleReconcileRetry() {
    if (_reconcileRetryCount >= maxReconcileRetries) {
      _logger.warning(
        'Push registration still out of sync after $maxReconcileRetries '
        'retries; waiting for the next auth, token or toggle event',
      );
      return;
    }
    _reconcileRetryCount++;
    final delay = _reconcileRetryBaseDelay * _reconcileRetryCount;
    _reconcileRetryTimer?.cancel();
    _reconcileRetryTimer = Timer(delay, () {
      _reconcileRetryTimer = null;
      _logger.info(
        'Retrying push registration reconcile '
        '(attempt $_reconcileRetryCount/$maxReconcileRetries)',
      );
      _reconcileRequested = true;
      _reconciling ??= _runReconcile();
    });
  }

  /// Removes this device's registration from the backend using the id kept
  /// from the last successful register call. Nothing to do when the device
  /// was never registered or the user is signed out (the endpoint needs the
  /// user's JWT). The stored id is kept on failure so a later attempt can
  /// still find the registration. Returns false when the backend call failed
  /// and a retry is worthwhile.
  Future<bool> _unregister() async {
    final serverId = await _storage.get<String>(StorageKeys.pushDeviceServerId);
    if (serverId == null || serverId.isEmpty) return true;
    if (!_loggedIn) return true;

    final result = await _repository.unregisterDeviceToken(serverId);
    return result.fold(
      (failure) {
        _logger.warning('Device unregister failed: ${failure.message}');
        return false;
      },
      (_) async {
        // Only forget the id this call removed. Nothing else can register
        // concurrently thanks to the reconcile loop, but a stale id must never
        // shadow a newer one.
        final stored = await _storage.get<String>(
          StorageKeys.pushDeviceServerId,
        );
        if (stored == serverId) {
          await _storage.remove(StorageKeys.pushDeviceServerId);
        }
        _logger.info('Device unregistered');
        return true;
      },
    );
  }

  Future<void> _onToken(String token) async {
    if (token == _token) return;
    _token = token;
    await _storage.set(StorageKeys.fcmToken, token);
    // Full token logged at debug level only (stripped from release builds) so
    // you can copy it into the Firebase console to send a test push.
    _logger.debug('FCM token: $token');
    _requestReconcile();
    await registrationSettled;
  }

  /// Returns false when the backend call failed and a retry is worthwhile.
  Future<bool> _register() async {
    if (!_loggedIn) return true;
    var token = _token;
    if (token == null) {
      // No token in hand while signed in is a failure, not a no-op: minting
      // after the sign-out delete can come back empty (iOS, APNs token not
      // ready yet). Reported as a failed pass so the backoff retries it,
      // rather than leaving the install unregistered until the next launch.
      token = await _repository.getToken();
      if (token == null) {
        _logger.warning('No FCM token yet; registration will be retried');
        return false;
      }
      _token = token;
      await _storage.set(StorageKeys.fcmToken, token);
    }
    final deviceId = await _deviceId();
    final result = await _repository.registerDeviceToken(
      token,
      deviceId: deviceId,
      preferences: await _readPreferences(),
    );
    return result.fold(
      (failure) {
        _logger.warning('Token registration failed: ${failure.message}');
        return false;
      },
      (serverId) async {
        if (serverId != null) {
          await _storage.set(StorageKeys.pushDeviceServerId, serverId);
        }
        _logger.info('Token registered');
        return true;
      },
    );
  }

  /// Reads the only notification preference that FCM cares about: whether
  /// plan/series pushes are enabled — the sole category delivered via push.
  ///
  /// It is the AND of the master switch and the "routine" toggle: master is the
  /// global kill-switch, so master OFF disables plan/series push regardless of
  /// the routine toggle. Recitation, mala and timer are local-only (handled
  /// on-device) and never go to the backend. Both flags default to `true` (the
  /// settings-screen default) when never set.
  ///
  /// This must be gated server-side: for background / terminated notification
  /// messages the OS displays the push before the app runs, so a local check
  /// can't suppress them — only the backend can.
  Future<Map<String, bool>> _readPreferences() async {
    Future<bool> read(String key) async =>
        (await _storage.get<bool>(key)) ?? true;
    final masterOn = await read(StorageKeys.notificationMasterEnabled);
    final routineOn = await read(StorageKeys.notificationRoutineEnabled);
    return {'routine': masterOn && routineOn};
  }

  /// Returns the stable per-install device id, generating and persisting one on
  /// first use. Lets backend token refreshes update the same record.
  Future<String> _deviceId() async {
    final existing = await _storage.get<String>(StorageKeys.pushDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _storage.set(StorageKeys.pushDeviceId, id);
    return id;
  }

  Future<void> _showNotification(PushMessage message) async {
    if (!message.hasNotification) return;
    // The session is still being restored; judge it once auth settles.
    if (!_authKnown) {
      _pendingForeground.add(message);
      return;
    }
    // Pushes only ever target signed-in accounts. One arriving now is left
    // over from the last session, before its token was deleted.
    if (!_loggedIn) {
      _logger.info('Foreground push suppressed: signed out');
      return;
    }
    if (!_foregroundFilter.shouldShow(message.data)) {
      _logger.info('Foreground push suppressed: already on screen');
      return;
    }
    _logger.info('Foreground message: ${message.title}');
    await _localNotifications.show(
      // Time-based id kept within the 32-bit range Android requires.
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      message.title,
      message.body,
      NotificationChannels.pushDefaultDetails,
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }

  void _flushPendingForeground() {
    final pending = List.of(_pendingForeground);
    _pendingForeground.clear();
    for (final message in pending) {
      unawaited(_showNotification(message));
    }
  }

  void _onNotificationTapped(PushMessage message) {
    _logger.info('Notification opened: ${message.title} data=${message.data}');
    onOpenMessage?.call(message);
  }

  Future<void> _createAndroidChannel() async {
    // Resolver returns null off-Android, so this is a no-op on iOS/macOS.
    final android =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await android?.createNotificationChannel(
      NotificationChannels.pushDefaultChannel,
    );
  }

  void dispose() {
    _initRetryTimer?.cancel();
    _initRetryTimer = null;
    _reconcileRetryTimer?.cancel();
    _reconcileRetryTimer = null;
    _pendingForeground.clear();
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
  }
}
