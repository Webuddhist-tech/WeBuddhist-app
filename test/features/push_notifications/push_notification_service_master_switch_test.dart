import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/push_notifications/application/foreground_push_filter.dart';
import 'package:flutter_pecha/features/push_notifications/application/push_notification_service.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeRepository extends Fake implements PushMessagingRepository {
  final tokenRefresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();

  String? token = 'tok-1';
  String serverIdToReturn = 'dev-1';
  Failure? registerFailure;
  Failure? unregisterFailure;
  final List<String> registered = [];
  final List<String> unregistered = [];

  /// When set, the next register / unregister call waits on it before
  /// answering, so a test can flip state while the request is in flight.
  Completer<void>? holdRegister;
  Completer<void>? holdUnregister;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> getToken() async => token;

  /// Thrown by the next [deleteToken] call, then cleared.
  Object? deleteTokenError;
  int deleteTokenCalls = 0;

  @override
  Future<void> deleteToken() async {
    deleteTokenCalls++;
    final error = deleteTokenError;
    deleteTokenError = null;
    if (error != null) throw error;
    // Firebase mints a new token on the next getToken.
    token = 'tok-${deleteTokenCalls + 1}';
  }

  @override
  Stream<String> get onTokenRefresh => tokenRefresh.stream;

  @override
  Stream<PushMessage> get onForegroundMessage => foreground.stream;

  @override
  Stream<PushMessage> get onMessageOpenedApp => opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => null;

  @override
  Future<Either<Failure, String?>> registerDeviceToken(
    String token, {
    String? deviceId,
    Map<String, bool>? preferences,
  }) async {
    registered.add(token);
    final hold = holdRegister;
    holdRegister = null;
    if (hold != null) await hold.future;
    final failure = registerFailure;
    if (failure != null) return Left(failure);
    return Right(serverIdToReturn);
  }

  @override
  Future<Either<Failure, Unit>> unregisterDeviceToken(
    String pushDeviceId,
  ) async {
    unregistered.add(pushDeviceId);
    final hold = holdUnregister;
    holdUnregister = null;
    if (hold != null) await hold.future;
    final failure = unregisterFailure;
    if (failure != null) return Left(failure);
    return const Right(unit);
  }

  Future<void> close() async {
    await tokenRefresh.close();
    await foreground.close();
    await opened.close();
  }
}

class _FakeStorage extends Fake implements LocalStorageService {
  final Map<String, Object?> values = {};

  @override
  Future<T?> get<T>(String key) async => values[key] as T?;

  @override
  Future<bool> set<T>(String key, T value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

/// Short backoff unit for the retry tests; production uses seconds.
const _retryDelay = Duration(milliseconds: 20);

/// Waits long enough for the [attempt]th linear-backoff retry to have fired.
Future<void> _afterRetry(int attempt) => Future<void>.delayed(
  _retryDelay * attempt + const Duration(milliseconds: 5),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepository repo;
  late _FakeStorage storage;
  late PushNotificationService service;

  setUp(() {
    // Off Android the service skips the local-notifications channel setup,
    // which has no platform implementation under test.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    repo = _FakeRepository();
    storage = _FakeStorage();
    service = PushNotificationService(
      repository: repo,
      storage: storage,
      foregroundFilter: ForegroundPushFilter(),
      reconcileRetryBaseDelay: _retryDelay,
    );
  });

  tearDown(() async {
    service.dispose();
    await repo.close();
    debugDefaultTargetPlatformOverride = null;
  });

  group('master switch', () {
    test('registration stores the backend device id', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();

      expect(repo.registered, ['tok-1']);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-1');
    });

    test('master off unregisters with the stored id and clears it', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();

      service.setMasterEnabled(false);
      await _settle();

      expect(repo.unregistered, ['dev-1']);
      expect(
        storage.values.containsKey(StorageKeys.pushDeviceServerId),
        isFalse,
      );
    });

    test('master back on registers again', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();
      service.setMasterEnabled(false);
      await _settle();

      repo.serverIdToReturn = 'dev-2';
      service.setMasterEnabled(true);
      await _settle();

      expect(repo.registered, ['tok-1', 'tok-1']);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-2');
    });

    test('a token refresh while master is off does not re-register', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();
      service.setMasterEnabled(false);
      await _settle();

      repo.tokenRefresh.add('tok-2');
      await _settle();

      expect(repo.registered, ['tok-1']);
    });

