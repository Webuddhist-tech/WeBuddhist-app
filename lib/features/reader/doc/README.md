# Reader Feature

> **LLM context doc** — read this before changing anything under `lib/features/reader/`.

## Purpose

Full-featured text reader: paginated segments, dual-slot layout (primary + secondary version), search, commentary, translation, plan/routine navigation, group chant modes.

## User-facing functionality

- Paginated segment loading with swipe navigation
- Dual-slot: interlinear / split view with version/language/script pickers
- In-text search, commentary panel, translation panel
- Font size, highlighting, segment action bar (copy, share, commentary, video)
- Plan/routine multi-item swipe between subtasks
- Group accumulator chant mode, group recitation collection mode
- Bookmarks, audio (plan subtasks), mala accumulation, offline chants

## Architecture

```
reader/
├── constants/
├── data/       settings remote datasource, models (ReaderState, NavigationContext, …)
├── domain/     entities, services (flattener, merger, navigation), usecases
├── presentation/  providers, screen, utils, widgets (grouped subfolders)
└── reader.dart
```

## Key files

| Area | Files |
|------|-------|
| Screen | `presentation/screens/reader_screen.dart` |
| Primary state | `presentation/providers/reader_notifier.dart` |
| Secondary | `reader_secondary_content_provider.dart`, `reader_dual_settings_provider.dart` |
| Data loading | **texts** `textDetailsFutureProvider` (not ReaderRepository in UI) |
| Navigation | `domain/services/navigation_service.dart`, `NavigationContext` |
| Flattening | `section_flattener_service.dart`, `FlattenedContent` |
| Barrel | `reader.dart` |

## State management

- `readerNotifierProvider` — family by `ReaderParams`
- `secondaryReaderNotifierProvider`, dual settings providers — keyed by
  `ReaderSettingsScope(textId, ReaderLayoutContext)`, see *Language defaults*
- `readerContextLayoutProvider(context)` — what the person changed inside an
  event / chant / plan (persisted per context, never for the library)
- Scroll: `readerScrollControllerProvider`, `pendingScrollTargetProvider`
- Domain use cases exist but **presentation loads via texts providers**

## Data sources

- **texts API** via `textDetailsFutureProvider` — paginated `ReaderResponse`
- **Reader settings API** — languages, scripts, versions
- **Local storage** — global secondary-layout toggles and script map (library);
  `reader_layout_<context>` JSON for event / chant / plan picks
- Segment commentary/translation via **texts** segment providers

## Cross-feature dependencies

- **texts** — core data (primary dependency)
- **plans** — navigation, audio, subtask completion
- **practice** — bookmarks
- **mala** — accumulation selection, sync
- **group_profile** — group chant UI
- **recitation** — list entry model

## Notable patterns

- **Thin screen, fat notifier** — `ReaderNotifier` owns pagination/selection
- **Flattened scroll model** for `scrollable_positioned_list`
- **NavigationContext** carries entry metadata (plan swipe, group chant, language override)
- Dual-slot: toggles persisted (globally in the library, per context elsewhere);
  per-text slot picks in-memory (`autoDispose`)

## Language defaults (event / chant / plan)

`readerLayoutContextOf(navigationContext)` sorts every reader into `library`,
`event` (any event id), `chant` (chant list, routine, collections, group chant)
or `plan`. The library keeps the app-wide settings untouched. The others:

1. `resolveInitialLayout` (`domain/layout/`) is a pure table. A text already
   in the UI (content) language is shown as written, alone. Otherwise: event →
   original on in the UI language's script (Roman, Devanagari for hi/ne,
   Cyrillic for mn, as written for bo and zh — there is no transliteration
   into Chinese) + translation in the UI language, else English; chant / plan
   → translation only, in the UI language, else English, else as written. A
   chant picked in a language (`NavigationContext.language`, sent by the chant
   list and collection items) shows that language whatever the app language:
   the edition as written when it is the text, else only its translation.
