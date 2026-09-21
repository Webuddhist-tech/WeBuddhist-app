# Timer Feature

> **LLM context doc** — read this before changing anything under `lib/features/timer/`.

## Purpose

Preset meditation timers with countdown, pause/resume, lock-screen display, session reporting, and offline stop queue.

## User-facing functionality

- Browse preset timers + user-created ("Your timers") (authenticated)
- Create a custom timer (duration, ambient sound) via "+ Custom timer"
- Edit or delete your own timers from the card's ⋮ menu
- 5-second countdown → running phase
- Pause/resume with **wall-clock** remaining time (survives backgrounding)
- Completion bell (in-app + scheduled local notification)
- Android ongoing lock-screen notification
- iOS Live Activity
- Report elapsed duration to backend
- Offline stop queue flushed on reconnect
- Bookmarks on preset screen (via practice)

## Architecture

```
timer/
├── data/       remote + local datasources, repository, session notifier, live activity
├── domain/     preset_timer entity, repository interface, usecases
└── presentation/  providers, screens, sound player, widgets
```

**No barrel file.**

## Key files

| Area | Files |
|------|-------|
| Presets + Your timers | `presentation/screens/preset_timers_screen.dart` |
| Create / edit custom timer | `presentation/screens/new_timer_screen.dart` |
| Duration / Ambient sound sheets | `presentation/widgets/{duration_picker_sheet,ambient_sound_sheet}.dart` |
| Ambient sound playback (preview + session) | `presentation/services/ambient_sound_player.dart` |
| Active session | `presentation/screens/active_timer_screen.dart` |
| Providers | `presentation/providers/timers_providers.dart` |
| Offline queue | `data/datasource/timers_local_datasource.dart` |
| Android notif | `data/services/timer_session_notifier.dart` |
| iOS | `data/services/timer_live_activity.dart` |
| Bootstrap | `timerSyncBootstrapProvider` |

## State management

- `presetTimersFutureProvider` — **StreamProvider**, cache-first
- **Session state is local to `ActiveTimerScreen`** — not Riverpod (`_endsAt` wall-clock)
- `timerSyncBootstrapProvider` — flush pending stops on reconnect
- Auth gate: guests get `AuthenticationFailure`

## Data sources

- **Remote:** `GET /timers`, `POST /timers/user` (create custom timer),
  `PUT /timers/user/{timer_id}` (edit user-created timer),
  `DELETE /timers/user/{timer_id}` (delete user-created timer),
  `POST /timers/user/timer_stop`, `GET /ambient-sounds`
- **Hive:** cached presets per user, pending stop queue
- **PreferencesService:** user ID namespacing
- **notifications** channels for session + completion bell

### Timer model (`GET /timers` / `POST /timers/user`)

`PresetTimer`/`PresetTimerModel` carry the full API shape: `id`, `name`,
`durationMs`, `userId`, `groupId`, `type` (`"preset"` or `"user_created"` —
`isPreset`/`isUserCreated` getters), `description`, `ambientSoundId`,
`bellAtStart`, `bellAtEnd`, `parentPresetId`, `createdAt`, `updatedAt`.
"Your timers" on the presets screen filters on `isUserCreated`; the
"Preset timers" grid filters on `isPreset`.

`POST /timers/user` (`TimersRemoteDatasource.createUserTimer`) intentionally
**never sends** `group_id` or `parent_preset_id` — no app concept for either
yet. The New Timer screen has no name/description inputs, so those are
derived: `name` = `"{n} minutes"`, `description` = `""` (always sent).
Start/end bells are always on (backend default); the create flow does not
expose or accept them as user-configurable params. After a
successful create (and after a successful edit or delete) the repository
patches the cached list through `TimersLocalDatasource.upsertPresetTimer` /
`removePresetTimer`, so "Your timers" updates via the existing Hive-watch
stream. The `refreshPresetTimers()` that follows is only a best-effort resync
with the server ordering: its failure must not turn a completed create, edit
or delete into an error.

