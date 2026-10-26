# Guest Mode Persistence - Technical Documentation

## Overview

This document describes the implementation of persistent guest mode in the Flutter Pecha app, allowing users to browse as guests without repeated login prompts across app sessions.

---

## Architecture

### High-Level Flow

```
App Launch
    ↓
AuthNotifier Constructor (isLoading: true)
    ↓
_restoreLoginState()
    ↓
├─ Check Valid Credentials
│  ├─ Yes → Restore Authenticated State
│  └─ No → Continue
│
├─ Check Guest Mode (SharedPreferences)
│  ├─ Yes → Restore Guest State
│  └─ No → Show Login
│
└─ Router Redirect Logic
   ├─ isLoading: true → /splash
   └─ isLoading: false → Route based on auth state
```

---

## Implementation Details

### 1. Guest Mode Storage

**Location:** `lib/features/auth/auth_service.dart`

**Storage Mechanism:** SharedPreferences

**Key:** `is_guest_mode` (boolean)

#### Methods

```dart
/// Save guest mode preference to SharedPreferences
Future<void> saveGuestMode() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_guestModeKey, true);
}

/// Check if user previously chose guest mode
Future<bool> isGuestMode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_guestModeKey) ?? false;
}

/// Clear guest mode state (called on login or logout)
Future<void> clearGuestMode() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_guestModeKey);
}
```

**Why SharedPreferences?**

- Simple boolean value
- Persistent across app sessions
- Platform-agnostic
- Fast access
- No security concerns (public state)

---

### 2. Auth State Management

**Location:** `lib/features/auth/presentation/providers/auth_notifier.dart` (`AuthNotifier`, exposed as `authProvider` in `presentation/providers/state_providers.dart`). The notifier talks to `AuthService` only through use cases (`ContinueAsGuestUseCase`, `IsGuestModeUseCase`, `ClearGuestModeAndOnboardingUseCase`, `LogoutUseCase`, …).

#### AuthState Properties

`lib/features/auth/presentation/state/auth_state.dart`:

```dart
class AuthState {
  final bool isLoggedIn;              // true for BOTH authenticated users and guests
  final bool isLoading;               // during launch restore / login
  final bool isGuest;                 // distinguishes guest from authenticated
  final String? errorMessage;
  final bool? hasCompletedOnboarding; // null = unknown; authenticated users only
}
```

There is no `userId` / `userProfile` on `AuthState`: the profile lives in
`userProvider` (`UserNotifier`), and the signed-in user's id is persisted under
`StorageKeys.currentUserId`.

#### State Restoration Logic (summary)

`_restoreLoginState()` (single-flight, also re-run on reconnect when the app
launched offline into guest/logged-out):

1. Android fresh install only: clear any residual credentials.
2. `InitializeAuthUseCase` (loads Auth0 config from `/props`, cached for offline).
3. `hasValidCredentials()` →
   - **yes** → `_restoreCredentials()`: fetch credentials; on success persist
     `currentUserId`, prefetch onboarding status + profile, then flip to
     authenticated. A *transient* failure keeps the session (offline-tolerant);
     only a *permanent* failure (`AuthenticationFailure`) falls through to the
     guest check.
   - **no** → `_checkGuestMode()`: `is_guest_mode` true → guest state, else logged out.
4. Anything unresolved in `finally` → logged-out state (never leaves the splash up).

#### State Transitions

- **Choosing guest mode:** `AuthNotifier.continueAsGuest(source:)` persists the
  flag via `AuthService.continueAsGuest()` and sets `isLoggedIn: true, isGuest: true`.
- **Guest → authenticated:** `AuthNotifier.login(connection:)` → on success
  `_handleSuccessfulLogin()` clears the guest flag *before* the state flips,
  stores `currentUserId`, prefetches onboarding + profile, then sets
  `isLoggedIn: true, isGuest: false`.
- **Logout (any mode):** `AuthNotifier.logout()` → `AuthService.localLogout()`
  clears Auth0 credentials **and** the guest flag (plus `currentUserId` /
  cached user data), and the state becomes logged out.
- A permanent token-renewal failure is **not** applied to guests: the
  `RetryInterceptor` checks `isGuestMode()` before calling `handleSessionExpired()`.

---

### 3. Router Integration

**Location:** `lib/core/config/router/route_guard.dart` (`RouteGuard.redirect`),
wired in `lib/core/config/router/app_router.dart`; route lists in
`lib/core/config/router/app_routes.dart`.

#### Key Design Decision

Guests have `isLoggedIn: true`, but the guard **does** distinguish them:

- `isLoading` → `/splash`.
- Authenticated → onboarding enforcement + pending-route restore.
- **Guest** (`_handleGuest`) → `/login`, `/onboarding`, `/splash` redirect to
  `/home`; any route not in `AppRoutes.guestAccessibleRoutes` (prefix match)
  redirects to `/home`.
- Logged out → public routes only; everything else redirects to `/login`
  (saving the pending route).

