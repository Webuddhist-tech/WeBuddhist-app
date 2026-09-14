# Tolgee over-the-air UI translations (Flutter)

UI strings can be updated in [Tolgee](https://tolgee.io) and picked up by
installed apps without a store release. Content/reader languages are a separate
system — this doc is only about **app UI i18n**.

## Purpose

- Ship default copy in ARB / gen-l10n (offline, type-safe).
- Override those strings at runtime from Tolgee Content Delivery (CDN).
- Keep every call site as `context.l10n.some_key` — no `tr('key')` migration.

## How it works

```
context.l10n.sign_in
  → TolgeeAppLocalizations (generated override)
     → Tolgee CDN value if loaded and language matches
     → else bundled AppLocalizationsEn / Bo / …
```

Key files:

| File | Role |
| --- | --- |
| [`lib/core/l10n/tolgee/tolgee_service.dart`](../lib/core/l10n/tolgee/tolgee_service.dart) | Fetch lifecycle, language switch, serialisation |
| [`lib/core/l10n/tolgee/tolgee_cdn.dart`](../lib/core/l10n/tolgee/tolgee_cdn.dart) | Reads `{CDN}/{tag}.json` directly |
| [`lib/core/l10n/tolgee/tolgee_bridge.dart`](../lib/core/l10n/tolgee/tolgee_bridge.dart) | Holds the payload; lookup + ICU format + ARB fallback |
| [`lib/core/l10n/tolgee/tolgee_locale_map.dart`](../lib/core/l10n/tolgee/tolgee_locale_map.dart) | App locale ↔ CDN tag |
| [`lib/core/l10n/tolgee/tolgee_localizations_delegate.dart`](../lib/core/l10n/tolgee/tolgee_localizations_delegate.dart) | Replaces `AppLocalizations.delegate` |
| [`lib/core/l10n/tolgee/tolgee_app_localizations.g.dart`](../lib/core/l10n/tolgee/tolgee_app_localizations.g.dart) | Generated overrides for all ARB keys |
| [`lib/main.dart`](../lib/main.dart) | Bootstrap + `tolgeeRevisionProvider` rebuild |

On cold start, the first frame may still show ARB text. After the CDN fetch
succeeds, `tolgeeRevisionProvider` bumps and `Localizations` reloads remote
strings. Offline or failed CDN → ARB only (no crash).

## CDN / project

Public Content Delivery prefix (namespace included; **no** trailing file name):

```text
https://cdn.tolg.ee/a23495c159b886551292e856ecf7a332/webuddhist
```

The app requests `{TOLGEE_CDN_URL}/{tag}.json` itself — see
[`tolgee_cdn.dart`](../lib/core/l10n/tolgee/tolgee_cdn.dart) and the note under
"Why the SDK is not used" below. Published files:

| CDN file | App UI `languageCode` |
| --- | --- |
| `en.json` | `en` |
| `bo-IN.json` | `bo` |
| `zh-Hant-TW.json` | `zh` |
| `hi.json` | `hi` |
| `mn.json` | `mn` |
| `ne.json` | `ne` |

Requirements in Tolgee Content Delivery:

- Format: **Flat JSON**
- Namespace: `webuddhist` (encoded in the URL prefix above)
- ICU placeholders enabled
- Publish after edits (or auto-publish)

Env (per flavor `.env.dev` / `.env.staging` / `.env.prod`):

```env
TOLGEE_API_URL=https://app.tolgee.io/v2
TOLGEE_API_KEY=tgpak_...          # read-only project key
TOLGEE_CDN_URL=https://cdn.tolg.ee/a23495c159b886551292e856ecf7a332/webuddhist
TOLGEE_ENABLED=true
```

`TOLGEE_API_KEY` and `TOLGEE_API_URL` are **no longer used to read
translations** — Content Delivery is public and the app fetches it directly.
They are still read by `Env.tolgeeEnabled`, so a build without them keeps
Tolgee switched off exactly as before; treat the key as a feature flag rather
than a credential. It ships inside the bundled `.env` asset — never grant write
scopes.

## Why the SDK is not used

`tolgee: ^1.2.0` stores a fetched payload under `Locale.toString()` but reads it
back under a normalised code, and the two disagree for any multi-part tag:

| Published tag | Stored as | Looked up as | |
| --- | --- | --- | --- |
| `en`, `hi`, `mn`, `ne` | `en` | `en` | ✅ |
| `bo-IN` | `bo-IN` | `bo` — region dropped | ❌ |
| `zh-Hant-TW` | `zh-Hant-TW` | `zh-hant-tw` — lower-cased | ❌ |

Two parts collapse to the language alone; anything else is lower-cased whole.
So `bo` and `zh` resolved **no keys at all** and silently fell back to the
bundled ARB, while the log still said the language was ready.

The app therefore fetches and parses the payload itself. Keying by the exact
tag requested makes tag shape irrelevant. Do not route lookups back through the
SDK unless this is fixed upstream.

## Languages and switching

UI locale stays Riverpod [`localeProvider`](../lib/core/config/locale/locale_notifier.dart)
with bare codes (`en`, `bo`, `zh`, …). `TolgeeLocaleMap` remaps only the Tolgee
fetch tag (`bo` → `bo-IN`, `zh` → `zh-Hant-TW`). ARB fallbacks and Material
locale remain `bo` / `zh`.

## Usage in widgets

```dart
Text(context.l10n.sign_in)
Text(context.l10n.ai_greeting(name))
```

Do not call the Tolgee SDK from feature code — nothing in `lib/` imports it.

Context-free paths (e.g. notification scheduling) use
`tolgeeAppLocalizationsFor(locale)` from
[`tolgee_localizations_delegate.dart`](../lib/core/l10n/tolgee/tolgee_localizations_delegate.dart).

## Adding a new UI string

1. Add the key and placeholder metadata to `app_en.arb`. Add bundled values to
   the other ARBs when they are already available.
2. Create any missing Tolgee keys (always inspect the dry run first):

```sh
dart run tool/tolgee_sync.dart push --dry-run
dart run tool/tolgee_sync.dart push
```

3. Regenerate:

```sh
flutter gen-l10n
dart run tool/generate_tolgee_bridge.dart
```

4. Use `context.l10n.your_new_key` in the widget.
5. Translate the created key in Tolgee (namespace `webuddhist`).
6. Publish Content Delivery.
7. Relaunch the app (or switch language) to pick up the remote value.

CI runs `dart run tool/generate_tolgee_bridge.dart --check` so the generated
bridge cannot drift from gen-l10n.

## Keeping ARB and Tolgee in sync

`tool/tolgee_sync.dart` is the supported sync tool. The same commands run
locally and in CI. Bundled ARBs stay the offline fallback; Tolgee CDN remains
the OTA override. Translation files are never rewritten invisibly during a
release build — the sync workflow opens a reviewable PR instead.

### Create the write-access sync key

Network sync commands need a **separate** write-capable project API key. Do not
reuse or widen the read-only `TOLGEE_API_KEY` stored in `.env.*` (those files
ship inside the app).

1. Open Tolgee → select the WeBuddhist project → **Project API Keys** (Account /
   project settings → API keys).
2. Click **+ API Key**.
3. Grant at least `keys.create`, plus `translations.view` and `languages.view`.
4. Copy the `tgpak_...` value once and place it only where sync tooling reads it:
   - **Local:** current shell session, e.g. PowerShell
     `$env:TOLGEE_SYNC_API_KEY = 'tgpak_...'`
   - **CI:** GitHub repository secret named exactly `TOLGEE_SYNC_API_KEY`
     (Settings → Secrets and variables → Actions), used by
     [`.github/workflows/tolgee-sync.yml`](../.github/workflows/tolgee-sync.yml)
5. **Rotate after use / if exposed.** If the key was pasted into chat, logged,
   committed, or shared, revoke/rotate it in the same Project API Keys UI, then
   update the GitHub secret and any open local shells. Prefer keeping the
   long-lived copy only as the GitHub Actions secret; export a key into the
   shell for one-off manual runs.

`TOLGEE_PROJECT_ID` is optional; the tool normally resolves the project from
the API key.

| Key | Where | Purpose | Scopes |
| --- | --- | --- | --- |
| `TOLGEE_API_KEY` | `.env.*` (ships in app) | Runtime OTA / CDN init | read-only (`translations.view`, `languages.view`) |
| `TOLGEE_SYNC_API_KEY` | shell env / GitHub secret only | Local or CI ARB ↔ Tolgee sync | write sync (`keys.create` + view scopes) |

### Manual vs automatic sync

Both paths call the same Dart tool. **Keep both.**

| | Manual (local) | Automatic (CI) |
| --- | --- | --- |
| How | shell + `dart run tool/tolgee_sync.dart ...` | Tolgee Sync workflow (schedule + `workflow_dispatch`) |
| Write key | `$env:TOLGEE_SYNC_API_KEY` | GitHub secret `TOLGEE_SYNC_API_KEY` |
| Best for | first sync, dry-runs, debugging, urgent new English keys | keeping bundled fallbacks fresh without remembering to pull |
| Result | changes in your working tree; you commit/PR | opens a reviewable sync PR (does not merge to `develop` by itself) |

**When automatic sync runs**

- **Schedule:** every Monday at **10:00 AM IST** (`cron: "30 4 * * 1"` = 04:30 UTC in [`.github/workflows/tolgee-sync.yml`](../.github/workflows/tolgee-sync.yml)). GitHub can start scheduled jobs a few minutes late.
- **Manual:** Actions → **Tolgee Sync** → **Run workflow** (`workflow_dispatch`).
- Sync does **not** run on every PR. PR CI only runs offline `dart run tool/tolgee_sync.dart doctor` (no push/pull, no write key).

Practical split: store the long-lived write key as the GitHub secret; export a
key into the shell when you need a manual run; rely on the Monday IST schedule
day-to-day; use local dry-run/pull for the first large sync or urgent `push`.

### Expected command order

Use this sequence for a full local sync:

1. `dart run tool/tolgee_sync.dart doctor` — offline ARB health first
2. `$env:TOLGEE_SYNC_API_KEY = 'tgpak_...'` — set write sync key for this shell
3. `dart run tool/tolgee_sync.dart push --dry-run` — preview missing Tolgee keys
4. `dart run tool/tolgee_sync.dart push` — create missing keys only (skip if dry-run is empty)
5. `dart run tool/tolgee_sync.dart pull --dry-run` — preview ARB value/insert changes
6. `dart run tool/tolgee_sync.dart pull` — write all six ARBs after a clean fetch
7. `flutter gen-l10n` — regenerate Flutter localizations from ARBs
8. `dart run tool/generate_tolgee_bridge.dart` — regenerate OTA bridge for CI freshness
9. `dart run tool/tolgee_sync.dart doctor --remote` — confirm ARB ↔ Tolgee ↔ CDN health

```
dart run tool/tolgee_sync.dart doctor
$env:TOLGEE_SYNC_API_KEY = 'tgpak_...'
dart run tool/tolgee_sync.dart push --dry-run
dart run tool/tolgee_sync.dart push
dart run tool/tolgee_sync.dart pull --dry-run
dart run tool/tolgee_sync.dart pull
flutter gen-l10n
dart run tool/generate_tolgee_bridge.dart
dart run tool/tolgee_sync.dart doctor --remote
```

Steps 3–4 are only needed when `app_en.arb` has new keys. Steps 5–8 are the
usual “bring translator updates into the app” path. Always dry-run before a
real push or pull.

### Detailed commands

#### 1. Offline doctor

This is the local structural health check for the six ARB files under
`lib/core/l10n/`. It reports keys present in English but missing from another
locale, orphan keys, stale `@key` metadata, and ICU placeholder argument-name
mismatches. It does not talk to Tolgee or the CDN, so no API key is required.
Exit status stays successful for ordinary “missing translations” (expected
while languages catch up); it fails only on structural problems such as orphans
or placeholder mismatches. Run this anytime, including before opening a PR.

```powershell
dart run tool/tolgee_sync.dart doctor
```

#### 2. Set the write sync key

Network commands (`push`, `pull`, `doctor --remote`) read
`TOLGEE_SYNC_API_KEY` from the process environment — not from `.env.*`. The
value must be a project API key with write scopes, separate from the read-only
runtime key that ships inside the app. Setting it in PowerShell only affects
the current terminal session; closing the window clears it. Never commit the
value, paste it into `.env` files, or check it into git. For recurring
automation, store the same name as a GitHub Actions secret instead of keeping
it in a local shell.

```powershell
$env:TOLGEE_SYNC_API_KEY = 'tgpak_...'
```

#### 3. Push dry-run

Compares `app_en.arb` message keys against Tolgee’s `webuddhist` namespace and
prints keys that exist locally but not yet in Tolgee. Nothing is created or
updated on Tolgee. Always run dry-run first so you can review the exact key
list; a real push without dry-run is hard to undo if you meant to rename a key
instead of creating a new one.

```powershell
dart run tool/tolgee_sync.dart push --dry-run
```

#### 4. Push

Creates only the missing keys reported by dry-run, uploading the English string
as the initial translation via Tolgee’s create-only import API. Existing Tolgee
keys and translator wording are never overwritten or deleted. After create,
publish Tolgee Content Delivery if you want the new keys on the CDN for OTA;
the API create alone does not refresh CDN files.

```powershell
dart run tool/tolgee_sync.dart push
```

#### 5. Pull dry-run

Fetches all six Tolgee languages in one pass (`en`, `bo-IN`, `zh-Hant-TW`,
`hi`, `mn`, `ne`), compares them to each `app_*.arb`, and prints per-locale
counts of values that would update, keys that would insert (only when the key
already exists in English), and keys left unchanged. No ARB files are written.
Use this to estimate review size before a real pull — the first pull can be
large (especially Tibetan).

```powershell
dart run tool/tolgee_sync.dart pull --dry-run
```

#### 6. Pull

Applies Tolgee wording into the bundled ARB fallbacks so offline or failed-CDN
users still see reasonably current copy. It fetches every language into memory
first, then writes all ARB files; a rate limit or network failure mid-fetch
leaves the tree untouched. It replaces message values only, preserves
`@@locale` and `@key` metadata, skips empty Tolgee strings, never deletes local
keys Tolgee lacks, and may insert a locale key only when that key exists in
`app_en.arb` and Tolgee has a non-empty translation. Review
`git diff` on `lib/core/l10n/app_*.arb` before committing.

```powershell
dart run tool/tolgee_sync.dart pull
```

#### 7. Regenerate Flutter localizations

After ARB files change, Flutter’s code generator must rebuild
`lib/core/l10n/generated/` so `AppLocalizations` getters match the new strings.
Skipping this leaves the app and analyzer out of date relative to the ARBs.
Expected “N untranslated message(s)” warnings for incomplete locales are normal
until those languages are pulled or filled.

```powershell
flutter gen-l10n
```

#### 8. Regenerate the Tolgee bridge

The OTA bridge (`TolgeeAppLocalizations`) is generated from gen-l10n output.
After `gen-l10n`, this regenerates overrides so every ARB key can still be
overridden from the Tolgee CDN at runtime. CI runs this tool with `--check`;
skipping regeneration after a pull will fail PR CI even if the ARBs themselves
are correct.

```powershell
dart run tool/generate_tolgee_bridge.dart
```

#### 9. Remote doctor

Runs the offline checks and then, using `TOLGEE_SYNC_API_KEY`, compares ARB
keys to Tolgee, reports per-language translation coverage, and smoke-tests each
published CDN JSON file (HTTP 200 + flat string map). Coverage gaps and
Tolgee-only keys are warnings; structural ARB problems still fail. Use this
after a real push/pull, or whenever you suspect CDN publish lag.

```powershell
dart run tool/tolgee_sync.dart doctor --remote
```

### What happens when CI auto-updates

The Tolgee Sync workflow runs on the Monday **10:00 AM IST** schedule (or via
**Run workflow**). It does **not** silently rewrite `develop` or ship
translations to production by itself. It runs push → pull → `flutter gen-l10n`
→ bridge generate → `doctor --remote` → open a PR via
`peter-evans/create-pull-request`. Humans still review and merge.

**Safe by design**

- Push is create-only — existing Tolgee translations are not overwritten or deleted
- Pull fetches all six languages before writing any ARB — a mid-run failure should not leave a half-updated tree
- Empty Tolgee strings are skipped — blanks cannot wipe good local ARB text
- Local ARB keys are not deleted just because Tolgee lacks them
- Result is a PR, not a direct commit to `develop` and not a release-build rewrite
- Bridge freshness check and localization tests run in the workflow

**Watch for**

1. **Large / noisy first PR** — the first pull can rewrite hundreds of strings (especially Tibetan) and reformat some ICU plurals. Review carefully; later PRs should be small.
2. **Push talks to Tolgee during the job** — a bad new English key already on `develop` can be created in Tolgee before the sync PR merges. ARB file changes still only land via PR.
3. **Missing or wrong secret** — without `TOLGEE_SYNC_API_KEY` the job fails; a read-only key fails `push`; an overly broad key increases leak risk. Keep scopes tight and rotate if exposed.
4. **Merge conflicts** — feature branches that also edit ARBs can conflict with the Monday sync PR. Coordinate ownership of sync merges.
5. **CDN lag** — creating keys or updating Tolgee does not instantly refresh Content Delivery. Runtime OTA still needs publish; bundled ARBs in the sync PR are separate from OTA.
6. **Bad translator copy** — pull trusts Tolgee wording. After merge, that wording becomes the offline ARB fallback. Skim meaningful diffs, especially `en` and high-traffic keys.
7. **Untranslated warnings** — keys with no Tolgee text for a locale stay missing in that ARB (`gen-l10n` “N untranslated” warnings). Expected until filled; not a CI crash unless doctor finds structural issues.
8. **`develop` tip only** — sync checks out `develop`. Unmerged ARB work that exists only on another branch is not pushed or pulled until it lands on `develop`.

**Bottom line:** auto-sync → PR → review → merge. The main operational risks are a large first PR, push creating Tolgee keys before ARB merge, CDN publish lag, and occasional conflicts with parallel ARB edits.
## Verify OTA

1. Browser: open  
   `https://cdn.tolg.ee/a23495c159b886551292e856ecf7a332/webuddhist/en.json`  
   — expect flat JSON (HTTP 200).
2. Run the app (`flutter run --flavor dev -t lib/main_dev.dart` preferred).
3. Logs should include:  
   `Tolgee: Tolgee ready for en (CDN tag en)`  
   not a “no usable strings” warning.
4. Change `sign_in` in Tolgee → Publish → fully restart the app → UI shows the new text.

## Known limits

- Updates apply on next launch or language switch (no live push).
- Empty/404 CDN responses, malformed bodies and transport failures all parse
  to an empty payload, which the bridge treats as “use ARB”.
- Do not put the filename in `TOLGEE_CDN_URL` — only the prefix through `/webuddhist`.
