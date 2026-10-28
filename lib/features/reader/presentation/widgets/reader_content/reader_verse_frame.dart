import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';

/// Colours of a verse's lines.
typedef ReaderVerseColors = ({Color original, Color translation});

/// The colours of a verse's lines. While a live room is followed the live
/// verse's original is at full strength and every other verse, both lines,
/// in the past/next colour; otherwise the original is text and the
/// translation, when it sits under an original, the translation colour.
ReaderVerseColors readerVerseColors(
  ReaderPalette palette, {
  required bool isLive,
  required bool followingLive,
  required bool translationUnderOriginal,
}) {
  if (followingLive && !isLive) {
    return (original: palette.pastVerse, translation: palette.pastVerse);
  }
  final main = isLive ? palette.liveOriginal : palette.text;
  return (
    original: main,
    translation: translationUnderOriginal ? palette.translation : main,
  );
}

/// One verse on the page: its side margins and the space around it, and the
/// rounded card it sits on while it is the live verse.
///
/// Every verse keeps the card's padding, so a verse does not move when it
/// becomes live. Half the gap between verses goes above it, half below.
class ReaderVerseFrame extends StatelessWidget {
  const ReaderVerseFrame({
    super.key,
    required this.style,
    required this.verseGap,
    required this.child,
    this.isLive = false,
    this.isGreyedOut = false,
    this.onTap,
  });

  final ReaderStyle style;

  /// The space between this verse and the next, at the current size step.
  final double verseGap;
  final Widget child;
  final bool isLive;
  final bool isGreyedOut;
  final VoidCallback? onTap;

  /// The card's inset from the screen edge; its padding makes up the rest of
  /// the page's side margin.
  static const double cardMargin = 8;
  static const double cardPadding =
      ReaderConstants.segmentHorizontalPadding - cardMargin;
  static const double cardRadius = 12;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(cardRadius);
    return AnimatedOpacity(
      opacity: isGreyedOut ? 0.3 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: cardMargin),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isLive ? style.palette.liveHighlight : Colors.transparent,
            borderRadius: radius,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                // Every line starts at the page margin, however deep its
                // section: the page is left-aligned throughout.
                padding: EdgeInsets.fromLTRB(
                  cardPadding,
                  verseGap / 2,
                  cardPadding,
                  verseGap / 2,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
