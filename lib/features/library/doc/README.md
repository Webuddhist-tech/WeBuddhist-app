# Library Feature

> **LLM context doc** — read this before changing anything under `lib/features/library/`.

## Purpose

**Client for the public library (texts) API** (`Env.libraryApiUrl`,
`/v2/...`). It has no screens: it composes the library's raw endpoints into
what the reader, segment panels, reader settings and chant lists need, and
plugs into those features through adapters that implement their interfaces.

## Architecture

```
library/
├── data/
│   ├── datasource/library_remote_datasource.dart   # one method per endpoint
│   ├── repositories/library_repository.dart        # composition + in-memory memo
│   ├── adapters/        # implement other features' interfaces
│   │   ├── library_text_remote_datasource.dart     → texts TextRemoteDatasource
│   │   ├── library_segment_repository.dart         → texts SegmentRepositoryInterface
│   │   ├── library_reader_settings_remote_datasource.dart → reader settings
│   │   └── library_recitations_remote_datasource.dart     → recitation datasource
│   └── models/          LibraryText, LibraryEdition, LibrarySegment, TOC, alignment, …
├── domain/
│   ├── library_content_slicer.dart   # code-point slicing of edition content → lines / HTML
│   └── library_toc_sections.dart     # nests a page's segments under TOC headings
└── presentation/providers/library_providers.dart
```

## Key concepts

- **Text vs edition.** A text has editions; the app's "text id" everywhere
  (reader, chants, bookmarks) is an **edition id**. `resolveEdition` still
  accepts a text id and falls back to its first edition for old links.
- **Families.** Translations chain via `translation_of`; `getTextFamily`
  walks up to the root and back down. Reader languages/versions are the
  family's editions.
- **Segments and content.** Segments carry line spans (code points, end
  exclusive) into the edition's content; `/content?span_start&span_end`
  returns the text, which the slicer cuts into lines and escaped HTML, with
  yigchung (small-text) runs wrapped in `<span class="yigchung">`.
- **No segment total in the API.** `loadWindow` fetches the edition's whole
  segment list (500 per page, memoised per edition) and pages it locally;
  `totalSegments` and positions come from that list.
- **Alignment.** `/v2/editions/{a}/alignments/{b}` pairs segments; the pair
  may be stored either way round, so the reverse is read and inverted. With
  no alignment, verses pair by numeric `reference` (or by position when
  references are not unique numbers). The parallel reader shows only the
  companion's verses aligned to the primary, numbered like it.
- **Yigchung marks** load alongside content with a 5 s budget; a page
  without them is `isPartial` and the texts cache refreshes it later.

## State management

- `libraryRepositoryProvider` — one app-wide `LibraryRepository` so its
  memo survives across screens.
- `_memo` caches futures per id; failures are dropped so they retry. Large
  per-edition results (segments, TOC, yigchungs, alignments) are LRU-capped
  at `segmentCacheSize` (6); segment resources at 200.
- `_fetchAllPages` stops on `has_more == false`, a page with nothing new, or
  `maxPages`, so a misbehaving server cannot loop it.

## Data sources

- **`libraryDioProvider`** — separate Dio, no auth; cache, error and logging
  interceptors. Errors are mapped by `ErrorInterceptor`; 404s are treated
  as "none" for TOC, yigchungs and alignments.
- Chants: `/v2/texts?tag_id=$LIBRARY_CHANTS_TAG_ID` (title filter ≥ 2 chars).
  User collections still come from the main API (practice).

## Cross-feature dependencies

- **texts** — implements its datasource/segment interfaces; uses its models.
- **reader** — reader settings datasource; `alignSegment` for plans, live
  recitation and translations opened under their original.
- **recitation / practice** — chant catalogue and search.
- **core** — `libraryDioProvider`, `Env`.

---

## How to make changes (LLM playbook)

### Do

- Add an endpoint in `LibraryRemoteDatasource`, compose it in
  `LibraryRepository`, and expose it to other features through an adapter.
- Memoise metadata that never changes in a session; cap anything per edition.
- Keep spans in code points (`runes`), not UTF-16 indices — Tibetan text
  breaks otherwise.

### Don't

- Don't let presentation code call `LibraryRemoteDatasource` directly.
- Don't assume the API gives totals or a stable `offset` echo — page by
  the offset you asked for and stop on empty pages.
- Don't hand a text id where an edition id is expected without
  `resolveEdition`.

### Testing

- Slicer: multi-byte runes, trimming, yigchung boundaries.
- `loadWindow`: next/previous, foreign anchors, alignment vs number pairing.
- `_fetchAllPages` / `_memo`: loop guards, failure eviction, LRU cap.
