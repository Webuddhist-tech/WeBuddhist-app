# More Feature

> **LLM context doc** — read this before changing anything under `lib/features/more/`.

## Purpose

**Me tab** (profile, stats, streak) and **Settings hub** (More): language, theme, notifications, legal, account management.

## User-facing functionality

- Me tab: profile header, streak card, practice stats (timer, accumulations, practice days)
- Settings (`/home/settings`): edit profile (signed-in only), language, notifications link, theme toggle, about, legal, Help & contact (→ **feedback**), sign in / log out
- Delete account: reached from Edit profile (`/delete-account`), not from Settings directly
- Legal hub (`/legal`) → terms of service (`/terms-of-service`) and privacy policy (`/privacy-policy`)
- Streak sharing sheet (verse-of-day integration)
- Mantra accumulation breakdown sheet
- Practice days / series completion history sheet
- Tradition selection on profile edit (reuses onboarding API)
- Guest vs logged-in views with login prompts

## Architecture

```
more/
├── data/       user stats datasource (local + remote), models, repository
├── domain/     entities, repository, usecases
└── presentation/  screens at feature root + providers + widgets
```

**Note:** screens live at `presentation/` root, not `presentation/screens/`.

## Key files

| Area | Files |
|------|-------|
| Me tab | `presentation/me_screen.dart` |
| Settings | `presentation/more_screen.dart` |
| Profile edit | `presentation/edit_profile_screen.dart` |
| Stats | `presentation/providers/user_stats_provider.dart` |
| Traditions | `user_traditions_provider`, onboarding datasource reuse |
| Delete account | `presentation/delete_account_screen.dart` |
| Legal / about | `presentation/{legal,terms_of_service_screen,privacy_policy_screen,about_screen}.dart` |
| Language picker | bottom sheet in `more_screen.dart` → `selectAppLanguage()` (`core/config/locale`) |

## State management

- `userStatsFutureProvider` — `StreamProvider<Either<Failure, UserStats>>`, auth-gated
- Mantra counts, series days — Future/stream providers
- Guests return `Left(AuthenticationFailure(...))`

## Data sources

- **Remote:** user stats, mantra counts, series completions
- **Local:** Hive/cache for offline stats
- **Onboarding remote:** tradition paths for profile edit

## Cross-feature dependencies

- **auth** — profile, delete account, guest gating
- **notifications** — settings screen link
- **feedback** — Help & contact row (`HelpContactScreen.open`)
- **core/config/locale** — `selectAppLanguage` (PUTs `/users/me/language` first when signed in)
- **onboarding** — tradition models/datasource
- **home** — verse of day in streak share
- **plans** — series-day DTO references

---

## How to make changes (LLM playbook)

### Principles

1. **Auth-gate stats providers** — return `AuthenticationFailure` for guests, show login CTA in UI.
2. **Reuse onboarding tradition infra** — don't duplicate tradition API calls.
3. **Match screen placement convention** — screens at `presentation/` root for this feature.
4. Settings navigates out to other features (notifications) — don't duplicate their logic.

### Do

- Add new stat rows via entity → repository → provider → `MeStatsSection`
- Use stream providers when data should update reactively after practice
- Apply Tibetan strut styles in settings app bar (existing pattern)

### Don't

- Don't fetch stats for guests without graceful failure UI
- Don't duplicate notification settings UI — link to notifications feature
- Don't move screens into `screens/` subfolder without team refactor

### Common tasks

| Task | Where to start |
|------|----------------|
| New stat metric | remote datasource → entity → use case → provider → widget |
| Settings row | `more_screen.dart` |
| Streak share | `streak_share_sheet.dart`, home verse provider |
| Profile field | coordinate with **auth** `UserNotifier` |

### Testing

- Test guest Me screen shows login prompts, not errors
- Test stats stream updates after auth login
