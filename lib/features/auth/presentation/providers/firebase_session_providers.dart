import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/realtime/firebase_auth_gateway.dart';
import 'package:flutter_pecha/core/realtime/realtime_providers.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/data/repositories/firebase_session_repository_impl.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/firebase_session_repository.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseSessionRepositoryProvider = Provider<FirebaseSessionRepository>(
  (ref) => FirebaseSessionRepositoryImpl(dio: ref.watch(dioProvider)),
);

class FirebaseSessionState {
  const FirebaseSessionState({
    this.signedIn = false,
    this.disabled = false,
    this.uid,
  });

  final bool signedIn;

  /// The backend answered 503: Firebase is off there until the next login.
  final bool disabled;
  final String? uid;

  FirebaseSessionState copyWith({bool? signedIn, bool? disabled, String? uid}) {
    return FirebaseSessionState(
      signedIn: signedIn ?? this.signedIn,
      disabled: disabled ?? this.disabled,
      uid: uid ?? this.uid,
    );
  }
}

/// Exponential backoff from 2 s, capped at 60 s.
Duration firebaseSignInDelay(int attempt) {
  final seconds = math.min(60, 2 << (attempt - 1).clamp(0, 5));
  return Duration(seconds: seconds);
}

/// Keeps Firebase Auth signed in as the backend user for as long as the app
/// is. The SDK refreshes its own session; the token endpoint is only called
/// when there is no Firebase user. Signals are read only while signed in.
class FirebaseSessionNotifier extends StateNotifier<FirebaseSessionState> {
  FirebaseSessionNotifier({
    required FirebaseSessionRepository repository,
    required FirebaseAuthGateway gateway,
    required void Function(bool signedIn) publish,
    Duration Function(int attempt) backoff = firebaseSignInDelay,
    int maxAttempts = 6,
  }) : _repository = repository,
       _gateway = gateway,
       _publish = publish,
       _backoff = backoff,
       _maxAttempts = maxAttempts,
       super(const FirebaseSessionState()) {
    _authSub = _gateway.authStateChanges().listen(_onFirebaseUser);
  }

  final FirebaseSessionRepository _repository;
  final FirebaseAuthGateway _gateway;
  final void Function(bool signedIn) _publish;
  final Duration Function(int attempt) _backoff;
  final int _maxAttempts;
  final _logger = AppLogger('FirebaseSession');

  StreamSubscription<String?>? _authSub;
  Timer? _retryTimer;
  int _attempt = 0;
  bool _wantSignedIn = false;
  bool _signingOut = false;

  /// Bumped on every login and logout; work begun in one session is dropped
  /// when it finishes in another.
  int _session = 0;

  /// The session a sign-in is running for, if any.
  int? _signingInFor;

  /// The Firebase user this session may use. Any other is a previous
  /// account's.
  String? _sessionUid;

  bool get _signingIn => _signingInFor == _session;

  void onAuthChanged({required bool loggedIn}) {
    if (loggedIn == _wantSignedIn) {
      // Opening logged out: a Firebase user saved from an earlier launch
      // belongs to whoever left, so it must not carry into the next login.
      if (!loggedIn && _session == 0) {
        _session++;
        if (_gateway.currentUid != null) unawaited(_signOut());
      }
      return;
    }
    _wantSignedIn = loggedIn;
    final firstSession = _session == 0;
    _session++;
    _retryTimer?.cancel();
    _attempt = 0;
    if (loggedIn) {
      state = state.copyWith(disabled: false);
      // Only a user persisted from an earlier launch is trusted; after a
      // logout here, one left over belongs to the account that left.
      final leftover = _gateway.currentUid;
      if (firstSession && leftover != null) {
        _sessionUid = leftover;
        _setSignedIn(true, uid: leftover);
      } else {
        unawaited(_signIn());
      }
    } else {
      _sessionUid = null;
      unawaited(_signOut());
    }
  }

  /// Retries a sign-in that gave up, on return to the foreground.
  void resume() {
    if (!_wantSignedIn || state.signedIn || state.disabled || _signingIn) {
      return;
    }
    _retryTimer?.cancel();
    _attempt = 0;
    unawaited(_signIn());
  }

