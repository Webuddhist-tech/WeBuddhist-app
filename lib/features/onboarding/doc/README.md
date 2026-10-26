# Onboarding Feature

> **LLM context doc** — read this before changing anything under `lib/features/onboarding/`.

## Purpose

First-run multi-step onboarding for signed-in users: welcome, language, tradition selection, finish.

## User-facing functionality

- PageView flow: Welcome → Language → Tradition → Finish
- Language step applies the UI locale + backend content language (`selectAppLanguage`) and saves the preference locally
- Tradition step saves selections to the backend (`POST/DELETE /users/me/traditions`, options from `GET /users/me/traditions/onboarding`)
- On completion: save preferences locally, `PUT /users/me/onboarding` (`has_seen_onboarding: true`), call auth `markOnboardingCompleted()`, navigate home
- The onboarding *step* no longer enrolls event plans. `EventEnrollmentService` (plan subscribe + routine time block) still lives here but is only used by `features/plans/presentation/plan_info.dart`; `kOnboardingEvents` is currently unreferenced

## Architecture

```
onboarding/
├── application/    notifiers + state (hooks_riverpod)
├── data/             local + remote datasources, models, repository
├── domain/           entities, repository, usecases
├── presentation/     providers, screens, widgets
└── onboarding.dart
```

**Application layer** holds notifiers separate from `presentation/providers/`.

## Key files

| Area | Files |
|------|-------|
| Flow host | `presentation/screens/onboarding_wrapper.dart` |
| State | `application/onboarding_notifier.dart`, `onboarding_state.dart` |
| Traditions | `application/tradition_selection_notifier.dart` |
| Completion | `OnboardingNotifier.submitPreferences()`, `data/repositories/onboarding_repository.dart` |
| Remote | `data/datasource/onboarding_remote_datasource.dart` (`/users/me/onboarding`, `/users/me/traditions*`) |
| Event enrollment (used by plans) | `application/event_enrollment_service.dart`, `presentation/providers/event_enrollment_providers.dart` |
| Analytics | `presentation/utils/onboarding_analytics.dart` |
| Barrel | `onboarding.dart` (not all screens exported) |

## State management

- `onboardingProvider` — page index, preferences (**not** autoDispose — page index survives across sessions in one process)
- `traditionSelectionProvider` — multi-select traditions (autoDispose)
- Uses **hooks_riverpod** in application layer

## Data sources

- **Local:** SharedPreferences / local datasource (preferences; backend preference sync is still a TODO in the repository)
- **Remote:** onboarding status (`GET/PUT /users/me/onboarding`), tradition paths and user traditions

## Cross-feature dependencies

- **auth** — `markOnboardingCompleted()` on finish (no network round-trip)
- **locale** — `selectAppLanguage` on the language step
- **plans / practice / notifications** — only through `EventEnrollmentService` (consumed by plans)

## Notable patterns

- Completion updates auth flag locally first
- Event enrollment (when used) is best-effort/idempotent
- Barrel hides duplicate `OnboardingPreferences` name

---

## How to make changes (LLM playbook)

### Principles

1. **Completion must call auth `markOnboardingCompleted()`** — router depends on it.
2. **Event enrollment failures are logged, not blocking** — user still reaches home.
3. **Keep application notifiers in `application/`** — don't move to presentation without refactor.
4. Adding steps requires updating PageView indices and wrapper sync.

### Do

- Add l10n for new steps
- Wire new preferences through `OnboardingPreferences` entity + local save
- Trigger notification sync after routine block creation

### Don't

- Don't block home navigation on enrollment API failure
- Don't fetch onboarding status before auth init completes
- Don't duplicate plan enrollment logic — use plans use cases

### Common tasks

| Task | Where to start |
|------|----------------|
| New onboarding step | screen widget + wrapper page list + notifier page count |
| New preference field | entity → local model → notifier → save use case |
| Event plan enrollment | `event_enrollment_service.dart` (called from plans) |
| Tradition options | remote datasource + tradition selection notifier |

### Testing

- Test completion marks auth onboarding flag
- Test partial progress persistence on kill/relaunch
- Test idempotent re-enrollment