Because guests are bounced off `/login`, in-app sign-in for guests goes through
the `LoginDrawer` bottom sheet (`lib/features/auth/presentation/widgets/login_drawer.dart`),
not a navigation to `/login`. Feature-level gating (e.g. "sign in to join a
group") also uses `LoginDrawer`.

---

### 4. Guest Profile UI

The old `ProfilePage` (`lib/features/auth/presentation/screens/profile_page.dart`)
still contains a guest variant but is **not referenced by any route** — and its
"Sign In" button does `context.go('/login')`, which the guard redirects back to
`/home` for guests. The live guest experience is the Me tab plus `LoginDrawer`
prompts.

---

## State Diagram

```
┌─────────────────┐
│   App Launch    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Auth Loading   │ isLoading: true
│ (/splash route) │ isLoggedIn: false
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│  Check Credentials          │
├─────────────────────────────┤
│ Has Valid Credentials?      │
│  ├─ Yes → Authenticated     │
│  └─ No  → Check Guest Mode  │
└────────┬────────────────────┘
         │
         ├─── Yes ──────────────────┐
         │                          │
         ▼                          ▼
┌────────────────┐        ┌────────────────┐
│ Authenticated  │        │  Guest Mode    │
│ State          │        │  State         │
├────────────────┤        ├────────────────┤
│ isLoggedIn: T  │        │ isLoggedIn: T  │
│ isGuest: F     │        │ isGuest: T     │
└────────┬───────┘        └────────┬───────┘
         │                         │
         └──────────┬──────────────┘
                    │
                    ▼
            ┌───────────────┐
            │  Home Screen  │
            └───────────────┘

         No Credentials & No Guest Mode
                    │
                    ▼
            ┌───────────────┐
            │  Login Page   │
            └───────────────┘
```

---

## Testing Strategy

### Unit Tests

See `test/` for the current `AuthNotifier` tests. `AuthNotifier` is constructed
with use cases + `ref` (not an `AuthService`), so tests override the use-case
providers. Cover: guest flag persisted/cleared, guest restored on relaunch,
guest not logged out by a permanent token-renewal failure.

### Manual Test Scenarios

1. **First Launch as Guest**

   - Open app → Tap "Continue as Guest" → Close app → Reopen
   - Expected: Home screen (guest mode)

2. **Guest to Authenticated**

   - Open as guest → trigger a `LoginDrawer` (e.g. Me tab sign-in) → Authenticate → Close app → Reopen
   - Expected: Home screen (authenticated)

3. **Logout from Guest**

   - Open as guest → Navigate to settings → Tap "Logout"
   - Expected: Login page shown


---

## Performance Considerations

### SharedPreferences Access

- **Read:** ~1-2ms (async but fast)
- **Write:** ~5-10ms (async, non-blocking)
- **Impact:** Negligible - happens once at app startup

### Auth State Initialization

- Runs asynchronously in constructor
- Native splash visible during initialization
- No blocking of UI thread

### Memory Footprint

- Single boolean value in SharedPreferences
- Minimal impact on app memory

---

## Security Considerations

### Why Guest Mode is Safe

1. **No Sensitive Data:** Only stores a boolean flag
2. **Public State:** Guest status is not private information
3. **Easy Reset:** User can logout to clear state
4. **No Credentials:** No auth tokens or passwords stored

### What Guest Users Cannot Do

- Access personalized data
- Sync across devices
- Save preferences permanently
- Access user-specific features

---

## Future Enhancements

### Possible Improvements

1. **Guest Data Migration**

   - Allow guests to keep their progress when signing in
   - Sync guest bookmarks to authenticated account

2. **Guest Feature Tracking**

   - Analytics on guest user behavior
   - Conversion rate from guest to authenticated

3. **Time-Limited Guest Mode**

   - Prompt sign-in after X days of guest usage
   - Progressive nudges to authenticate

4. **Guest Mode Customization**
   - Allow some preferences in guest mode
   - Theme preferences, language, etc.

---

## Troubleshooting

### Guest Mode Not Persisting

**Symptoms:** Guest users see login screen on restart

**Check:**

1. SharedPreferences write succeeding?
2. App has storage permissions?
3. `saveGuestMode()` being called?

**Debug:**

```dart
final prefs = await SharedPreferences.getInstance();
print('Guest mode: ${prefs.getBool('is_guest_mode')}');
```

### Guest Bounced to Home

**Symptoms:** Navigating to a screen as a guest lands on Home

**Check:** the route (or a prefix of it) is listed in
`AppRoutes.guestAccessibleRoutes`; `/login` is never reachable for guests by design.

---

## References

- [SharedPreferences Package](https://pub.dev/packages/shared_preferences)
- [Flutter State Management Best Practices](https://docs.flutter.dev/data-and-backend/state-mgmt)
- [Material Design - Guest Access Patterns](https://material.io)

---

**Last Updated:** October 22, 2026 (synced with current `AuthNotifier` / `RouteGuard`)  
**Version:** 1.0  
**Author:** Development Team
