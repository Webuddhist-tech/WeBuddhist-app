# Recitation Feature

> **LLM context doc** — read this before changing anything under `lib/features/recitation/`.

## Purpose

Two unrelated jobs share this folder:

1. **Chant catalogue data** — the list/search model, repository and
   providers behind the Practice tab's chant lists. The screens themselves
   live in **practice** (`recitations_search_screen.dart`,
   `select_recitation_screen.dart`, `add_chants_to_collection_screen.dart`);
   chants open in the **reader** by `textId` (a library edition id).
2. **Live recitation** — the event puja socket
   (`WS /events/{event_id}/recitation/live`) that lets readers follow the
   operator's position, plus a one-shot peek used by home to open a live
   event at the right text.

There are no screens in this feature any more (the old
`RecitationDetailScreen`, save controller and language-config matrix were
removed).

## Architecture

```
recitation/
├── data/
│   ├── datasource/
│   │   ├── recitations_remote_datasource.dart  # abstract; library adapter implements it
│   │   ├── recitation_live_client.dart         # socket + frame parsing
│   │   └── recitation_live_peek.dart           # connect once, read the snapshot
│   ├── models/        RecitationModel, page response, live position, collection list row
│   └── repositories/recitations_repository.dart # cache-first list/search
├── domain/        Recitation entity, ContentType
└── presentation/
    ├── providers/  recitations_providers, recitations_datasource_provider,
    │               recitation_search_provider, recitation_live_notifier
    └── widgets/    recitation_list_skeleton, recitation_live_sync_toggle
```

## Key files

| Area | Files |
|------|-------|
| Datasource wiring | `presentation/providers/recitations_datasource_provider.dart` → `library/data/adapters/library_recitations_remote_datasource.dart` |
| Cache-first list | `data/repositories/recitations_repository.dart` |
| Full list | `recitationsFutureProvider` (`recitations_providers.dart`) |
| Search | `RecitationSearchNotifier` (debounced 500 ms, min 3 chars); provider lives in practice `practice_recitations_paginated_provider.dart` |
| Live socket | `presentation/providers/recitation_live_notifier.dart` (`recitationLiveProvider(eventId)`) |
| Live pill | `presentation/widgets/recitation_live_sync_toggle.dart` |
| Live peek | `data/datasource/recitation_live_peek.dart` (used by home) |

## Data sources

- **Library API** (`/v2/texts?tag_id=…`) — the chant catalogue, filtered by
  the `LIBRARY_CHANTS_TAG_ID` env tag; search is the library `title` filter
  (≥ 2 chars). `RecitationModel.textId` is the text's **primary edition id**.
  The library has no total, so `total` is synthesised from `has_more`.
- **Main API** — the user's recitation collections (practice datasource),
  merged into the first page when `shouldIncludeCollections` is set; a
  collections failure never hides the chants.
- **Hive cache** — `RecitationsRepository`: fresh → return; stale → return
  and refresh in background; offline with no cache → `NetworkFailure`.
- **WebSocket** — live recitation (token in the query string).

## Live recitation

- `recitationLiveProvider(eventId)` holds one socket per event, shared by
  every reader on screen and kept 5 s after the last one leaves (a text
  switch replaces the reader route).
- Reconnects with backoff, pings every 30 s, drops the socket while the app
  is backgrounded and reconnects on resume.
- Fatal error frames (401/403/404, or a bare `{"detail": …}`) stop it
  (`unavailable`); no token → `unavailable`.
- The position frame right after `session_info` is the **snapshot**
  (`positionIsSnapshot`): the reader highlights it but does not navigate a
  user away from the text they opened.
- Follow mode (`following` / `paused` / `off`) is client-only; the socket
  stays open in every mode.

## Cross-feature dependencies

- **library** — catalogue and search.
- **practice** — owns the chant screens, search provider and collections.
- **reader** — opens chants; consumes the live notifier.
- **home** — live event entry via the peek.
- **core** — `contentLanguageProvider`, `CacheService`, `authServiceProvider`
  (socket token), `apiConfigProvider`.

---

## How to make changes (LLM playbook)

### Do

- Keep `RecitationModel.textId` an edition id — the reader, saved chants and
  collections all store that id.
- Keep cache-first behaviour for list fetches.
- Add new socket frame types in `RecitationLiveClient.parseFrame` and handle
  them in `RecitationLiveNotifier._onEvent`.

### Don't

- Don't add a chant HTTP datasource here — extend the library adapter.
- Don't navigate on a snapshot position.
- Don't tie the follow mode to the socket connection.

### Testing

- Library adapter paging (`nextSkip`, synthesised `total`, short queries).
- Live notifier: reconnect/backoff, fatal frames, snapshot grace, lifecycle.
- Peek: snapshot, no snapshot within the grace, timeout.
