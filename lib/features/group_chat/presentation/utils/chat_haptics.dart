import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The haptic for a long-press that starts a selection.
///
/// Platform-specific on purpose. On Android every `HapticFeedback.*Impact`
/// maps to a keyboard-style tick (`mediumImpact` is `KEYBOARD_TAP`), which is
/// faint enough to miss on most phones; `vibrate()` is the one call that maps
/// to `HapticFeedbackConstants.LONG_PRESS`, the buzz the system itself uses
/// for a long-press. iOS has no such constant, and `mediumImpact` is the
/// right weight there.
///
/// Android still honours the system "touch feedback" setting: with it off,
/// no in-app haptic plays at all.
Future<void> chatLongPressHaptic() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return HapticFeedback.vibrate();
  }
  return HapticFeedback.mediumImpact();
}
