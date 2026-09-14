import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============ Primary Colors (Logo Red) ============
  /// Dominant fill from `assets/images/webuddhist_logo.png`.
  static const Color primary = Color(0xFFFF0000);
  static const Color primaryLight = Color(0xFFFF3333);
  static const Color primaryDark = Color(0xFFAD2424); // darker brand red
  static const Color primaryDarkest = Color(0xFF871C1C);

  /// Primary color containers and tints
  static const Color primaryContainer = Color(0xFFFFEBEE); // Red 50
  static const Color primarySurface = Color(0xFFFFF5F5);

  // ============ Legacy gold (AI + onboarding only) ============
  /// Previous gold primary — kept so AI / onboarding stay visually unchanged
  /// while the rest of the app moves to logo red.
  static const Color accentGold = Color(0xFFDEAD2D);
  static const Color accentGoldDark = Color(0xFFB3861C);
  static const Color accentGoldDarkest = Color(0xFF805700);
  static const Color accentGoldContainer = Color(0xFFFAE6E6);
  static const Color accentGoldSurface = Color(0xFFFCF2F2);

  /// Poem author name accent.
  static const Color poemAuthor = Color(0xFFC17600);

  // ============ Surface Colors ============
  static const Color surfaceLight = Color(0xFFFBF9F4); // Light BG
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Dark mode surfaces
  static const Color backgroundDark = Colors.black; // Main dark background
  static const Color surfaceDark = Color(0xFF222222); // Card/surface dark
  static const Color surfaceVariantDark = Color(
    0xFF252525,
  ); // Search bar, inputs
  static const Color cardDark = Color(0xFF222222); // Card background dark
  static const Color cardBorderDark = Color(0xFF353535); // Card border dark

  /// Chips and pills rendered on top of [surfaceVariantDark] inputs, which
  /// need a fill one step lighter than the surface behind them.
  static const Color chipBackgroundDark = Color(0xFF353535);

  // ============ Gold/Accent Colors ============
  /// Warm gold tones for cards and highlights
  static const Color goldLight = Color(0xFFFBF9F4); // MG 50
  static const Color goldAccent = Color(0xFFF6F3E9); // MG 100

  // ============ Grey Scale ============
  static const Color greyLight = Color(0xFFEDEDED); // MGS 100
  static const Color greyMedium = Color(
    0xFF707070,
  ); // MGS 800 - onboarding quote light
  static const Color greyDark = Color(0xFF454545); // MGS 900

  // Extended grey scale for dark mode
  static const Color grey00 = Color(0xFFFFFFFF); // MGS 00
  static const Color grey50 = Color(
    0xFFF2F2F2,
  ); // MGS 50 - onboarding quote dark
  static const Color grey100 = Color(0xFFEDEDED); // MGS 100
  static const Color grey300 = Color(0xFFDADADA); // MGS 300
  static const Color grey400 = Color(0xFFC4C4C4); // MGS 400
  static const Color grey500 = Color(0xFFB3B3B3); // MGS 500
  static const Color grey600 = Color(0xFFA1A1A1); // MGS 600
  static const Color grey800 = Color(0xFF707070); // MGS 800
  static const Color grey900 = Color(0xFF454545); // MGS 900

  // ============ Text Colors ============
  // Light mode text
  static const Color textPrimary = Color(0xFF000000);
  static const Color textPrimaryLight = Color(
    0xFF707070,
  ); // onboarding quote light
  static const Color textSecondary = Color(0xFF707070);

  // Dark mode text
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Primary white
  static const Color textSecondaryDark = Color(0xFFE4E4E4); // Emphasis/headings
  static const Color textTertiaryDark = Color(0xFFB3B3B3); // Less emphasis
  static const Color textMutedDark = Color(0xFFC4C4C4); // Muted
  static const Color textSubtleDark = Color(0xFFA1A1A1); // Subtle
  static const Color textLabelDark = Color(0xFFDADADA); // Labels

  // ============ Blue Colors ============
  static const Color blue = Color(0xFF0C53C5); // Light mode
  static const Color blueDark = Color(0xFF8CB5F8); // Dark mode
  static const Color brandblue = Color(0xFF3382FD);

  /// My Practices card and filled action button — dark card with a subtle blue tint.
  static final Color myPracticesBackground = Color.lerp(cardDark, blue, 0.18)!;

  // ============ Semantic Colors (for compatibility) ============
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF008000);
  static const Color warning = Color(0xFFFFA500);
  static const Color info = Color(0xFF0000FF);
  static const Color danger = Color(0xFFD32F2F);

  // ============ Background Colors ============
  static const Color scaffoldBackgroundLight = Color(0xFFFBF9F4);
  static const Color scaffoldBackgroundDark = Color(0xFF000000);
  static const Color cardBackgroundLight = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF232121);

  // onboarding screen ring color
  static const Color outerCircleColor = Color(0xFFAD2424);
  static const Color middleCircleColor = Color(0xFF871C1C);
  static const Color innerCircleColor = Color(0xFF611414);

  // ============ Group chat bubbles ============
  /// Outgoing message fill: #DC8600 at 10% (`#DC86001A`), a warm tint of the
  /// page rather than a second solid colour.
  static const Color chatOutgoingBubble = Color(0x1ADC8600);

  /// Dark mode uses its own value: #FDAE33, the brighter amber, but at 30%
  /// rather than the 70% first tried — over black that read as a highlight
  /// rather than a bubble. Still clearly warmer than the incoming fill.
  static const Color chatOutgoingBubbleDark = Color(0x4DFDAE33);

  // ============ Group chat sender colours ============
  /// One colour per participant in a group thread, picked by a stable hash of
  /// the sender so a person keeps the same colour across every message.
  ///
  /// Two variants because the same hue cannot serve both: these are read on a
  /// white bubble in light mode and on a dark bubble in dark mode.
  static const List<Color> chatSenderColors = [
    Color(0xFFC2410C), // orange
    Color(0xFFB45309), // amber
    Color(0xFF15803D), // green
    Color(0xFF0F766E), // teal
    Color(0xFF0C53C5), // blue
    Color(0xFF6D28D9), // violet
    Color(0xFFA21CAF), // fuchsia
    Color(0xFFBE123C), // rose
    Color(0xFF4D7C0F), // lime
    Color(0xFF0369A1), // sky
  ];

  static const List<Color> chatSenderColorsDark = [
    Color(0xFFFB923C), // orange
    Color(0xFFF59E0B), // amber
    Color(0xFF4ADE80), // green
    Color(0xFF2DD4BF), // teal
    Color(0xFF8CB5F8), // blue
    Color(0xFFA78BFA), // violet
    Color(0xFFE879F9), // fuchsia
    Color(0xFFFB7185), // rose
    Color(0xFFA3E635), // lime
    Color(0xFF38BDF8), // sky
  ];

  // ============ Event chips ============
  /// In-person (amber) and online (green) event tags; backgrounds are these
  /// at low alpha so they sit on any card colour.
  static const Color eventInPersonChip = Color(0xFFB45309);
  static const Color eventInPersonChipDark = Color(0xFFF59E0B);
  static const Color eventOnlineChip = Color(0xFF15803D);
  static const Color eventOnlineChipDark = Color(0xFF4ADE80);

  // ============ Design System Reference ============
  // Figma file: 0TE5qdViUvrisFZfNqODpX/WeBuddhist-App
  // Design system: Monlam Colors
  // Primary theme: Logo red (WeBuddhist mark)
}
