# UI locale vs content language

Language in this app is two independent axes. They often match. They are
allowed to differ, and content API calls must not treat them as the same.

| Axis | Provider | Storage key | What it controls |
| --- | --- | --- | --- |
| **UI locale** | `localeProvider` | `StorageKeys.preferredLanguage` | App chrome: ARB / Tolgee strings, Material widgets, fonts for UI |
| **Content language** | `contentLanguageProvider` | `StorageKeys.contentLanguage` | Backend `language` query param for translatable content |

Implementation lives in [`locale_notifier.dart`](locale_notifier.dart).

## Why they are separate

UI locale is **bounded**. The app can only render chrome in a language it
ships an ARB for (`L10n.all`: `en`, `zh`, `zh-Hans`, `bo`, `hi`, `mn`,
`ne`).

Content language is **open-ended**. The backend may serve languages the app
has no UI translation for (`th`, `tib`, `tibphono`, or any code from
`availableContentLanguagesProvider`). The raw code is stored and sent
verbatim.

Selecting such a language keeps chrome in English and content in that
language. That split is intentional.

```
User picks Thai ("th")
        │
        ▼
selectAppLanguage(ref, 'th')
        │
        ├── contentLanguageProvider  →  "th"     (sent to APIs)
        └── localeProvider           →  "en"     (ARB fallback)
```

`applyUiLocaleForContent` maps the content code through
`AppConfig.resolveContentLanguage`: if the code is a bundled UI language it
is used as-is; otherwise the UI falls back to English. It never throws for
unknown codes.

## Which provider to use

**Content APIs** (`language` query param, localized names/titles/bodies) —
watch or read `contentLanguageProvider`:

- traditions (`/users/me/traditions`, onboarding paths)
- series, tags, plans, texts, recitations
- connect feeds, groups, events

**UI chrome** (buttons, labels, `context.l10n`, `MaterialApp.locale`) —
watch `localeProvider`.

Do not send `localeProvider.languageCode` to a content endpoint. When the
axes diverge, that request is answered in the UI language (usually English)
and the user sees the wrong content.

The language picker and onboarding call `selectAppLanguage`, which updates
both axes from one choice. Feature code should still read the axis it
actually needs.

## Persistence

- UI locale: `StorageKeys.preferredLanguage`
- Content language: `StorageKeys.contentLanguage`

Existing installs that only have the UI locale are migrated: content
language is seeded from `preferredLanguage` on first load so behaviour is
unchanged until the user picks a new language.

## Related

- UI over-the-air strings: [`docs/tolgee.md`](../../../../docs/tolgee.md)
- Bundled UI locales: [`lib/core/l10n/l10n.dart`](../../l10n/l10n.dart)
- Content language list / kill switch: [`lib/core/localization/languages_providers.dart`](../../localization/languages_providers.dart)