    test('the same value twice is a no-op', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();

      service.setMasterEnabled(true);
      service.setMasterEnabled(true);
      await _settle();

      expect(repo.registered, ['tok-1']);
      expect(repo.unregistered, isEmpty);
    });

    test('signing in with master off removes a registration left from an '
        'earlier session', () async {
      storage.values[StorageKeys.pushDeviceServerId] = 'dev-old';
      service.setMasterEnabled(false);
      await service.initialize();

      service.onAuthChanged(loggedIn: true);
      await _settle();

      expect(repo.registered, isEmpty);
      expect(repo.unregistered, ['dev-old']);
      expect(
        storage.values.containsKey(StorageKeys.pushDeviceServerId),
        isFalse,
      );
    });

    test('master off while signed out waits for sign-in', () async {
      storage.values[StorageKeys.pushDeviceServerId] = 'dev-old';
      await service.initialize();

      service.setMasterEnabled(false);
      await _settle();
      expect(repo.unregistered, isEmpty);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-old');
    });

    test('a failed unregister keeps the id for a later attempt', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();

      repo.unregisterFailure = const NetworkFailure('offline');
      service.setMasterEnabled(false);
      await _settle();

      expect(repo.unregistered, ['dev-1']);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-1');
    });
  });

  group('master switch races', () {
    test(
      'master off while a register is in flight still unregisters',
      () async {
        await service.initialize();
        final hold = repo.holdRegister = Completer<void>();
        service.onAuthChanged(loggedIn: true);
        await _settle();
        expect(repo.registered, ['tok-1']);
        expect(storage.values[StorageKeys.pushDeviceServerId], isNull);

        // Opt out before the backend has answered the register call.
        service.setMasterEnabled(false);
        await _settle();
        expect(repo.unregistered, isEmpty);

        hold.complete();
        await service.registrationSettled;

        expect(repo.unregistered, ['dev-1']);
        expect(
          storage.values.containsKey(StorageKeys.pushDeviceServerId),
          isFalse,
        );
      },
    );

    test('master back on while an unregister is in flight re-registers and '
        'keeps the new id', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();

      final hold = repo.holdUnregister = Completer<void>();
      service.setMasterEnabled(false);
      await _settle();
      expect(repo.unregistered, ['dev-1']);

      repo.serverIdToReturn = 'dev-2';
      service.setMasterEnabled(true);
      await _settle();
      // The register waits for the unregister to finish.
      expect(repo.registered, ['tok-1']);

      hold.complete();
      await service.registrationSettled;

      expect(repo.registered, ['tok-1', 'tok-1']);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-2');
    });

    test(
      'off then on before either request lands ends registered once',
      () async {
        await service.initialize();
        service.onAuthChanged(loggedIn: true);
        await _settle();

        final hold = repo.holdUnregister = Completer<void>();
        service.setMasterEnabled(false);
        service.setMasterEnabled(true);
        await _settle();
        hold.complete();
        await service.registrationSettled;

        expect(repo.unregistered, ['dev-1']);
        expect(repo.registered, ['tok-1', 'tok-1']);
        expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-1');
      },
    );
  });

  group('reconcile retries', () {
    test('a failed unregister is retried until it succeeds', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();

      repo.unregisterFailure = const NetworkFailure('offline');
      service.setMasterEnabled(false);
      await _settle();
      expect(repo.unregistered, ['dev-1']);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-1');

      // Connection is back before the first retry fires.
      repo.unregisterFailure = null;
      await _afterRetry(1);
      await service.registrationSettled;

      expect(repo.unregistered, ['dev-1', 'dev-1']);
      expect(
        storage.values.containsKey(StorageKeys.pushDeviceServerId),
        isFalse,
      );
    });

    test('a failed register is retried', () async {
      repo.registerFailure = const NetworkFailure('offline');
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();
      expect(repo.registered, ['tok-1']);

      repo.registerFailure = null;
      await _afterRetry(1);
      await service.registrationSettled;

      expect(repo.registered, ['tok-1', 'tok-1']);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-1');
    });

    test('an explicit request supersedes a pending retry', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();

      repo.unregisterFailure = const NetworkFailure('offline');
      service.setMasterEnabled(false);
      await _settle();
      expect(repo.unregistered, ['dev-1']);

      // User changes their mind before the retry fires: only the register
      // should run, and the stale unregister retry must not fire afterwards.
      service.setMasterEnabled(true);
      await service.registrationSettled;
      await _afterRetry(1);
      await service.registrationSettled;

      expect(repo.unregistered, ['dev-1']);
      expect(repo.registered, ['tok-1', 'tok-1']);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-1');
    });

    test('gives up after the retry cap and waits for the next event', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await _settle();

      repo.unregisterFailure = const NetworkFailure('offline');
      service.setMasterEnabled(false);
      // Initial attempt plus every retry, with linear backoff between them.
      for (
        var attempt = 1;
        attempt <= PushNotificationService.maxReconcileRetries;
        attempt++
      ) {
        await _afterRetry(attempt);
      }
      await service.registrationSettled;
      final attempts = repo.unregistered.length;
      expect(attempts, PushNotificationService.maxReconcileRetries + 1);

      // No further retries on their own.
      await _afterRetry(PushNotificationService.maxReconcileRetries + 1);
      expect(repo.unregistered.length, attempts);

      // The next explicit event tries again.
      repo.unregisterFailure = null;
      service.refreshRegistration();
      await service.registrationSettled;
      expect(repo.unregistered.length, attempts + 1);
      expect(
        storage.values.containsKey(StorageKeys.pushDeviceServerId),
        isFalse,
      );
    });
  });

  group('sign-out', () {
    Future<void> signIn() async {
      await service.initialize();
      service.onAuthChanged(loggedIn: true);
      await service.registrationSettled;
    }

    /// The order `AuthNotifier.logout` uses: unregister first, then the
    /// state flip that triggers the detach.
    Future<void> logOut() async {
      final unregister = service.unregisterForSignOut();
      service.onAuthChanged(loggedIn: false);
      await unregister;
      await _settle();
      await service.registrationSettled;
    }

    test('logout unregisters, deletes the token and clears the ids', () async {
      await signIn();

      await logOut();

      expect(repo.unregistered, ['dev-1']);
      expect(repo.deleteTokenCalls, 1);
      expect(
        storage.values.containsKey(StorageKeys.pushDeviceServerId),
        isFalse,
      );
      // The replacement token is kept for the next sign-in, not registered.
      expect(storage.values[StorageKeys.fcmToken], 'tok-2');
      expect(repo.registered, ['tok-1']);
    });

    test('a failed unregister still deletes the token', () async {
      await signIn();
      repo.unregisterFailure = const NetworkFailure('offline');

      await logOut();

      expect(repo.unregistered, ['dev-1']);
      expect(repo.deleteTokenCalls, 1);
      expect(
        storage.values.containsKey(StorageKeys.pushDeviceServerId),
        isFalse,
      );
    });

    test('an expired session deletes the token without a backend call', () async {
      await signIn();

      service.onAuthChanged(loggedIn: false);
      await _settle();
      await service.registrationSettled;

      expect(repo.unregistered, isEmpty);
      expect(repo.deleteTokenCalls, 1);
    });

    test('a failed token delete keeps the id for the next attempt', () async {
      await signIn();
      repo.deleteTokenError = Exception('offline');

      service.onAuthChanged(loggedIn: false);
      await _settle();
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-1');

      // Any later signed-out snapshot, e.g. the next launch as a guest.
      service.onAuthChanged(loggedIn: false);
      await _settle();
      await service.registrationSettled;

      expect(repo.deleteTokenCalls, 2);
      expect(
        storage.values.containsKey(StorageKeys.pushDeviceServerId),
        isFalse,
      );
    });

    test('a guest install left registered by an old session is detached', () async {
      storage.values[StorageKeys.pushDeviceServerId] = 'dev-old';

      await service.initialize();
      service.onAuthChanged(loggedIn: false);
      await _settle();
      await service.registrationSettled;

      expect(repo.deleteTokenCalls, 1);
      expect(repo.registered, isEmpty);
      expect(
        storage.values.containsKey(StorageKeys.pushDeviceServerId),
        isFalse,
      );
    });

    test('a guest that never registered keeps its token', () async {
      await service.initialize();
      service.onAuthChanged(loggedIn: false);
      await _settle();

      expect(repo.deleteTokenCalls, 0);
      expect(repo.registered, isEmpty);
    });

    test('signing in again registers the fresh token', () async {
      await signIn();
      await logOut();

      repo.serverIdToReturn = 'dev-2';
      service.onAuthChanged(loggedIn: true);
      await service.registrationSettled;

      expect(repo.registered, ['tok-1', 'tok-2']);
      expect(storage.values[StorageKeys.pushDeviceServerId], 'dev-2');
    });
  });
}
