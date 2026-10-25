# WeBuddhist App

A Flutter app (package `flutter_pecha`) for learning, practising and sharing
Buddhist teachings: a text reader, practice plans, chants, mala and timer
tools, a Tibetan calendar, and community groups with chat and events.

Targets: Android and iOS (shipped), macOS (runs locally). Bundle / application
IDs: `org.pecha.app` (prod), `org.pecha.app.staging`, `org.pecha.app.dev`.

## 🛠 Features

Bottom navigation: **Home · Practice · Connect · Me**. Each module lives in
`lib/features/<name>/` and most have a `doc/README.md`
(index: [`lib/features/doc/README.md`](lib/features/doc/README.md)).

| Area | Feature modules |
| --- | --- |
| Home & shell | `home` (dashboard, verse of the day, streak, main navigation shell), `calendar` (Tibetan lunar calendar, moon phases) |
| Reading | `reader` (segmented reader, dual-version layout, search, commentary), `texts` (reader-facing text contracts), `library` (WeBuddhist Library API client: texts, TOC, editions, alignments, chant list), `recitation` (catalogue + "My Recitations"), `poems` (story-style poems viewer) |
| Practice | `practice` (Practice tab, daily routine), `plans` (enrol + track practice plans), `mala` (prayer-bead counter, personal + group accumulation), `timer` (meditation timers, lock-screen Live Activity) |
| Community | `connect` (Connect tab: feed, events, group discovery), `group_profile` (group pages, events, members, collective accumulators, recitation collections), `group_chat` (group + direct chat over WebSocket, reactions, prayer intentions, moderation) |
| Account & settings | `auth` (Auth0 login, guest mode, profile), `onboarding`, `more` (Me tab + settings), `feedback` (help / contact form, forwarded by the backend) |
| Notifications | `notifications` (local scheduled reminders), `push_notifications` (Firebase Cloud Messaging) |
| Placeholders | `explore`, `learn` (not in navigation) |

Cross-cutting: light/dark themes, six UI languages (`en`, `bo`, `zh`, `hi`,
`mn`, `ne`) with over-the-air text via Tolgee, PostHog + Microsoft Clarity
analytics, Firebase Crashlytics, Airbridge attribution and deep links, and a
forced-update prompt (`upgrader`).

## 📦 Getting Started

### Requirements
- Flutter **3.35.7** (stable) — the version CI pins in `.github/workflows/*.yml`
  (Dart SDK constraint in `pubspec.yaml`: `^3.7.2`)
- Xcode (iOS/macOS) and Android Studio / JDK 17 (Android)

### 1. Clone the repository
```sh
git clone https://github.com/Webuddhist-tech/WeBuddhist-app.git
cd WeBuddhist-app
```

### 2. Install dependencies
```sh
flutter pub get
```

### 3. Environment setup
Each flavor entrypoint loads its own dotenv file (`lib/main_<flavor>.dart` →
`.env.<flavor>`). All three files are declared as assets in `pubspec.yaml`,
so **all three must exist** before any build, even if you only run one flavor:
```sh
cp .env.example .env.dev
cp .env.example .env.staging
cp .env.example .env.prod
```
Edit each file with the values for that environment. Keys read by the app
(see `lib/env.dart` and `lib/features/auth/application/config_service.dart`):

| Variable | Required | Description |
|----------|----------|-------------|
| `BASE_API_URL` | yes | WeBuddhist backend base URL |
| `ENVIRONMENT` | yes | `development` / `staging` / `production` |
| `LIBRARY_API_URL` | no | Library (texts) API; defaults to `https://library.webuddhist.com` |
| `LIBRARY_CHANTS_TAG_ID` | yes for chants | Library tag that marks chants |
| `AUTH0_SCHEME` | yes | Auth0 callback scheme (`org.pecha.app`, `.dev`, `.staging`) |
| `AUTH0_DOMAIN` / `AUTH0_CLIENT_ID` / `AUTH0_AUDIENCE` | no | Fallbacks; normally fetched from the backend `/props` endpoint |
| `LOCATIONIQ_TOKEN` | no | Event venue search; empty hides the search box |

> The `.env.*` files are bundled into the app as assets and can be extracted
> from any build. Put **only client-safe values** in them — never server
> secrets such as webhook URLs or write API keys.

