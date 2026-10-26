# Texts Feature

> **LLM context doc** — read this before changing anything under `lib/features/texts/`.

## Purpose

**Reader-facing contracts for text content.** Texts owns the models the
reader renders (`ReaderResponse`, `Section`, `Segment`, commentary and
translation DTOs), the use cases and Riverpod providers the reader loads
pages, search and segment panels through, and a few shared text widgets.

It no longer talks to an API of its own: every request is served by the
**library** feature's adapters (`LibraryTextRemoteDatasource`,
`LibrarySegmentRepository`) over the library API. There are no screens here
(the old library browser, `ChaptersScreen`, collections and version
selection were removed).

## Architecture

```
texts/
├── constants/   TextDetailsConstants (page size), screen constants
├── data/
│   ├── datasource/text_remote_datasource.dart   # interface only
│   ├── models/          ReaderResponse, Section, Segment, commentary/, translation/, search/
│   └── repositories/texts_repository.dart       # cache-first page loads
├── domain/      SegmentRepositoryInterface, use cases (content, search, segment)
├── presentation/
│   ├── providers/   texts_provider, segment_provider, use_case_providers, font_size_notifier
│   ├── segment_html_widget.dart
│   └── widgets/segment_drawer.dart
└── utils/text_highlight_helper.dart
```

No barrel file — import files directly.

## Key files

| Area | Files |
|------|-------|
| Reader pages | `textDetailsFutureProvider` (`texts_provider.dart`) → `GetTextDetailsUseCase` → `TextsRepository.fetchTextDetails` |
| In-text search | `multilingualSearchProvider` → `MultilingualSearchUseCase` |
| Segment panels | `segment_provider.dart` (info, commentaries, translations, root texts) |
| DI | `presentation/providers/use_case_providers.dart` — wires the library adapters |
| Verse alignment | `TextsRepository.alignSegment` → library `alignSegment` |
| Page size | `constants/text_details_constants.dart` (`defaultPageSize = 20`) |

## State management

- `Either<Failure, T>` (fpdart) from repository / use cases.
- `TextDetailsParams` composite `key` gives the provider family its equality.
- `textDetailsFutureProvider` and `multilingualSearchProvider` are **not
  autoDispose**: every page (and every `Left` failure) stays cached for the
  app session. The reader's two fetch helpers (`ReaderNotifier._fetchContent`,
  `SecondaryReaderNotifier._fetchParams`) invalidate a page's params when it
  fails, and `ReaderNotifier.reload()` invalidates the whole family. Any new
  caller must drop failed params itself (search still does not).
- `segment*FutureProvider` families are not autoDispose either;
  `segmentDetailProvider` is.
- `fontSizeProvider` — global reader font size (SharedPreferences).

## Data sources

- **TextRemoteDatasource** (interface) — implemented by
  `library/data/adapters/library_text_remote_datasource.dart`.
- **SegmentRepositoryInterface** — implemented by
  `library/data/adapters/library_segment_repository.dart`.
- **TextsRepository** adds a Hive page cache (`CacheService.textContentBox`):
  fresh → return; stale or `isPartial` (yigchung marks missing) → return and
  refresh in the background; offline → expired cache, then the page saved
  under the previous cache-key version; offline with no cache still tries
  the network (connectivity checks give false negatives).

## Cross-feature dependencies

- **library** — serves all content (see `library/doc/README.md`).
- **reader** — the main consumer: pages, search, segment panels, models.
- **plans** — `plan_text_screen.dart`, `plan_inline_markdown_view.dart`
  use the shared models/widgets.

---

## How to make changes (LLM playbook)

### Principles

1. **Texts defines contracts; library fulfils them.** New data needs go into
   the interface here and the library adapter, not a new Dio call here.
2. **Keep `TextDetailsParams.key` complete** — every field that changes the
   request must be in the key, or two requests share one cached result.
3. **A cached `Left` is sticky.** If a caller can retry, invalidate the
   failed `TextDetailsParams` before retrying.

### Do

- Add fields to `ReaderResponse` / `Segment` with `fromJson`/`toJson` both
  updated (pages are persisted in Hive; old cache entries must still parse).
- Bump the cache key version (`CacheKeys.textDetails`) when the page shape
  changes incompatibly; `textDetailsPrevious` keeps offline reading working.

### Don't

- Don't reintroduce a texts-owned HTTP datasource.
- Don't change `TextDetailsConstants.defaultPageSize` casually — reader
  pagination thresholds and plan windows key off it.

### Testing

- Provider family key stability (`TextDetailsParams`).
- Repository cache paths: fresh, stale, partial, offline, previous-key fallback.
- Regression-test the reader after model changes.
