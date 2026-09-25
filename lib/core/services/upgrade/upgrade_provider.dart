import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/services/upgrade/app_upgrade_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('UpgradeProvider');

/// Provider that reports whether an app update is available.
///
/// Emits `true` if a newer version is available in the app store. It
/// re-emits whenever upgrader refreshes the store version (upgrader does
/// this on every resume from background), so the gate reacts to a store
/// lookup that failed at launch or a release published mid-session.
///
/// Only enforced in release builds, so debug/profile builds used during
/// development — whose version is usually ahead of or behind the store —
/// are never blocked.
///
/// **For Testing:**
/// Set `debugDisplayAlways` to `true` to always show the forced-update
/// modal, even in debug builds with no update available.
final updateAvailableProvider = StreamProvider<bool>((ref) async* {
  // Set to true to test the forced-update modal UI; revert before shipping
  const debugDisplayAlways = false;

  // The analyzer flags this branch as dead code while the toggle is true.
  // ignore: dead_code
  if (!kReleaseMode && !debugDisplayAlways) {
    yield false;
    return;
  }

  try {
    await AppUpgradeService.initialize(debugDisplayAlways: debugDisplayAlways);
  } catch (e) {
    _logger.error('Error initializing AppUpgradeService', e);
    yield false;
    return;
  }

  final isAvailable = AppUpgradeService.isUpdateAvailable();
  _logger.info('Update check complete. Available: $isAvailable');
  yield isAvailable;

  await for (final _ in AppUpgradeService.stateStream) {
    yield AppUpgradeService.isUpdateAvailable();
  }
});

/// Provider to trigger opening the app store.
/// Call `ref.read(openAppStoreProvider)` to open the store.
final openAppStoreProvider = Provider<void Function()>((ref) {
  return () {
    AppUpgradeService.openAppStore();
  };
});

/// Tracks whether the update banner has been shown in this app session.
/// Once shown (and auto-dismissed), it won't show again until app restart.
final updateBannerShownProvider = StateProvider<bool>((ref) => false);
