# Push Notifications Feature

> **LLM context doc** — read this before changing anything under `lib/features/push_notifications/`.

## Purpose

Firebase Cloud Messaging (FCM) lifecycle: token registration, foreground display, tap routing, and preference sync for **server-delivered** plan/series reminders.

## User-facing functionality

- Request OS permission, initialize FCM
- Register device tokens with backend on sign-in
- Show foreground pushes via local notifications
- Skip the banner for a push about the screen already in front (`ForegroundPushFilter`)
- Handle taps: foreground, background, terminated
- Deep-link by `session_type` + `source_id`
- Sync push targeting prefs when notification settings change
- Retry init on cold-start failure (max 3, backoff)

## Architecture

```
push_notifications/
├── application/push_notification_service.dart
├── data/repositories/push_messaging_repository_impl.dart
├── domain/entities, repositories
└── presentation/push_message_navigator.dart, providers
```

**No barrel file.** No domain use cases — application service pattern.

## Key files

| Area | Files |
|------|-------|
| Service | `application/push_notification_service.dart` |
| Foreground filter | `application/foreground_push_filter.dart` |
| Bootstrap | `presentation/providers/push_notification_providers.dart` |
| Navigator | `presentation/push_message_navigator.dart` |
| Firebase adapter | `data/repositories/push_messaging_repository_impl.dart` |
| Background handler | top-level `pushNotificationBackgroundHandler` |

## State management

- `pushNotificationBootstrapProvider` — wired at app root (`MyApp`)
- Listens: `authProvider`, `notificationProvider`
- `pushMessageNavigatorProvider` — single routing funnel

## Data sources

- **Firebase Cloud Messaging** — only imported in repository impl
- **Backend:** `POST /users/me/push-devices`
- **Local:** FCM token, `pushDeviceId` UUID, notification preference flags
- **flutter_local_notifications** — foreground display

## Routing (`PushSessionType`)

| Type | Destination |
|------|-------------|
| PLAN | My Practices + pending nav seed |
| SERIES | Series detail by `source_id` |
| TIMER | Timers screen |
| RECITATION / COLLECTION / ACCUMULATION | Practice tab |
| VERSE_OF_DAY (and aliases) | Home tab (verse card) |
| CHAT + `chat_kind: GROUP` | Group chat by `group_id` (`source_id` is the room id) |
| CHAT + `chat_kind: PRIVATE` | Home tab (no private chat screen yet) |
| GROUP_POST | Post detail by `source_id` |
| EVENT / EVENT_REMINDER | Event detail by `source_id` |
| GROUP (join request created / decided) | Group profile by `source_id` |
| Empty / unknown | Home tab |

Post-frame scheduling (`_schedule`) — defer navigation until tree ready.

## Cross-feature dependencies

- **auth**, **notifications**, **home** (MainTab), **practice** (pending nav), **core** (router, dio)

## Server vs local split

- **FCM:** plan, series (routine toggle gates backend prefs), group chat, group posts, events, event reminders, join requests, verse of the day
- **Local only (notifications feature):** recitation, mala, timer

## Master switch

The app's master notification toggle is enforced server-side by
**unregistering the device**: OFF calls `DELETE /users/me/push-devices/{id}`
with the id kept from the register response (`StorageKeys.pushDeviceServerId`),
ON registers again. Token refreshes and sign-in while master is off never
re-register; sign-in with master off removes a registration left from an
earlier session. Register and unregister run through one reconcile loop
(`_requestReconcile`) that re-reads state after each pass and retries a
failed backend call with linear backoff, up to `maxReconcileRetries`.
Per-group toggles (group_profile feature) are separate, server-stored, and
greyed out in the UI while master is off.

---

## How to make changes (LLM playbook)

### Principles

1. **Firebase only in repository impl** — keep isolation.
2. **All tap paths through `PushMessageNavigator`** — no duplicate routing.
3. **Guests excluded** from token registration.
4. **Post-frame navigation** — don't push routes synchronously from FCM callbacks.

### Do

- Add new `session_type` in navigator + constants
- Re-register token when master/routine toggles change
- Use `Either` for backend registration errors

### Don't

- Don't import `firebase_messaging` outside repository impl
- Don't route plan/series locally — they're server push
- Don't register tokens before auth sign-in completes

### Common tasks

| Task | Where to start |
|------|----------------|
| New deep link type | `PushMessageNavigator`, `PushSessionType` |
| Token registration bug | service + repository + auth listener |
| Foreground display | service + `NotificationService` |
| Hide the banner while a screen shows the content | claim a matcher on `foregroundPushFilterProvider` in `initState`, release in `dispose` (see `GroupChatScreen._showsPush`) |
| Preference sync | listener on `notificationProvider` |

### Testing

- Test terminated vs background tap paths
- Test guest skips registration
- Test preference change re-registers token
