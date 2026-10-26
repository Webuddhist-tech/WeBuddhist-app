# Documentation Index

Every Markdown document in the repository, grouped by location. **Status**:
*current* = matches the code; *historical* = describes an earlier
implementation (paths/APIs may be gone); *proposal* = not implemented yet.

## Project level

| Doc | Purpose | Status |
| --- | --- | --- |
| [README.md](../README.md) | Setup, flavors, env keys, structure, CI | current |
| [CONTRIBUTING.md](../CONTRIBUTING.md) | Automatic versioning rules | current |
| [WARP.md](../WARP.md) | Short guide for coding agents | current |
| [docs/README.md](./README.md) | Documentation hub | current |
| [docs/SUMMARY.md](./SUMMARY.md) | This index | current |
| [docs/tolgee.md](./tolgee.md) | Tolgee OTA translations and ARB sync | current |
| [GOOGLE_LOGIN_FIX.md](../GOOGLE_LOGIN_FIX.md) | One-off Auth0 Google callback URL fix guide | historical |
| [documentation/chat-message-deletion-api.md](../documentation/chat-message-deletion-api.md) | Chat message deletion today + proposed bulk endpoint | proposal |

## Feature docs (`lib/features/<feature>/doc/README.md`)

Index and LLM usage guide: [lib/features/doc/README.md](../lib/features/doc/README.md).

| Feature | Scope |
| --- | --- |
| [auth](../lib/features/auth/doc/README.md) | Auth0 login, guest mode, user profile |
| [calendar](../lib/features/calendar/doc/README.md) | Tibetan lunar calendar |
| [connect](../lib/features/connect/doc/README.md) | Connect tab: feed, events, group discovery |
| [explore](../lib/features/explore/doc/README.md) | Placeholder tab (not in navigation) |
| [feedback](../lib/features/feedback/doc/README.md) | Help / contact form (backend forwards to Discord) |
| [group_chat](../lib/features/group_chat/doc/README.md) | Group and direct chat (WebSocket), reactions, prayer intentions, moderation |
| [group_profile](../lib/features/group_profile/doc/README.md) | Group pages, events, members, collective accumulators, collections |
| [home](../lib/features/home/doc/README.md) | Home dashboard + main navigation shell |
| [learn](../lib/features/learn/doc/README.md) | Placeholder tab (not in navigation) |
| [library](../lib/features/library/doc/README.md) | WeBuddhist Library API client: texts, TOC, editions, alignments, chants |
| [mala](../lib/features/mala/doc/README.md) | Prayer-bead counter, personal + group accumulation |
| [more](../lib/features/more/doc/README.md) | Me tab and settings |
| [notifications](../lib/features/notifications/doc/README.md) | Local scheduled reminders and notification settings |
| [onboarding](../lib/features/onboarding/doc/README.md) | First-run onboarding |
| [plans](../lib/features/plans/doc/README.md) | Practice plans: enrol, daily tasks, progress |
| [poems](../lib/features/poems/doc/README.md) | Story-style poems viewer |
| [practice](../lib/features/practice/doc/README.md) | Practice tab and daily routine |
| [push_notifications](../lib/features/push_notifications/doc/README.md) | Firebase Cloud Messaging lifecycle |
| [reader](../lib/features/reader/doc/README.md) | Text reader |
| [recitation](../lib/features/recitation/doc/README.md) | Recitation catalogue and My Recitations |
| [texts](../lib/features/texts/doc/README.md) | Reader-facing text contracts |
| [timer](../lib/features/timer/doc/README.md) | Meditation timers, Live Activity |

Other docs inside feature folders:

| Doc | Status |
| --- | --- |
| [lib/features/mala/README.md](../lib/features/mala/README.md) | current (mala internals and tests) |
| [lib/features/recitation/ARCHITECTURE_DIAGRAM.md](../lib/features/recitation/ARCHITECTURE_DIAGRAM.md) | historical |
| [lib/features/recitation/BEST_PRACTICES_APPLIED.md](../lib/features/recitation/BEST_PRACTICES_APPLIED.md) | historical (refactor notes) |
| [lib/features/recitation/CODE_IMPROVEMENTS.md](../lib/features/recitation/CODE_IMPROVEMENTS.md) | historical (refactor notes) |
| [lib/features/recitation/REFACTORING_SUMMARY.md](../lib/features/recitation/REFACTORING_SUMMARY.md) | historical (refactor notes) |

