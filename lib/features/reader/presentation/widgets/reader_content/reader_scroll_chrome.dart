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
  /// back up the page does not bring hidden bars back. Returns true when
  /// [barsVisible] changed.
  bool scrolled(double delta, {bool countUp = true}) {
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
/// [lastVerseNumber] (the last verse on screen) out of [totalVerses]. A
/// plan task's texts load completely, so it is measured by rows:
/// [lastVisibleRow] out of [rowCount].
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
