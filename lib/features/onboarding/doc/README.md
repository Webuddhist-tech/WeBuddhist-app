# Onboarding Feature

> **LLM context doc** — read this before changing anything under `lib/features/onboarding/`.

## Purpose

First-run multi-step onboarding: welcome, language, tradition selection, finish — plus optional event plan enrollment.

## User-facing functionality

- PageView flow: Welcome → Language → Tradition → Finish
- Persists preferences locally during flow
- Optional event plan enrollment (`kOnboardingEvents` hardcoded promos)
- On completion: save preferences, mark onboarding done in auth, enroll plans + routine block, navigate home

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
| Completion | `application/event_enrollment_service.dart` |
| Barrel | `onboarding.dart` (not all screens exported) |

## State management

- `onboardingProvider` — page index, preferences
- `traditionSelectionProvider` — multi-select traditions
- Uses **hooks_riverpod** in application layer

## Data sources

- **Local:** SharedPreferences / local datasource
- **Remote:** tradition paths, preference sync

## Cross-feature dependencies

- **auth** — `markOnboardingCompleted()` on finish (no network round-trip)
- **plans** — `SubscribeToPlanUseCase`, enrollments
- **practice** — routine time-block creation, Hive
- **notifications** — sync engine after routine save

## Notable patterns

- Completion updates auth flag locally first
- Event enrollment is best-effort/idempotent
- Hardcoded `kOnboardingEvents` for promotional plans
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
| Event promo | `kOnboardingEvents` + enrollment service |
| Tradition options | remote datasource + tradition selection notifier |

### Testing

- Test completion marks auth onboarding flag
- Test partial progress persistence on kill/relaunch
- Test idempotent re-enrollment
