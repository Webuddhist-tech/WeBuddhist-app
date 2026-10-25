# Feedback Feature (Help & contact)

> **LLM context doc** — read this before changing anything under `lib/features/feedback/`.

## Purpose

One form for reporting a problem, sharing an idea, suggesting content, or offering to help. The message goes to `POST /feedback`; the backend stores it, forwards it to Discord, and posts it into the user's **WeBuddhist Team** direct chat, where replies arrive.

## User-facing functionality

- Help & contact screen (`/help-contact`): optional topic chip, message (max 1000 chars), up to 3 photos from the gallery
- Topics: Report a problem, Idea or feedback, Suggest content, Help or collaborate
- "Message sent" sheet after a send, with **Open chat** → the Team chat room (or the Chats list when the backend returns no room)
- Localized error messages: offline, rate-limited, images too large, service unavailable, generic failure
- Team chat shows the backend's "Sent from Help & contact · {topic} · {n} photos" context line translated (parsed by `parseHelpContext`)

## Architecture

```
feedback/
├── data/          feedback_remote_datasource.dart, feedback_repository_impl.dart
├── domain/        entities (FeedbackReport, FeedbackReceipt, HelpTopic), repository, help_context_line.dart
└── presentation/  providers, screens/help_contact_screen.dart, utils, widgets
```

No local storage, no barrel file.

## Key files

| Area | Files |
|------|-------|
| Screen + entry point | `presentation/screens/help_contact_screen.dart` (`HelpContactScreen.open`) |
| Send | `presentation/providers/feedback_providers.dart` (`sendFeedbackProvider` → `SendFeedback`) |
| API | `data/datasource/feedback_remote_datasource.dart` |
| Sent sheet | `presentation/widgets/message_sent_sheet.dart` |
| Chat context line | `domain/help_context_line.dart` |
| Errors | `presentation/utils/feedback_failure_message.dart`, `FeedbackFailure` enum |
| Tests | `test/features/feedback/`, `test/core/config/protected_routes_feedback_test.dart` |

## Data flow

1. `HelpContactScreen.open(context, ref, {topic})` — guests get `LoginDrawer` instead (the backend has no anonymous feedback). Entry points: Settings ("Help & contact" row) and the home share prompt's Feedback button (`HelpTopic.ideaFeedback`).
2. `SendFeedback` builds a `FeedbackReport` with app version (`packageInfoProvider`) and `Platform.operatingSystem{,Version}`, calls the repository, and throws `FeedbackException(FeedbackFailure)` on failure.
3. `FeedbackRemoteDatasource.submit` checks total image size (≤ 10 MB, `tooLargeCode`), then posts multipart: `content`, `platform`, `app_version`, optional `topic` (slug), and one `images` part per file (`feedback_{n}.{ext}`).
4. The screen pops with a `HelpContactResult`; `open` then shows `MessageSentSheet`.

## Backend contract

- `POST /feedback` (protected — listed in `ProtectedRoutes.paths`; sender comes from the token).
- 60 s send/receive timeouts and **no automatic retry** (`RetryInterceptor.noRetryKey`): a retry after the backend committed would store and post the message twice.
- 413 → `ValidationException(code: feedback_too_large)`.
- 201 body: only `room_id` is read, and it is optional (the backend may not send it yet).

## Cross-feature dependencies

- **auth** — `authProvider` (guest gating), `LoginDrawer`, `userProvider` (first name on the sent sheet)
- **group_chat** — `/chats`, `/direct-chat/:roomId`; `chat_rooms_list.dart` and `direct_chat_screen.dart` use `parseHelpContext`
- **more** — Settings row; **home** — share prompt button
- **core** — `ClarityMask` on the route and sent sheet (the message is private)

---

## How to make changes (LLM playbook)

### Principles

1. **One send path** — the app sends no chat message itself; the backend posts into the Team chat.
2. **Never retry `POST /feedback` automatically** — duplicates reach Discord and the chat.
3. **Topic labels are matched in English, shown translated** — `HelpTopic.canonicalLabel` must match what the backend writes; unknown parts of the context line are skipped, never shown.
4. Keep the route and sent sheet Clarity-masked.

### Do

- Add a topic by extending `HelpTopic` (slug + canonical label) and `help_topic_l10n.dart`, and coordinate the slug/label with the backend
- Map new failure types in `feedbackFailureOf` and `feedbackFailureMessage`

### Don't

- Don't allow guests to reach the form — use `HelpContactScreen.open`, not a raw `push`
- Don't raise image limits without matching the backend's 10 MB total cap

### Testing

- `feedback_remote_datasource_test.dart` (form shape, size cap, 413), `feedback_providers_test.dart` (failure mapping), `help_context_line_test.dart`, `help_contact_screen_test.dart`
