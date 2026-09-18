import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

abstract class TimerLockScreenActivity {
  Future<void> start({
    required String sessionName,
    required DateTime endsAt,
    required int totalSeconds,
  });

  Future<void> update({
    required DateTime? endsAt,
    required bool isPaused,
    required int remainingSeconds,
  });

  Future<void> end();
}

/// iOS Live Activity for a running meditation timer — the lock-screen and
/// Dynamic Island countdown.
///
/// The Swift side renders the countdown with `Text(timerInterval:countsDown:)`,
/// which the system ticks natively, so a normal session pushes no updates at
/// all after [start]: only pause/resume changes the content state.
///
/// No-op on Android, which uses an ongoing chronometer notification instead
/// (see `TimerSessionNotifier`).
///
/// Live Activities can be turned off system-wide or per-app in Settings, and
/// are unavailable below iOS 16.2 — every call here is best-effort so a missing
/// Live Activity can never break the session itself.
class TimerLiveActivity implements TimerLockScreenActivity {
  TimerLiveActivity() : _logger = AppLogger('TimerLiveActivity');

  final AppLogger _logger;

  static const MethodChannel _channel = MethodChannel(
    'org.pecha.app/timer_activity',
  );

  bool get _supported => Platform.isIOS;

  /// Starts the activity for a session ending at [endsAt].
  ///
  /// The Swift side first ends any orphaned activity: the app can be killed
  /// mid-session and cannot end its own activity from a dead process, so
  /// cleanup happens on the next start.
  @override
  Future<void> start({
    required String sessionName,
    required DateTime endsAt,
    required int totalSeconds,
  }) => _invoke('start', {
    'sessionName': sessionName,
    'endTimestamp': endsAt.millisecondsSinceEpoch / 1000.0,
    'totalSeconds': totalSeconds,
    'isPaused': false,
    'remainingSeconds': totalSeconds,
  });

  /// Pushes a new content state. Only needed for pause and resume — while
  /// running, the system ticks the countdown on its own.
  @override
  Future<void> update({
    required DateTime? endsAt,
    required bool isPaused,
    required int remainingSeconds,
  }) => _invoke('update', {
    'endTimestamp':
        (endsAt ?? DateTime.now().add(Duration(seconds: remainingSeconds)))
            .millisecondsSinceEpoch /
        1000.0,
    'isPaused': isPaused,
    'remainingSeconds': remainingSeconds,
  });

  /// Dismisses the activity. Called on finish, discard and dispose.
  @override
  Future<void> end() => _invoke('end', const {});

  Future<void> _invoke(String method, Map<String, dynamic> args) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Widget extension not present in this build — nothing to do.
    } catch (e) {
      _logger.warning('Live Activity $method failed: $e');
    }
  }
}
