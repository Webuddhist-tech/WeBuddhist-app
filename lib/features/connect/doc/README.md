# Connect Feature

> **LLM context doc** — read this before changing anything under `lib/features/connect/`.

## Purpose

Social hub tab: unified feed, group events, and group discovery from followed communities.

## User-facing functionality

- Main nav **Connect** tab with 3 sub-tabs
- **Feed** — merged posts, events, practices from followed groups; posts carry likes and comments
- **Events** — group events with attendance
- **Groups** — discover, my groups, follow/unfollow
- Group search (`GroupSearchScreen`), My Groups list, followed-groups row above the tabs
- Post detail (drawer from a card, or `/home/posts/:postId` route from a push) with comment thread
- App-bar **Chats** action with unread dot (members only) — opens `group_chat`'s Chats screen
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
| Tab host | `presentation/screens/connect_screen.dart` (tabs `feed` / `events` / `groups`, `_ChatsAction`) |
| Feed | `connect_unified_feed_providers.dart`, `connect_feed_merge_utils.dart` |
| Post likes/comments | `connect_post_like_actions.dart`, `connect_post_comments_providers.dart` |
| Followed practices list | `connect_practices_providers.dart` — no tab of its own; backs the group post composer's in-app content sheet |
| Events | `connect_events_providers.dart` (`myConnectEventsProvider` family by format, `discoverConnectEventsProvider`) |
| Groups | `connect_providers.dart`, `discover_groups_screen.dart`, `my_groups_screen.dart` |
| Search | `group_search_provider.dart`, `group_search_screen.dart` |
| Post detail | `connect_post_detail_screen.dart` (`ConnectPostDetailPanel`), `connect_post_detail_drawer.dart` |
| Optimistic UI | `pendingJoinedGroupsProvider`, `pendingUnjoinedGroupIdsProvider` |
| Barrel | `connect.dart` (screen only) |

## State management

- `StateNotifierProvider.autoDispose` with explicit state classes per tab (`myUnifiedConnectFeedProvider` / `discoverUnifiedConnectFeedProvider`, events, practices, `discoverGroupsProvider`, `groupSearchProvider`, `connectPostCommentsProvider` family)
- `FutureProvider`: `myGroupsProvider`
- `StateProvider`: pending join/unjoin optimistic state
- `ConnectLazyMyDiscoverTabMixin` (in `connect_lazy_segment_mixin.dart`) — lazy My/Discover segment loading; pass `isActive` to defer fetch
- `ConnectMyDiscoverTabGate` — waits for the first My fetch, then opens on Discover if My is empty

## Data sources

- **Remote only** via `ConnectRemoteDatasource`
- Events tab and the feed's practice merge delegate to **`GroupProfileRepositoryInterface`** (`getConnectEvents`, `getConnectPractices`)

## Cross-feature dependencies

- **auth** — guest gating, login prompts
- **group_chat** — `chatRoomsProvider` / `chatRoomsPushRefreshProvider` drive the Chats unread dot
- **group_profile** — entities (`GroupProfile`, `GroupEvent`, `GroupPractice`), repository, follow invalidation
- **core** — `contentLanguageProvider`, theme

## Notable patterns

- **`hasLoaded`** on paginated states — distinguish empty vs not-yet-fetched
- **`ensureLoaded()`** lazy init for discover groups
- Unified feed merges via `ConnectFeedMergeUtils` (dedupe by key, newest first); feed and practices page independently
- Post detail has no single-post fetch: it renders `initialPost`, so a route opened without one (push deep link) shows a placeholder post
- Follow/unfollow must invalidate connect + group_profile providers

---

## How to make changes (LLM playbook)

### Principles

1. **Split providers by tab/concern** — don't create one mega-provider file.
2. **Preserve optimistic pending groups** — merge with API via existing utils.
3. **Lazy load tabs** — use `isActive` / `ConnectLazyMyDiscoverTabMixin`.
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
| New sub-tab | provider file + tab widget + `_tabNames` / `TabController` length in `ConnectScreen` |

### Testing

- Test optimistic join/unjoin reconciliation
- Test lazy tab loading (no fetch when inactive)
- Test empty vs loading states via `hasLoaded`
