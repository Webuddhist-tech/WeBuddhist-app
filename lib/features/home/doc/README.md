# Home Feature

> **LLM context doc** — read this before changing anything under `lib/features/home/`.

## Purpose

Home dashboard and **main navigation shell** (bottom nav: Home, Practice, Connect, Me). Aggregates verse of the day (with likes/comments/share), streak, today's events, shortcuts, My Practices stats, featured series, group events and poems previews.

## User-facing functionality

Home tab (`HomeScreen`, top to bottom):

- **App bar** (`HomeTabAppBar` in `home_header.dart`) — greeting, calendar button (`AppRoutes.calendar`), streak badge (`streakFutureProvider`)
- **Today's events banner** (`HomeEventBanner` → `TodayEventBadge`) — from `GET /events/today`; re-evaluates "live" status every minute with a `Timer.periodic`; tapping opens the group event page via `openHomeLiveEvent` (`utils/home_live_event_navigation.dart`), which can deep-jump into the live recitation (`resolveHomeLiveEntry`)
- **Verse of the day** (`VerseOfDayCard`) — likes, likers sheet, threaded comments sheet (`verse_comments_sheet.dart`, `utils/verse_comment_threading.dart`), image/text share sheet
- **Shortcuts row** (`HomeShortcutsRow`) — Plans (`AllPlansScreen`, uses `practiceExploreSeriesProvider`), Chants (`AllRecitationsScreen`), Mala (`/mala`) and Timer (`/home/timers`); Mala/Timer are login-gated
- **My Practices stats** (`MyPracticesStatsCard`, `routineInfoFutureProvider`) → `my-practices` route
- **Featured series** (`FeaturedPlanSection`) → `home-series-detail`
- **Group events preview** (`GroupEventsSection`, `homeGroupEventsPreviewProvider`, logged-in only) → `GroupEventsScreen` (`home-group-events`, tabbed by event format)
- **Poems preview** (`PoemsSection`, `homePoemsPreviewProvider`, public) → `home-poems`
- **Share-the-app prompt** (`HomeSharePrompt`)
- Pull-to-refresh invalidates every home provider and reloads verse engagement

Other screens: `SeriesDetailScreen` / `SeriesInfoScreen` (series browse + enrollment, incl. group enrollment), `PlanListScreen` (`home-plans`, plans by tag), `GroupEventsScreen`.

On first mount `HomeScreen` requests notification permission, triggers a notification-engine sync, then consumes `pendingOnboardingPlanProvider` to open the onboarding plan in Practice.

## Architecture

```
home/
├── home.dart           # partial barrel (mostly legacy tags/featured-day symbols)
├── data/               datasources, models, repositories, week_plan_*.dart (unused)
├── domain/             entities, all repository interfaces in home_repository.dart, usecases
└── presentation/       providers (one per concern), screens, utils, widgets, constants
```

## Key files

| Area | Files |
|------|-------|
| Nav shell | `presentation/screens/main_navigation_screen.dart` — `MainTab`, `mainNavigationIndexProvider`, `pendingOnboardingPlanProvider`, `HomeShellScaffold` (ShellRoute scaffold + Android back handling), `MainNavigationBottomBar` |
| Dashboard | `presentation/screens/home_screen.dart`, `presentation/widgets/home_header.dart` |
| DI hub | `presentation/providers/use_case_providers.dart` (datasources, repositories, use cases, `homeSyncBootstrapProvider`) |
| Local cache | `data/datasource/home_local_datasource.dart` (Hive box `home_local_data`, opened in `main.dart`) |
| Verse engagement | `presentation/providers/verse_of_day_engagement_providers.dart` |
| Series | `data/repositories/series_repository.dart`, `presentation/providers/series_enrollment_provider.dart` |
| Live event entry | `presentation/utils/home_live_event_navigation.dart`, `home_live_event_entry.dart` |
| Analytics | `presentation/utils/home_analytics.dart`, `series_analytics.dart` |

## State management