2. `ReaderInitialLayoutApplier` (owned by `ReaderScreen`) runs once when the
   text language and `/texts/{id}/languages` are known: seeds the layout into
   `ReaderDualSettingsNotifier` and fills the translation (remembered pick →
   default → content language) through `fillSecondaryWithLanguages`, which
   tries each candidate until one has a version. While the languages request
   has failed it only seeds the layers and script; the sheet's retry brings
   the list and the applier then runs for real. A stored "on" with nothing to
   fill is held off for the visit (`markTranslationUnavailable`) so the sheet
   never claims a translation the screen lacks — but not when the fill was
   `superseded` by a toggle or a pick made in the sheet meanwhile. A fill
   that `failed` on a versions request is held off too: the stored pick is
   untouched and switching on again requests the versions afresh. Automatic
   fills write the slot with `fillSecondary`, so `isSecondaryEdited` stays
   the person's own picks only. A stored script pick applies from the first
   frame (`readerOriginalScriptProvider` reads the store before the seed).
3. Seeds live in memory for the visit. What the person changes goes to
   `readerContextLayoutProvider(context)` and wins on every later open in that
   context; untouched fields keep following the resolver. That covers the
   Original and Translation switches, the translation language, the script per
   source language and the translation edition per text
   (`translationVersions`, the 50 most recent texts), which
   `autoSelectSecondaryVersion` prefers whenever the language offers it
   (then the edition the reader was opened with, then the first). The picks
   are kept on the device only (SharedPreferences, `reader_layout_<context>`);
   the API has no reader-settings endpoint, so they do not follow the person
   to another device.
4. Every fill uses the same order,
   `ReaderDualSettingsNotifier.preferredTranslationLanguages`: remembered pick
   → the opened edition's language → this visit's default → content language
   (library: content language only). So switching the translation back on, or
   hiding the original, through `fillPreferredSecondary` brings back what the
   first open showed (Chinese UI on an English-only event text gets English
   again).
5. The picks belong to the app language they were made under
   (`StorageKeys.readerLayoutLanguage`). When the content language changes,
   `ReaderLayoutLanguageGuard.sync` drops the event, chant and plan stores so
   the new language's defaults apply — switching back included; the library's
   app-wide settings stay. `MyApp` stamps the startup language once the
   content language is read (so picks from before the stamp existed count as
   made under it) and listens to `contentLanguageProvider` for changes; the
   applier re-checks before it fills, in case a switch was missed. Syncs run
   one at a time, so two quick changes cannot leave the earlier language as
   the stamp.
6. A translated edition (the library's `translation_of`: the hi / zh / mn /
   en chant lists, the Tara event's English and Chinese plans) opens under
   its original (`ReaderNotifier._openAsTranslation` →
   `ReaderDualSettingsNotifier.openAsTranslation`). That layout is this
   visit's default, not an override: translation on, original hidden except
   in an event (events keep it on, as for any text), and the saved picks
   win — a stored "off" stays off, and a remembered translation language or
   edition replaces the opened edition
   (`readerOpenedTranslationNeedsRefill`, whether or not the switch is on;
   if nothing can be shown the opened edition goes back). A chant picked in
   a language pins the layer that holds it: the opened translation stays on
   until the person touches the Translation switch, an original picked in
   its own language stays shown until they touch the Original switch, and a
   remembered language never replaces the picked edition. When the original
   cannot be loaded, the edition opens as the text itself.

- `ReaderRepository` domain interface exists but **not wired in presentation**

---

## How to make changes (LLM playbook)

### Principles

1. **Load content through texts providers** — don't duplicate text API in reader datasources.
2. **Extend NavigationContext** for new entry modes — don't add parallel route params.
3. **Secondary reader aligns by `segment_number`** across versions.
4. Widget subfolders by concern — place new UI in matching folder (`reader_content/`, etc.).

### Do

- Pagination changes in `ReaderNotifier` + flattener/merger services
- Panel UI in `reader_panels/`, settings in `reader_settings/`
- Plan swipe via `SwipeNavigationWrapper` + navigation service
- Invalidate texts providers when version/language changes

### Don't

- Don't wire ReaderRepository in presentation without team refactor
- Don't break segment_number alignment for dual layout
- Don't fetch full text upfront — preserve pagination

### Common tasks

| Task | Where to start |
|------|----------------|
| New panel | widget subfolder + reader state flags in `ReaderState` |
| Scroll-to-segment | `pendingScrollTargetProvider`, notifier scroll logic |
| Plan integration | `NavigationContext`, `navigation_service.dart` |
| Group chant overlay | group_profile providers + reader screen overlays |

### Testing

- Test pagination merge across pages
- Test dual-slot version switch reload
- Test plan swipe completion on navigate away
