// Riverpod provider and logic for authentication state.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/domain/entities/auth_credentials.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/clear_guest_mode_and_onboarding_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/clear_guest_mode_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/continue_as_guest_usecase.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/utils/auth_analytics.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/get_credentials_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/has_valid_credentials_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/initialize_auth_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/is_guest_mode_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/config/router/pending_route_provider.dart';
import 'package:flutter_pecha/core/network/interceptors/cache_interceptor.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/providers/push_notification_providers.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final InitializeAuthUseCase _initializeAuthUseCase;
  final HasValidCredentialsUseCase _hasValidCredentialsUseCase;
  final GetCredentialsUseCase _getCredentialsUseCase;
  final ContinueAsGuestUseCase _continueAsGuestUseCase;
  final IsGuestModeUseCase _isGuestModeUseCase;
  final ClearGuestModeUseCase _clearGuestModeUseCase;
  final LogoutUseCase _localLogoutUseCase;
  final ClearGuestModeAndOnboardingUseCase _clearGuestModeAndOnboardingUseCase;
  final Ref ref;
  final _logger = AppLogger('AuthNotifier');

  /// Subscription to connectivity changes, used to reconcile a session that was
  /// restored offline once the network returns. Cancelled in [dispose].
  StreamSubscription<bool>? _connectivitySub;

  /// Guards [_reconcileOnReconnect] so overlapping connectivity events don't
  /// fire concurrent profile refetches.
  bool _reconciling = false;

  /// Monotonic counter bumped whenever the session is invalidated (logout,
  /// expiry, new login). Async continuations capture the value before an
  /// await and discard their result if the epoch changed — prevents a stale
  /// onboarding prefetch from re-applying `isLoggedIn: true` after logout.
  int _authEpoch = 0;

  /// Epoch of the auth attempt analytics is identified as, or null once
  /// reset. See [_resetAnalyticsIdentity].
  int? _identityEpoch;

  /// Prevents overlapping background onboarding refetches.
  bool _onboardingFetchInFlight = false;

  /// Debounces navigation-triggered onboarding retries so redirects stay cheap.
  DateTime? _lastOnboardingRetryAt;

  static const _onboardingRetryDebounce = Duration(seconds: 5);

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required InitializeAuthUseCase initializeAuthUseCase,
    required HasValidCredentialsUseCase hasValidCredentialsUseCase,
    required GetCredentialsUseCase getCredentialsUseCase,
    required ContinueAsGuestUseCase continueAsGuestUseCase,
    required IsGuestModeUseCase isGuestModeUseCase,
    required ClearGuestModeUseCase clearGuestModeUseCase,
    required LogoutUseCase localLogoutUseCase,
    required ClearGuestModeAndOnboardingUseCase
    clearGuestModeAndOnboardingUseCase,
    required this.ref,
  }) : _loginUseCase = loginUseCase,
       _initializeAuthUseCase = initializeAuthUseCase,
       _hasValidCredentialsUseCase = hasValidCredentialsUseCase,
       _getCredentialsUseCase = getCredentialsUseCase,
       _continueAsGuestUseCase = continueAsGuestUseCase,
       _isGuestModeUseCase = isGuestModeUseCase,
       _clearGuestModeUseCase = clearGuestModeUseCase,
       _localLogoutUseCase = localLogoutUseCase,
       _clearGuestModeAndOnboardingUseCase = clearGuestModeAndOnboardingUseCase,
       super(const AuthState(isLoggedIn: false, isLoading: true)) {
    _restoreLoginState();
    _listenForReconnect();
  }

  /// When the app launches offline, the session is kept ([_restoreCredentials]'s
  /// transient branch) but the one-shot credential renewal and user-profile
  /// fetch fail and are never retried — leaving a "logged in but empty profile"
  /// state that, before this, only a relaunch could fix. Listen for the
  /// offline→online transition and reconcile then.
  void _listenForReconnect() {
    _connectivitySub = ref
        .read(connectivityServiceProvider)
        .onConnectivityChanged
        .listen((isOnline) {
          if (isOnline) unawaited(_reconcileOnReconnect());
        });
  }

  /// Reconcile auth/user state once connectivity returns after an offline
  /// launch.
  ///
  /// Two cases:
  /// - Real session already restored (`isLoggedIn && !isGuest`): just refresh
  ///   the user profile. Uses [refreshUser] (not [initializeUser]) so an
  ///   already-populated profile doesn't flash a loading state and a failed
  ///   refetch keeps the current state. The refetch hits a protected endpoint
  ///   so it also drives a silent token renewal via the interceptor; a dead
  ///   session surfaces as a 401 handled by the reactive-401 path, not here.
  /// - Not a confirmed real login (guest / logged out): the launch may have
  ///   fallen through to guest because auth init (`ConfigService.loadConfig`)
  ///   or `hasValidCredentials()` failed without a network. Re-run the restore
  ///   now that we're online so a real stored session is recovered without a
  ///   relaunch. A genuine guest with no credentials simply stays a guest.
  Future<void> _reconcileOnReconnect() async {
    if (_reconciling) return;
    _reconciling = true;
    try {
      if (state.isLoggedIn && !state.isGuest) {
        _logger.info('Connectivity restored — reconciling user profile');
        await ref.read(userProvider.notifier).refreshUser();
        await _refreshOnboardingStatus(skipDebounce: true);
      } else {
        _logger.info('Connectivity restored — re-running login restore');
        await _restoreLoginState();
      }
    } catch (e) {
      _logger.warning('Reconcile on reconnect failed (ignored): $e');
    } finally {
      _reconciling = false;
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _restoreLoginState() async {
    _logger.debug('Restoring login state');

    // Fresh-install handling.
    // iOS: Keychain survives uninstall — we WANT that, so we never clear here.
    //      The silent renewal in _restoreCredentials() decides logged-in state,
    //      giving the seamless reinstall contract.
    // Android: Auto Backup is disabled (manifest), so a reinstall is a genuine
    //      clean slate. This clear is belt-and-suspenders for the edge case where
    //      a residual credential exists (e.g. backup re-enabled by misconfig).
    final isKnownInstall = await ref
        .read(localStorageServiceProvider)
        .get<bool>(StorageKeys.firstLaunch);

    if (isKnownInstall == null) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _localLogoutUseCase(const NoParams());
        _logger.info(
          'Android fresh install — cleared any residual credentials',
        );
      } else {
        _logger.info(
          'iOS fresh install — preserving Keychain for seamless reinstall',
        );
      }
      await ref
          .read(localStorageServiceProvider)
          .set(StorageKeys.firstLaunch, true);
    }

    // Initialize auth
    final initResult = await _initializeAuthUseCase(const NoParams());
    initResult.fold(
      (failure) {
        _logger.error('Failed to initialize auth: ${failure.message}');
      },
      (_) {
        _logger.debug('Auth initialized successfully');
      },
    );

    // Check if we have any credentials at all
    final credentialsResult = await _hasValidCredentialsUseCase(
      const NoParams(),
    );
    credentialsResult.fold(
      (failure) {
        _logger.error('Failed to check credentials: ${failure.message}');
        // Fall through to check guest mode
      },
      (hasCredentials) {
        _logger.debug('Credentials valid: $hasCredentials');

        if (hasCredentials) {
          _restoreCredentials();
        } else {
          _checkGuestMode();
        }
      },
    );
  }

  Future<void> _restoreCredentials() async {
    final credentialsResult = await _getCredentialsUseCase(const NoParams());

    // Extract result outside fold so we can await async operations below.
    // fpdart's fold() is synchronous and will not await returned Futures.
    AuthCredentials? credentials;
    Failure? failure;
    credentialsResult.fold((f) => failure = f, (creds) => credentials = creds);

    // Happy path: we have a fresh token.
    if (credentials != null && credentials!.idToken.isNotEmpty) {
      final epoch = _authEpoch;

      // Store currentUserId before updating auth state so feature code can
      // resolve the active account when the router refreshes.
      final userId = _extractUserIdFromToken(credentials!.idToken);
      if (userId != null) {
        await ref
            .read(localStorageServiceProvider)
            .set(StorageKeys.currentUserId, userId);
        if (!_isAuthEpochCurrent(epoch)) return;
        _logger.debug('Restored currentUserId');
        await _identifyAuthenticatedUser(
          userId: userId,
          isGuest: false,
          epoch: epoch,
        );
        if (!_isAuthEpochCurrent(epoch)) return;
      }

      // Prefetch onboarding status while the token is fresh. Emitting auth
      // state once with the complete picture means the route guard's
      // redirect fires synchronously — no second navigation or per-nav
      // network call. This also populates userProvider (via
      // _fetchOnboardingStatusSafe's caller chain), so no separate
      // initializeUser() call is needed afterward.
      final onboardingStatus = await _fetchOnboardingStatusSafe();
      if (!_isAuthEpochCurrent(epoch)) return;
      await ref.read(userProvider.notifier).initializeUser();
      _applyAuthenticatedLoginState(
        epoch: epoch,
        onboardingStatus: onboardingStatus,
        logMessage: 'Login state restored',
      );
      if (onboardingStatus == null) {
        unawaited(_refreshOnboardingStatus(skipDebounce: true));
      }
      return;
    }

    // No fresh token. Only sign the user out when the session is *permanently*
    // gone (no credentials / no refresh token → AuthenticationFailure).
    // hasValidCredentials() already confirmed a session exists, so a
    // transient/offline renewal failure (NetworkFailure) must NOT wipe it —
    // keep the user logged in and renew on the first authenticated request.
    if (failure is AuthenticationFailure) {
      _logger.info(
        'Stored credentials permanently invalid — checking guest mode',
      );
      _checkGuestMode();
      return;
    }

    _logger.warning(
      'Could not refresh credentials at launch (transient/offline). '
      'Keeping the existing session; it will renew on the next request.',
    );
    final epoch = _authEpoch;
    final storedUserId = await ref
        .read(localStorageServiceProvider)
        .get<String>(StorageKeys.currentUserId);
    if (!_isAuthEpochCurrent(epoch)) return;

    _applyAuthenticatedLoginState(
      epoch: epoch,
      onboardingStatus: null,
      logMessage: 'Offline session kept — onboarding status pending',
    );
    unawaited(_refreshOnboardingStatus(skipDebounce: true));

    if (storedUserId != null && storedUserId.isNotEmpty) {
      unawaited(
        _identifyAuthenticatedUser(
          userId: storedUserId,
          isGuest: false,
          epoch: epoch,
        ),
      );
    }
    try {
      ref.read(userProvider.notifier).initializeUser();
    } catch (e) {
      _logger.warning('Could not initialize user data', e);
    }
  }

  Future<void> _checkGuestMode() async {
    _logger.debug('No valid credentials found, checking guest mode');

    final guestModeResult = await _isGuestModeUseCase(const NoParams());
    guestModeResult.fold(
      (failure) {
        _logger.error('Failed to check guest mode: ${failure.message}');
        _setLoggedOutState();
      },
      (isGuest) {
        if (isGuest) {
          // Restore guest mode
          state = state.copyWith(
            isLoggedIn: true,
            isLoading: false,
            isGuest: true,
            errorMessage: null,
          );
          _logger.info('Guest mode restored from preferences');
          unawaited(_markGuestSession());
        } else {
          // No credentials and not guest mode, user needs to log in
          _setLoggedOutState();
        }
      },
    );
  }

  void _setLoggedOutState() {
    _invalidateAuthSession();
    _logger.info('No valid credentials or guest mode found, showing login');
  }

  /// Called when a renewal fails *permanently* mid-session (refresh token gone
  /// or revoked). Clears local credentials and flips to logged-out so the
  /// router redirects to login. Does NOT fire for transient/offline failures —
  /// those keep the session (see [AuthService.isSessionPermanentlyLost]).
  ///
  /// The router reacts to auth state via `refreshListenable`, and the route
  /// guard preserves the intended route, so after re-login the user returns
  /// where they were. No additional navigation here.
  Future<void> handleSessionExpired() async {
    _logger.info('Session permanently expired — routing to login');
    _invalidateAuthSession();
    await _localLogoutUseCase(const NoParams());
    // As on logout: the next session must not carry this user's identity.
    await _resetAnalyticsIdentity();
  }

  Future<void> _handleAuthFailure() async {
    _invalidateAuthSession();
    final logoutResult = await _localLogoutUseCase(const NoParams());
    logoutResult.fold(
      (failure) {
        _logger.warning(
          'Failed to clear credentials during logout: ${failure.message}',
        );
      },
      (_) {
        _logger.debug('Credentials cleared during failure handling');
      },
    );
  }

  Future<void> login({String? connection, AuthSource? source}) async {
    _bumpAuthEpoch();
    state = state.copyWith(isLoading: true, errorMessage: null);

    final loginResult = await _loginUseCase(
      LoginParams(connection: connection),
    );
    loginResult.fold(
      (failure) {
        _logger.error('Login failed: ${failure.message}');
        _authAnalytics.loginFailed(
          method: connection,
          source: source,
          reason: failure.message,
        );
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed: ${failure.message}',
        );
        // A login this one superseded may have identified its user already.
        unawaited(_resetAnalyticsIdentity(onlyIfStale: true));
      },
      (credentials) {
        unawaited(
          _handleSuccessfulLogin(
            credentials,
            connection: connection,
            source: source,
          ),
        );
      },
    );
  }

  Future<void> _handleSuccessfulLogin(
    AuthCredentials credentials, {
    String? connection,
    AuthSource? source,
  }) async {
    final epoch = _authEpoch;

    // 1. Clear the guest mode flag from storage before the router fires.
    await _clearGuestMode();
    if (!_isAuthEpochCurrent(epoch)) return;

    // 2. Persist the user's ID before updating auth state.
    //    The router refreshes the moment auth state changes.
    final userId = _extractUserIdFromToken(credentials.idToken);
    if (userId != null) {
      await ref
          .read(localStorageServiceProvider)
          .set(StorageKeys.currentUserId, userId);
      if (!_isAuthEpochCurrent(epoch)) return;
      _logger.debug('Stored currentUserId');
      await _identifyAuthenticatedUser(
        userId: userId,
        isGuest: false,
        epoch: epoch,
      );
      if (!_isAuthEpochCurrent(epoch)) return;
    }

    _authAnalytics.loginSucceeded(method: connection, source: source);

    // 3. Prefetch onboarding status and full user profile so the route guard
    //    can decide instantly.
    ref.read(cacheInterceptorProvider).clearUserScoped();
    final onboardingStatus = await _fetchOnboardingStatusSafe();
    if (!_isAuthEpochCurrent(epoch)) return;
    await ref.read(userProvider.notifier).initializeUser();

    // 4. Update auth state — triggers the router refresh.
    _applyAuthenticatedLoginState(
      epoch: epoch,
      onboardingStatus: onboardingStatus,
      logMessage: 'User authenticated',
    );
    if (onboardingStatus == null) {
      unawaited(_refreshOnboardingStatus(skipDebounce: true));
    }
  }

  /// Clears the guest mode flag from storage.
  /// Onboarding completion is intentionally NOT touched here — it is tracked
  /// per user ID and must survive login/logout/guest transitions.
  Future<void> _clearGuestMode() async {
    final result = await _clearGuestModeAndOnboardingUseCase(
      const ClearGuestModeAndOnboardingParams(wasGuest: false),
    );
    result.fold(
      (failure) =>
          _logger.warning('Failed to clear guest mode: ${failure.message}'),
      (_) => _logger.debug('Guest mode cleared'),
    );
  }

  /// Extracts the user ID (sub claim) from a JWT ID token without verification.
  /// Used only to identify the user for onboarding tracking — not for auth.
  static String? _extractUserIdFromToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      final claims = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
      return claims['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  // continue as guest
  Future<void> continueAsGuest({required AuthSource source}) async {
    // Persist guest mode preference
    final guestResult = await _continueAsGuestUseCase(const NoParams());
    guestResult.fold(
      (failure) {
        _logger.error('Failed to continue as guest: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to continue as guest: ${failure.message}',
        );
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          isGuest: true,
        );
        _logger.info('Guest mode activated and persisted');
        _authAnalytics.guestStarted(source: source);
        unawaited(_markGuestSession());
      },
    );
  }

  Future<void> logout() async {
    // Started before the state flips: the flip makes the push service delete
    // the FCM token, and it must first let this unregister use the stored id
    // while the JWT is still valid. Awaited below, before credentials go.
    final pushUnregister = _unregisterPushDevice();
    _invalidateAuthSession();
    ref.read(cacheInterceptorProvider).clearUserScoped();

    // Best-effort flush of any unsynced mala counts while the token is still
    // valid. Local data is namespaced by user id and is NOT deleted here, so
    // any remaining tail flushes on next login.
    try {
      await ref.read(malaSyncManagerProvider).flush(SyncReason.logout);
    } catch (e) {
      _logger.warning('Mala flush on logout failed (ignored): $e');
    }
    await pushUnregister;

    final logoutResult = await _localLogoutUseCase(const NoParams());
    logoutResult.fold(
      (failure) {
        _logger.error('Failed to logout: ${failure.message}');
        state = state.copyWith(
          errorMessage: 'Failed to logout: ${failure.message}',
        );
      },
      (_) {
        _logger.debug('Logout successful');
      },
    );

    // Clear user profile data and the stored user ID.
    // Onboarding completion is NOT cleared — it persists per user ID
    // so the user never sees onboarding again on re-login.
    await ref.read(userProvider.notifier).clearUser();
    await ref
        .read(localStorageServiceProvider)
        .remove(StorageKeys.currentUserId);

    // Clear any pending deep-link route so a stale destination doesn't survive logout.
    ref.read(pendingRouteProvider.notifier).state = null;

    // Cancel every pending notification so a different signing-in user
    // does not inherit this user's schedule.
    try {
      await RoutineNotificationService().cancelAll();
    } catch (e) {
      _logger.warning('Failed to cancel notifications on logout: $e');
    }

    await _resetAnalyticsIdentity();

    _logger.info('User logged out, auth and user state cleared');
  }

  /// Permanently deletes the user's account via DELETE /users/info, then clears
  /// all local data and logs out.
  ///
  /// Returns `null` on success or an error message string on failure.
  Future<String?> deleteAccount() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final deleteResult = await ref
        .read(deleteAccountUseCaseProvider)
        .call(const NoParams());

    return deleteResult.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        _logger.error('Failed to delete account: ${failure.message}');
        return failure.message;
      },
      (_) async {
        _logger.info('Account deleted — clearing local data and logging out');
        await clearAllUserData();
        await logout();
        return null;
      },
    );
  }

  /// Completely clear all user data (account deletion or privacy reset).
  Future<void> clearAllUserData() async {
    try {
      await ref.read(userProvider.notifier).clearUser();

      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      await onboardingRepo.clearPreferences();

      await _analytics.reset();
      _logger.info('All user data and onboarding preferences cleared');
    } catch (e) {
      _logger.warning('Failed to clear user data: $e');
    }
  }

  /// Reset onboarding status (for testing).
  Future<void> resetOnboarding() async {
    try {
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      final result = await onboardingRepo.resetOnboardingStatus();
      result.fold(
        (failure) => _logger.warning(
          'Failed to reset onboarding status: ${failure.message}',
        ),
        (_) {
          _logger.info(
            'Onboarding reset — user will see onboarding on next login',
          );
          // Reflect the reset immediately so the route guard re-enforces onboarding.
          state = state.copyWith(hasCompletedOnboarding: false);
        },
      );
    } catch (e) {
      _logger.warning('Failed to reset onboarding: $e');
    }
  }

  /// Schedules a background onboarding fetch when status is still unknown.
  ///
  /// Called synchronously from the router redirect (fire-and-forget) so
  /// endpoint failures retry on later navigations without blocking transitions.
  void refreshOnboardingStatusIfNeeded() {
    if (!state.isLoggedIn || state.isGuest) return;
    if (state.hasCompletedOnboarding != null) return;
    unawaited(_refreshOnboardingStatus());
  }

  int _bumpAuthEpoch() => ++_authEpoch;

  bool _isAuthEpochCurrent(int epoch) => epoch == _authEpoch;

  /// Stops server pushes for the account signing out. Never throws: the
  /// service swallows backend failures, and building it can throw only where
  /// Firebase is not set up.
  Future<void> _unregisterPushDevice() {
    try {
      return ref.read(pushNotificationServiceProvider).unregisterForSignOut();
    } catch (e) {
      _logger.warning('Push unregister on logout skipped: $e');
      return Future.value();
    }
  }

  void _invalidateAuthSession() {
    _bumpAuthEpoch();
    state = state.copyWith(
      isLoggedIn: false,
      isLoading: false,
      isGuest: false,
      hasCompletedOnboarding: null,
    );
  }

  /// Applies logged-in auth state only when [epoch] still matches — drops stale
  /// continuations from login/restore paths that raced with logout/expiry.
  void _applyAuthenticatedLoginState({
    required int epoch,
    required bool? onboardingStatus,
    required String logMessage,
  }) {
    if (!_isAuthEpochCurrent(epoch)) {
      _logger.debug('Discarding stale authenticated state ($logMessage)');
      return;
    }
    state = state.copyWith(
      isLoggedIn: true,
      isLoading: false,
      isGuest: false,
      hasCompletedOnboarding: onboardingStatus,
      errorMessage: null,
    );
    _logger.info(logMessage);
  }

  Future<void> _refreshOnboardingStatus({bool skipDebounce = false}) async {
    if (!state.isLoggedIn || state.isGuest) return;
    if (state.hasCompletedOnboarding != null) return;
    if (_onboardingFetchInFlight) return;

    if (!skipDebounce &&
        _lastOnboardingRetryAt != null &&
        DateTime.now().difference(_lastOnboardingRetryAt!) <
            _onboardingRetryDebounce) {
      return;
    }

    _onboardingFetchInFlight = true;
    _lastOnboardingRetryAt = DateTime.now();
    final epoch = _authEpoch;

    try {
      final status = await _fetchOnboardingStatusSafe();
      if (!_isAuthEpochCurrent(epoch)) return;
      if (!state.isLoggedIn || state.isGuest) return;
      if (status != null) {
        state = state.copyWith(hasCompletedOnboarding: status);
      }
    } finally {
      _onboardingFetchInFlight = false;
    }
  }

  /// Fetches the onboarding completion flag once, returning null on any error
  /// so callers can retry rather than treating failure as "completed".
  Future<bool?> _fetchOnboardingStatusSafe() async {
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final result = await repo.isOnboardingCompleted();
      return result.fold((failure) {
        _logger.warning(
          'Could not prefetch onboarding status: ${failure.message}',
        );
        return null;
      }, (hasCompleted) => hasCompleted);
    } catch (e) {
      _logger.warning('Could not prefetch onboarding status: $e');
      return null;
    }
  }

  /// Called by the onboarding flow when the user successfully completes
  /// onboarding. Updates the in-state flag so the route guard reflects the
  /// change without a network round-trip.
  void markOnboardingCompleted() {
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);
  AuthAnalytics get _authAnalytics => ref.read(authAnalyticsProvider);

  Future<void> _identifyAuthenticatedUser({
    required String userId,
    required bool isGuest,
    required int epoch,
  }) async {
    _identityEpoch = epoch;
    await _analytics.identify(
      userId: userId,
      properties: {AnalyticsProperties.isGuest: isGuest},
    );
  }

  /// Resets analytics unless the current auth attempt owns its identity.
  ///
  /// Logout and expiry show the login screen before their cleanup finishes,
  /// so a login can identify its user meanwhile; that identity is kept. Any
  /// other identity belongs to a signed-out user or to a login a newer auth
  /// attempt superseded, and is reset. [onlyIfStale] skips the reset when
  /// nothing is identified, for flows that are not a sign-out.
  Future<void> _resetAnalyticsIdentity({bool onlyIfStale = false}) async {
    final owner = _identityEpoch;
    if (owner != null && owner == _authEpoch) return;
    if (onlyIfStale && owner == null) return;
    _identityEpoch = null;
    await _analytics.reset();
  }

  Future<void> _markGuestSession() async {
    await _analytics.setSuperProperties({AnalyticsProperties.isGuest: true});
  }
}
