import 'dart:math' as math;

/// Focus mode: the reader's header and bottom bar slide away once the page
/// has moved [hideAfter] pixels down, and come back after [showAfter] pixels
/// up. Each direction counts from where the page last turned.
class ReaderFocusMode {
  static const double hideAfter = 24;
  static const double showAfter = 8;

  bool _barsVisible = true;
  double _down = 0;
  double _up = 0;

  bool get barsVisible => _barsVisible;

  /// Feeds one scroll step of [delta] pixels, positive downwards. With
  /// [countUp] false an upward step is ignored, so a jump the app makes
  /// back up the page does not bring hidden bars back. A step while the page
  /// is [outOfRange] is ignored: an iOS bounce springing back from the top
  /// is not the person scrolling down. [atTop] brings the bars back. Returns
  /// true when [barsVisible] changed.
  bool scrolled(
    double delta, {
    bool countUp = true,
    bool outOfRange = false,
    bool atTop = false,
  }) {
    if (atTop) return show();
    if (outOfRange) return false;
    if (delta > 0) {
      _up = 0;
      _down += delta;
      if (_barsVisible && _down >= hideAfter) {
        _barsVisible = false;
        _down = 0;
        return true;
      }
    } else if (delta < 0 && countUp) {
      _down = 0;
      _up -= delta;
      if (!_barsVisible && _up >= showAfter) {
        _barsVisible = true;
        _up = 0;
        return true;
      }
    }
    return false;
  }

  /// Brings the bars back whatever the page did. Returns true when they were
  /// hidden.
  bool show() {
    _down = 0;
    _up = 0;
    if (_barsVisible) return false;
    _barsVisible = true;
    return true;
  }
}

/// How far through the page the reader is, from 0 to 1, for the progress
/// line under the header.
///
/// A whole text is measured by its verses, since it loads page by page:
/// [lastVerseNumber] (the last verse on screen) out of [totalVerses].
/// Without verses to go by it falls back to rows: [lastVisibleRow] out of
/// [rowCount]. A plan task uses [readerTaskProgress].
double readerProgress({
  int? lastVerseNumber,
  int totalVerses = 0,
  required int lastVisibleRow,
  required int rowCount,
}) {
  final double value;
  if (lastVerseNumber != null && totalVerses > 0) {
    value = lastVerseNumber / totalVerses;
  } else if (rowCount > 0) {
    value = (lastVisibleRow + 1) / rowCount;
  } else {
    value = 0;
  }
  return math.min(1, math.max(0, value));
}

/// How far through a plan task the reader is, from 0 to 1, counted in
/// verses across its texts, loaded or not: the texts before [source] in
/// full, then [verseInSource] (the last verse on screen, counted from 1)
/// of [source]'s. [sourceVerses] is each text's verse count: its picked
/// verses, or a whole text's total; null while a whole text that has not
/// started is unknown. An unknown text counts as one verse still to read,
/// so the line cannot reach the end before it is known.
double readerTaskProgress({
  required List<int?> sourceVerses,
  required int source,
  required int verseInSource,
}) {
  int count(int? verses) => verses == null || verses < 1 ? 1 : verses;
  var total = 0;
  var done = 0;
  for (var i = 0; i < sourceVerses.length; i++) {
    final verses = count(sourceVerses[i]);
    total += verses;
    if (i < source) done += verses;
  }
  if (total == 0) return 0;
  done += verseInSource;
  return math.min(1, math.max(0, done / total));
}