## Core

| Doc | Purpose | Status |
| --- | --- | --- |
| [lib/core/config/router/README.md](../lib/core/config/router/README.md) | Router, redirect guard and route table | current |
| [lib/core/config/locale/README.md](../lib/core/config/locale/README.md) | UI locale vs content language | current |
| [lib/core/theme/FONT_SYSTEM_GUIDE.md](../lib/core/theme/FONT_SYSTEM_GUIDE.md) | Font system, Tibetan vertical metrics | current |
| [assets/fonts/README.md](../assets/fonts/README.md) | Patched Tibetan font builds and how to rebuild them | current |
| [test/core/config/README.md](../test/core/config/README.md) | Locale provider tests | current |

## Architecture (`docs/architecture/`)

| Doc | Purpose | Status |
| --- | --- | --- |
| [LOCAL_FIRST_ARCHITECTURE.md](./architecture/LOCAL_FIRST_ARCHITECTURE.md) | Hive-backed local-first screen pattern (Home, Mala, Me stats) | current |
| [AUTH_IMPLEMENTATION.md](./architecture/AUTH_IMPLEMENTATION.md) | Auth architecture: Auth0 access tokens, Dio interceptors, credentials-manager refresh | current (rewritten Oct 2026) |
| [TOKEN_REFRESH_FLOW.md](./architecture/TOKEN_REFRESH_FLOW.md) | Original ID-token refresh deep dive | historical — refresh now goes through the Auth0 credentials manager |
| [GUEST_MODE_PERSISTENCE.md](./architecture/GUEST_MODE_PERSISTENCE.md) | Guest mode persistence (`AuthNotifier` / `RouteGuard`) | current (synced Oct 2026) |

## Implementation notes (`docs/implementation/`)

| Doc | Purpose | Status |
| --- | --- | --- |
| [AIRBRIDGE_SETUP.md](./implementation/AIRBRIDGE_SETUP.md) | Airbridge SDK and native secret injection | current |
| [FORCE_UPDATE_MODAL.md](./implementation/FORCE_UPDATE_MODAL.md) | Blocking `upgrader` update dialog | current |
| [ERROR_MESSAGE_MAPPER_IMPLEMENTATION.md](./implementation/ERROR_MESSAGE_MAPPER_IMPLEMENTATION.md) | `ErrorMessageMapper` (`lib/core/error/error_message_mapper.dart`) | current (rewritten Oct 2026) |
| [PLAN_SEARCH_PAGINATION.md](./implementation/PLAN_SEARCH_PAGINATION.md) | Plan search + infinite scroll | partly historical — search now lives in `lib/features/practice` |
| [TASK_COMPLETION_TRACKING.md](./implementation/TASK_COMPLETION_TRACKING.md) | Plan task/subtask completion and offline queue | current (rewritten Oct 2026) |

## Changelog (`docs/changelog/`)

| Doc | Purpose | Status |
| --- | --- | --- |
| [AUTH0_TOKEN_REFRESH_FIXES.md](./changelog/AUTH0_TOKEN_REFRESH_FIXES.md) | Oct 2025 ID-token refresh review | historical |
| [SPLASH_AND_GUEST_MODE_IMPROVEMENTS.md](./changelog/SPLASH_AND_GUEST_MODE_IMPROVEMENTS.md) | Oct 2025 splash / guest mode changes (v0.8.5) | historical |
| [RECITATION_API_FIX.md](./changelog/RECITATION_API_FIX.md) | Nov 2025 recitation API fix | historical |
| [V2.8.9_RELEASE_NOTES.md](./changelog/V2.8.9_RELEASE_NOTES.md) | v2.8.9 release notes | historical |
| [TEST_RELEASE_NOTES.md](./changelog/TEST_RELEASE_NOTES.md) | Draft "what's new" for a test release | historical |
