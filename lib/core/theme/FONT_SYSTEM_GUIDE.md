# Multi-Language Font System Guide

## Overview

The app now supports separate fonts for **system UI** and **content** across multiple languages:

- **System Fonts**: Used for UI elements (tabs, navigation, settings, buttons, etc.)
- **Content Fonts**: Used for backend content (texts, practice plans, recitations, etc.)

## Current Configuration

### Tibetan (bo, tib)
- **System**: `NotoSerifTibetanWB` — bundled build of Noto Serif Tibetan (400/500/600/700)
- **Content**: `WBTibetanContent` — bundled build of BabelStone Tibetan

Both are local assets with **rewritten vertical metrics**; see
"Tibetan vertical metrics" below and `assets/fonts/README.md`.

### English (en, tibphono)
- **System**: Google Inter
- **Content**: Google Source Serif 4

### Chinese (zh)
- **System**: Google Noto Sans Traditional Chinese
- **Content**: Google Noto Serif Traditional Chinese

## Architecture

### 1. Font Configuration (`font_config.dart`)

Central configuration file that defines fonts for each language:

```dart
// Get font family name for a language and type
String fontName = AppFontConfig.getFontFamily('bo', FontType.system);
// Returns: 'NotoSerifTibetanWB'

// Get TextTheme for system UI
TextTheme theme = AppFontConfig.getTextTheme('bo', FontType.system, Brightness.light);

// Get TextStyle for content
TextStyle? style = AppFontConfig.getContentTextStyle('bo', baseStyle);
```

### 2. App Theme (`app_theme.dart`)

The app theme automatically uses **system fonts** based on the current locale:

```dart
ThemeData theme = AppTheme.lightTheme(Locale('bo'));
// All system UI will use NotoSerifTibetanWB for Tibetan
```

### 3. Helper Functions (`shared/utils/helper_functions.dart`)

For content widgets, use these helper functions:

```dart
// Get content font family name
String? fontFamily = getFontFamily('bo'); // Returns 'WBTibetanContent'

// Get complete TextStyle with content font
TextStyle? style = getContentTextStyle('bo', TextStyle(fontSize: 18));
```

## Usage Examples

### System UI Elements (Automatic)

System UI elements (AppBar, BottomNavigationBar, Buttons, etc.) automatically use the correct system font based on locale:

```dart
// No special handling needed - theme handles it
AppBar(
  title: Text('Title'), // Uses system font automatically
)
```

### Content Widgets (Manual)

For content from backend, explicitly use content fonts. **Both methods work correctly:**

#### Option 1: Using fontFamily parameter (Simple)

```dart
Text(
  'Content from backend',
  style: TextStyle(
    fontFamily: getFontFamily(language), // Returns proper Google Font family name
    fontSize: 18,
  ),
)
```

This works for both Google Fonts and local fonts. The `getFontFamily()` function now returns the actual Google Font family name that can be used directly.

#### Option 2: Using getContentTextStyle (Recommended for more control)

```dart
Text(
  'Content from backend',
  style: getContentTextStyle(
    language,
    TextStyle(fontSize: 18, color: Colors.black),
  ),
)
```

This method is recommended when you need more control over the TextStyle, as it properly applies all Google Fonts features and optimizations.

#### Option 3: HTML Widget

```dart
Html(
  data: htmlContent,
  style: {
    "body": Style(
      fontSize: FontSize(18),
      fontFamily: getFontFamily(language), // Content font
    ),
  },
)
```

### Direct Access to Font Config

```dart
import 'package:flutter_pecha/core/theme/font_config.dart';

// Get system font for Tibetan
String systemFont = AppFontConfig.getFontFamily('bo', FontType.system);

// Get content font for English
String contentFont = AppFontConfig.getFontFamily('en', FontType.content);

// Get all supported languages
List<String> languages = AppFontConfig.supportedLanguages;
```

## Adding New Languages

To add a new language, update `font_config.dart`:

```dart
static const Map<String, LanguageFontConfig> _languageFonts = {
  // ... existing languages ...

  // New language
  'hi': LanguageFontConfig(
    systemFont: 'Roboto',           // For UI elements
    contentFont: 'Noto Serif Devanagari', // For content
    systemFontIsGoogle: true,
    contentFontIsGoogle: true,
  ),
};
```

### For Local Fonts

If you need to use local fonts (from assets):

```dart
'bo': LanguageFontConfig(
  systemFont: 'MonlamTibetan',
  contentFont: 'TsumachuTibetan',
  systemFontIsGoogle: false,    // Set to false for local fonts
  contentFontIsGoogle: false,
),
```

Then add the font to `pubspec.yaml`:

```yaml
fonts:
  - family: TsumachuTibetan
    fonts:
      - asset: assets/fonts/Tsumachu.ttf
```

