import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = AppLogger('AppUpgradeService');

/// Service for checking app updates and launching the app store.
///
/// Uses the upgrader package to check App Store / Play Store for newer versions.
class AppUpgradeService {
  AppUpgradeService._();

  static Upgrader? _upgrader;
  static bool _isInitialized = false;
  static bool _debugDisplayAlways = false;

  /// Initialize the upgrader. Call once at app startup.
  ///
  /// Set [debugDisplayAlways] to true to always show the update banner
  /// for testing purposes, even when no update is available.
  static Future<void> initialize({bool debugDisplayAlways = false}) async {
    if (_isInitialized) return;
    _debugDisplayAlways = debugDisplayAlways;

    _upgrader = Upgrader(
      countryCode: _getCountryCode(),
      debugLogging: debugDisplayAlways,
      debugDisplayAlways: debugDisplayAlways,
      durationUntilAlertAgain: Duration.zero,
      storeController: UpgraderStoreController(
        onAndroid: () => UpgraderPlayStore(),
        oniOS: () => UpgraderAppStore(),
      ),
    );

    await _upgrader!.initialize();
    _isInitialized = true;
    _logger.info(
      'AppUpgradeService initialized (debugDisplayAlways: $debugDisplayAlways)',
    );
  }

  /// Emits whenever upgrader re-evaluates its state, including after it
  /// refreshes the store version when the app returns from the background.
  static Stream<UpgraderState> get stateStream =>
      _upgrader?.stateStream ?? const Stream.empty();

  /// Check if an update is available.
  ///
  /// Returns true if either:
  /// - A real update is available in the store, OR
  /// - debugDisplayAlways is enabled (for testing)
  ///
  /// Deliberately bypasses upgrader's "ignore" / "remind later" / alert
  /// frequency bookkeeping: the update is mandatory, so it stays required
  /// until the installed version matches the store version.
  static bool isUpdateAvailable() {
    if (!_isInitialized || _upgrader == null) {
      _logger.warning('AppUpgradeService not initialized');
      return false;
    }

    try {
      final isAvailable = _debugDisplayAlways || _upgrader!.isUpdateAvailable();
      _logger.debug('Update available: $isAvailable');
      return isAvailable;
    } catch (e) {
      _logger.error('Error checking for update', e);
      return false;
    }
  }

  /// Open the WeBuddhist listing in the App Store (iOS) or Play Store
  /// (Android).
  ///
  /// Uses the fixed store URLs from [AppConfig] rather than
  /// `Upgrader.sendUserToAppStore`, which silently does nothing when the store
  /// lookup returned no listing URL and, on Android 11+, when `canLaunchUrl`
  /// is blocked by package visibility rules.
  static Future<void> openAppStore() async {
    final url = Platform.isIOS ? AppConfig.appStoreUrl : AppConfig.playStoreUrl;

    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        _logger.info('Opened app store: $url');
      } else {
        _logger.warning('Could not open app store: $url');
      }
    } catch (e) {
      _logger.error('Error opening app store', e);
    }
  }

  /// Get the current installed version.
  static String? getCurrentVersion() {
    return _upgrader?.currentInstalledVersion;
  }

  /// Get the app store version (latest available).
  static String? getStoreVersion() {
    return _upgrader?.currentAppStoreVersion;
  }

  /// Gets the country code from user's device locale.
  /// iOS needs explicit country code; Android auto-detects.
  static String? _getCountryCode() {
    if (Platform.isIOS) {
      final locale = ui.PlatformDispatcher.instance.locale;
      final countryCode = locale.countryCode;
      return countryCode?.isNotEmpty == true ? countryCode : 'US';
    }
    return null;
  }
}
