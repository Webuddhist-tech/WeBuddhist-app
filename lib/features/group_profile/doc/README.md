# Group Profile Feature

> **LLM context doc** — read this before changing anything under `lib/features/group_profile/`.

## Purpose

Group/community profile pages: follow, events, practices, members, collective accumulators, and recitation collections.

## User-facing functionality

- Group profile with banner, avatar, follow/join, about, social links
- Tabs: posts, events, practices, members (posts tab shows when the group has posts or the user may post)
- Follow/unfollow (community vs page types)
- Series enrollment through a group (auto-join on enroll)
- Event detail + join/leave
- **Group accumulators** — collective chant counters (integrates with mala)
- **Recitation collections** — daily chant checklist with completion tracking
- Deep links and share support

## Architecture

```
group_profile/
├── data/       datasources (profile + accumulator), models, repositories
├── domain/     entities, repositories, get_group_profile_usecase
└── presentation/  providers (~950 lines hub), screens, utils, widgets
```

**No barrel file.**

## Key files

| Area | Files |
|------|-------|
| Main screen | `presentation/screens/group_profile_screen.dart` |
| Provider hub | `presentation/providers/group_profile_providers.dart` |
| Posts | `group_post_providers.dart`, `group_profile_posts_tab.dart`, `group_post_composer_screen.dart`, `group_post_add_link_sheet.dart`, `group_post_add_in_app_content_sheet.dart` (followed events/practices/chants → `/open/...` deep link via `GroupPostInAppContent`, posted unshortened so the feed's link card can route it in-app via `openLink`) |
| Events composer | `group_event_composer_screen.dart` (4-step wizard; draft in `GroupEventDraft`). Step 1 "About": `group_event_about_step.dart` (cover sheet, languages sheet, markdown editor; languages from `/languages`). Step 2 "When & where": `group_event_when_where_step.dart` with date/time/timezone/repeats sheets (`group_event_schedule_utils.dart` derives recurrence rules from the first date, lunar via `tibetanCalendarServiceProvider`), venue = `group_event_venue_sheet.dart` → `group_event_pin_screen.dart` (flutter_map + optional LocationIQ via `Env.locationIqToken`) → `group_event_venue_name_sheet.dart`, live link with "Use channel link". Step 3 "Practices & videos": `group_event_practices_step.dart`; picker `group_event_add_practice_sheet.dart` reads the group practices feed (`groupEventPracticeOptionsProvider`, client-side filter/search; one plan-or-series + one chant collection + many accumulations, each with a count mode → accumulation `event_format`/`count_mode`), videos via `group_event_add_video_sheet.dart` (YouTube oEmbed title through `chatLinkPreviewProvider`; sent as `links` type `video`). Step 4 "Review & publish": `group_event_review_step.dart` (rows jump back to a step; settings sheet `group_event_settings_sheet.dart` = chat/notifications/intentions from `GET /cms/intentions`), publish = upload cover (`/cms/media/upload`) → `POST /cms/author/groups/{id}/locations` for a new venue → `POST /cms/events` (`GroupEventRequestBuilder` mirrors the studio body: uppercase language codes, UTC instants via `timezone`, recurring anchored on now) → `group_event_published_view.dart`; create/update send `status` (`published` on Publish, `draft` on close once name + schedule are valid, "Saved as draft" toast); composer pops `GroupEventComposerResult` and the body refreshes the events tab. Publishers see the CMS list (`groupCmsEventsProvider`, `GET /cms/events?group_id=`) with a Drafts section; a draft reopens via `GroupEventDraftMapper.fromJson(raw)` and saves through `PUT /cms/events/{id}` (venue/cover reused when unchanged); Delete draft = `DELETE /cms/events/{id}` |
| Accumulator | `group_accumulator_providers.dart`, `group_accumulator_screen.dart` |
| Recitation collection | `group_recitation_collection_screen.dart`, completion providers |
| Repository | `GroupProfileRepositoryInterface` (note naming) |
| Follow | `groupFollowProvider` with sealed `GroupFollowState` |

## State management

- `FutureProvider.autoDispose.family`: profile, events, event detail
- `StateNotifierProvider.autoDispose.family`: practices, members, follow, recitation completion
- Sealed `GroupFollowState`: Loading / Success / Failure
- Request generation counters on paginated notifiers — drop stale responses
- Cross-invalidation with connect on follow/unfollow

## Data sources

- **Remote API** — profile, members, events, practices, follow, accumulators, recitation completions, posts (`GroupPostRemoteDatasource`: permission, list, CMS create + media upload)
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
4. **Accumulator session vs lifetime** — align with mala doc (`lib/features/mala/doc/README.md`).
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
