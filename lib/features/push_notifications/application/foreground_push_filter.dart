import 'package:flutter_pecha/core/utils/app_logger.dart';

/// Decides whether a foreground push is about what [data] describes.
typedef ForegroundPushMatcher = bool Function(Map<String, dynamic> data);

final _logger = AppLogger('ForegroundPushFilter');

/// Screens that already show what a push is about register a matcher here
/// while they are in front. A foreground push any live matcher claims is not
/// shown as a banner: the member is looking at it, and the banner's tap would
/// only lead back to where they are.
///
/// Knows nothing about rooms or routes. The push feature stays isolated from
/// the screens that consume it, so each screen brings its own matcher.
class ForegroundPushFilter {
  final Map<Object, ForegroundPushMatcher> _claims = {};

  /// Registers [matcher] under [owner], an identity token (the screen's
  /// State is the natural one). Claims are keyed by owner so a screen can
  /// only release its own, and two screens stacked by a deep link keep both
  /// claims until each is popped. Claiming again under the same owner
  /// replaces the earlier matcher.
  void claim(Object owner, ForegroundPushMatcher matcher) {
    _claims[owner] = matcher;
  }

  /// Drops [owner]'s claim. Unknown owners are ignored.
  void release(Object owner) {
    _claims.remove(owner);
  }

  /// Whether the banner for a push carrying [data] should be shown.
  ///
  /// A matcher that throws counts as not matching: a broken closure on one
  /// screen must never hide pushes about something else.
  bool shouldShow(Map<String, dynamic> data) {
    for (final matcher in _claims.values) {
      try {
        if (matcher(data)) return false;
      } catch (e, st) {
        _logger.warning('Push matcher threw; treating as no match', e, st);
      }
    }
    return true;
  }
}
