# Learn Feature

> **LLM context doc** — read this before changing anything under `lib/features/learn/`.

## Purpose

**Placeholder** for a future Learn tab. Not in bottom navigation today.

## User-facing functionality

- Static "Coming Soon" screen
- Commented out in `main_navigation_screen.dart`
- l10n: `nav_learn`, `comingSoonHeadline`, `learn_coming_soon_subtitle`

## Architecture

```
learn/
└── presentation/
    └── screens/
        └── learn_screen.dart
```

No data, domain, providers, or barrel.

## Cross-feature dependencies

- **core** — l10n only

> Status: dead code — `LearnScreen` is not imported anywhere (only a commented-out tab in `main_navigation_screen.dart` references it).

---

## How to make changes (LLM playbook)

### Principles

Same as **explore** — reserved namespace until product scopes the feature.

### Do

- Keep minimal until requirements exist
- When building out, mirror `plans` or `texts` architecture depending on content type

### Don't

- Don't add state management to the placeholder
- Don't wire into nav without product sign-off

### When implementing for real

1. Define content model (courses? texts? plans?)
2. Scaffold full clean architecture
3. Add routes, barrel, and nav tab
4. Replace placeholder incrementally
