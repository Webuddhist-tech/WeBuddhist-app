# Router (go_router + auth guard)

> **LLM context doc** — read before adding or changing a route. Keep the route
> table below in sync with `app_router.dart`.

## Files

| File | Purpose |
|------|---------|
| `app_router.dart` | `appRouterProvider` (the single `GoRouter`), every route, `rootNavigatorKey` / `shellNavigatorKey`, `GoRouterRefreshStream` |
| `app_routes.dart` | Path constants, route categories, `isPublicRoute` / `isGuestAccessible` / `requiresAuth` |
| `route_guard.dart` | `RouteGuard.redirect()` — the top-level, **synchronous** redirect |
| `pending_route_provider.dart` | `pendingRouteProvider` — route to resume after login; cleared on logout |
| `page_transitions.dart` | `buildPlanNavigationTransition` (directional slide for plan/collection navigation) |
| `route_config.dart` | Deprecated shim; only referenced by the unused `auth/.../profile_page.dart` |

## Router setup

- `initialLocation: /home`, `overridePlatformDefaultLocation: true` — app links are
  delivered by `AppLinksDeepLinkService` / `AirbridgeDeepLinkService` (wired in
  `main.dart`), not by go_router's platform launch URL, so a cold-start link is
  not inserted twice.
- `refreshListenable: GoRouterRefreshStream(authProvider.notifier.stream)` —
  redirect re-runs on every auth state change.
- `redirect` always reads the latest `authProvider` (never captured) and kicks
  `refreshOnboardingStatusIfNeeded()` (fire-and-forget).
- `errorBuilder` renders `MainNavigationScreen` for unknown paths.
- Analytics route observers are attached to both the root navigator and the
  shell navigator.

## Redirect logic (`RouteGuard.redirect`)

The guard matches on `state.fullPath` — the **route pattern** (e.g.
`/home/events/:eventId`), not the concrete location.

1. `authState.isLoading` → `/splash`.
2. **Signed in (not guest)**
   - `hasCompletedOnboarding == false` → `/onboarding` (unless already on
     `/onboarding` or `/login`). `null` (unknown) fails open.
   - On `/onboarding` while onboarded/unknown → `/home`.
   - On `/login` or `/splash` → pending route (then cleared) or `/home`.
3. **Guest** — `/onboarding`, `/login`, `/splash` → `/home`; any path that is
   not `isGuestAccessible` → `/home`.
4. **Signed out** — public routes allowed (`/splash` → `/login`); anything
   else stores the path in `pendingRouteProvider` and goes to `/login`.

## Access categories (`app_routes.dart`)

- **Public** (exact match): `/splash`, `/login`, `/get-app`, `/open`.
- **Guest-accessible** (prefix match — every sub-path inherits access):
  `/open`, `/get-app`, `/home`, `/more`, `/settings`, `/about`, `/legal`,
  `/terms-of-service`, `/privacy-policy`, `/practice`, `/practice/my-practices`,
  `/practice/plans/preview`, `/reader`, `/notifications`, `/plan-text`.
- **Everything else requires a full sign-in** for guests: `/mala`, `/profile`,
  `/delete-account`, `/chats`, `/direct-chat/*`, `/groups/*/chat`,
  `/help-contact`.

Caveats (current behaviour, not intent):

- Because `/practice` and `/home` are prefixes, **all** `/practice/*` and
  `/home/*` routes are guest-accessible, including `/practice/edit-routine`,
  `/practice/details`, `/practice/bookmarks`, `/practice/plans/info`, and the
  group / event / timer screens under `/home`. Screens gate their data on auth
  instead.
- `_protectedBasePaths` / `requiresAuth()` are not used by the guard (only by the
  deprecated `RouteConfig`), so adding a path there does **not** block guests.
  Its `plansInfo` constant (`/plans/info`) does not match the real route
  (`/practice/plans/info`).
- `AppRoutes.more` (`/more`) and `AppRoutes.settings` (`/settings`) have no
  route; Settings lives at `/home/settings`.

## Route table

Top level (root navigator):

