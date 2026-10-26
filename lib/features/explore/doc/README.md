# Explore Feature

> **LLM context doc** — read this before changing anything under `lib/features/explore/`.

## Purpose

**Placeholder** for a future Explore tab. Not wired into main navigation today.

## User-facing functionality

- Static "Coming Soon" screen with localized headline and subtitle
- Previously intended as bottom-nav tab (commented out in `main_navigation_screen.dart`)
- **Practice tab** uses `PracticeExploreScreen` from `features/practice` instead

## Architecture

```
explore/
└── presentation/
    └── screens/
        └── explore_screen.dart
```

No data, domain, providers, or barrel file.

## Key files

- `presentation/screens/explore_screen.dart` — only file

## Cross-feature dependencies

- **core** — `context_ext.dart` for l10n (`nav_explore`, `comingSoonHeadline`, `explore_coming_soon_subtitle`)

> Status: dead code — `ExploreScreen` is not imported anywhere (only a commented-out tab references it).

---

## How to make changes (LLM playbook)

### Principles

1. **This is a reserved namespace** — do not bolt production logic onto the stub without a product decision.
2. When implementing for real, follow the same clean-architecture layout as `practice`, `home`, or `connect`.
3. Wire into `MainNavigationScreen` only when product replaces or adds the tab.

### Do

- Keep the screen minimal until the feature is scoped
- Add l10n keys in Tolgee/core l10n, not hardcoded strings
- When building out: create `data/`, `domain/`, `presentation/providers/` from scratch using sibling features as templates

### Don't

- Don't duplicate Practice Explore functionality here without explicit requirement
- Don't add Riverpod/providers for a static placeholder
- Don't import heavy dependencies into a StatelessWidget stub

### When implementing for real

1. Define user stories and nav placement with team
2. Scaffold `data/domain/presentation` like `connect` or `practice`
3. Add barrel `explore.dart`, route in `app_router.dart`, tab in `MainTab`
4. Replace placeholder copy with real UI incrementally
