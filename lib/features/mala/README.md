# Mala (Prayer-Bead Counter)

A per-mantra recitation counter. The user taps an arc of prayer beads; each tap
is a monotonic +1 that is persisted locally and synced to the backend as an
**absolute lifetime total**. Counting never decreases.

## Architecture

Clean architecture, Riverpod for DI/state:

```
data/
  datasources/
    mala_remote_datasource.dart   REST calls (dio)
    mala_local_datasource.dart    Hive store (LocalMalaState), namespaced by user
  models/
    accumulator_model.dart        JSON DTOs + toEntity()/toMalaCount()
    accumulator_group_model.dart  Group accumulator DTOs (ImageUrlModel → ResponsiveImage)
  repositories/
    mala_repository_impl.dart     maps exceptions → Failure (fpdart Either)
domain/
  entities/
    mantra.dart                   Mantra, MantraText, AccumulatorMetadata; kBeadsPerRound = 108
    mala_count.dart               MalaCount (total, accumulatorId, beadImageUrl)
    accumulator_group.dart        Joined group accumulator summary for a preset
  repositories/mala_repository.dart
  usecases/mala_usecases.dart     GetCatalogue / GetAccumulatorDetail / Create / Update
presentation/
  providers/
    mala_providers.dart           all DI providers + user-id resolution
    mala_counter_notifier.dart    per-mantra counter (seed + increment)
    mala_sync_manager.dart        app-scoped background sync
    mala_settings_provider.dart   sound / vibration toggles (persisted)
    accumulator_groups_provider.dart  joined groups + session seed fetch (autoDispose family)
    group_accumulation_counts_provider.dart  per-group session counts (Hive + sync)
    mala_accumulation_selection_provider.dart  personal vs group selection (SharedPreferences)
    accumulation_search_provider.dart preset search state (settings / add flows)
  services/
    mala_sound_player.dart        bead-tap click (just_audio)
  screens/mala_screen.dart        screen layout (mantra card → counter → beads → group bar)
  widgets/
    mala_beads.dart               the tappable bead-arc CustomPainter
    mantra_switcher.dart          infinite looping carousel (swipe + ‹ › chevrons)
    group_accumulations_bar.dart  joined-group pill with overlapping avatars
    group_accumulations_sheet.dart  group accumulations bottom sheet
    mala_settings_sheet.dart      sound/vibration, reset, bookmark, add accumulation
    mala_skeleton.dart            loading placeholder
```

## Backend API

