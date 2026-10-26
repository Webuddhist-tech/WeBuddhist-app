# Group Chat Feature

> **LLM context doc** — read this before changing anything under `lib/features/group_chat/`.

## Purpose

Real-time chat for community groups, one-to-one direct chats (in practice with the WeBuddhist Team), and the prayer-request board of a group event. One message thread implementation backs all of them.

## User-facing functionality

- **Group chat** (`/groups/:groupId/chat`, optional `?messageId=` to open on a message) — members only; the first send creates the room
- **Direct chat** (`/direct-chat/:roomId`, room may travel in `extra`) — Help & contact messages show a context label above the body
- **Chats list** (`/chats`) — group + direct rooms, most recent first; unread dot on the Connect app bar
- Replies (swipe or menu) with quoted original, emoji reactions (one per member, WhatsApp-style swap), copy, report, delete for everyone (tombstone)
- Multi-select (up to `kChatMaxSelection` = 10) for copy / delete
- Link previews in bubbles and in the composer draft; inline formatting (bold, italic, strike, code) via `ChatComposerController` / `chat_inline_format.dart`
- Per-group notification bell in the header
- **Prayer requests** (event sheet) — post/edit/delete a request with an intention, pray (batched taps), filter/sort, supporters list, translation

## Architecture

```
group_chat/
├── chat_moderation.dart   # backend moderation / invalid-parent codes
├── data/
│   ├── datasource/        # REST datasource, WS live client, room cache, link preview service
│   ├── models/            # DTOs used directly by presentation (no separate entities)
│   └── repositories/      # GroupChatRepositoryImpl → Either<Failure, T>
├── domain/                # repository interface, ResolveGroupChatRoom use case, filters, bulk-delete failure
└── presentation/          # providers, screens, utils, widgets
```

**DTOs are the domain model** — there is no entity layer; widgets consume `ChatMessageDTO`, `ChatRoomDTO`, etc.

## Key files

| Area | Files |
|------|-------|
| Group chat shell | `presentation/screens/group_chat_screen.dart` (member gate, room resolve, socket, push backstop, send) |
| Direct chat | `screens/direct_chat_screen.dart` + `providers/direct_chat_providers.dart` (`DirectChatNotifier` owns socket + send) |
| Chats list | `screens/chats_screen.dart`, `providers/chat_rooms_providers.dart` |
| Thread state | `providers/group_chat_thread_providers.dart` (`groupChatThreadProvider` family by room id) |
| Thread UI | `widgets/group_chat_thread.dart`, `group_chat_message_bubble.dart`, `utils/chat_thread_rows.dart` |
| Socket | `data/datasource/group_chat_live_client.dart` (`ChatLiveClient`, sealed `ChatLiveEvent`) |
| Room lookup | `domain/usecases/resolve_group_chat_room.dart`, `data/datasource/group_chat_room_cache.dart` |
| Prayer requests | `providers/prayer_requests_providers.dart`, `widgets/prayer_requests_sheet.dart`, `new_prayer_request_sheet.dart` |
| DI | `providers/group_chat_providers.dart` |
| Analytics | `utils/chat_analytics.dart` (`groupChatAnalyticsProvider`) |

## State management

- `groupChatThreadProvider` — `StateNotifierProvider.autoDispose.family<…, String roomId>`; newest-first list rendered with `ListView(reverse: true)`
- `directChatProvider` — autoDispose family by room id; messages live in the room's `groupChatThreadProvider`
- `chatRoomsProvider` — autoDispose; refetched on resume, on chat push (`chatRoomsPushRefreshProvider`), and when Chats is shown
- `prayerRequestsProvider` (family by event id), `prayerSupportersProvider`, `prayerIntentionsProvider`, `prayerRequestCountProvider`
- `pendingPrayerSendsProvider` — prayer calls still in flight; sign-out waits on them
- Group chat's socket lives in the **screen State**, not a provider; direct chat's lives in `DirectChatNotifier`; the prayer sheet owns its own event-scoped socket

## Data sources

