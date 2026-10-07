# Connect Feature

> **LLM context doc** — read this before changing anything under `lib/features/connect/`.

## Purpose

Social hub tab: unified feed, group events, and group discovery from followed communities.

## User-facing functionality

- Main nav **Connect** tab with 3 sub-tabs
- **Feed** — merged posts, events, practices from followed groups; posts carry likes and comments
- **Events** — group events with attendance
- **Groups** — discover, my groups, follow/unfollow
- Group search, post detail with comment thread
- Optimistic pending join/unjoin while API catches up

## Architecture

```
connect/
├── connect.dart          # exports ConnectScreen only
├── data/                 datasource, models, repository impl
├── domain/               entities, repository interface
└── presentation/         providers (split by tab), screens, utils, widgets
```

**No domain use-case layer** — logic lives in repository + notifiers + utils.

## Key files

| Area | Files |
|------|-------|
| Tab host | `presentation/screens/connect_screen.dart` |
| Feed | `connect_unified_feed_providers.dart`, `connect_feed_merge_utils.dart` |
| Post likes/comments | `connect_post_like_actions.dart`, `connect_post_comments_providers.dart` |
| Groups | `connect_providers.dart`, `discover_groups_screen.dart` |
| Optimistic UI | `pendingJoinedGroupsProvider`, `pendingUnjoinedGroupIdsProvider` |
| Barrel | `connect.dart` (screen only) |

## State management

- `StateNotifierProvider.autoDispose` with explicit state classes per tab
- `FutureProvider`: `myGroupsProvider`
- `StateProvider`: pending join/unjoin optimistic state
- `ConnectLazySegmentMixin` — lazy tab loading; pass `isActive` to defer fetch

## Data sources

- **Remote only** via `ConnectRemoteDatasource`
- Events tab and the feed's practice merge delegate to **`GroupProfileRepositoryInterface`** (`getConnectEvents`, `getConnectPractices`)

## Cross-feature dependencies

- **auth** — guest gating, login prompts
- **group_profile** — entities (`GroupProfile`, `GroupEvent`, `GroupPractice`), repository, follow invalidation
- **core** — `contentLanguageProvider`, theme

## Notable patterns

- **`hasLoaded`** on paginated states — distinguish empty vs not-yet-fetched
- **`ensureLoaded()`** lazy init for discover groups
- Unified feed merges via `ConnectFeedMergeUtils`
- Follow/unfollow must invalidate connect + group_profile providers

---

## How to make changes (LLM playbook)

### Principles

1. **Split providers by tab/concern** — don't create one mega-provider file.
2. **Preserve optimistic pending groups** — merge with API via existing utils.
3. **Lazy load tabs** — use `isActive` / `ConnectLazySegmentMixin`.
4. **Reuse group_profile entities** — don't duplicate group models here.

### Do

- Add new feed item types in `connect_feed_model.dart` + merge utils + card widget
- Invalidate `myGroupsProvider`, `discoverGroupsProvider` on follow state change
- Match pagination patterns from existing notifiers (`hasLoaded`, `ensureLoaded`)
- Gate authenticated actions with `LoginDrawer`

### Don't

- Don't add a use-case layer unless the team is standardizing connect — follow existing pattern
- Don't fetch all tabs eagerly on screen open
- Don't break optimistic pending merge when changing my-groups API

### Common tasks

| Task | Where to start |
|------|----------------|
| New feed card type | entity/model → datasource → merge utils → tab widget |
| Comment thread | `connect_post_comments_providers.dart`, detail screen |
| Like behavior | `connect_post_like_actions.dart`, `connect_like_utils.dart` |
| New sub-tab | screen segment + provider file + `ConnectScreen` tab enum |

### Testing

- Test optimistic join/unjoin reconciliation
- Test lazy tab loading (no fetch when inactive)
- Test empty vs loading states via `hasLoaded`
