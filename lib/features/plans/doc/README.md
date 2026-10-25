# Plans Feature

> **LLM context doc** — read this before changing anything under `lib/features/plans/`.

## Purpose

Browse, enroll in, and track meditation/practice plans — daily tasks, subtasks, progress, authors, and sharing.

## User-facing functionality

- Enrolled-plan tracking page (`PlanDetails`, route `/practice/details`) — day carousel, tasks, missed-day badge, day-completion sheet, share
- Catalogue preview (`PlanPreviewDetails`, `/practice/plans/preview`, `/home/plans/:tag/preview`) and enrollment info page (`PlanInfo`, `/practice/plans/info`)
- Group-event plans: `PlanDetails`/`PlanPreviewDetails` with `eventId` host a live stream header, Replays menu (`event_replays.dart`), prayer requests, and an embedded subtask panel (`plan_embedded_host.dart`)
- Group accumulation tasks open the group accumulator practice instead of the reader
- Day carousel, task/subtask completion
- Mixed subtask navigation (text, images → reader)
- Author profiles and listings
- Share, missed-day / on-track badges, short-video carousel (`plan_shorts_section.dart`)
- Audio segment playback with auto-advance (`PlanSegmentAudioController`, shared with the reader)
- Offline-first: Hive cache (`PlansLocalDatasource`) + pending-action queue flushed on reconnect

> **Legacy / unrouted:** `PlansScreen` (My/Browse tab hub), `MyPlansTab`, `FindPlansTab`, `PlanSearchDelegate` and `planSearchProvider` are still exported from `plans.dart` but are not mounted anywhere and push routes that no longer exist (`/plans/info`, `/plans/details`). Plan browsing/search now lives in `features/practice` (`AllPlansScreen`, `PlansSearchScreen` → `seriesSearchProvider`).

## Architecture

```
plans/
├── constants/
├── data/         datasources, models, repositories, utils
├── domain/       entities, repositories, usecases, subtask_navigation
├── exceptions/
├── presentation/ providers, screens, search, widgets, plan_info
├── services/     plan_share_service
└── plans.dart    # large barrel
```

## Key files

| Area | Files |
|------|-------|
| Enrolled plan page | `presentation/widgets/plan_track/plan_details.dart` |
| Preview page | `presentation/widgets/plan_preview/plan_preview_details.dart` |
| Enroll info | `presentation/plan_info.dart` (enrolls via onboarding `eventEnrollmentServiceProvider`) |
| Inline TEXT/IMAGE/VIDEO subtask screen | `presentation/screens/plan_text_screen.dart` (route `/plan-text/:subtaskId`) |
| Navigation | `presentation/widgets/plan_navigation/plan_navigator.dart`, `domain/subtask_navigation.dart` |
| Subtask bar | `plan_navigation_bottom_bar.dart` |
| Pagination | `findPlansPaginatedProvider` (used by practice `SelectPlanScreen`), `myPlansPaginatedProvider` (home, practice, group events) |
| Date math | `data/utils/plan_utils.dart` (`parseCalendarDate`, `daysBetween`, `dayNumberFor`, `calculateMissedDays`) |
| Offline cache / queue | `data/datasource/plans_local_datasource.dart`, `data/repositories/user_plans_repository.dart` |
| Sync | `plansSyncBootstrapProvider` (watched in `main.dart`; flushes pending actions when connectivity returns) |
| Analytics | `presentation/utils/plan_analytics.dart` |
| Barrel | `plans.dart` |

## State management

- `StateNotifier` paginated lists: `findPlansPaginatedProvider`, `myPlansPaginatedProvider` (both seed from Hive cache, then fetch; `myPlansPaginatedProvider.refresh()` is the only path that forces the network)
- Watch-based `StreamProvider`s backed by Hive (`_watchSingle`: cached → refresh → Hive watch): `userPlansFutureProvider`, `userPlanDayContentFutureProvider`, `userPlanDaysCompletionStatusProvider`, `userPlanProgressDetailsFutureProvider`, `plansFutureProvider`, `planByIdFutureProvider`
- Mutations: `completeTaskFutureProvider`, `deleteTaskFutureProvider`, `completeSubTaskFutureProvider`, `userPlanSubscribeFutureProvider`, `userPlanUnsubscribeFutureProvider`
- `planDaysByPlanIdFutureProvider` (in `plan_days_providers.dart`), author providers
- DI in `use_case_providers.dart`
- User-scoped providers reset on auth change via `auth/.../user_session_bootstrap.dart` (currently only `userPlansFutureProvider` from this feature)

## Data sources

- **Remote:** catalogue, enrollment, progress, day content, completion status, task/subtask completion, authors
- **Local:** `PlansLocalDatasource` (Hive box, keys per user/language/page) for cache-first reads; user id from `StorageKeys.currentUserId`
- **Pending actions:** subscribe/unsubscribe/complete/delete are enqueued before the API call and removed on success; `flushPendingPlanActions()` replays them in order (stops at the first failure) before every user-plans refresh and on reconnect

## Cross-feature dependencies

- **auth** — guest gating on enroll
- **reader** — `NavigationContext`, `NavigationService` for SOURCE_REFERENCE subtasks
- **onboarding** — event enrollment in `PlanInfo`
- **home** — featured day overlap, tag plan lists (`PlanListScreen`) read `myPlansPaginatedProvider`
- **practice** — browse/search UI, routine ↔ plan linking, `SelectPlanScreen`
- **group_profile / connect** — live event header, replays, prayer requests, group accumulator practice
- **series** — preview-unlock day counts (`series_plan_utils.dart`)

## Notable patterns

- Richest feature module — subtask navigation in `PlanNavigator`
- `ResponsiveImage` on `Plan` entity
- Tibetan/English title via `getDisplayTitle(preferTibetan)`
- Domain exceptions in `exceptions/` folder

---

## How to make changes (LLM playbook)

### Principles

1. **Subtask navigation is centralized** — extend `PlanNavigator` / `subtask_navigation.dart`, don't one-off routes.
2. **Pagination providers** for lists — follow existing page/load-more pattern.
3. **Reader integration** for text subtasks — pass `NavigationContext` correctly.
4. Use plan utils for dates/sharing (`plan_utils.dart`, `plan_date_format.dart`, `plan_share_service.dart`). Backend start dates are calendar dates — parse with `PlanUtils.parseCalendarDate`, and count days with `PlanUtils.daysBetween` (UTC-based, DST-safe) rather than `local.difference().inDays` or `start.add(Duration(days: n))`.

### Do

- Add new subtask types in domain + navigator switch + bottom bar
- Cache catalogue changes through local datasource + sync bootstrap
- Gate enrollment with auth + login drawer
- Add skeleton widgets for new list views

### Don't

- Don't bypass `PlanNavigator` for prev/next between subtasks
- Don't hardcode plan IDs except documented promos (onboarding)
- Don't break completion API when changing task UI

### Common tasks

| Task | Where to start |
|------|----------------|
| New subtask type | domain entity → day content model → navigator + screen |
| Progress badge | track widgets + completion status providers |
| Search | practice `PlansSearchScreen` / `seriesSearchProvider` (the plans-feature delegate is legacy) |
| Share | `plan_share_service.dart`, `plan_day_share.dart` |

### Testing

- Test subtask navigation edge cases (first/last day)
- Test guest enroll blocked
- Test offline catalogue cache
- Test day numbers / carousel locking across a DST transition