## Tibetan vertical metrics

Flutter builds every line box from the font's ascender/descender. When a
style sets `height:` (the app uses `tibetanUiLineHeight` 1.55 and
`tibetanCompactLineHeight` 1.25 for Tibetan) the box is resized around the
**baseline**, not around the glyphs. The upstream fonts declare far more
space than their glyphs use:

| Font | Upstream asc / desc (em) | Ink of ordinary text (em) |
| --- | --- | --- |
| Noto Serif Tibetan | 1.466 / 1.349 (2.82 per line) | vowel signs to +1.08 (+1.16 over a superscript), stacks to -0.47 (-0.70 deep) |
| BabelStone Tibetan | 1.102 / 1.901 (3.00 per line) | vowel signs to +0.84 (+0.93), stacks to -0.62 |

At `height: 1.55` that gave a box of 0.83 em above / 0.72 em below the
baseline for the UI font (0.38 / 1.17 for the content font). Two symptoms
followed:

1. **Clipped vowel signs.** The first line's vowels sit above the box. Nothing
   is visible until something clips: `RenderParagraph` clips itself whenever
   the text overflows (`maxLines` + `ellipsis`/`clip`), and `ClipRRect`,
   `Material(clipBehavior: ...)` etc. clip too. That is why only some pages
   were affected — truncated descriptions, card titles, list previews.
2. **Labels riding high in buttons/chips.** The box centre was ~0.06 em above
   the baseline while Tibetan ink is centred ~0.30 em above it, so
   `Center`/padding put the ink ~0.25 em (3 px at 13 px) too high.

`tibetanStrutStyle()` hid both on the screens that use it, because a
`StrutStyle` without `fontFamily` measures the platform default font
(Roboto/SF), whose 1.55 box happens to be 1.12 / 0.43 em — a good fit for
Tibetan ink. Screens with plain `Text` did not get that box.

The shipped fonts are rebuilt (`tool/patch_tibetan_font_metrics.py`) with
ascender/descender fitted to the ink, so the same `height:` values now
produce boxes that enclose the glyphs and are centred on them:

| Font | New asc / desc | Box at `height: 1.55` |
| --- | --- | --- |
| `NotoSerifTibetanWB` | 1.220 / 0.580 (1.80 per line) | 1.095 / 0.455 em |
| `WBTibetanContent` | 1.000 / 0.600 (1.60 per line) | 0.975 / 0.575 em |

Rules that follow from this:

- Never replace the bundled files with upstream downloads (and do not switch
  the Tibetan system font back to `google_fonts`): the metrics are the fix.
  `test/core/theme/tibetan_font_metrics_test.dart` fails if that happens.
- `tibetanStrutStyle()` is still fine to use, but it is no longer required to
  make Tibetan text sit correctly; a plain `Text` now behaves the same way.
- 1.55 em is still tighter than the full ink envelope (~1.8 em). On a
  *truncated* paragraph the last line can lose the bottom of a deep stack
  (e.g. ུ under a subjoined letter, ~3 px at 13 px) and the first line can
  lose ~1 px of a vowel over a superscript. If that matters on a screen,
  give that `Text` more height (≈1.8) or avoid truncation; raising
  `tibetanUiLineHeight` globally is a design decision.
- Widgets that use the font's natural line height (no `height:` — e.g.
  `TextField`, `Chip`, `Tab`) got shorter: 1.80 em per line instead of 2.82.

## Testing

To test the font system:

1. **System UI**: Change app locale and verify UI elements use the correct system font
2. **Content**: Verify content widgets (texts, recitations) use the correct content font
3. **Multiple Languages**: Test switching between different languages

## Notes

- Google Fonts (Inter, Source Serif 4, Noto *TC) are downloaded on-demand and cached automatically; the Tibetan fonts are bundled assets
- System fonts are applied globally through the theme
- Content fonts must be explicitly set in content widgets
- Fallback to Inter/Source Serif 4 for unknown languages
- Line heights and font sizes remain in `helper_functions.dart` for now

## Migration from Old System

### Before
```dart
String? fontFamily = getFontFamily(language); // Mixed system/content
```

### After
```dart
// For UI elements - handled automatically by theme
// For content elements - same function, now returns content font
String? fontFamily = getFontFamily(language);
```

The `getFontFamily()` helper function now:
1. Returns **content fonts** by default (system fonts are handled by theme)
2. Returns the actual Google Font family name that works with `TextStyle(fontFamily: ...)`
3. Works for both Google Fonts and local fonts

**Technical Detail**: For Google Fonts, the function calls the GoogleFonts API (e.g., `GoogleFonts.jomolhari()`) to get the proper font family name, ensuring the font is loaded and available. This is why both `getFontFamily()` and `getContentTextStyle()` now work correctly.