- **REST** (`GroupChatRemoteDatasource`, Dio): `/chat/rooms…`, `/chat/groups/{id}/messages`, `/chat/users/{id}/messages`, `/chat/events/{id}/room|messages`, reactions, prayers, report, read receipts, `/intentions`
- **WebSocket** `WS /chat/live?token=…&group_id|event_id|receiver_id[&room_id]` — frames: `room_info`, `message_created`, `message_updated`, `message_deleted`, `reactions_updated`, `prayers_updated`, `room_closed`, `typing`, `presence`, `error`
- **Local**: `GroupChatRoomCache` (storage key `group_chat.room.<accountId>.<groupId>`); keyed by the JWT `sub`, not the profile id
- Deletion API details: `documentation/chat-message-deletion-api.md`

## Cross-feature dependencies

- **auth** — `authProvider` gate, `userProvider` (viewer id/email for "is mine"), `authServiceProvider.getValidAccessToken` for the socket
- **group_profile** — `groupProfileProvider`, `groupFollowProvider` (membership gate), notification preferences, event detail
- **push_notifications** — foreground pushes refresh the thread / rooms; `foregroundPushFilterProvider` suppresses banners for the open room
- **feedback** — Help & contact context line parsing in direct chat
- **connect** — hosts the Chats action / unread dot

## Notable patterns

- **Push as socket backstop**: a foreground push for the open room triggers `refreshLatest(socketGrace: 2s)`; if the page holds a message the socket never delivered, the socket is replaced
- **Reconnect** with `chatReconnectDelay` backoff (1s → 30s cap); after a reconnect the newest page is merged by id
- **Dedup by id** everywhere: REST send response + `message_created` echo produce one row
- **Fetch guards**: deletions/reaction summaries that land while a page is in flight are held and re-applied after the page commits
- **Reactions**: optimistic, chained per message, swap = POST new then DELETE old; summaries mid-swap are deferred
- **Delete**: no optimistic removal; confirmed rows get `deleted_at` and render as tombstones; quotes of a deleted original are stamped too
- **Container reads**: screens capture `ProviderScope.containerOf` in `initState` so socket/push callbacks never `ref.read` through a deactivated element
- **Prayers**: taps batched per message and paced (server limit 10/s); a closed sheet drains what it still owes

---

## How to make changes (LLM playbook)

### Principles

1. **One thread notifier** — group and direct chat share `GroupChatThreadNotifier`; extend it rather than forking a direct-only list.
2. **Never trust ordering on the wire** — merge by id, keep the fetch-in-flight guards when adding new mutation types.
3. **Identity from `userProvider.user.id`** (chat `sender_id` space), falling back to email — never the JWT `sub`.
4. **Socket callbacks must check `_disposed`** and go through the captured container.

### Do

- Add new live frames to `ChatLiveClient.parseFrame` + the sealed `ChatLiveEvent`, then handle them in all three consumers (group screen, `DirectChatNotifier`, prayer sheet)
- Read `ref`-derived services *before* awaits when the result must be recorded after dispose (analytics pattern)
- Map new backend error codes in `chat_send_error.dart` / `chat_moderation.dart`
- Add l10n keys to every `app_*.arb`

### Don't

- Don't remove a row optimistically on delete
- Don't open a second socket — respect the `_connecting` / `_live != null` guards
- Don't treat a failed room lookup as "no room" (`GroupChatRoomUnavailable` vs `GroupChatRoomMissing`)

### Common tasks

| Task | Where to start |
|------|----------------|
| New message action | `group_chat_thread.dart` (pill / selection header) → notifier → repository → datasource |
| New socket frame | `group_chat_live_client.dart` → `_onLiveEvent` in each consumer |
| Chats list change | `chat_rooms_providers.dart`, `utils/chat_rooms_list.dart`, `chat_room_tile.dart` |
| Prayer request change | `prayer_requests_providers.dart`, `prayer_request_tile.dart` |

### Testing

Existing tests live under `test/features/group_chat/`.

- Thread merge/refresh/deletion races (`refreshLatest`, pending deletions, reaction swaps)
- Reconnect + push-backstop behaviour (fake `ChatLiveClient` via `connect:` / `clientFactory`)
- Room resolution: cache hit, stale cache (404), lookup failure
