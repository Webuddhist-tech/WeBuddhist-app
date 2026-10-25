# Task and Subtask Completion Tracking

## Overview

How the app records plan progress: **tasks** are ticked manually (or automatically after a group accumulation session) on the plan day screen, and **subtasks** are completed automatically as the user moves forward through a plan's content in the reader / plan text screens. Every write goes through `UserPlansRepository`, which queues it locally first so it can be replayed when the network returns.

**Last Updated**: October 2026 (rewritten against current code; the January 2025 v1.0 design — `PlanStoryPresenter`, 300 ms debounce, direct repository calls — no longer exists)

---

## Architecture

```
PlanDetails (task checkbox)            Reader / PlanTextScreen (swipe "next", finish, audio auto-advance)
  completeTaskFutureProvider(taskId)     planSubtaskCompletionProvider.completeCurrent(navContext)
  deleteTaskFutureProvider(taskId)         └─ completeSubTaskUseCaseProvider
            │                                        │
            ▼                                        ▼
        UserPlansRepository (lib/features/plans/data/repositories/user_plans_repository.dart)
          1. enqueue PendingPlanAction in PlansLocalDatasource
          2. call UserPlansRemoteDatasource
          3. on success remove the pending action; on error return Left(Failure) (action stays queued)
            │
            ▼
        flushPendingPlanActions()  ← app resume (main.dart), connectivity regained
                                     (plansSyncBootstrapProvider), before every user-plans refresh
```

---

## Task completion

**Location**: `lib/features/plans/presentation/widgets/plan_track/plan_details.dart` → `_handleTaskToggle`, `_completeTask`

1. User taps a task checkbox → `_handleTaskToggle(taskId, tasks)`.
2. Re-entrancy guard: `_togglingTaskIds` ignores taps while that task's request is in flight.
3. Optimistic UI: `_optimisticCompletions[taskId] = !task.isCompleted` inside `setState`.
4. Calls `completeTaskFutureProvider(taskId)` or `deleteTaskFutureProvider(taskId)` (`FutureProvider.autoDispose.family` in `user_plans_provider.dart`, so each tap is a fresh request).
5. On success: logs `planTaskToggled` analytics, invalidates `userPlanDayContentFutureProvider(PlanDaysParams(...))` and `userPlanDaysCompletionStatusProvider(planId)`.
6. On failure (or a non-2xx result): drops the optimistic value and shows `updateTaskError` / `errorDetail` snackbar. All `setState` / snackbar calls are `mounted`-guarded.

`_completeTask` is the "complete only, never untick" variant used after a **group accumulation** session returns `practiced == true`.

---

## Subtask completion

**Location**: `lib/features/plans/presentation/widgets/plan_navigation/plan_subtask_completion.dart` → `PlanSubtaskCompletionService` (`planSubtaskCompletionProvider`)

Callers:
- `reader/presentation/widgets/reader_gestures/swipe_navigation_wrapper.dart` — forward swipe and "finish" (awaited before pop)
- `reader/presentation/screens/reader_screen.dart`
- `plans/presentation/screens/plan_text_screen.dart` — forward navigation and audio auto-advance

Behaviour of `completeCurrent(navContext)`:
- No-op unless `navContext.source == NavigationSource.plan`, the current item exists, is not already completed, and has subtask ids (preview mode has none).
- A combined item completes **all** of its `subtaskIds` that aren't in `completedSubtaskIds`.
- An in-memory `_completedSubtaskIds` set (claimed *before* the POST) prevents re-posting when the user swipes back over a finished item — the `NavigationContext` snapshot never updates.
- Failed ids are removed from the set so a later swipe retries.
- After any success it invalidates the plan-day content and completion-status providers. The service holds a container-scoped `Ref`, so this still runs after `pushReplacement` has disposed the screen that started it.

Analogous services exist for other sources: `groupRecitationCompletionProvider` (group_profile) and `myRecitationCompletionProvider` (practice; per-day dedupe that resets at local midnight).

---

## API endpoints

Paths are relative to the API base URL (`ApiConfig.baseUrl`, which already includes `/api/v1`):

| Action | Request | Notes |
|--------|---------|-------|
| Complete task | `POST /users/me/tasks/{taskId}/complete` | 2xx = success |
| Uncomplete task | `DELETE /users/me/task/{taskId}` | singular `task` |
| Complete subtask | `POST /users/me/sub-tasks/{subTaskId}/complete` | **409 = already completed, treated as success** |
| Day content | `GET /users/me/plan/{planId}/days/{dayNumber}` | |
| Day completion map | `GET /users/me/plans/{planId}/days/completion_status` | |

All are bearer-protected; see `lib/core/config/protected_routes.dart` (paths there omit `/api/v1`).

---

## Edge cases

- **Rapid taps on one task** — blocked by `_togglingTaskIds`.
- **Screen disposed mid-request** — task flow is `mounted`-guarded; subtask flow lives in a container-scoped service.
- **Repeat swipes** — `_completedSubtaskIds` dedupe + backend 409 handled as success.
- **Offline** — the action is queued (`PendingPlanAction`) and replayed by `flushPendingPlanActions()`; the UI still shows an error for task toggles because the repository returns `Left`.

### Known gaps

- `flushPendingPlanActions()` stops at the first failing action and never discards it, so a permanently rejected action (e.g. a 4xx on a deleted task) is retried forever and blocks every action queued after it.
- A task toggled offline shows an error and reverts, yet the queued action is still replayed later, so the server can end up in the state the user saw rejected. A complete followed by an untick both replay in order, which is correct; a lone rejected complete is not.
- `_completedSubtaskIds` is session-scoped and never cleared (fine for plan subtasks, which complete once).

---

## Code references

- Task UI: `lib/features/plans/presentation/widgets/plan_track/plan_details.dart`
- Subtask service: `lib/features/plans/presentation/widgets/plan_navigation/plan_subtask_completion.dart`
- Providers: `lib/features/plans/presentation/providers/user_plans_provider.dart`, `use_case_providers.dart`, `plan_days_providers.dart`
- Use cases: `lib/features/plans/domain/usecases/user_plans_usecases.dart`
- Repository: `lib/features/plans/data/repositories/user_plans_repository.dart`
- Pending queue: `lib/features/plans/data/datasource/plans_local_datasource.dart` (`PendingPlanAction`, `PendingPlanActionType`)
- Datasource: `lib/features/plans/data/datasource/user_plans_remote_datasource.dart`
- Models: `lib/features/plans/data/models/user/user_tasks_dto.dart`, `user_subtasks_dto.dart`, `lib/features/plans/data/models/response/user_plan_day_detail_response.dart`
- Router: `lib/core/config/router/app_router.dart`

## Related documentation

- [Token refresh flow](../architecture/TOKEN_REFRESH_FLOW.md)
- [Auth implementation](../architecture/AUTH_IMPLEMENTATION.md)
- [Local-first architecture](../architecture/LOCAL_FIRST_ARCHITECTURE.md)
- [Plan search pagination](./PLAN_SEARCH_PAGINATION.md)
