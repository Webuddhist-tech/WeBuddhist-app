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

1. `resolveInitialLayout` (`domain/layout/`) is a pure table: event → original
   on in the UI language's script (Roman, Devanagari for hi/ne, Cyrillic for
   mn, as written for bo) + translation in the UI language, else English;
   chant / plan → translation only in the UI language when offered, else as
   written; a chant opened in the list's own language → as written.
2. `ReaderInitialLayoutApplier` (owned by `ReaderScreen`) runs once when the
   text language and `/texts/{id}/languages` are known: seeds the layout into
   `ReaderDualSettingsNotifier` and fills the translation (remembered pick →
   default → content language) through `fillSecondaryWithLanguages`.
3. Seeds live in memory for the visit. What the person changes goes to
   `readerContextLayoutProvider(context)` and wins on every later open in that
   context; untouched fields keep following the resolver.

Known gap: a chant tapped in the Hindi list arrives as the Hindi edition and
the API never lists its Tibetan original, so the sheet reads "Original: Hindi"
rather than "Original off + Translation Hindi".
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