Native secrets (Airbridge SDK token etc.) live outside dotenv — copy
`ios/Flutter/Secrets.xcconfig.example` and `android/local.properties.example`;
see [Airbridge setup](docs/implementation/AIRBRIDGE_SETUP.md).

#### Analytics (optional)

Analytics keys are optional; when absent the SDK stays off. Each flavor should
use its own PostHog project token:

| Variable | Description |
|----------|-------------|
| `POSTHOG_API_KEY` | PostHog project API key for this flavor |
| `POSTHOG_HOST` | PostHog ingest host (default `https://us.i.posthog.com`) |
| `POSTHOG_ENABLED` | Set to `false` to disable analytics locally |

Screen views (`$screen`) come from the route observers on both the root and
the tab-shell navigator, so every named route is tracked. Product events are
declared once in `lib/core/analytics/analytics_events.dart` and follow the
team tracking plan (forum post "Current state of analytics in the WeBuddhist
app", section 5): `object_verb` names, snake_case properties, never text a
user typed. Each feature fires them through a small analytics class
(`PlanAnalytics`, `ReaderAnalytics`, `MalaAnalytics`, ...) in its
`presentation/utils` folder, so screens never spell out event names or
property keys themselves. Every share sheet reports one `content_shared`
event with a `surface` and the user's content `language`, only after the
sheet was actually used.

Microsoft Clarity adds session recordings and per-screen heatmaps on top of
PostHog. One Clarity project can serve every flavor: each session is tagged
with `environment` and `app_flavor`, so dev traffic can be filtered out on the
dashboard. Screens are named after the go_router route name (`reader`,
`home-settings`, …), imperatively pushed screens after their `RouteSettings`
name, and the four bottom tabs as `tab-home` / `tab-practice` / `tab-connect` /
`tab-me`.

| Variable | Description |
|----------|-------------|
| `CLARITY_PROJECT_ID` | Clarity project ID (Clarity dashboard → Settings → Overview). Empty disables Clarity |
| `CLARITY_ENABLED` | Set to `false` to disable Clarity locally |

### 4. Run the app

Always pass both the flavor and its entrypoint:

```sh
flutter run --flavor dev     -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod    -t lib/main_prod.dart

# macOS
flutter run -d macos --flavor dev -t lib/main_dev.dart
```

Release builds:
```sh
flutter build apk       --flavor prod -t lib/main_prod.dart
flutter build appbundle --flavor prod -t lib/main_prod.dart
flutter build ipa       --flavor prod -t lib/main_prod.dart
```

### Checks (same as CI)
```sh
dart run tool/generate_tolgee_bridge.dart --check
dart run tool/tolgee_sync.dart doctor
flutter analyze
flutter test
```

### 5. Adding localizations

The app uses Flutter's built-in internationalization (l10n) with ARB files for translations.

**Localization files location:**
`lib/core/l10n/`

**To add a new translation string:**

1. Add the key to the ARB files (`app_en.arb` is the template; the others are
   `app_bo.arb`, `app_zh.arb`, `app_hi.arb`, `app_mn.arb`, `app_ne.arb`):

```json
// app_en.arb
"my_new_key": "My English text",

// app_bo.arb
"my_new_key": "My Tibetan text",

// app_zh.arb
"my_new_key": "My Chinese text",
```

2. Generate localization files:
```sh
flutter gen-l10n
dart run tool/generate_tolgee_bridge.dart
```

The second command regenerates the Tolgee bridge so the new key can also be
updated over the air. CI fails if it is skipped — see
[Over-the-air translations](#-over-the-air-translations-tolgee).

3. Use in your widget:
```dart
import 'package:flutter_pecha/core/extensions/context_ext.dart';

// Access translation via context.l10n
Text(context.l10n.my_new_key)
```

**For translations with parameters:**

```json
// app_en.arb
"greeting": "Hello {name}",
"@greeting": {
  "placeholders": {
    "name": {"type": "String"}
  }
}
```

Usage:
```dart
Text(context.l10n.greeting('John'))
```

## 🌍 Over-the-air translations (Tolgee)

Translation text can be corrected in [Tolgee](https://tolgee.io) and picked up
by installed apps without shipping a new release. Nothing changes at call
sites: `context.l10n.my_key` keeps working exactly as before.

### How it works

`tool/generate_tolgee_bridge.dart` reads the gen-l10n output and emits
`TolgeeAppLocalizations`, a subclass of `AppLocalizations` that overrides every
key. Each override asks Tolgee first and falls back to the bundled ARB value.
It is registered in `main.dart` in place of `AppLocalizations.delegate`.

The ARB files stay the source of truth in git and are the offline fallback;
Tolgee is an override layer on top of them.

```
context.l10n.my_key
  -> TolgeeAppLocalizations.my_key      (generated override)
     -> Tolgee CDN value                (if loaded and for the right language)
     -> bundled ARB value               (otherwise)
```

Because the bundled ARB is always the fallback, the app behaves exactly as it
did before Tolgee whenever the CDN is unreachable, still fetching, or missing
a key.

The payload is fetched and parsed by the app rather than by the Tolgee SDK,
which cannot serve a multi-part language tag such as `bo-IN`. See
[docs/tolgee.md](docs/tolgee.md#why-the-sdk-is-not-used).

### Configuration

None. The Content Delivery URL is public and the same for every flavor, so it
lives in code as `TolgeeCdn.baseUrl`
([`tolgee_cdn.dart`](lib/core/l10n/tolgee/tolgee_cdn.dart)) and Tolgee is on in
every build. There are no `.env` lines or GitHub secrets for it.

To fix a bad translation, correct it in Tolgee and publish — see
[docs/tolgee.md](docs/tolgee.md#a-bad-translation-shipped).

> **Never put a Tolgee key in `.env`.** The files are bundled as assets and can
> be extracted from a release build. The app needs no key at all; the sync key
> below stays in your shell or GitHub secrets.

### Tolgee project requirements

- App UI locales use bare codes (`en`, `bo`, `zh`, `hi`, `mn`, `ne`). Tolgee
  Content Delivery language tags (and CDN filenames) must be `en`, `bo-IN`,
  `zh-Hant-TW`, `hi`, `mn`, `ne` — the app maps `bo`/`zh` to those CDN tags
  via `TolgeeLocaleMap`. Publishing `bo.json` or `zh.json` will 404.
- Enable ICU placeholder support so plural strings are served as ICU source.
- Content Delivery must export **flat** JSON (nesting and arrays disabled),
  one file per language at `<TolgeeCdn.baseUrl>/<tag>.json`. The SDK's CDN parser
  expects `{"key": "value"}` and cannot read nested objects.

### When updates apply

Translations are fetched on app start, on language change, and when the app
returns to the foreground (at most every 5 minutes). An edit published in
Tolgee reaches users within minutes of their next launch or return to the app;
there is no live push. A cold start with no network shows the bundled ARB text
until a later return to the app fetches again.

### ARB sync (manual and CI)

Bundled ARB files stay the offline fallback; the Tolgee CDN is the OTA
override. Sync uses a write key that must never live in `.env.*`:

| Key | Where | Role |
| --- | --- | --- |
| `TOLGEE_SYNC_API_KEY` | shell env or GitHub Actions secret only | Local / CI ARB ↔ Tolgee sync (write) |

You can sync manually with `dart run tool/tolgee_sync.dart ...`, or let the
**Tolgee Sync** workflow do it on a schedule / via **Run workflow**. Keep both.
CI opens a reviewable PR — it does not merge to `develop` by itself.

Full command order, write-key creation (Tolgee → Project API Keys → + API Key),
rotate-after-exposure guidance, and CI auto-update risks are in
[Tolgee integration and sync](docs/tolgee.md).

## ⚙️ Project Structure

Feature modules follow **Clean Architecture** (presentation → domain → data),
with Riverpod for state and dependency injection.

```
lib/
├── main.dart                 # Shared bootstrap (Firebase, analytics, ProviderScope, router)
├── main_dev.dart             # Flavor entrypoints: load .env.<flavor>, then call main.dart
├── main_staging.dart
├── main_prod.dart
├── env.dart                  # Typed access to dotenv keys
├── firebase_options.dart
├── core/                     # Shared infrastructure
│   ├── analytics/            # PostHog/Clarity service + event catalogue
│   ├── cache/                # Hive-backed cache
│   ├── config/               # API config, feature flags, locale, router (go_router)
│   ├── deep_linking/         # Deep-link / Airbridge routing
│   ├── di/                   # Core Riverpod providers
│   ├── error/                # Failures / exceptions
│   ├── l10n/                 # ARB files, generated localizations, Tolgee bridge
│   ├── network/              # DioClient + interceptors, connectivity
│   ├── services/             # Audio, sharing, upgrade, background images
│   ├── storage/              # Preferences / secure storage
│   ├── theme/                # Themes and fonts (see theme/FONT_SYSTEM_GUIDE.md)
│   └── utils/, widgets/, extensions/, constants/, localization/
├── features/                 # One folder per feature (see Features above)
│   └── <feature>/
│       ├── data/             # DTOs, datasources, repository implementations
│       ├── domain/           # Entities, repository contracts, use cases
│       ├── presentation/     # Screens, widgets, providers
│       └── doc/README.md     # Feature documentation
└── shared/                   # Cross-feature data/domain/presentation helpers and widgets

packages/youtube_player_flutter/   # Vendored 9.1.3 with a playInBackground flag
tool/                               # Tolgee bridge generator + sync CLI, Tibetan font patcher
ci/scripts/                         # Version bump + .env generation used by GitHub Actions
```

### Networking

`lib/core/network/dio_client.dart` adds interceptors in this order:
`auth → timezone → cache → retry → error → logging`.

- **AuthInterceptor** attaches `Authorization: Bearer <access token>` for
  protected paths (`lib/core/config/protected_routes.dart`) and, when signed
  in, for optional-auth paths.
- **TimezoneInterceptor** sends the device time zone.
- **CacheInterceptor** serves/stores cacheable GET responses.
- **RetryInterceptor** queues 401s (and bearer-less 403s), forces one token
  refresh through `AuthService.forceRefreshAccessToken()`, replays the queue,
  and retries network errors with backoff.
- **ErrorInterceptor** maps `DioException`s to typed exceptions;
  **LoggingInterceptor** logs the final result.

The public Library API uses a separate, unauthenticated Dio
(`libraryDioProvider` in `lib/core/di/core_providers.dart`) that shares the
cache, error and logging interceptors.

### Authentication

Auth0 Universal Login via `auth0_flutter` (Google, Apple, SMS), with guest
mode. The Auth0 domain/client ID come from the backend `/props` endpoint;
the callback scheme comes from `AUTH0_SCHEME`. The Auth0 credentials manager
is the single refresh path. The router (`lib/core/config/router/app_router.dart`)
re-runs `RouteGuard.redirect` whenever auth state changes.

Details: [`lib/features/auth/doc/README.md`](lib/features/auth/doc/README.md)
and [`lib/core/config/router/README.md`](lib/core/config/router/README.md).

## 🚚 CI/CD (GitHub Actions)

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `ci.yml` | PR into `develop` / `main` | Tolgee bridge check, ARB doctor, `flutter analyze`, `flutter test` |
| `release-dev.yml` | push to `develop` | Previews the next version, builds the **dev** flavor, uploads to Play internal + TestFlight |
| `release-prod.yml` | push to `main` | Bumps the version (committed + tagged), builds the **prod** flavor, uploads to stores, creates a GitHub release |
| `build-android.yml` / `build-ios.yml` | called by the release workflows | Signed build per flavor; `.env.*` written by `ci/scripts/create_env_files.sh` from secrets |
| `tolgee-sync.yml` | weekly / manual | Syncs ARB ↔ Tolgee and opens a PR |
| `code-review.yml` | PRs, PR comments, pushes to `main` | Automated code review (Amchi) |

Versioning is automatic from commit messages / branch names — see
[CONTRIBUTING.md](CONTRIBUTING.md). `codemagic.yaml` is a legacy config and is
not the active pipeline.

## 📚 Further documentation

- [docs/README.md](docs/README.md) — documentation hub (architecture, implementation notes, Tolgee)
- [docs/SUMMARY.md](docs/SUMMARY.md) — index of every doc in the repo
- [lib/features/doc/README.md](lib/features/doc/README.md) — feature doc index

## 🤝 Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md). Pull requests target `develop`.
