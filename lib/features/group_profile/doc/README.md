# Group Profile Feature

> **LLM context doc** — read this before changing anything under `lib/features/group_profile/`.

## Purpose

Group/community profile pages: follow, events (attend, live stream, composer, admin tools), practices, posts, members, collective accumulators, recitation collections, and admin queues (join requests, reports).

## User-facing functionality

- Group profile with banner, avatar, follow/join, about (`group_about_screen.dart`), social links
- Tabs: posts, events, practices, members (posts tab shows when the group has posts or the user may post)
- Follow/unfollow (community vs page types); private communities use a join request (`group_join_request_drawer.dart`, `submitGroupJoinRequest`) and show a removal/ban notice (`group_removed_notice_card.dart`, `groupRemovalNoticeProvider`)
- Per-group push toggles (chat / content) — `group_notification_settings_drawer.dart`
- Series enrollment through a group (auto-join on enroll)
- Event detail (`group_event_detail_screen.dart`): attend/leave (hybrid events ask online vs in-person via `group_event_participation_dialog.dart`), participants drawer, videos/about/accumulations tabs, "enter puja" (auto-enrolls in the event's series or previews its plan), live YouTube player with language switch (`group_event_live_player.dart` → `GroupEventLiveHeader` / `GroupEventLivePlayer`, also embedded in `plans/.../plan_details.dart`), add offline recitations to an event accumulation
- Event admin: `group_event_manage_screen.dart` (edit → composer, in-person counts → `group_event_in_person_counts_screen.dart`)
- **Group accumulators** — collective chant counters (integrates with mala); leaderboard + my contributions; session-complete share sheet
- **Recitation collections** — daily chant checklist with completion tracking; chants with audio get a play button that opens the reader with the first recording auto-playing (`group_recitation_audio_sheet.dart`, `collectionAudioTracksFor`)
- Admin queues: join requests (`group_join_requests_screen.dart`), reported chat messages (`group_reports_screen.dart`), remove/ban member (`group_remove_member_sheet.dart`)
- Deep links and share support

## Architecture

```
group_profile/
├── data/       datasources (profile, accumulator, post, event composer, place search), models, repositories
├── domain/     entities, repositories, usecases (get profile, update notification prefs)
└── presentation/  providers (hub ~1.8k lines + focused files), screens, utils, widgets
```

**No barrel file.**

## Key files

| Area | Files |
|------|-------|
| Main screen | `presentation/screens/group_profile_screen.dart` |
| Provider hub | `presentation/providers/group_profile_providers.dart` |
| Posts | `group_post_providers.dart`, `group_profile_posts_tab.dart`, `group_post_composer_screen.dart`, `group_post_add_link_sheet.dart`, `group_post_add_in_app_content_sheet.dart` (followed events/practices/chants → `/open/...` deep link via `GroupPostInAppContent`, posted unshortened so the feed's link card can route it in-app via `openLink`) |
| Events composer | `group_event_composer_screen.dart` (4-step wizard; draft in `GroupEventDraft`). Step 1 "About": `group_event_about_step.dart` (cover sheet, languages sheet, markdown editor; languages from `/languages`). Step 2 "When & where": `group_event_when_where_step.dart` with date/time/timezone/repeats sheets (`group_event_schedule_utils.dart` derives recurrence rules from the first date, lunar via `tibetanCalendarServiceProvider`), venue = `group_event_venue_sheet.dart` → `group_event_pin_screen.dart` (flutter_map + optional LocationIQ via `Env.locationIqToken`) → `group_event_venue_name_sheet.dart`, live link with "Use channel link". Step 3 "Practices & videos": `group_event_practices_step.dart`; picker `group_event_add_practice_sheet.dart` reads the studio's CMS lists (`groupEventPracticeOptionsProvider` → `GET /cms/dashboard/items?group_id&status=PUBLISHED&include_partner_groups`, `/cms/author/groups/{id}/recitation-collections`, `/cms/groups/{id}/accumulators`; the public practices feed hid items; client-side filter/search; one plan-or-series + one chant collection + many accumulations, each with a count mode → accumulation `event_format`/`count_mode`), videos via `group_event_add_video_sheet.dart` (YouTube oEmbed title through `chatLinkPreviewProvider`; sent as `links` type `video`). Step 4 "Review & publish": `group_event_review_step.dart` (rows jump back to a step; settings sheet `group_event_settings_sheet.dart` = chat/notifications/intentions from `GET /cms/intentions`), publish = upload cover (`/cms/media/upload`) → `POST /cms/author/groups/{id}/locations` for a new venue → `POST /cms/events` (`GroupEventRequestBuilder` mirrors the studio body: uppercase language codes, UTC instants via `timezone`, recurring anchored on now) → `group_event_published_view.dart`; create/update send `status` (`published` on Publish, `draft` on close once name + schedule are valid, "Saved as draft" toast); composer pops `GroupEventComposerResult` and the body refreshes the events tab. Publishers see the CMS list (`groupCmsEventsProvider`, `GET /cms/events?group_id=`) with a Drafts section; a draft reopens via `GroupEventDraftMapper.fromJson(raw)` and saves through `PUT /cms/events/{id}` (venue/cover reused when unchanged); Delete draft = `DELETE /cms/events/{id}` |
| Event detail / live | `group_event_detail_screen.dart`, `group_event_live_player.dart`, `group_event_live_utils.dart`, `group_event_actions.dart`; providers `groupEventDetailProvider`, `groupEventInLanguageProvider` (live language toggle), `groupEventParticipantsProvider`; attending goes through `joinGroupEventEnsuringGroupMembership` (connect, auto-joins the group first) → `POST /events/{id}/participants`, leave = `DELETE /events/{id}/participants/me` |
| Event admin | `group_event_manage_screen.dart`, `group_event_in_person_counts_screen.dart` + `groupEventInPersonCountsProvider` (`/cms/events/{id}/in-person-counts`, reloads page 1 after every write so API totals stay right) |
| Accumulator | `group_accumulator_providers.dart` (`joinGroupAccumulator`, `finishGroupAccumulatorSession`, `refreshGroupAccumulatorData`, join cache), `group_accumulator_screen.dart`, `group_accumulator_practice_launcher.dart` (`openGroupAccumulatorPractice` from plan tasks), `group_accumulator_chant_bar.dart` (reader/mala target picker), `group_accumulator_session_complete_sheet.dart` |
| Recitation collection | `group_recitation_collection_screen.dart`, `group_recitation_collection_row.dart`, `group_recitation_audio_sheet.dart`, `group_recitation_completion_service.dart`, completion providers in the hub |
| Join requests / reports / members | `groupJoinRequestsProvider` (hub), `group_reports_providers.dart`, `groupMembersProvider.removeMember` (`/cms/author/groups/{id}/joined-users/{userId}/remove`), `groupMembershipEpochProvider` |
| Notifications | `group_notification_preferences_provider.dart` (queued per-toggle writes, keep-alive while a write drains; `/users/me/notification-preferences/groups/{id}`) |
| Repository | `GroupProfileRepositoryInterface` (note naming) |
| Follow | `groupFollowProvider` with sealed `GroupFollowState` |

## State management

- `FutureProvider.autoDispose.family`: profile, events, event detail, accumulators, accumulator detail, CMS events, post permission
- `StateNotifierProvider.autoDispose.family`: practices, members, follow, recitation completion, posts, join requests, reports, event participants, accumulator members, in-person counts, notification preferences
- Work that can outlive the screen (join accumulator, finish chant session, attend event) takes a `ProviderContainer` (`ProviderScope.containerOf(context, listen: false)`), not a `WidgetRef` — a disposed widget's `ref` throws
- Sealed `GroupFollowState`: Loading / Success / Failure
- Request generation counters on paginated notifiers — drop stale responses
- Cross-invalidation with connect on follow/unfollow

## Data sources

- **Remote API** — profile (`/author/groups/{id}`), members, events (`/events`, `/events/{id}`, participants), practices, follow, accumulators (`/group-accumulators/...`, join = `POST /group-accumulators/{id}/join`), recitation completions, join requests, reports, posts (`GroupPostRemoteDatasource`: permission, list, CMS create + media upload), event composer (`GroupEventComposerRemoteDatasource`: `/cms/events`, locations, intentions, in-person counts), place search (LocationIQ)
- Language-aware via `contentLanguageProvider`
- Offline chant dialog for accumulator contributions (synced via **mala**)

## Cross-feature dependencies

- **auth** — login gating, bearer-sensitive `is_group_enrolled`
- **connect** — pending groups, my groups, discover sync; posts reuse `ConnectPost` + `ConnectPostCard`
- **home** — series enrollment helpers
- **mala** — accumulator sync, group session counts
- **plans** — markdown, date formatting on practice cards

## Notable patterns

- **`GroupProfileRepositoryInterface`** — not plain `GroupProfileRepository`
- Optimistic follow with `countDelta` on member counts
- Tri-state group enrollment for series: `true` / `false` / `null`
- Members tab lazy refresh via `groupMembersTabActiveProvider`
- Many APIs return `Either<Failure, T>` in FutureProviders

---

## How to make changes (LLM playbook)

### Principles

1. **`group_profile_providers.dart` is large** — add focused provider files when possible instead of growing the hub.
2. **Always invalidate connect providers** after follow/unfollow.
3. **Respect tri-state enrollment** — don't coerce `null` to `false`.
4. **Accumulator session vs lifetime** — align with mala doc (`lib/features/mala/doc/README.md`). An accumulator's "joined" (`is_joined`, `joined_only`) means the user called the accumulation's `/join`, not that they are a group member. Group count sync posts an absolute total and the server ignores a lower one, so seed local totals from a fresh server count before adding (see `_addRecitations` in the event detail screen).
5. Use `GroupProfileRepositoryInterface` naming consistently.

### Do

- Add new tabs as separate widget + provider family with lazy load flags
- Use sealed states for async UI (follow pattern)
- Increment request generation on paginated fetches to ignore stale pages
- Gate auth-required actions with login drawer

### Don't

- Don't gate the posts tab on the profile payload — `groupPostPermissionProvider` (`/users/me/permission/{groupId}`) decides who may post
- Don't duplicate connect feed logic here
- Don't break mala group sync when changing accumulator API fields
- Don't fetch members tab aggressively — use lazy refresh providers

### Common tasks

| Task | Where to start |
|------|----------------|
| New profile field | model → entity → remote datasource → repository → profile provider |
| Event UI | `group_event_detail_screen.dart`, events providers |
| Accumulator change | coordinate with `mala` sync manager + accumulator providers |
| Follow flow | `groupFollowProvider`, connect invalidation list |

### Testing

- Test optimistic follow rollback on failure
- Test stale pagination ignored via generation counter
- Test auth-gated enrollment fields