### Editing a user timer (`PUT /timers/user/{timer_id}`)

`NewTimerScreen` doubles as the edit screen: passing `timer:` switches the
title to "Edit timer", prefills duration + ambient sound, replaces the app-bar
"Save"/"Begin session" pair with a single "Save changes" button, and routes
through `UpdateUserTimerUseCase`. Route: `/home/timers/edit` with the
`PresetTimer` as `extra`, opened from the "Edit timer" entry in
`TimerMoreBottomSheet` (shown only when `isUserCreated`, like delete).

Only `name`, `duration` and `ambient_sound_id` are sent — nothing else on the
timer is user-owned yet. The name keeps tracking the duration (`"{n} minutes"`)
so the card label stays truthful. `ambient_sound_id` is **always** in the body,
including as `null`, which is how "Default (no sound)" clears an existing
sound.

### Ambient sounds (`GET /ambient-sounds`)

Separate small resource: `AmbientSound` entity / `AmbientSoundModel` /
`AmbientSoundsRemoteDatasource`, exposed via `ambientSoundsFutureProvider`
(`FutureProvider.autoDispose`, **not cached** — URLs are short-lived signed
S3 links, so it's refetched every time the sheet opens).

The "Ambient sounds" picker sheet previews a track on tap via
`AmbientSoundPlayer` (a `just_audio` wrapper). The volume slider in
that sheet is **local-only** — it controls preview playback volume and is
never sent to the API (no volume field exists on `CreateTimerRequest`).

`ActiveTimerScreen` uses the same player for the session track: it resolves
`ambientSoundId` against `ambientSoundsFutureProvider` when the running phase
starts, loops it, pauses/resumes it with the session, and stops it on
completion. The provider is kept alive with `ref.listenManual` for the
session because the urls expire. Ambient playback is best-effort — a missing
or unplayable track leaves the session running silently.

The bundled `assets/audios/meditation.wav` bell (`TimerSoundPlayer`) always
plays at session start and completion, and the scheduled start/completion
notifications are always armed when backgrounded.

## Cross-feature dependencies

- **auth** — preset list and stop reporting
- **notifications** — channels, ID scheme, completion scheduling
- **practice** — bookmarks on preset screen
- **push_notifications** — timer deep link → `/home/timers`

## Notable patterns

- **Wall-clock timing:** `_endsAt` is source of truth
- **Best-effort notifications** — never crash session on notif failure
- **Offline-first writes** for stop reports
- Completion bell scheduled only on backgrounding (avoid double-ring with in-app sound)

---

## How to make changes (LLM playbook)

### Principles

1. **Don't move active session to Riverpod** without strong reason — wall-clock local state is intentional.
2. **Enqueue failed stops locally** — flush via bootstrap on reconnect.
3. **Per-user Hive namespacing** — use same user ID pattern as mala.
4. Notification failures must not abort timer session.

### Do

- Cache presets cache-first (emit cached, refresh background)
- `GET /timers` must opt out of the HTTP cache so pull-to-refresh and
  user-created timer mutations show the latest server list.
- Use `StopUserTimerUseCase` for all session reporting
- Platform-specific lock screen: Android notifier vs iOS Live Activity
- Gate preset list for auth loading/guest states

### Don't

- Don't use periodic Timer for remaining time without wall-clock anchor
- Don't schedule completion bell in foreground if in-app sound plays (double-ring)
- Don't skip offline queue on API failure

### Common tasks

| Task | Where to start |
|------|----------------|
| Preset UI | `preset_timer_card.dart`, presets screen |
| Session UX | `active_timer_screen.dart`, `timer_progress_ring.dart` |
| Offline sync | local datasource + `timerSyncBootstrapProvider` |
| Lock screen | `timer_session_notifier.dart` / `timer_live_activity.dart` |

### Testing

- Test pause/resume after backgrounding
- Test pending stop flush on reconnect
- Test guest cannot load presets
