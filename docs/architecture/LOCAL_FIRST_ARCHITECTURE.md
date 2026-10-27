# Local-First Architecture Guide

## Purpose

Use this document as context when converting any screen to local-first behavior.

Local-first means the app treats device storage as the UI source of truth. The
server remains the canonical backend, but screens should not wait for the server
before showing the last known state.

The expected UX is:

```text
Open screen
  -> show local Hive data immediately
  -> fetch server data in the background
  -> save changed server data into Hive
  -> UI updates from Hive/provider stream
```

Do not clear the provider, invalidate the UI state, or show skeletons when local
data already exists.

## Core Rules

- UI reads local state first.
- Remote calls refresh local state.
- Hive/local storage is the screen's source of truth.
- Skeletons are only for first ever load when there is no local data.
- Offline with local data should show the normal screen.
- Offline without local data may show the existing empty/error state.
- Pull-to-refresh should force a server fetch, but keep current UI visible.
- App resume/screen entry may trigger background refresh, but must not clear UI.
- For frequently changing values, do not throttle background refresh unless the
  product explicitly accepts stale data.
- Do not use TTL-based `CacheService` for local-first user state. TTL caches can
  delete useful offline data.

## Read Flow

Use this flow for stats, profile cards, home sections, lists, and any read-only
screen data.

```text
Provider watches repository stream
  -> repository reads Hive
  -> if Hive has data: yield it immediately
  -> repository fetches remote in background
  -> if remote succeeds and data changed: write Hive
  -> Hive watcher/provider emits updated value
  -> if remote fails and Hive had data: keep showing Hive data
  -> if remote fails and Hive had no data: return Failure
```

Important: a background refresh should write to Hive, not directly mutate the UI.
The UI updates because the provider observes local state.

## Write Flow

Use this flow for actions such as count, enroll, complete task, send form, etc.

```text
User action
  -> write local state immediately
  -> mark item/action dirty or pending
  -> update UI immediately from local state
  -> try remote sync
  -> if success: mark clean/synced
  -> if failure/offline: keep pending
  -> on reconnect/app resume: flush pending actions
```

For counters, prefer sending an absolute total instead of only a delta when the
backend supports it. Absolute totals are safer for retries because resending the
same value is idempotent.

## Recommended File Pattern

For each feature:

```text
lib/features/<feature>/
  data/
    datasource/
      <feature>_local_datasource.dart
      <feature>_remote_datasource.dart
    repositories/
      <feature>_repository_impl.dart
    models/
      <model>.dart
  domain/
    repositories/
      <feature>_repository.dart
  presentation/
    providers/
      <feature>_provider.dart
```

## Generic Helper (Preferred For New Screens)

Read-only screen data no longer needs its own Hive datasource. Use the shared
screen cache in `lib/core/cache/screen_cache/`:

- `ScreenCacheStore`: one Hive box of last-known-good JSON per key, no TTL.
  Opened by `ScreenCacheStore.init()` in `lib/main.dart`; a failed open means
  network-only, never a crash.
- `ScreenCacheKey.public(...)` / `ScreenCacheKey.user(...)`: keys namespaced
  by language and user id, with a per-screen `version` for schema bumps.
- `ScreenCacheSource<T>`: `watch()` yields the stored value, revalidates in
  the background and yields again only if the raw JSON changed; `refresh()`
  is for pull-to-refresh. Failures are mapped through `ExceptionMapper`.
- `ScreenCacheBuilder<T>` (`lib/core/widgets/`): data wins even while
  reloading, skeleton only when nothing is loaded, `ErrorStateWidget` with
  retry otherwise.

Repository shape:

```dart
Stream<Either<Failure, Thing>> watchThing({required String language}) =>
    _source(language).watch();

Future<Either<Failure, Thing>> refreshThing({required String language}) =>
    _source(language).refresh();

ScreenCacheSource<Thing> _source(String language) => ScreenCacheSource(
  store: store,
  key: ScreenCacheKey.public('thing', language: language),
  fetchJson: () => remote.fetchThingJson(language: language),
  fromJson: (json) => ThingModel.fromJson(json as Map<String, dynamic>).toEntity(),
  failureMessage: 'Failed to load thing',
);
```

Rules:

- `fetchJson` must send `Options(extra: {'no_cache': true})`; otherwise the
  HTTP `CacheInterceptor` can answer the revalidation with stale data.
- User-scoped providers must `ref.watch(authProvider)` so an account switch
  rebuilds the stream under the new user's key.
