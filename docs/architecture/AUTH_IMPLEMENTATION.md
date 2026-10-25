# Authentication Architecture

## Overview

WeBuddhist uses Auth0 (Universal Login via `auth0_flutter`) for sign-in and
sends the Auth0 **access token** (a JWT minted for the API `audience`) as the
bearer to the backend. The ID token is used only client-side, for identity
(the `sub` claim → `currentUserId`).

> Rewritten Oct 2026. The previous version described an `http`-based
> `ApiClient` and ID-token bearer (`getValidIdToken` / `refreshIdToken`); that
> code no longer exists.

---

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                         Flutter Application                       │
│                                                                    │
│  UI (LoginPage, LoginDrawer) ──► AuthNotifier (authProvider)       │
│                                   │  use cases (domain/usecases)   │
│                                   ▼                                │
│                          AuthRepositoryImpl ──► AuthService        │
│                                                  (singleton)       │
│                                                     ▲              │
│  Dio (dioProvider)                                  │              │
│   AuthInterceptor ──► AuthServiceTokenProvider ─────┤              │
│   RetryInterceptor (401 / bearer-less 403) ─────────┘              │
│        │ permanent failure → AuthNotifier.handleSessionExpired()   │
└────────┼───────────────────────────────────────────────────────────┘
         ▼
   Auth0 SDK credentialsManager  ──►  Keychain / Keystore
```

---

## Design Decisions

### 1. Access token as the API bearer

- Login requests `audience: ConfigService.auth0Audience`, so the access token
  is a verifiable JWT. `AuthService.getValidAccessToken()` is the only bearer
  source; ID tokens are never sent to the API.
- Sessions created before the audience was configured hold an **opaque**
  access token that the backend rejects and refresh cannot upgrade.
  `AuthService.isUsableApiAccessToken` + `AuthException(code:
  'opaque_access_token')` treat that as a permanent session loss (forces
  re-login). This is a **transitional migration net**; the backend no longer
  issues opaque tokens to new sessions.

### 2. The credentials manager is the only refresh path

`AuthService._validCredentials()` funnels every caller through Auth0's
`credentialsManager` (`credentials(minTtl: 120)` proactively,
`renewCredentials()` when forced). It is **single-flight**: concurrent callers
share one in-flight call, a forced caller never joins a non-forced read, and a
forced fetch is sequenced *after* any running call so a rotating refresh
token is never consumed twice. Awaiters time out after 20 s. Never call
`_auth0.api.renewCredentials` directly.

### 3. Singleton `AuthService`

`AuthService.instance` owns the single `Auth0` client. `initialize()` is
single-flight and loads config from `ConfigService`.

### 4. Riverpod + use cases

`authProvider` (`StateNotifierProvider<AuthNotifier, AuthState>`, in
`presentation/providers/state_providers.dart`) builds `AuthNotifier` from
use-case providers (`presentation/providers/use_case_providers.dart`).
Profile data is a separate notifier (`userProvider` / `UserNotifier`).

---

## Component Details

### ConfigService (`lib/features/auth/application/config_service.dart`)

Fetches `domain`, `client_id`, `audience` (legacy key `auth0Audience`) from
`GET {BASE_API_URL}/props` (8 s timeout) and caches them in
SharedPreferences, so Auth0 can be built offline. Falls back to
`AUTH0_AUDIENCE` from `.env`. `auth0Scheme` comes from `AUTH0_SCHEME`.

### AuthService (`lib/features/auth/auth_service.dart`)

```dart
Future<void> initialize()
Future<Credentials?> loginWithGoogle()   // connection 'google-oauth2', prompt=select_account
Future<Credentials?> loginWithApple()    // connection 'apple'
Future<Credentials?> loginWithPhone()    // connection 'sms' (Universal Login passwordless)
Future<Credentials?> getCredentials()    // launch restore; minTtl 120 s
Future<String?> getValidAccessToken()    // proactive (request path)
Future<String?> forceRefreshAccessToken()// reactive 401 path; throws on opaque token
Future<String?> getIdTokenForIdentity()
Future<bool> hasValidCredentials()       // false is INDETERMINATE; timeout → true
Future<void> localLogout()               // clear credentials + guest flag + local identity
Future<void> globalLogout()              // also ends the Auth0 web session (unused by UI)
static bool isSessionPermanentlyLost(Object e) // no creds / no refresh token / opaque
static bool isTokenRenewalFailed(Object e)     // RENEW_FAILED
// guest flag: saveGuestMode / continueAsGuest / isGuestMode / clearGuestMode
```

### Network layer (`lib/core/network/`, wired in `lib/core/di/core_providers.dart`)

- `AuthInterceptor` — for paths matched by `ProtectedRoutes.isProtected` or
  `isOptional` (`lib/core/config/protected_routes.dart`) attaches
  `Authorization: Bearer <access token>` from `AuthServiceTokenProvider`
  (which swallows errors → request goes out without a bearer).
- `RetryInterceptor` — on **401**, or **403 without an Authorization header**
  on a protected/optional route (FastAPI `HTTPBearer` answers a missing header
  with 403), queues the request, runs one `forceRefreshAccessToken()`, and
  replays the queue with the new token on a bare Dio. Network errors are
  retried with backoff (opt out with `extra['no_retry']`).
- The library Dio (`libraryDioProvider`) is unauthenticated.

### AuthNotifier (`presentation/providers/auth_notifier.dart`)

```dart
class AuthState {
  final bool isLoggedIn;              // true for guests too
  final bool isLoading;
  final bool isGuest;
  final String? errorMessage;
  final bool? hasCompletedOnboarding; // null = unknown → route guard fails open
}
```

Uses an **auth epoch** (bumped on login/logout/expiry) so stale async
continuations never re-apply a logged-in state.

---

## Security Architecture

### Token Storage

Auth0 `credentialsManager` (iOS Keychain / Android Keystore). The app stores
no tokens in SharedPreferences or `flutter_secure_storage`. SharedPreferences
holds only the guest flag, `currentUserId`, cached profile JSON and the cached
Auth0 config.

### Token Transmission

HTTPS; `Authorization: Bearer` only on protected/optional routes.
`LoggingInterceptor` masks the header (`Bearer ***`).

### Backend auth responses (observed)

- Missing header → **403**
- Invalid / non-JWT bearer → **401**
- JWT-shaped but unverifiable bearer → **500** (backend bug; not retried as auth)

---

## Error Handling Strategy

```
credentials error
   ├─ no credentials / no refresh token / opaque token → permanent
   ├─ RENEW_FAILED
   │    ├─ at launch (getCredentials)   → transient: keep session (likely offline)
   │    └─ on reactive 401 path         → permanent (server answered, so online)
   └─ anything else (IO, timeout)       → transient: keep session