| Path | Name | Screen / behaviour |
|------|------|--------------------|
| `/splash` | splash | `SplashScreen` |
| `/get-app` | get-app | redirect → `/home` (Airbridge fallback) |
| `/open/series/:seriesId` | open-series | redirect → `/home/series/:seriesId` |
| `/open/poem/:poemId` | open-poem | redirect → `/home/poems?poemId=` |
| `/open/reader/:textId` | open-reader | redirect → `/reader/:textId?segment=&lang=` |
| `/open` | open | redirect → `/home` |
| `/login` | login | `LoginPage` |
| `/onboarding` | onboarding | `OnboardingWrapper` |
| `/chats` | chats | `ChatsScreen` (Clarity-masked) |
| `/direct-chat/:roomId` | direct-chat | `DirectChatScreen` (extra: `ChatRoomDTO?`) |
| `/help-contact` | help-contact | `HelpContactScreen` (extra: `HelpTopic?`, Clarity-masked) |
| `/groups/:groupId/chat` | group-chat | `GroupChatScreen` (`?messageId=`) |
| `/mala` | mala | `MalaScreen` (extra map: `presetId`, `groupAccumulatorId`, `groupAccumulatorEnded`) |
| `/practice` | practice | `PracticeExploreScreen` |
| `/practice/my-practices` | my-practices | `PracticeScreen(showAppBar: true)` |
| `/practice/edit-routine` | edit-routine | `EditRoutineScreen` (extra map: `initialPlan`, `initialRecitation`, `initialSeries`, `initialMantra`, `enrollSeriesId`, `initialTimer`, `initialGroupCollection`, `initialMyCollection`, `initialGroupAccumulator`) |
| `/practice/edit-routine/select-plan` | select-plan | `SelectPlanScreen` |
| `/practice/edit-routine/select-recitation` | select-recitation | `SelectRecitationScreen` |
| `/practice/bookmarks` | bookmarks | `BookmarksScreen` |
| `/practice/details` | practice-plan-details | `PlanDetails` (extra `plan: UserPlansModel` required) |
| `/practice/plans/preview` | practice-plan-preview | `PlanPreviewDetails` (extra `plan: Plan` required) |
| `/practice/plans/info` | practice-plan-info | `PlanInfo` (extra `plan: Plan` required) |
| `/practice/plans/info/details` | practice-plan-info-details | `PlanDetails` |
| `/plan-text/:subtaskId` | plan-text | `PlanTextScreen` (extra `NavigationContext`; falls back to `MainNavigationScreen` without it) |
| `/reader/:textId` | reader | `ReaderScreen` (`?segment=`/`?segmentId=`; extra `NavigationContext` or map) |

Shell routes (`ShellRoute` → `HomeShellScaffold`, persistent bottom nav).
Entries marked **root** set `parentNavigatorKey: rootNavigatorKey` and render
above the shell:

| Path | Name | Screen |
|------|------|--------|
| `/home` | home | `MainNavigationScreen` (tabs are not routes; see `mainNavigationIndexProvider`) |
| `/home/plans/:tag` | home-plans | `PlanListScreen` |
| `/home/plans/:tag/preview` | home-plan-preview | `PlanPreviewDetails` (extra `plan` required) |
| `/home/series/:id` | home-series-detail | `SeriesDetailScreen` — root |
| `/home/series/:id/info` | home-series-info | `SeriesInfoScreen` — root |
| `/home/group/:groupId/recitation-collections/:collectionId` | home-group-recitation-collection | `GroupRecitationCollectionScreen` — root |
| `/home/recitation-collection/:collectionId` | recitation-collection | `GroupRecitationCollectionScreen(groupId: '')` — root |
| `/home/my-recitation-collection/:collectionId` | my-recitation-collection | `MyRecitationCollectionScreen` — root |
| `/home/group/:groupId` | home-group-profile | `GroupProfileScreen` — root |
| `/home/group-accumulator/:accumulatorId` | home-group-accumulator | `GroupAccumulatorScreen` — root |
| `/home/group-events` | home-group-events | `GroupEventsScreen` — root |
| `/home/events/:eventId` | home-group-event | `GroupEventDetailScreen` (`?prayers=1`, extra `HomeLiveEventEntry?`) — root |
| `/home/poems` | home-poems | `PoemsViewerScreen` (`?poemId=` or extra `initialPoemId`) — root |
| `/home/posts/:postId` | home-connect-post | `ConnectPostDetailScreen` — root |
| `/home/timers` | home-timers | `PresetTimersScreen` |
| `/home/timers/active` | home-timer-active | `ActiveTimerScreen` (extra `PresetTimer` required) — root |
| `/home/timers/new` | home-timer-new | `NewTimerScreen` |
| `/home/timers/edit` | home-timer-edit | `NewTimerScreen(timer:)` (extra `PresetTimer` required) |
| `/home/settings` | home-settings | `MoreScreen` (Settings) |
| `/home/calendar` | home-calendar | `TibetanCalendarScreen` |
| `/notifications` | notifications | `NotificationSettingsScreen` |
| `/profile` | profile | `EditProfileScreen` |
| `/about` | about | `AboutScreen` |
| `/legal` | legal | `LegalScreen` |
| `/terms-of-service` | terms-of-service | `TermsOfServiceScreen` |
| `/privacy-policy` | privacy-policy | `PrivacyPolicyScreen` |
| `/delete-account` | delete-account | `DeleteAccountScreen` |

Routes whose builder throws on a missing `extra` (`Missing required
parameters` / `Missing preset timer`) cannot be opened from a URL — only via
`push(..., extra:)`.

## Adding a route

1. Add the path constant (and a path builder if it has params) to `AppRoutes`.
2. Decide access: a guest-accessible route must be listed in
   `guestAccessibleRoutes` or sit under a listed prefix. There is no working
   "protected under a guest prefix" list — put routes that need sign-in at top
   level outside `/home` and `/practice`.
3. Add the `GoRoute` in `app_router.dart`. Full-screen pages pushed from
   root-level routes should use `parentNavigatorKey: rootNavigatorKey` to avoid
   go_router inserting a second `/home` shell page (duplicate page keys).
4. If it calls authenticated APIs, add them to `core/config/protected_routes.dart`
   (`ProtectedRoutes.paths`) so the auth interceptor attaches the token.
5. Update the table above.