- "Data changed" is a raw JSON string compare, not model equality.
- `.future` on a converted `StreamProvider` resolves with the stored value.
  Call the repository `refreshX()` when fresh data is required.
- Retry after a first-load failure is `ref.invalidate(provider)`.
- Per-feature local datasources are still right for write flows and pending
  queues (Mala, series enrollments).

Converted screens: recitations list (`RecitationsRepository`), my groups
(`ConnectRepositoryImpl`), group profile (`GroupProfileRepositoryImpl`).

Initialize every Hive-backed local datasource during app startup after
`Hive.initFlutter()`, before providers try to read boxes. Current examples are
initialized in `lib/main.dart`:

- `MalaLocalDataSource.init()`
- `HomeLocalDatasource.init()`
- `UserStatsLocalDatasource.init()`
- `TimersLocalDatasource.init()`
- `PlansLocalDatasource.init()`
- `ScreenCacheStore.init()`

The local datasource should:

- open/use a dedicated Hive box
- namespace user-specific data by user id
- namespace localized public data by language
- expose `read...`, `save...`, and `watch...` methods
- store durable last-known-good data without TTL expiry
- catch JSON parse errors and return null/empty safely

The repository should:

- read local first
- refresh remote in the background
- write successful remote responses to local storage
- expose a stream for UI providers
- expose an explicit refresh method for pull-to-refresh or push notifications

The provider should:

- prefer `StreamProvider` when the UI must update from local storage changes
- avoid `autoDispose` for tab-level state that should survive navigation
- return auth failures only when the user is not logged in
- not invalidate itself just to refresh data

The screen should:

- watch the local-first provider
- call the repository refresh method for pull-to-refresh
- optionally call the repository refresh method on screen entry and app resume
- keep rendering the last provider value while refresh is running
- never call `ref.invalidate(...)` just to check for new server data

## Repository Stream Template

Use this shape for local-first reads:

```dart
Stream<Either<Failure, T>> watchThing() async* {
  final userId = await local.currentUserId();
  if (userId == null || userId.isEmpty) {
    yield const Left(AuthenticationFailure('Not authenticated'));
    return;
  }

  final cached = local.readThing(userId);
  if (cached != null) {
    yield Right(cached.toEntity());
  }

  try {
    final remoteModel = await remote.fetchThing();
    final current = local.readThing(userId);
    if (current?.toEntity() != remoteModel.toEntity()) {
      await local.saveThing(userId, remoteModel);
    }
    yield Right(remoteModel.toEntity());
  } catch (e) {
    if (cached == null) {
      yield Left(toFailure(e));
    }
  }

  await for (final _ in local.watchThing(userId)) {
    final latest = local.readThing(userId);
    if (latest != null) {
      yield Right(latest.toEntity());
    }
  }
}
```

For pull-to-refresh:

```dart
Future<Either<Failure, T>> refreshThing() async {
  final userId = await local.currentUserId();
  if (userId == null || userId.isEmpty) {
    return const Left(AuthenticationFailure('Not authenticated'));
  }

  try {
    final remoteModel = await remote.fetchThing();
    await local.saveThing(userId, remoteModel);
    return Right(remoteModel.toEntity());
  } catch (e) {
    return Left(toFailure(e));
  }
}
```

## Provider Template

```dart
final thingProvider = StreamProvider<Either<Failure, Thing>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
    return Stream.value(const Left(AuthenticationFailure('Not authenticated')));
  }

  final repository = ref.watch(thingRepositoryProvider);
  return repository.watchThing();
});
```

Use `autoDispose` only for detail screens where it is acceptable to rebuild
state when leaving. Avoid it for bottom-tab screens like Home or Me.

## Screen Template

Do this:

```dart
final thingAsync = ref.watch(thingProvider);

return thingAsync.when(
  data: (either) => either.fold(
    (failure) => ErrorStateWidget(error: failure, onRetry: refresh),
    (thing) => ThingView(thing: thing),
  ),
  loading: () => const ThingSkeleton(),
  error: (error, _) => ErrorStateWidget(error: error, onRetry: refresh),
);
```

Only show the skeleton when there is no local/provider value yet. Do not
invalidate the provider in `initState` to refresh. That clears state and causes
the skeleton flash.

