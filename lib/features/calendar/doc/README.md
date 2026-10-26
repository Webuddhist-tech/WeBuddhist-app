# Calendar Feature

> **LLM context doc** — read this before changing anything under `lib/features/calendar/`.

## Purpose

Tibetan lunar calendar: Gregorian grid with lunar day info and moon phases (screen at `/home/calendar`, opened from the home header calendar button). The engine is also used by group events for lunar repeat rules.

## User-facing functionality

- Full calendar screen with month grid (`TibetanCalendarScreen`, route `AppRoutes.calendar` = `/home/calendar`)
- Header card for the selected day: "Day {lunarDay}", lunar-month label, moon-phase icon
- Month navigation (chevrons + horizontal swipe) with a lunar-month subtitle; padded leading/trailing days
- "Upcoming events" list: moon-phase events (lunar days 1/8/15/30) in the focused month from today on, collapsed to 2 with Show more/less
- "Today" sync on open and when the app resumes on a new calendar day
- Day tapping is currently disabled (`onDaySelected` commented out in `tibetan_calendar_grid.dart`), so the selected day is always today

## Architecture

```
calendar/
├── data/       remote datasource, kharag engine, models, repository impl
├── domain/     entities, models (events/phases), repository, usecases, engine interface
└── presentation/  providers, screen, widgets, l10n utils
```

**No barrel file** — import paths directly.

## Key files

| Area | Files |
|------|-------|
| Screen | `presentation/screens/tibetan_calendar_screen.dart` |
| Providers | `presentation/providers/tibetan_calendar_providers.dart` |
| Offline engine | `data/kharag_tibetan_calendar_service.dart` |
| Engine interface | `domain/tibetan_calendar_service.dart` |
| Remote API | `data/datasource/calendar_remote_datasource.dart` |
| Events list | `presentation/widgets/upcoming_events_list.dart` |
| `GET /calendar/today` | `todayCalendarDayProvider` — defined but **not consumed anywhere** today |

## State management

- `StateProvider`: `selectedCalendarDayProvider`, `focusedCalendarMonthProvider`
- `Provider`: `tibetanCalendarServiceProvider` (engine), `engineMonthDaysProvider` (family), `resolvedMonthDaysProvider` (family — merges engine + backend overlay), `resolvedDayProvider` (family), `monthEventsProvider` (family)
- `FutureProvider.family`: `calendarMonthProvider` (keyed by Gregorian `(year, month)`; returns `[]` on failure), `backendMonthOverlayProvider`
- `FutureProvider`: `todayCalendarDayProvider` (unused)
- None of these are `autoDispose`: a month that failed (offline) stays cached as empty for the process lifetime

## Data sources

- **Remote:** `GET /calendar/{year}/{month}`, `GET /calendar/today`
- **Offline engine:** `KharagTibetanCalendarService` — always available fallback
- No persistent cache; engine computes synchronously

## Cross-feature dependencies

- **home** — `home_header.dart` pushes `AppRoutes.calendar`. (`CalendarBannerCard` in home is a stateless widget that is not currently rendered and does not read calendar providers.)
- **group_profile** — `group_event_repeats_sheet.dart` / `group_event_schedule_utils.dart` use `TibetanCalendarService` (Phugpa) for lunar recurrence
- **core** — `dioProvider`, l10n, router

## Hybrid resolution pattern

**Backend-primary, engine-fallback.** UI never blocks on network. Backend refines when available. Do not invert this — the grid must render immediately from the engine.

---

## How to make changes (LLM playbook)

### Principles

1. **Never block UI on network** — engine data renders first.
2. **Register all `ref.watch` before first `await`** in async providers (documented in codebase).
3. **Gregorian-month keyed API** with neighbour-month prefetch for grid padding.
4. Keep `domain/models/` for events/phases; `domain/entities/` for full entities.

### Do

- Extend moon-phase logic in `domain/models/moon_phase.dart`
- Add festival events in `monthEventsProvider` when backend supports them
- Update l10n via `calendar_l10n_utils.dart`
- Keep `TibetanCalendarService` stable — group events depend on it

### Don't

- Don't remove offline engine fallback
- Don't add blocking loading states for the month grid
- Don't create a barrel file without team agreement (feature has none today)

### Common tasks

| Task | Where to start |
|------|----------------|
| New lunar event type | `calendar_event.dart`, `monthEventsProvider`, widgets |
| Cell UI change | `calendar_day_cell.dart`, `tibetan_calendar_grid.dart` |
| API shape change | models → repository → `resolvedMonthDaysProvider` merge logic |
| Home entry point | `home/.../home_header.dart` (calendar button) |

### Testing

- Test engine-only path (no network)
- Test backend overlay merge
- Test month boundary / padding days
- Test a month containing a DST transition (range loops use `DateTime.add(Duration(days: 1))` on local dates)
