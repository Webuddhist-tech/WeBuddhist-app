# Practice Feature

> **LLM context doc** — read this before changing anything under `lib/features/practice/`.

## Purpose

**Practice tab** (main nav) — explore hub for plans (series), chants, accumulations (mala) and timers; the user's **daily routine** (server-synced, mirrored to Hive for notifications); bookmarks; and user-created **My Recitation Collections**.

## User-facing functionality

- **Practice Explore** (`PracticeExploreScreen`, route `/practice`): "My Practices" and "Bookmarks" buttons, then sections for plans, chants, accumulations, timers (`practice_explore_providers.dart`). "See all" + search screens: `AllPlansScreen`, `AllRecitationsScreen`, `AllAccumulationsScreen`, `PlansSearchScreen`, `RecitationsSearchScreen`, `AccumulationsSearchScreen`
- **My Practices** (`PracticeScreen(showAppBar: true)`, route `my-practices`): server routine via `userRoutineProvider`; `RoutineFilledState` (time blocks, tap-to-open items, handles `pendingNotificationNavProvider` deep links) or `RoutineEmptyState`
- **Edit routine** (`EditRoutineScreen`, route `edit-routine`): add/remove/reorder time blocks and items; each change syncs immediately per block through a serial op queue; "Done" persists to Hive, pops, then drains the queue and syncs notifications in the background. Accepts `initial*` extras (plan, series, recitation, mantra, timer, group collection, my collection, group accumulator) and `enrollSeriesId`
- **Session picker** (`SelectSessionScreen`) returns a sealed `SessionSelection` (plan / recitation / series / timer / mantra)
- **Bookmarks** (`BookmarksScreen`, route `bookmarks`, login-gated): tabs all / plans / chants / mala / group accumulation / timers / texts (`BookmarkTab`)
- **My Recitation Collections**: `MyRecitationCollectionScreen` (route `my-recitation-collection`), `CreateEditCollectionScreen` (`openEditCollectionScreen`), `AddChantsToCollectionScreen`, options sheet; daily chant completion while swiping in the reader
- Guest gating on routine editing, bookmarks and collections

## Architecture

```
practice/
├── data/       datasources, models, repositories, utils (routine API mapper, time utils, display order planner)
├── domain/     entities, repositories, usecases
├── presentation/  controllers, providers, screens, utils, widgets
└── practice.dart
```

## Key files

| Area | Files |
|------|-------|
| Explore tab | `presentation/screens/practice_explore_screen.dart`, `providers/practice_explore_providers.dart` |
| My Practices | `screens/practice_screen.dart`, `widgets/routine_filled_state.dart` |
| Routine (local) | `providers/routine_provider.dart` (`routineProvider` / `RoutineNotifier`) |
| Routine (server) | `providers/routine_api_providers.dart` (`userRoutineProvider`, time-block use cases), `data/utils/routine_api_mapper.dart` |
| Edit routine | `screens/edit_routine_screen.dart`, `widgets/routine_time_block.dart` |
| Session picker | `screens/select_session_screen.dart`, `data/models/session_selection.dart` |
| Local storage | `data/datasource/routine_local_storage.dart` (Hive box `routine_data`); provider `routineLocalStorageProvider` in `providers/practice_providers.dart` — **must be overridden in `main.dart`** |
| Bookmarks | `controllers/bookmark_controller.dart`, `providers/bookmark_providers.dart`, `data/repositories/bookmark_repository.dart` |
| My collections | `providers/my_recitation_collections_providers.dart`, `providers/my_recitation_completion_service.dart`, `data/repositories/my_recitation_collections_repository.dart` |
| Barrel | `practice.dart` |

## State management

- **Dual routine stack:** server routine (`userRoutineProvider`, `FutureProvider<RoutineData?>`, null for guests) is what screens render; local Hive mirror (`routineProvider`) is what the notification engine reads. `notification_sync_bootstrap.dart` calls `RoutineNotifier.hydrateFromServer` after login
- `RoutineNotifier.whenLoaded` / `loadFailed` let the notification engine skip reconciliation when Hive could not be read
- Bookmarks: `bookmarksProvider` (single fetch, per-tab slices), global `bookmarkExistsCacheProvider` + `bookmarkExistsProvider` / `isBookmarkedProvider` for icon state; `BookmarkController` does optimistic toggles with a `WidgetRef`
- My collections: `myRecitationCollectionDetailProvider`, `myRecitationCollectionCompletionProvider` (today's completions), `myRecitationCompletionProvider` (container-scoped service called from reader swipes; per-day dedupe)
- Paginated / search providers: `practiceRecitationsPaginatedProvider`, `practiceItemsPaginatedProvider`, `seriesSearchProvider`
- `PracticeRepositoryImpl` + `use_case_providers.dart` (start/complete practice, progress) operate on the Hive routine store and are largely legacy

## Data sources

- **Remote:** `/users/me/routine` (GET), `/routines` (POST routine + first block), `/routines/{id}/time-blocks[/{blockId}]` (POST/PUT/DELETE), `/practice/items`, `/users/me/bookmarks` (+ `/exists`, DELETE `/{id}`), `/users/me/recitation-collections` (CRUD, `/upload-image`, `/{id}/items`, `/{id}/complete`, `/{id}/complete/today`, `/{id}/complete/days-count`)
- **Local Hive:** routine mirror for offline + notifications

## Cross-feature dependencies

- **plans**, **home** (series, routine info), **mala**, **recitation**, **timer**, **group_profile** (group collections/accumulators)
- **notifications** — `NotificationSyncEngine`, routine notification service, sync bootstrap
- **reader** — recitation navigation utils, completion services
- **auth** — guest gating

## Critical setup

`routineLocalStorageProvider` **must be overridden** in the root `ProviderContainer` (`main.dart`: `overrides: [routineLocalStorageProvider.overrideWithValue(routineStorage)]`).

---

## How to make changes (LLM playbook)

### Principles

1. **`SessionSelection` aggregates picks** from multiple features — extend it when adding session types.
2. **Mirror server routine to Hive on login** — notification bootstrap depends on it.
3. **Don't break the Hive override** in the app entrypoint.
4. Edit-routine API calls go through `_enqueue`/`_syncBlock`; read use cases before queuing (the closure can outlive the widget).
5. Strip `Exception:` prefix in friendly error messages (existing UI pattern).

### Do

- Add new session type: extend `SessionSelection` + picker screen + `routine_item_display.dart` + `routine_api_mapper.dart`
- Trigger `NotificationSyncEngine` after routine saves (`RoutineNotifier.syncNotifications`)
- Invalidate `userRoutineProvider` and `routineInfoFutureProvider` after routine mutations
- Update `bookmarkExistsCacheProvider` and invalidate `bookmarksProvider` after bookmark changes

### Don't

- Don't store routine only locally without the API sync path
- Don't duplicate plan/recitation/mala pickers — link to existing select screens
- Don't skip notification reconciliation after routine edits

### Common tasks

| Task | Where to start |
|------|----------------|
| New routine session type | `SessionSelection`, `routine_item_display.dart`, `routine_api_mapper.dart`, select screens |
| Explore section | section widget + `practice_explore_providers.dart` (add to explore pull-to-refresh) |
| Bookmark | `bookmark_controller.dart`, `bookmark_providers.dart` |
| Routine sync bug | `routine_api_providers.dart` + `RoutineNotifier` + `notification_sync_bootstrap.dart` |
| Collection edit | `create_edit_collection_screen.dart` (`_submitEdit`: metadata → removals → additions → order) |

### Testing

- Test routine save triggers notification sync
- Test guest cannot edit routine
- Test Hive mirror matches server after login