- `StreamProvider` backed by the local cache (names still end in `FutureProvider`): `verseOfDayFutureProvider`, `todayEventsFutureProvider`, `streakFutureProvider`, `routineInfoFutureProvider`, `featuredSeriesFutureProvider`, `seriesListFutureProvider`, `seriesByIdProvider`, `userSeriesEnrollmentsProvider`
- `FutureProvider.autoDispose`: `homeGroupEventsPreviewProvider`, `homePoemsPreviewProvider`
- `StateNotifierProvider.autoDispose.family`: `seriesEnrollmentProvider`, `verseOfDayLikesProvider`, `verseOfDayLikersProvider`, `verseOfDayCommentsProvider` (likes/comments re-created on login/logout)
- `StateProvider`: `mainNavigationIndexProvider`, `pendingOnboardingPlanProvider`
- User-scoped providers (streak, routine info) are invalidated on auth transitions by `userSessionBootstrapProvider` (auth feature)
- Day-scoped data (verse, today's events, streak) is **not** refreshed on day rollover/app resume — only on pull-to-refresh, language change or cold start

## Data sources

- **Remote:** `/verse-of-day/today` (+ `/likes`, `/likes/users`, `/comments`, `/comments/{id}/likes`), `/events/today`, `/users/me/streak`, `/users/me/routine/info`, `/series`, `/series/featured`, `/series/{id}`, `/users/me/series` (GET enrollments, POST enroll with optional `group_id`), `/plans/featured/day`, `/plans/tags`
- **Local:** `HomeLocalDatasource` — keys per language (`verse_of_day:`, `today_events:v2:`, `series_list:` …) or per user (`streak:`, `routine_info:`, `series_enrollments:`, pending enrollments). Repos yield cache first, refresh remote, then re-yield on `box.watch(key)`
- **Pending writes:** a personal series enrollment that fails offline (`NetworkException`) is queued locally and replayed by `flushPendingEnrollments()` (on enrollment refresh and on connectivity regain via `homeSyncBootstrapProvider`). Group enrollments never enter the queue (it doesn't keep `groupId`, so a replay would enroll personally); a failed group enrollment returns a `Left` and leaves any queued personal enrollment alone. A server rejection of a personal enrollment returns a `Left` and is undone locally, except a temporary error (5xx) on one that was already queued, which stays queued. The flush stops on network/auth/rate-limit errors, drops permanent refusals (400, 403, 404, 422), and skips (keeps) other errors so they don't block later items

## Cross-feature dependencies

- **auth**, **calendar**, **group_profile** (events, group enrollment), **plans**, **practice** (routine, explore providers, all-plans/all-recitations screens), **poems**, **recitation** (live position peek), **notifications**, **connect**, **more** (Me tab)

## Notable patterns

- All repository interfaces live in one `domain/repositories/home_repository.dart`
- Stream + local cache: remote writes to Hive, UI watches streams
- Skeleton widgets paired with async cards
- Notification permission: capture `ProviderContainer` before await (the OS dialog can dispose the State)

## Legacy / unused code

Not referenced outside their own file (still exported from `home.dart`): `ActionOfTheDayCard`, `weekPlanProvider` + `week_plan_*.dart`, `CalendarBannerCard`, `TagSearchOverlay`, `StatButton`, `SeriesCard`, `featuredDayFutureProvider`, `tagsFutureProvider`. Placeholder use cases in `home_usecases.dart` (DailyPrayer etc.) have no backend.

---

## How to make changes (LLM playbook)

### Principles

1. **Main nav lives here** — tab changes affect the whole app.
2. **Prefer stream + cache pattern** for new home feed data.
3. **Check barrel exports** — most providers aren't in `home.dart`; import directly.
4. Use `home_screen_constants.dart` for layout magic numbers.

### Do

- Add new dashboard sections as widget + provider + repository triplet
- Pair async cards with skeleton widgets
- Add new providers to `HomeScreen._onRefresh`
- Invalidate related providers on enrollment changes
- Use existing share sheet patterns for new shareable content

### Don't

- Don't block home render on optional cards — use AsyncValue / skeletons
- Don't move main navigation to another feature without team decision
- Don't implement placeholder use cases in `home_usecases.dart` without backend

### Common tasks

| Task | Where to start |
|------|----------------|
| New home card | widget + provider + datasource/repo, add to `_onRefresh` |
| Nav tab change | `main_navigation_screen.dart`, `MainTab`, routes in `core/config/router/app_router.dart` |
| Series enrollment | `series_enrollment_provider.dart`, `series_repository.dart`, group_profile `enrollSeriesThroughGroup` |
| Verse likes/comments | `verse_of_day_engagement_providers.dart`, `verse_of_day_repository.dart` |

### Testing

- Test offline stream replay from local datasource
- Test guest vs authenticated card visibility
- Test nav index persistence and Android back handling in `HomeShellScaffold`