Base dio (`dioProvider`). **All `/accumulators/*` routes require the bearer
token** — they are registered as protected in
`lib/core/config/protected_routes.dart` (`'/accumulators/'` catch-all). Without
it the user-scoped endpoints return **403**. The public preset catalogue is only
fetched by authenticated users, so the catch-all is safe.

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/accumulators/presets` | Catalogue of preset mantras (paged, `language`). Sent with `no_cache` so it skips the 5-min HTTP cache and always returns the latest titles/images. |
| `GET` | `/accumulators/{parent_id}` | The user's detail for one preset. **404 ⇒ no accumulator yet ⇒ seed at 0.** |
| `GET` | `/accumulators/{accumulator_id}/groups` | Groups using this preset. Query `joined_only=true` returns only groups the user has joined. `{accumulator_id}` is the preset id (`Mantra.presetId`). Each row includes `user_total_count` — the user's **lifetime** total for that group (shown in the accumulations sheet). Sent with `no_cache`. |
| `POST` | `/accumulators/user` | Lazily create the user's accumulator (`{parent_id}`, starts at 0). |
| `PUT` | `/accumulators/user/{id}` | Push the absolute `current_count`. |
| `DELETE` | `/accumulators/user/{id}` | Soft-delete the active session accumulator (personal reset). |
| `GET` | `/group-accumulators/{group_accumulator_id}` | Group accumulator detail (group_profile). `user.total_count` is the user's **active session** count for bead tapping and sync. |
| `POST` | `/group-accumulators/{group_accumulator_id}` | Submit the user's absolute group session count (`{current_count}`). Path param is `group_accumulator_id` from the groups list, not `group_id`. |
| `DELETE` | `/group-accumulators/{group_accumulator_id}` | Soft-delete the user's active group session (group reset). Lifetime history on prior records is preserved server-side. |

`mala_image_url` appears at both the accumulator and mantra level; it drives the
bead artwork (see below).

## Counting model

Personal and group bead counting both sync **active session** absolutes
(`current_count` / `user.total_count`). Lifetime totals for group rows in the
accumulations sheet come from a separate field — see
[Group counting: session vs lifetime](#group-counting-session-vs-lifetime).

- **Monotonic absolute session totals.** The client always sends the absolute
  session total for the active accumulator, and both sides take `max()`.
  Re-sending the same total is a no-op, so retries are always safe and counts
  reconcile across devices.
- **Seed-before-send.** `MalaCounterNotifier.seed()` fetches the server total
  and `max()`-merges with the local total *before* taps are enabled
  (`isSeeding`), so a stale low value is never sent. Seed uses API
  `current_count` (active session) via `GET /accumulators/{parent_id}`, not
  `total_counted` (lifetime history). When `accumulator_id` is null — fresh
  install or after reset — the client keeps the local session tally (0 after
  reset) and ignores a stale `current_count`.
- **`beadInRound = total % 108`, `rounds = total ~/ 108`** (`kBeadsPerRound`).
- Taps are blocked while `isSeeding`; a failed seed shows a retry
  (`seedFailed`).

### User-id resolution (important)

`mala_providers._resolveUserId()` reads the **persisted** `currentUserId`
(`StorageKeys.currentUserId`, written at login *before* auth state flips) and
only falls back to `userProvider.user?.id`. This avoids a race where the screen
is reachable (auth gate passes) but the async profile fetch hasn't populated
`userProvider` yet. The counter caches the resolved id (`_userId`) on a
successful seed so the synchronous `incrementBead` can persist taps.

The local store **and** the sync manager must use the *same* id (the counter
writes Hive taps keyed by it; the sync manager reads dirty entries by it), so
both resolve through `_resolveUserId` (the sync manager's `currentUserId`
callback is async).

## Sync (`MalaSyncManager`)

App-scoped (`malaSyncManagerProvider`, kept alive for the app lifetime),
observes lifecycle + connectivity. Reads dirty entries straight from Hive, so it
flushes even after the user leaves the screen.

- **Triggers:** launch, each tap (debounced 5s), round completion (immediate),
  background/pause, connectivity reconnect, screen-leave.
- **Flow per dirty preset:** create the accumulator once if `accumulatorId` is
  null (POST), then PUT the absolute total. On success, `max()`-merge the
  returned total into local `total`/`syncedTotal`.
- **Failure:** entry stays dirty; exponential backoff retry (cap 60s).
- Concurrent triggers collapse via an `_isSyncing`/`_dirty` guard.

### Reset

1. Optional **PUT** if `total > syncedTotal` (flush unsynced taps to the
   active accumulator so lifetime totals on that record are preserved).
2. **DELETE** `/accumulators/user/{id}` — soft-delete the active session.
3. **`clearSession()`** locally — `total=0`, `syncedTotal=0`, `accumulatorId=null`.
4. Next tap/sync: **POST** (lazy create) + **PUT** as on first use.

Re-entry runs `seed()` again; with no active `accumulator_id`, the on-screen
count stays at 0 even if the parent detail echoes a non-zero `current_count`.

### Group reset

Same pattern as personal reset, scoped to one joined group:

1. Optional **POST** if the local group entry is dirty (flush unsynced taps so
   lifetime totals on the deleted record are preserved).
2. **DELETE** `/group-accumulators/{group_accumulator_id}` — soft-delete the
   active group session.
3. **`clearGroupSession()`** locally — group `total=0`, `syncedTotal=0` in
   `mala_group_counts`; the user remains joined.
4. Next tap/sync: **POST** the new absolute session count as counting resumes.

After a successful group reset, providers are invalidated so session counts
re-seed from detail (`joinedGroupUserCountsProvider`) and lifetime totals
refresh from the groups list (`joinedAccumulatorGroupsProvider`).

## Group counting: session vs lifetime

Group accumulators expose **two different user counts** from two endpoints:

| Source | Field | Meaning | Used for |
| --- | --- | --- | --- |
| `GET /accumulators/{presetId}/groups` | `user_total_count` | Lifetime total across all sessions for that group | [GroupAccumulationsSheet] row labels only |
| `GET /group-accumulators/{id}` (group_profile) | `user.total_count` | Active session count (resets on DELETE) | Mala counter, bead taps, Hive, background sync |

**On-screen counter (`_CounterBlock` / bead arc):** when a group is selected,
shows the **session** count from [groupAccumulationCountsProvider] (Hive +
`joinedGroupUserCountsProvider` seed). Resets to 0 after a group reset.

**Accumulations sheet:** group rows show **`AccumulatorGroup.userTotalCount`**
(lifetime from the groups list), plus any **unsynced local taps**
(`displayLifetimeCount` = API baseline + dirty tail). The sheet watches
[joinedAccumulatorGroupsProvider] and [groupAccumulationCountsProvider] so counts
update live; after a successful group POST the groups list is refetched. Lifetime
does not drop to 0 when the active session is reset.

**Personal row in the sheet:** shows `MalaCounterState.total` (personal active
session), same semantics as the counter when personal is selected.

Providers:

- [joinedAccumulatorGroupsProvider] — groups list metadata + `userTotalCount`
  (lifetime).
- [joinedGroupUserCountsProvider] — fetches detail per joined group to seed
  session counts (`user.total_count`).
- [groupAccumulationCountsProvider] — local session state, increments on tap,
  `mergeFromServerCounts()` reconciles with detail API, `resetCount()` for
  group reset.

## Local store (`MalaLocalDataSource`)

Hive box `mala_counts`, keys `userId:presetId`, value = JSON `LocalMalaState`
(`total`, `syncedTotal`, `accumulatorId`, `beadImageUrl`). `isDirty =
total > syncedTotal`. `pruneSynced` removes fully-synced entries (keeps dirty
tails).

Group counts use a separate Hive box `mala_group_counts`, keys
`userId:groupAccumulatorId`, value = JSON `LocalGroupMalaState` (`total`,
`syncedTotal`). Same dirty model; flushed by [MalaSyncManager] via
`POST /group-accumulators/{id}`.

Opened once in app bootstrap via `MalaLocalDataSource.init()`.

## Bead artwork & caching

`MalaCounterNotifier` downloads bead artwork via dio during seed (not in the
widget). URLs from the API are **presigned S3 links** that expire (~1 hour), so
stale Hive URLs are retried against fresh catalogue / detail URLs before giving
up. Successful downloads are stored as **`beadImageBase64`** in Hive.

`MalaBeads` renders **`beadImageBytes` only** (MemoryImage). While bytes are
still downloading — or when download fails — the painter draws a gradient bead
(`_drawDrawnBead`). This avoids loading expired presigned URLs directly in the
widget layer (which would log ImageResourceService 403 errors).

- **Preset source.** `Mantra.beadImageUrl` resolves to the mantra-level
  `mala_image_url` first, falling back to the accumulator-level one.
- **Offline.** Persisted bytes in `LocalMalaState` let the strand render on a
  cold start without network.

## Bead input & feedback

Counting is triggered two ways over the bead region (`HitTestBehavior.opaque`),
both +1 and both blocked while seeding:
- **Tap** anywhere on the strand.
- **Right-to-left swipe** — a leftward drag past `_kSwipeDistance` (24px) or a
  leftward fling past `_kFlingVelocity` (200px/s), matching the strand's right→
  left motion. Left-to-right is ignored (counting is monotonic).

Each `incrementBead`:
1. `_sound?.play()` — `MalaSoundPlayer` plays `AppAssets.malaSound`
   (`assets/audios/mala-sound.wav`), loaded once and restarted from the top per
   tap so rapid counting stays responsive. Provider:
   `malaSoundPlayerProvider` (`Provider.autoDispose`, disposed with the screen).
2. `HapticFeedback.lightImpact()` (and `mediumImpact()` on round completion).

## Bead arc rendering (`MalaBeads` / `_MalaBeadsPainter`)

A `CustomPaint` strand that advances **forward only** (counting is monotonic).

- **Curve:** a quadratic Bézier from bottom-left (`a`) up to top-right (`b`) with
  the control point (`c`) **above the chord** so the arc bows *outward* (convex
  toward the bottom-right) — flat near the top-right, steepening toward the
  bottom-left. Drawn as the red mala thread (`threadColor`).
- **Even spacing:** beads are spaced by **arc length**, not by the Bézier
  parameter `t` (a Bézier isn't uniform in `t`, which would bunch/overlap beads
  at the ends). An arc-length lookup table (sampled over an extended `t` range)
  maps a bead's position → `t`, so on-screen spacing is constant and the strand
  fills out to the edges.
- **One gap:** a single fixed gap (the counting point, right-of-centre) where
  the red thread shows through. Implemented by pushing beads right of the focal
  slot by `_gap` bead-steps via a `_smoothstep`, so the front-right bead glides
  smoothly *through* the gap on a tap.
- **Animation:** the slide plays **only on a genuine +1 count**
  (`widget.total == oldWidget.total + 1`): the strand slides one bead
  **right → left** (the front-right bead crosses the gap to join the left pile,
  a new bead enters from the top-right). `AnimationController` 280ms,
  `Curves.easeOut`, forward only — never `reverse()`. Any other total change —
  **switching mantras** or the initial **seed load** — snaps straight to the new
  count with no slide (`didUpdateWidget`).

### Tuning knobs (all in `_MalaBeadsPainter`)

| Constant | Meaning | Current |
| --- | --- | --- |
| `_radiusFactor` | bead radius as a fraction of width | `0.075` (diameter ≈ 15% of width) |
| `_spacingFactor` | centre-to-centre spacing × radius | `2.0` (touching) |
| `_focalT` | arc position (0..1) of the gap | `0.56` |
| `_gap` | empty bead-steps of thread at the gap | `1.0` |
| `_from` / `_to` | candidate bead indices drawn (rest skipped/clipped) | `-9 / 9` |
| `a`, `c`, `b` | Bézier points (overall curvature) | see `paint()` |

> Note: a `canvas.clipRect(...)` line exists in `paint()` to cut overflow at the
> edges; toggle it depending on whether beads should be hard-cut at the bounds.

## Screen layout (`MalaScreen`)

Below the app bar, the body is a vertical column (24px horizontal padding, 16px
bottom):

1. **`MantraSwitcher`** — `Expanded(flex: 36)`, inside a white card
   (`AppColors.surfaceWhite`, 16px corner radius). Infinite looping carousel
   (unbounded `PageView` seeded at `_loopBase * length + index`, mapped back
   with `page % length`); swipe or tap chevrons to wrap. The screen owns
   `_index`; the carousel reports settles via `onIndexChanged`. With one mantra
   it locks (no swipe, chevrons disabled).
2. **`_CounterBlock`** — `n/108` bead-in-round and rounds count, left-aligned.
3. **`MalaBeads`** — `Expanded(flex: 42)`, top-aligned in a canvas sized to
   ~85% of the available height so the arc sits higher on screen.
4. **`GroupAccumulationsBar`** — fixed 40px slot at the bottom (see below).

States: skeleton (loading), error+retry (catalogue or seed failure), data.

## Group accumulations bar (`GroupAccumulationsBar`)

Entry point for group counting tied to the current preset. Fetched per mantra via
`joinedAccumulatorGroupsProvider(presetId)` →
`MalaRepository.getJoinedAccumulatorGroups()` →
`GET /accumulators/{presetId}/groups?joined_only=true`.

- **Visibility:** the grey pill appears only when the response contains at
  least one group. Loading, error, and empty responses show nothing inside the
  slot.
- **Layout stability:** the widget always reserves **40px height**
  (`GroupAccumulationsBar.barHeight`) so the bead arc does not jump when the
  request resolves.
- **Preview:** up to two overlapping circular avatars (28px, 10px overlap) plus
  a chevron. Tapping opens [GroupAccumulationsSheet] with the cached groups list.
- **Selection:** [malaAccumulationSelectionProvider] persists the active source
  per preset (`personal` or `group:{uuid}` in SharedPreferences). The mala
  counter and bead arc display the selected **session** total; taps increment
  personal or group session counts accordingly. Group session counts are
  persisted locally per `(userId, groupAccumulatorId)` and synced in the
  background by [MalaSyncManager] (debounced tap flush, round-complete immediate
  flush, lifecycle + reconnect), mirroring personal accumulation.
- **Images:** group `image` is parsed as `ImageUrlModel` (`thumbnail` /
  `medium` / `original`) via `ImageModel.fromJsonMap()` and mapped to
  `ResponsiveImage` on the entity. Avatars render through `ResponsiveCoverImage`
  so the thumbnail tier is picked for the small circle.

`AccumulatorGroup` entity fields used today: `groupAccumulatorId`, `groupId`,
`title`, `image`, `userTotalCount` (lifetime — sheet display only), `isJoined`.
The DTO also carries `target_count`, dates, etc. — not yet mapped on the client.

On API failure the provider returns an empty list (bar stays hidden, slot
reserved).

## Group accumulations sheet (`GroupAccumulationsSheet`)

Opened from the bar pill. Receives the already-fetched [AccumulatorGroup] list
and the user's personal **session** count for the current preset
(`MalaCounterState.total`).

- **User row:** name and avatar from [userProvider] (local cache written at
  login; refreshes via `GET /users/info` when the sheet opens and no user is
  cached yet). Count shows the personal mala session total. Tappable; selected
  row uses `AppColors.blue` / `AppColors.blueDark`.
- **Groups list:** each row shows group image, title, and a **lifetime** count
  (`userTotalCount` from the groups list + unsynced local taps). Not the session
  count used by the counter — so a group reset clears the counter but lifetime
  totals in the sheet stay visible. Watches providers for live updates. Tappable;
  accent colour on the active row.
- **Persistence:** selection survives app restarts via
  `StorageKeys.malaAccumulationSelectionPrefix` + preset id. Invalid group ids
  fall back to personal when the groups list reloads.

Settings (from the mala app bar) can reset the active session (personal or
group), add offline mala rounds to the active session, and bookmark the preset.

## Analytics

`MalaAnalytics` (`presentation/utils/mala_analytics.dart`) owns the events:
`mala_screen_opened`, `mala_mantra_switched`, `mala_mode_changed`,
`mala_offline_rounds_added`, `mala_sync_failed`, plus the session events
`mala_session_started`, `mala_round_completed` and `mala_session_ended`, which
`MalaSessionTracker` groups from the first counted bead until the screen
closes, the app backgrounds, or five minutes pass without a bead.

## Tests (`test/features/mala/`)

- `mala_counter_notifier_test.dart` — seed merge, post-reset stale-count guard,
  offline-tail preservation, no-op while seeding, monotonic increment, round
  completion, fresh-install seed-at-0, `resetCount()` success/failure/mounted.
- `mala_sync_manager_test.dart` — create-once-then-update, absolute-total PUT,
  `max()` adoption, dirty-on-failure, logged-out no-op, per-user namespacing,
  group count POST flush + dirty-on-failure, group reset (flush-then-DELETE).
- `mala_beads_test.dart` — tap increments, right-to-left swipe increments,
  left-to-right doesn't, and disabled beads ignore both.

`currentUserId` callbacks are async (`Future<String?> Function()`) in both the
notifier and sync manager.
