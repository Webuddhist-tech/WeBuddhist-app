# Airbridge SDK — Setup & Secrets

## Overview

The app uses [Airbridge](https://www.airbridge.io/) for attribution, install tracking, and re-engagement deep links. The SDK is initialised natively on both platforms using credentials that are **never committed to source control**.

---

## Required credentials

| Variable | Where to find it |
|---|---|
| `AIRBRIDGE_APP_NAME` | Airbridge dashboard → Settings → App Name |
| `AIRBRIDGE_SDK_TOKEN` | Airbridge dashboard → Settings → SDK Token |

Use the same Airbridge app for all environments:

| Flavor | Airbridge app name |
|---|---|
| `dev` | `webuddhist` |
| `staging` | `webuddhist` |
| `prod` | `webuddhist` |

---

## Local development

### iOS

Copy the example config and fill in your values:

```bash
cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig
# Edit Secrets.xcconfig — never commit it
```

`Secrets.xcconfig` is included via `#include? "Secrets.xcconfig"` in every flavor xcconfig file and is listed in `ios/.gitignore`.

### Android

Copy the example and fill in your values:

```bash
cp android/local.properties.example android/local.properties
# Edit local.properties — never commit it
```

`local.properties` is listed in `android/.gitignore`.

---

## CI / Codemagic

Set the following as **secure environment variables** (not visible in build logs):

```
AIRBRIDGE_APP_NAME=webuddhist
AIRBRIDGE_SDK_TOKEN=<prod token from dashboard>
```

Codemagic pre-build script (before `flutter build ipa`):

```bash
./ios/scripts/prepare_ci_secrets.sh
```

- **Android:** `build.gradle.kts` reads `AIRBRIDGE_APP_NAME` and `AIRBRIDGE_SDK_TOKEN` from the environment first, then falls back to `android/local.properties`. No extra steps required.
- **iOS:** `AIRBRIDGE_APP_NAME` is set per flavor in `ios/Flutter/*-release.xcconfig` (not secret). For `AIRBRIDGE_SDK_TOKEN`, run `ios/scripts/prepare_ci_secrets.sh` **before** `flutter build ipa` in CI, or copy `Secrets.xcconfig` locally for development.

---

## Airbridge dashboard configuration

Before the first production build, verify these settings in the [Airbridge dashboard](https://dashboard.airbridge.io/):

1. **Android URI scheme:** `webuddhist`
2. **iOS URI scheme:** `webuddhist`
3. **Android package name:** `org.pecha.app`
4. **iOS bundle ID:** `org.pecha.app`
5. **Tracking link domain:** `join.webuddhist.com` (custom domain)
6. **App Store Connect ID:** confirm the numeric App Store ID for `org.pecha.app`

---

## App-side deep-link handling

Two independent entry points feed `DeepLinkRouter` (`lib/core/deep_linking/deep_link_router.dart`):

| Source | Wiring | Links handled |
|---|---|---|
| Airbridge SDK | `Airbridge.setOnDeeplinkReceived` in `lib/main.dart` → `AirbridgeDeepLinkService` (`lib/core/services/airbridge_deep_link_service.dart`) | `webuddhist://…` scheme hosts (`home`, `practice`, `more`, `profile`, `notifications`), `join.webuddhist.com`, `*.airbridge.io`, `*.abr.ge` (tracking links land on Home) |
| OS App/Universal Links | `AppLinksDeepLinkService` (`lib/core/deep_linking/app_links_deep_link_service.dart`, `app_links` package) | First-party `https://webuddhist.com/open/...` links (series, reader, plan, group, events, group-accumulator, mala, timer, poem, more) |

Both services buffer a link that arrives before the router exists and dispatch
it once `MyApp` registers the router (post-frame). Share URLs are built by
`lib/core/deep_linking/deep_link_url_builder.dart`.

---

## Server-side verification files

These must be hosted externally (not in this repo) before App Links / Universal Links will verify:

| File | Hosted at |
|---|---|
| `apple-app-site-association` | `https://join.webuddhist.com/.well-known/apple-app-site-association` |
| `apple-app-site-association` | `https://webuddhist.airbridge.io/.well-known/apple-app-site-association` (Airbridge hosts this) |
| `apple-app-site-association` | `https://webuddhist.abr.ge/.well-known/apple-app-site-association` (Airbridge hosts this) |
| `assetlinks.json` | `https://join.webuddhist.com/.well-known/assetlinks.json` |
| `apple-app-site-association` / `assetlinks.json` | `https://webuddhist.com/.well-known/…` (first-party `/open/...` links; `applinks:webuddhist.com` is in the entitlements) |

For `assetlinks.json`, include the **release signing certificate SHA-256** for `org.pecha.app`. Retrieve it with:

```bash
keytool -J-Duser.language=en -list -v -keystore <your-release.keystore> -alias <key-alias>
```

---

## Pre-merge / pre-release checklist

- [ ] Prod iOS build succeeds with `AIRBRIDGE_APP_NAME=webuddhist` in CI; generated `Runner.entitlements` contains `applinks:webuddhist.airbridge.io` and `applinks:webuddhist.abr.ge`
- [ ] Prod Android release build contains correct `AIRBRIDGE_APP_NAME` and `AIRBRIDGE_SDK_TOKEN` in `BuildConfig`; App Link intent filters compile without errors
- [ ] Share sheet shows `https://join.webuddhist.com/get-app`
- [ ] Tap tracking link on device with prod build → app opens; Airbridge dashboard shows open/re-engagement event
- [ ] Deferred install: uninstall → tap link → install from store → first open attributed in Airbridge dashboard
- [ ] Dev flavor uses `webuddhist` credentials and expected development metadata is present if events need to be separated from production