For silent background refresh on screen entry:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    unawaited(ref.read(thingRepositoryProvider).refreshThing());
  });
}
```

This keeps the local UI visible while the remote fetch happens.

For screens that should refresh when the app returns to the foreground, add a
`WidgetsBindingObserver` and call the same repository refresh method from
`didChangeAppLifecycleState(AppLifecycleState.resumed)`. This is useful for
counts and stats where users expect current server values when internet is
available.

## Current Implementations To Use As References

### Home

Reference files:

- `lib/features/home/data/datasource/home_local_datasource.dart`
- `lib/features/home/data/repositories/series_repository.dart`
- `lib/features/home/presentation/providers/series_provider.dart`
- `lib/features/home/presentation/providers/verse_of_day_provider.dart`
- `lib/features/home/presentation/providers/routine_info_provider.dart`

Home stores public localized data by language and authenticated data by user id.
It also queues pending series enrollments locally and flushes them when
connectivity returns.

### Mala

Reference files:

- `lib/features/mala/data/datasources/mala_local_datasource.dart`
- `lib/features/mala/presentation/providers/mala_counter_notifier.dart`
- `lib/features/mala/presentation/providers/mala_sync_manager.dart`
- `lib/features/mala/presentation/widgets/mala_beads.dart`

Mala uses Hive as the source of truth for counts. Taps update local total
immediately. Sync sends the absolute total to the server later. Bead image bytes
are stored locally so the bead artwork can render immediately on later loads.

### Me Stats

Reference files:

- `lib/features/more/data/datasource/user_stats_local_datasource.dart`
- `lib/features/more/data/repositories/user_stats_repository_impl.dart`
- `lib/features/more/presentation/providers/user_stats_provider.dart`
- `lib/features/more/presentation/me_screen.dart`

Me stats show last-known stats instantly and then fetch `/users/me/stats` in the
background. If the server returns changed stats, the repository writes Hive and
the provider updates the UI. It does not invalidate the provider on screen entry.

Note: `userStatsFutureProvider` is currently a `StreamProvider` despite the old
name. Keep that local-first behavior even if the variable is renamed later.

## Backend Notification Model

The best future version is server-driven invalidation:

```text
Backend stats changed
  -> backend sends push/WebSocket/SSE event
  -> app receives event
  -> app calls repository.refreshThing()
  -> repository fetches remote
  -> repository writes Hive if changed
  -> UI updates from local stream
```

Even with backend notifications, keep the local-first model. The notification
should trigger a refresh; it should not become the UI source of truth.

## Common Mistakes To Avoid

- Do not call `ref.invalidate(provider)` just to refresh data on screen entry.
- Do not show skeleton if local data exists.
- Do not return remote API data directly to the UI and skip local save.
- Do not store authenticated data without user id namespacing.
- Do not store localized data without language namespacing.
- Do not use TTL expiry for state that should survive offline.
- Do not block user actions just because network seed failed, if the action can
  be stored locally and synced later.
- Do not throttle background refresh for values users expect to update
  immediately, such as counts or stats, unless product accepts that delay.
- Do not send low/stale values to the server. For counters, reconcile with
  `max(localTotal, serverTotal)` or use an idempotent absolute-total API.

## Manual Acceptance Checklist

For any screen converted to local-first:

- Open online once; confirm data is saved locally.
- Restart app offline; confirm the screen still shows local data.
- Reopen the screen online; confirm local data shows first with no skeleton.
- Confirm a background refresh updates the UI if server data changed.
- Pull-to-refresh should force remote refresh without clearing local UI first.
- Logout/login as another user; confirm user-specific data does not leak.
- Change app language if the data is localized; confirm language-specific data.
- Make a local action offline; confirm UI updates immediately.
- Restore internet; confirm pending actions sync and become clean.

## Conversion Checklist For The Next Screen

Use this when converting another screen:

1. Identify the exact data the UI needs and whether it is public localized data
   or authenticated user data.
2. For read-only data, build a `ScreenCacheSource` in the repository (see
   "Generic Helper"); only write flows need their own Hive datasource.
3. For a new Hive datasource, add `init()` and call it from `lib/main.dart`.
4. Update the repository so reads yield local data first.
5. Make remote refresh save into Hive instead of returning directly to the UI.
6. Add a watcher stream from Hive and expose it through a `StreamProvider`.
7. Update the screen so pull-to-refresh calls `refresh...()` without invalidating
   the provider.
8. For writes, update Hive first and queue/mark pending work before trying the
   API.
9. Add reconnect/app-resume sync for pending writes or frequently changing
   server values.
10. Manually verify offline restart, online background refresh, user switching,
    and language switching when applicable.
