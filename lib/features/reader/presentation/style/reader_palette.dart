import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_background_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:flutter_pecha/features/reader/presentation/style/reader_background.dart';

/// Every colour the reader page and its sheets draw with.
///
/// Reader text is [ink]; every other reader colour is the ink at a set
/// strength over the page, blended into one solid colour rather than drawn
/// with transparency. Reader widgets take their colours from here rather
/// than from the theme.
class ReaderPalette {
  const ReaderPalette({
    required this.background,
    required this.ink,
    required this.text,
    required this.translation,
    required this.heading,
    required this.headingRule,
    required this.verseNumber,
    required this.pastVerse,
    required this.instruction,
    required this.divider,
    required this.liveHighlight,
    required this.liveOriginal,
    required this.yigchung,
    required this.footnoteMarker,
    required this.footnoteText,
    required this.footnoteBackground,
    required this.pillBackground,
    required this.pillText,
    required this.pillMuted,
    required this.drawerBackground,
    required this.drawerChip,
    required this.drawerDivider,
    required this.drawerHandle,
    required this.chipFill,
    required this.chipOutline,
    required this.sheetMuted,
    required this.sheetCurrentRow,
    required this.selectedChip,
    required this.selectedChipText,
    required this.livePill,
    required this.livePillText,
    required this.pausedPill,
    required this.pausedPillText,
  });

  /// The page behind the text.
  final Color background;

  /// Reader text at full strength.
  final Color ink;

  /// A verse's original line.
  final Color text;

  /// A translation shown under its original.
  final Color translation;

  /// Section headings, their numbers and text titles.
  final Color heading;

  /// The short rule under a top-level heading's number.
  final Color headingRule;
  final Color verseNumber;

  /// Verses before and after the live one, both lines.
  final Color pastVerse;

  /// Ritual directions between verses.
  final Color instruction;

  /// Rules on the page and the progress track.
  final Color divider;

  /// The card behind the line the puja leader is on.
  final Color liveHighlight;

  /// The live verse's original line.
  final Color liveOriginal;
  final Color yigchung;
  final Color footnoteMarker;
  final Color footnoteText;
  final Color footnoteBackground;

  /// The sections pill: its fill, its title and its count.
  final Color pillBackground;
  final Color pillText;
  final Color pillMuted;

  /// Sheets over the page, and their chips, size buttons, rules and handle.
  final Color drawerBackground;
  final Color drawerChip;
  final Color drawerDivider;
  final Color drawerHandle;

  /// An unselected chip's fill and edge: in light only an edge, as every
  /// light mock draws it (WF13, WF17, WF21); in dark filled as the card
  /// gives (WF18).
  final Color chipFill;
  final Color chipOutline;

  /// The sections sheet: secondary text and the row on screen.
  final Color sheetMuted;
  final Color sheetCurrentRow;

  /// A selected chip or toggle, and its label.
  final Color selectedChip;
  final Color selectedChipText;

  /// The pill shown while following a live recitation, and its label.
  final Color livePill;
  final Color livePillText;

  /// The pill shown when the person stopped following, and its label.
  final Color pausedPill;
  final Color pausedPillText;

  static const Color inkLight = Color(0xFF222222);
  static const Color inkDark = Color(0xFFFFFFFF);
  static const Color plum = Color(0xFF4D1B3B);
  static const Color gold = Color(0xFFDA9F3E);
  static const Color liveRed = Color(0xFFD63A3D);
  static const Color yigchungLight = Color(0xFF1F4E9C);
  static const Color yigchungDark = Color(0xFF9CBFF9);

  /// Sheets in light mode, on every background, as the mocks draw them.
  static const Color drawerLight = Color(0xFFFBF9F4);

  /// An unselected chip's edge in light, the same on every background.
  static const Color chipOutlineLight = Color(0xFFDADADA);

  /// The palette for the reader's picked background and [theme]'s
  /// brightness.
  static ReaderPalette resolve(ThemeData theme, WidgetRef ref) =>
      of(ref.watch(readerBackgroundProvider), theme.brightness);

  /// The palette for [background] in [brightness].
  static ReaderPalette of(ReaderBackground background, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final page = background.of(brightness);
    final ink = isDark ? inkDark : inkLight;
    final drawer =
        isDark
            ? Color.alphaBlend(Colors.black.withValues(alpha: 0.32), page)
            : drawerLight;

    // The ink at [light] or [dark] strength (0-1) over [over].
    Color shade(double light, double dark, {Color? over}) => Color.alphaBlend(
      ink.withValues(alpha: isDark ? dark : light),
      over ?? page,
    );

    final past = shade(0.70, 0.66);
    final translation = shade(0.72, 0.76);
    // Chips and rules on a sheet: the light mocks blend them over the page,
    // not the near-white sheet (#F2E7D7 chips on Rice Paper, #E9E9E9 rules
    // on White); the dark ones over the sheet.
    final onDrawer = isDark ? drawer : page;
    final liveHighlight = shade(0.08, 0.10);
    final drawerChip = shade(0.06, 0.12, over: onDrawer);
    final drawerDivider = shade(0.10, 0.12, over: onDrawer);
    return ReaderPalette(
      background: page,
      ink: ink,
      text: ink,
      translation: translation,
      heading: ink,
      headingRule: past,
      verseNumber: past,
      pastVerse: past,
      instruction: past,
      divider: shade(0.10, 0.10),
      liveHighlight: liveHighlight,
      liveOriginal: shade(1.0, 0.87),
      yigchung: isDark ? yigchungDark : yigchungLight,
      footnoteMarker: const Color(0xFF007bff),
      footnoteText: const Color(0xFF8a8a8a),
      footnoteBackground: const Color(0xFFF0F0F0),
      pillBackground: shade(0.06, 0.14),
      pillText: ink,
      // The past-verse strength falls under 4.5:1 on the pill's darker fill
      // (dark Gold, Sky, Robe Saffron); the translation's does not.
      pillMuted: translation,
      drawerBackground: drawer,
      drawerChip: drawerChip,
      drawerDivider: drawerDivider,
      drawerHandle: shade(0.55, 0.40, over: drawer),
      chipFill: isDark ? drawerChip : drawer,
      chipOutline: isDark ? drawerDivider : chipOutlineLight,
      // The sheets' secondary text and current row are drawn as the
      // translation and the live verse's card (WF11, WF12, WF19, WF20).
      sheetMuted: translation,
      sheetCurrentRow: liveHighlight,
      selectedChip: isDark ? gold : plum,
      selectedChipText: isDark ? inkLight : inkDark,
      livePill: liveRed,
      livePillText: Colors.white,
      pausedPill: past,
      pausedPillText: isDark ? inkLight : Colors.white,
    );
  }
}
