import 'dart:async';
import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/application/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  late final Auth0 _auth0;
  final _logger = AppLogger('AuthService');

  bool _isInitialized = false;

  /// Minimum lifetime (seconds) a token must have left before we proactively
  /// renew it through the credentials manager. Matches the 2-minute buffer in
  /// [isJwtExpired].
  static const int _kMinTokenTtlSeconds = 120;

  /// Ceiling for awaiters of a native credentials call; the call itself runs on.
  static const Duration _kCredentialsTimeout = Duration(seconds: 20);

  // SharedPreferences key for guest mode
  static const String _guestModeKey = 'is_guest_mode';

  /// [AuthException.code] used when the access token is opaque (not a JWT) and
  /// therefore unusable as our API bearer. Recognised by
  /// [isSessionPermanentlyLost] so the session is treated as terminal.
  static const String opaqueAccessTokenCode = 'opaque_access_token';

  /// Single-flight guard so concurrent proactive/reactive callers share one
  /// in-flight renewal instead of each hitting the credentials manager.
  Future<Credentials>? _inflightCredentials;

  /// Whether [_inflightCredentials] is a *forced* renewal. A forced caller may
  /// only share an in-flight call that is itself forced — otherwise it might
  /// receive a plain cache read (the very token the server just rejected).
  bool _inflightIsForced = false;

  /// A call whose awaiters timed out; the next fetch waits (bounded) behind it.
  Future<Credentials>? _staleCredentials;

  /// In-flight [initialize], shared so concurrent callers never double-assign [_auth0].
  Future<void>? _initializing;

  Future<void> initialize() {
    if (_isInitialized) return Future.value();
    return _initializing ??= _doInitialize().whenComplete(
      () => _initializing = null,
    );
  }

  Future<void> _doInitialize() async {
    // load config from config service
    final config = ConfigService.instance;
    await config.loadConfig();
    // Initialize Auth0
    _auth0 = Auth0(config.auth0Domain!, config.auth0ClientId!);

    _isInitialized = true;
  }

  // Common login method
  Future<Credentials?> _loginWithConnection(
    String connection, [
    Map<String, String>? additionalParameters,
  ]) async {
    try {
      final parameters = {"connection": connection};
      if (additionalParameters != null) {
        parameters.addAll(additionalParameters);
      }

      final credentials = await _auth0
          .webAuthentication(
            scheme: ConfigService.instance.auth0Scheme ?? 'org.pecha.app',
          )
          .login(
            useHTTPS: defaultTargetPlatform != TargetPlatform.macOS,
            // Requesting the API audience yields a verifiable JWT access token
            // (instead of an opaque /userinfo token). This access token — not
            // the ID token — is the bearer we send to our backend.
            audience: ConfigService.instance.auth0Audience,
            parameters: parameters,
            scopes: {"openid", "profile", "email", "offline_access"},
          );

      // Store credentials in the credentials manager
      await _auth0.credentialsManager.storeCredentials(credentials);
      _logger.info('Credentials stored successfully');

      // VERIFY STORAGE IMMEDIATELY AFTER STORING
      final verified = await _auth0.credentialsManager.hasValidCredentials();
      _logger.debug('Verification after store: $verified');

      _logger.info('Login successful for connection: $connection');
      return credentials;
    } on WebAuthenticationException catch (e) {
      _logger.warning('WebAuth error for $connection: ${e.message}');
      if (e.code == 'a0.session.user_cancelled') {
        throw AuthException('Login was cancelled by user', code: e.code);
      }
      throw AuthException('Login failed: ${e.message}', code: e.code);
    } catch (e) {
      _logger.error('Unexpected login error for $connection', e);
      throw AuthException('An unexpected error occurred during login');
    }
  }

  Future<Credentials?> getCredentials() async {
    try {
      // Same renewal threshold as the request path (_validCredentials) so the
      // launch/restore path and the API path never disagree on when to renew —
      // and a low threshold keeps a safe margin below any configured Auth0
      // access-token lifetime (the SDK throws when minTtl exceeds it).
      return await _auth0.credentialsManager
          .credentials(minTtl: _kMinTokenTtlSeconds)
          .timeout(_kCredentialsTimeout);
    } on CredentialsManagerException catch (e) {
      // Surface the SDK code at the boundary for diagnostics, then rethrow so
      // the repository maps it: no-credentials / no-refresh-token / opaque →
      // AuthenticationFailure (re-login), everything else (incl. RENEW_FAILED,
      // which at launch is almost always offline) → NetworkFailure (keep the
      // session and renew on the next request). See
      // [AuthRepositoryImpl._credentialFailure] and [isSessionPermanentlyLost].
      _logger.warning('credentials() failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

  // Login with Google
  Future<Credentials?> loginWithGoogle() async {
    return _loginWithConnection('google-oauth2', {'prompt': 'select_account'});
  }

  // Login with Apple
  Future<Credentials?> loginWithApple() async {
    return _loginWithConnection('apple');
  }

  /// Login with a phone number via Auth0's passwordless SMS connection.
  ///
  /// Runs through Universal Login rather than the embedded
  /// `api.startPasswordlessWithPhoneNumber` / `api.loginWithSmsCode` pair, so
  /// phone entry, OTP entry, resend throttling and bot detection are all
  /// handled by the hosted page — and, critically, this path already requests
  /// the API `audience` and persists to the credentials manager. The embedded
  /// API does neither by default.
  Future<Credentials?> loginWithPhone() async {
    return _loginWithConnection('sms');
  }

  // Local logout - clears credentials from device only
  Future<void> localLogout() async {
    try {
      await _auth0.credentialsManager.clearCredentials();
      await _clearLocalIdentity();
      _logger.info('Local logout successful');
    } catch (e) {
      _logger.error('Logout failed', e);
    }
  }

  // Global logout - clears credentials from device and server
  Future<void> globalLogout() async {
    try {
      await _auth0
          .webAuthentication(
            scheme: ConfigService.instance.auth0Scheme ?? 'org.pecha.app',
          )
          .logout(useHTTPS: defaultTargetPlatform != TargetPlatform.macOS);
      await _auth0.credentialsManager.clearCredentials();
      await _clearLocalIdentity();
      _logger.info('Global logout successful');
    } catch (e) {
      _logger.error('Logout failed', e);
    }
  }

  /// Clears every local identity marker so a subsequent reinstall/login can't
  /// read stale identity. Auth0 tokens (access/refresh/id) are NOT handled here
  /// — the credentials manager owns that storage and is cleared via
  /// `clearCredentials()`; we deliberately do not touch `flutter_secure_storage`
  /// (it stores no tokens in this app).
  Future<void> _clearLocalIdentity() async {
    await clearGuestMode();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.currentUserId);
      await prefs.remove(StorageKeys.userData);
    } catch (e) {
      _logger.warning('Failed to clear local identity markers: $e');
    }
  }

  /// Decode a JWT and report whether it is expired (or within [bufferSeconds]
  /// of expiry). Returns true on any parse failure (treat as expired).
  ///
  /// Token-agnostic: works for both access and ID tokens.
  bool isJwtExpired(String jwt, {int bufferSeconds = _kMinTokenTtlSeconds}) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      final exp = (claims['exp'] as num?)?.toInt();
      if (exp == null) return true;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

      return DateTime.now().isAfter(
        expiryDate.subtract(Duration(seconds: bufferSeconds)),
      );
    } catch (e) {
      _logger.warning('Failed to parse jwt exp: $e');
      return true;
    }
  }

  /// Decode and check if an ID token is expired. Retained for ID-token
  /// (identity) call sites; delegates to the token-agnostic [isJwtExpired].
  bool isIdTokenExpired(String idToken) => isJwtExpired(idToken);

  /// Seconds of remaining lifetime for [jwt]; 0 if expired/unparseable.
  int jwtRemainingTtlSeconds(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return 0;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      final exp = (claims['exp'] as num?)?.toInt();
      if (exp == null) return 0;
      final secs = exp - (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      return secs > 0 ? secs : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Returns valid credentials, renewing via the credentials manager when the
  /// access token is within [_kMinTokenTtlSeconds] of expiry. All concurrent
  /// callers (proactive + reactive, across both Dio clients) share one
  /// in-flight renewal.
  ///
  /// The credentials manager is the **single** refresh path: it serializes its
  /// own renewals and stores the rotated refresh token atomically, so a
  /// single-use refresh token can never be consumed by two racing callers.
  /// Do not call `_auth0.api.renewCredentials` directly anywhere.
  Future<Credentials> _validCredentials({bool force = false}) {
    final inflight = _inflightCredentials;
    // Share the in-flight renewal when it satisfies us: a non-forced caller
    // accepts any in-flight call; a forced caller only accepts one that is
    // itself forced. A forced caller must NOT join a non-forced cache read, or
    // it could be handed back the token the server just rejected.
    if (inflight != null && (!force || _inflightIsForced)) {
      return inflight.timeout(_kCredentialsTimeout);
    }

    // We need a (possibly forced) renewal that no in-flight call provides. If a
    // non-forced call is currently running, sequence our forced fetch *after*
    // it settles rather than racing it, so the credentials manager stays the
    // single, rotation-safe refresh path (one renewal in flight at a time).
    final previous = inflight ?? _staleCredentials;
    // `tracked` IS the future we store and return, so its error is delivered to
    // the awaiting caller (handled). Do NOT drop a separate `whenComplete`
    // future here — its error would have no listener and surface as an
    // unhandled async exception when a renewal fails.
    late final Future<Credentials> tracked;
    tracked = _runCredentialsFetch(force: force, after: previous).whenComplete(
      () {
        // Only clear if we're still the current in-flight; a later forced call
        // may have already superseded us.
        if (identical(_inflightCredentials, tracked)) {
          _inflightCredentials = null;
          _inflightIsForced = false;
        }
        if (identical(_staleCredentials, tracked)) _staleCredentials = null;
      },
    );
    _inflightCredentials = tracked;
    _inflightIsForced = force;
    return tracked.timeout(
      _kCredentialsTimeout,
      onTimeout: () {
        // Release the slot so later callers retry instead of queueing forever.
        if (identical(_inflightCredentials, tracked)) {
          _inflightCredentials = null;
          _inflightIsForced = false;
          _staleCredentials = tracked;
        }
        throw TimeoutException('Credentials call timed out', _kCredentialsTimeout);
      },
    );
  }

  Future<Credentials> _runCredentialsFetch({
    required bool force,
    Future<Credentials>? after,
  }) async {
    if (after != null) {
      // Let the prior renewal finish (ignore its result/error) so two renewals
      // never hit the rotating refresh token concurrently. Bounded, so a stuck
      // call cannot block every later renewal.
      try {
        await after.timeout(_kCredentialsTimeout);
      } catch (_) {
        // Ignored — we proceed to our own fetch regardless.
      }
    }
    return _fetchCredentials(force: force);
  }

  Future<Credentials> _fetchCredentials({required bool force}) async {
    final Credentials creds;
    if (force) {
      // Forced (reactive 401) renewal. `renewCredentials()` unconditionally
      // fetches a fresh credential set and stores the rotated refresh token
      // atomically, so it renews even when the current access token still has
      // lifetime left — and it stays inside the credentials manager (the
      // single, rotation-safe refresh path).
      //
      // We previously forced via `credentials(minTtl: remaining + buffer)`, but
      // the SDK rejects a `minTtl` greater than the token's configured lifetime
      // ("minTTL requested … is greater than the lifetime of the renewed access
      // token"); and capping `minTtl` at that lifetime is satisfied by a fresh
      // token, so it would not force a renewal at all.
      creds = await _auth0.credentialsManager.renewCredentials();
    } else {
      // Proactive: return the cached token, renewing only when it is within the
      // skew buffer of expiry.
      creds = await _auth0.credentialsManager.credentials(
        minTtl: _kMinTokenTtlSeconds,
      );
    }
    return creds;
  }

  /// API bearer. Proactive renewal happens inside the credentials manager when
  /// the access token is within [_kMinTokenTtlSeconds] of expiry.
  Future<String?> getValidAccessToken() async {
    final creds = await _validCredentials();
    return creds.accessToken;
  }

  /// Whether [token] is usable as our API bearer. The backend verifies a JWT
  /// access token (minted only when the API `audience` is requested at login),
  /// so an opaque `/userinfo` token — issued for sessions created before the
  /// audience was configured — is not a JWT and can never authenticate API
  /// calls. Such sessions cannot be salvaged by refresh (the refresh token is
  /// not bound to the audience), so the only resolution is to sign in again.
  static bool isUsableApiAccessToken(String token) =>
      token.split('.').length == 3;

  /// Reactive 401 path: force a renewal and return a fresh access token.
  ///
  /// Throws an [AuthException] with [opaqueAccessTokenCode] when the renewed
  /// token is still opaque (a pre-audience session). That surfaces as a
  /// permanent session loss so the caller redirects to login, where a fresh
  /// audience-scoped login mints a verifiable JWT.
  Future<String?> forceRefreshAccessToken() async {
    final creds = await _validCredentials(force: true);
    final accessToken = creds.accessToken;
    if (!isUsableApiAccessToken(accessToken)) {
      _logger.warning(
        'Access token is opaque (not a JWT) — pre-audience session cannot be '
        'refreshed into an API bearer; re-authentication required.',
      );
      throw AuthException(
        'Opaque access token; re-authentication required',
        code: opaqueAccessTokenCode,
      );
    }
    return accessToken;
  }

  /// Identity only (client-side). Profile claims (email/name/sub) live in the
  /// ID token. Used at login/restore for identity — NEVER as an API bearer.
  Future<String?> getIdTokenForIdentity() async {
    final creds = await _validCredentials();
    return creds.idToken;
  }

  /// Whether [error] from a credentials operation means the session is truly
  /// gone and the user must sign in again — as opposed to a transient/offline
  /// failure we should tolerate (keep the user signed in and renew later).
  ///
  /// Only a missing credential, a missing refresh token, or an opaque
  /// (non-JWT) access token is treated as permanent. `RENEW_FAILED` is treated
  /// as transient: at app open it is almost always a connectivity problem, and
  /// wiping a valid session for that is the bug we are fixing.
  static bool isSessionPermanentlyLost(Object error) {
    if (error is AuthException && error.code == opaqueAccessTokenCode) {
      return true;
    }
    return error is CredentialsManagerException &&
        (error.isNoCredentialsFound || error.isNoRefreshTokenFound);
  }

  /// Whether [error] is a failed token *renewal* (`RENEW_FAILED` — the refresh
  /// token could not be exchanged).
  ///
  /// Deliberately separate from [isSessionPermanentlyLost]: at **app open** a
  /// renewal failure is usually transient/offline and must NOT wipe the
  /// session. But in the **reactive 401 path** the server just answered us, so
  /// we are provably online — a renewal failure there means the refresh token
  /// is rejected (revoked/expired/rotated) and the session is terminal.
  /// Without this, a dead refresh token traps the user in an endless 401 loop
  /// with no prompt to re-authenticate.
  static bool isTokenRenewalFailed(Object error) =>
      error is CredentialsManagerException && error.isTokenRenewFailed;

  /// Check if credentials exist and are valid.
  ///
  /// A `false` result is INDETERMINATE, not proof the session is gone: any
  /// exception from the credentials manager (transient keystore/plugin IO)
  /// is also collapsed to `false`. Never use `false` here as grounds for
  /// logging the user out — terminal decisions need the typed errors from an
  /// actual credentials/renewal attempt (see [isSessionPermanentlyLost]).
  Future<bool> hasValidCredentials() async {
    try {
      return await _auth0.credentialsManager.hasValidCredentials().timeout(
        const Duration(seconds: 10),
      );
    } on TimeoutException {
      // Indeterminate: let credentials() make the terminal call, not a logout.
      _logger.warning('Credentials check timed out — assuming a session');
      return true;
    } catch (e) {
      _logger.warning('Error checking valid credentials: $e');
      return false;
    }
  }

  // Guest Mode Persistence Methods

  /// Save guest mode preference to SharedPreferences
  Future<void> saveGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, true);
      _logger.info('Guest mode saved to preferences');
    } catch (e) {
      _logger.warning('Failed to save guest mode: $e');
    }
  }

  /// Check if user previously chose guest mode
  Future<bool> isGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(_guestModeKey) ?? false;
      return isGuest;
    } catch (e) {
      _logger.warning('Failed to check guest mode: $e');
      return false;
    }
  }

  /// Clear guest mode state (called when user logs in or logs out)
  Future<void> clearGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestModeKey);
      _logger.info('Guest mode cleared from preferences');
    } catch (e) {
      _logger.warning('Failed to clear guest mode: $e');
    }
  }

  /// Continue as guest mode
  Future<void> continueAsGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, true);
      _logger.info('Guest mode saved to preferences');
    } catch (e) {
      _logger.warning('Failed to save guest mode: $e');
    }
  }
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message';
}