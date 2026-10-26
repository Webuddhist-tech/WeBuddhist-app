# WeBuddhist App — Documentation Hub

Start here when you need more than the project [README](../README.md).
[SUMMARY.md](./SUMMARY.md) lists every Markdown doc in the repository with its
status.

## Where documentation lives

| Location | What it holds |
| --- | --- |
| [`/README.md`](../README.md) | Setup, flavors, env keys, project structure, CI overview |
| [`/CONTRIBUTING.md`](../CONTRIBUTING.md) | Automatic versioning rules |
| [`lib/features/<feature>/doc/README.md`](../lib/features/doc/README.md) | **Primary per-feature docs** — read the relevant one before changing a feature |
| `docs/architecture/` | Cross-cutting design notes |
| `docs/implementation/` | Notes on specific integrations and features |
| `docs/changelog/` | Historical fix write-ups and release notes |
| [`docs/tolgee.md`](./tolgee.md) | Over-the-air translations and ARB ↔ Tolgee sync |

## Current, maintained docs

- **[Tolgee integration and sync](./tolgee.md)** — OTA UI strings via the
  Tolgee CDN, locale tag mapping, adding keys, the `tool/tolgee_sync.dart` CLI.
- **[Local-first architecture](./architecture/LOCAL_FIRST_ARCHITECTURE.md)** —
  the Hive-backed local-first pattern used by Home, Mala and Me stats.
- **[Airbridge setup](./implementation/AIRBRIDGE_SETUP.md)** — attribution /
  deep-link SDK and how its native secrets are injected.
- **[Force update modal](./implementation/FORCE_UPDATE_MODAL.md)** — the
  blocking `upgrader` dialog.
- **[Guest mode persistence](./architecture/GUEST_MODE_PERSISTENCE.md)** —
  guest sessions across launches (`AuthNotifier` / `RouteGuard`).
- **[Error message mapper](./implementation/ERROR_MESSAGE_MAPPER_IMPLEMENTATION.md)** —
  `lib/core/error/error_message_mapper.dart`.
- **[Task completion tracking](./implementation/TASK_COMPLETION_TRACKING.md)** —
  plan task/subtask progress and its offline queue.
- **[Authentication implementation](./architecture/AUTH_IMPLEMENTATION.md)** —
  current design (Auth0 access tokens, Dio interceptors, credentials-manager
  refresh). Feature-level reference:
  [`lib/features/auth/doc/README.md`](../lib/features/auth/doc/README.md).

## Historical docs (read with care)

The documents below describe earlier implementations. File paths and APIs in
them may no longer exist; check the code or the feature doc first.

- [Token refresh flow](./architecture/TOKEN_REFRESH_FLOW.md) — describes the
  former **ID-token**, `ApiClient`-based design. The app now sends Auth0
  **access tokens** through Dio interceptors, and the Auth0 credentials
  manager is the single refresh path (`AuthService.getValidAccessToken()` /
  `forceRefreshAccessToken()`).
- [Plan search and pagination](./implementation/PLAN_SEARCH_PAGINATION.md) —
  partly historical; plan search now lives in `lib/features/practice`.
- Everything in [`changelog/`](./changelog/)

## Adding documentation

- Feature behaviour → that feature's `lib/features/<feature>/doc/README.md`
  (and its row in `lib/features/doc/README.md`).
- Cross-cutting design → `docs/architecture/`; a specific integration →
  `docs/implementation/`.
- Add the new file to [SUMMARY.md](./SUMMARY.md).
- Reference real file paths and keep them current; delete a doc rather than
  let it describe code that no longer exists.
