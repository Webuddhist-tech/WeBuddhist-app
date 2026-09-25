# Force Update Modal Implementation

## Overview

Implements an app-wide, non-dismissible forced-update modal on Android and iOS. When the `upgrader` package detects that a newer version is available on the Play Store / App Store, a blocking dialog is shown over every route and cannot be dismissed — the user must tap "Update now" to be taken to the store. It stays up until the installed version matches the store version. The check only runs in release builds.

The soft, dismissible update banner that previously appeared only on the home screen has been removed; the force modal supersedes it entirely.

---

## Files

| File | Role |
|------|------|
| `lib/core/services/upgrade/app_upgrade_service.dart` | Static wrapper around `upgrader`; exposes `isUpdateAvailable()`, `stateStream` and `openAppStore()` |
| `lib/core/services/upgrade/upgrade_provider.dart` | Riverpod providers: `updateAvailableProvider` (stream), `openAppStoreProvider` |
| `lib/core/services/upgrade/force_update_dialog.dart` | Non-dismissible `AlertDialog` UI |
| `lib/core/services/upgrade/force_update_gate.dart` | Gate widget mounted in `MaterialApp.router`'s `builder`; layers the modal over the app and swallows system back |

---

## Architecture

```
UncontrolledProviderScope
  └─ MaterialApp.router
      └─ builder: ForceUpdateGate          ← watches updateAvailableProvider
          └─ Stack
              ├─ GoRouter Navigator        ← all routes (focus/semantics excluded while blocked)
              ├─ ModalBarrier              ← only while an update is required
              └─ ForceUpdateDialog         ← only while an update is required
```

`ForceUpdateGate` lives above the navigator so it covers every route. The modal is part of the gate's own widget tree, **not** a navigator route.

### Flow

```
App launch
  → ForceUpdateGate watches updateAvailableProvider (StreamProvider)
      → non-release build and debugDisplayAlways == false → emits false, stops
      → AppUpgradeService.initialize()
          → Upgrader fetches store version via Play Store / App Store API
      → emits AppUpgradeService.isUpdateAvailable()
          → debugDisplayAlways || upgrader.isUpdateAvailable() (store > installed)
      → re-emits on every upgrader state change (upgrader refreshes on resume)
  → true → gate shows ModalBarrier + ForceUpdateDialog in its Stack
  → User taps "Update now"
      → AppUpgradeService.openAppStore()
          → launchUrl(AppConfig.appStoreUrl / AppConfig.playStoreUrl)
```

---

## Key Design Decisions

### Why not `showDialog`
An earlier version pushed the dialog with `showDialog(context: rootNavigatorKey.currentContext)`. That creates a *pageless* route on the GoRouter navigator, and GoRouter drops pageless routes whenever it rebuilds its page stack — e.g. the auth redirect right after launch. The modal vanished after a few seconds and the app became usable. Rendering the modal in the gate's `Stack` keeps it independent of navigation.

### Non-dismissibility
- `ModalBarrier(dismissible: false)` — tapping outside the dialog does nothing, and it absorbs all touches meant for the app underneath (including the iOS edge-swipe back gesture).
- **Android back / predictive back:** `PopScope` can't help because the modal isn't a route. The gate is a `WidgetsBindingObserver` registered in `initState` — before the Router below it — so it is offered back events first. While blocked, `didPopRoute` and `handleStartBackGesture` return `true`, consuming them.
- **Back at the root route:** with `android:enableOnBackInvokedCallback="true"`, when the navigator has nothing to pop Flutter tells Android the framework doesn't handle back, and Android finishes the activity without calling `didPopRoute`. While blocked, the gate intercepts `NavigationNotification`s and forces `SystemNavigator.setFrameworkHandlesBack(true)` so back always reaches the observer.
- No "Later" / "Skip" / close button.

### Mandatory for any newer version
`isUpdateAvailable()` uses `upgrader.isUpdateAvailable()` (plain store-vs-installed comparison) instead of `shouldDisplayUpgrade()`, which also applies upgrader's "ignore this version" and "remind later" throttling — irrelevant for a forced update.

### Re-checking
`updateAvailableProvider` is a `StreamProvider` that re-emits on `upgrader.stateStream`. Upgrader refreshes the store version on every resume from background, so a lookup that failed at launch (offline) or a release published mid-session still blocks the user.

### Release builds only
In debug/profile builds the provider emits `false` without contacting the store, so development builds (whose version is often ahead of the store) are never blocked. `debugDisplayAlways` overrides this for testing.

### Opening the store
`openAppStore()` launches the fixed `AppConfig` store URLs with `url_launcher`. `upgrader.sendUserToAppStore()` isn't used: it silently no-ops when the lookup returned no listing URL, and on Android 11+ its `canLaunchUrl` check fails without an `https` `<queries>` entry in the manifest.

### Platform guard
The gate returns the unwrapped child on non-Android/iOS platforms (e.g. macOS) because neither the Play Store nor the App Store is reachable there.

---

## Localization

Three keys added to all ARB files (`app_en.arb`, `app_bo.arb`, `app_zh.arb`):

| Key | English | Tibetan | Chinese |
|-----|---------|---------|---------|
| `force_update_title` | Update required | གསར་བསྒྱུར་དགོས་མཁོ། | 需要更新 |
| `force_update_message` | A new version of the app is available. Please update to continue. | མཉེན་ཆས་ཀྱི་པར་གཞི་གསར་པ་ཞིག་ཡོད་པས། མུ་མཐུད་སྤྱོད་རོགས་གནང་བར་གསར་བསྒྱུར་མཛད་རོགས། | 有新版本可用，請更新後繼續使用。 |
| `force_update_button` | Update now | གསར་བསྒྱུར། | 立即更新 |

Access via `context.l10n.force_update_title` etc.

---

## Testing

To force the modal on every launch without a real store update — including in debug builds — set `debugDisplayAlways = true` in `upgrade_provider.dart`:

```dart
// lib/core/services/upgrade/upgrade_provider.dart
const debugDisplayAlways = true; // revert to false before shipping
```

**Revert to `false` before releasing to production.**

### Checklist
- [ ] Modal appears over splash / login / home on cold start and stays up (logged in and logged out)
- [ ] Android back button / predictive back gesture does nothing while modal is visible, including on `/home`
- [ ] Tapping outside the dialog does nothing
- [ ] "Update now" opens the correct store listing (real device; the iOS Simulator has no App Store)
- [ ] Modal does NOT appear on macOS builds
- [ ] Modal does NOT appear when `debugDisplayAlways = false` and app is up to date
- [ ] Modal does NOT appear in debug builds when `debugDisplayAlways = false`

---

## Caveats

- **Any newer store version is treated as mandatory.** There is no backend-driven `min_supported_version` flag. If you need selective enforcement (e.g. patch versions optional, minor versions forced), add a `min_supported_version` field to the `/props` endpoint and compare against `PackageInfo.version`.
- **Store version detection requires network.** Users who launch offline are not blocked until the next resume with a successful lookup — acceptable behaviour, since they couldn't update anyway.
- **iOS iTunes lookup can lag** up to ~30 minutes after a new release is published. The modal will not appear until the lookup returns the new version.