```

Permanent on the request path (and the user is not a guest) →
`RetryInterceptor.onAuthExpired` → `AuthNotifier.handleSessionExpired()`
(flip to logged out, clear local credentials, reset analytics identity). The
router then redirects to `/login` and remembers the pending route.

Login errors: `WebAuthenticationException` (`a0.session.user_cancelled` →
"cancelled") → `AuthException` → `AuthenticationFailure`.

---

## Deployment Considerations

### Environment Variables (`.env.<flavor>`)

```env
BASE_API_URL=...      # also used for GET /props
AUTH0_SCHEME=org.pecha.app            # per flavor
AUTH0_AUDIENCE=...                    # fallback when /props has none
```

Domain and client ID come from `/props`, not `.env`.

### Auth0 Configuration

Native application; Authorization Code + Refresh Token grants; refresh-token
rotation enabled; API audience configured so access tokens are JWTs. Callback
URLs per flavor: see `GOOGLE_LOGIN_FIX.md`.

---

## Login Flow

```
LoginPage / LoginDrawer button
  → AuthNotifier.login(connection: 'google' | 'apple' | 'sms', source:)
      → epoch++ ; isLoading = true
      → LoginUseCase → AuthService._loginWithConnection (Universal Login, audience, offline_access)
      → credentialsManager.storeCredentials
  → _handleSuccessfulLogin
      → clear guest flag
      → currentUserId = id_token.sub ; analytics identify
      → clear auth-scoped HTTP cache
      → prefetch onboarding status + initializeUser()
      → state = logged in (only if epoch unchanged) → router redirect
```

---

## Token Refresh Flow

```
Request to protected route
  → AuthInterceptor → getValidAccessToken()
      → credentialsManager.credentials(minTtl: 120)  // renews only near expiry
  → 401 (or bearer-less 403)?
      → RetryInterceptor queues request; first one calls forceRefreshAccessToken()
          → credentialsManager.renewCredentials()  (single-flight)
          → token opaque? → AuthException(opaque_access_token) → permanent
      → success: replay every queued request with the new bearer
      → permanent failure (non-guest): handleSessionExpired(); fail queue
      → transient failure: fail queue, keep session
```

---

## Logout Flow

`AuthNotifier.logout()` (the only UI logout; `globalLogout` is unused):

```
start push-device unregister (needs the JWT)
→ state = logged out (epoch++) ; clear auth-scoped HTTP cache
→ flush mala counts ; settle pending prayer sends ; await push unregister
→ AuthService.localLogout() (credentials, guest flag, currentUserId, user data)
→ clear userProvider ; clear pending deep-link route
→ cancel scheduled routine notifications ; reset analytics identity
```

The push service also deletes the FCM token on any signed-out snapshot.

---

## State Restoration

```
AuthNotifier constructor → _restoreLoginState() (single-flight)
  → Android fresh install: clear residual credentials
  → InitializeAuthUseCase (ConfigService /props or cache)
  → hasValidCredentials()?
      ├─ yes → getCredentials()
      │        ├─ ok        → currentUserId, identify, prefetch onboarding + user
      │        │              (each step ≤10 s budget) → logged in
      │        ├─ permanent → guest check
      │        └─ transient → keep session logged in (offline); refresh later
      └─ no  → guest flag? → guest : logged out
  → never leaves isLoading = true
Connectivity offline→online → reconcile (refresh user, or re-run restore)
```

---

## Best Practices

1. Get the bearer only via `AuthService.getValidAccessToken()` (normally through
   `AuthInterceptor`); add new authenticated endpoints to `ProtectedRoutes`.
2. Never add a second refresh path; go through `_validCredentials`.
3. Treat `hasValidCredentials() == false` as indeterminate — log out only on
   typed permanent errors.
4. Respect the auth epoch for any async work that writes auth state.
5. Persist `currentUserId` before flipping auth state.

---

## Troubleshooting

### 401 loop
Check the access token is a JWT (audience configured in `/props` / `.env`).
Opaque tokens are converted into a forced re-login.

### Requests go out without a bearer
`AuthServiceTokenProvider` swallows credential errors and returns null; look
for `Failed to get valid access token` in logs. The backend answers 403, which
`RetryInterceptor` treats as an auth failure on protected routes.

### User unexpectedly logged out
Look for `Token refresh failed permanently` / `Session is unrecoverable`
(refresh token revoked, expired or rotated away).

### Login fails with "An unexpected error occurred during login"
Auth0 was never initialised (first launch with `/props` unreachable and no
cached config). Restore re-runs on reconnect.

---

**Last Updated:** October 22, 2026