  Future<void> _signIn() async {
    if (_signingIn || !_wantSignedIn || state.disabled) return;
    final session = _session;
    _signingInFor = session;
    try {
      final result = await _repository.fetchCustomToken();
      if (!mounted || session != _session) return;
      final token = result.fold((failure) {
        if (failure is FirebaseDisabledFailure) {
          _logger.info('Firebase disabled on this backend; no live updates');
          state = state.copyWith(disabled: true);
          return null;
        }
        _scheduleRetry(failure.message);
        return null;
      }, (token) => token);
      if (token == null) return;

      try {
        final uid = await _gateway.signInWithCustomToken(token.token);
        if (!mounted) return;
        if (session != _session) {
          unawaited(_dropStaleUser(uid));
          return;
        }
        if (uid != token.uid) {
          _logger.warning(
            'Firebase uid $uid differs from backend ${token.uid}',
          );
        }
        _attempt = 0;
        _sessionUid = uid;
        _setSignedIn(true, uid: uid);
      } catch (e) {
        if (!mounted || session != _session) return;
        _scheduleRetry('$e');
      }
    } finally {
      if (_signingInFor == session) _signingInFor = null;
    }
  }

  /// A sign-in for an ended session landed. Signs it out unless a newer
  /// sign-in has already replaced it, or it is this session's own user.
  Future<void> _dropStaleUser(String uid) async {
    if (_gateway.currentUid != uid || uid == _sessionUid) return;
    try {
      await _gateway.signOut();
    } catch (e) {
      _logger.warning('Firebase sign-out of a stale user failed: $e');
    }
  }

  void _scheduleRetry(String reason) {
    _attempt++;
    if (_attempt > _maxAttempts) {
      _logger.warning('Firebase sign-in gave up: $reason');
      return;
    }
    _retryTimer?.cancel();
    _retryTimer = Timer(_backoff(_attempt), () {
      if (mounted) unawaited(_signIn());
    });
  }

  /// Flips the flag first so listeners cancel before Firestore refuses them.
  Future<void> _signOut() async {
    _signingOut = true;
    _setSignedIn(false, uid: null);
    try {
      await _gateway.signOut();
    } catch (e) {
      _logger.warning('Firebase sign-out failed: $e');
    } finally {
      _signingOut = false;
    }
  }

  void _onFirebaseUser(String? uid) {
    if (!mounted) return;
    if (uid == null) {
      if (state.signedIn) _setSignedIn(false, uid: null);
      if (_wantSignedIn && !_signingOut && !_signingIn) unawaited(_signIn());
      return;
    }
    if (_wantSignedIn && !state.signedIn && uid == _sessionUid) {
      _setSignedIn(true, uid: uid);
    }
  }

  /// Idempotent: the sign-in call and the auth stream both report success.
  void _setSignedIn(bool signedIn, {required String? uid}) {
    if (state.signedIn == signedIn && state.uid == uid) return;
    state = FirebaseSessionState(
      signedIn: signedIn,
      disabled: state.disabled,
      uid: uid,
    );
    _publish(signedIn);
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}

/// Null where Firebase did not start.
final firebaseSessionProvider =
    StateNotifierProvider<FirebaseSessionNotifier, FirebaseSessionState>((ref) {
      final gateway = ref.watch(firebaseAuthGatewayProvider);
      if (gateway == null) {
        throw StateError('Firebase is not initialised');
      }
      return FirebaseSessionNotifier(
        repository: ref.watch(firebaseSessionRepositoryProvider),
        gateway: gateway,
        publish: (signedIn) {
          ref.read(firebaseSignedInProvider.notifier).state = signedIn;
        },
      );
    });

/// Signs in to Firebase once the backend user is known and out when they
/// leave. Watch for the app lifetime, next to the push bootstrap.
final firebaseSessionBootstrapProvider = Provider<void>((ref) {
  if (Firebase.apps.isEmpty) return;
  final notifier = ref.watch(firebaseSessionProvider.notifier);

  void syncAuth() {
    final auth = ref.read(authProvider);
    if (auth.isLoading) return;
    notifier.onAuthChanged(loggedIn: auth.isLoggedIn && !auth.isGuest);
  }

  ref.listen<AuthState>(
    authProvider,
    (_, __) => syncAuth(),
    fireImmediately: true,
  );
});
