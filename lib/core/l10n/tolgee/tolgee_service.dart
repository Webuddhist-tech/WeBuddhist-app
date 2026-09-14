import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../env.dart';
import '../../utils/app_logger.dart';
import 'tolgee_bridge.dart';
import 'tolgee_cdn.dart';
import 'tolgee_locale_map.dart';

/// Incremented whenever Tolgee has new translations in memory.
///
/// `_MyAppState` watches this and feeds it to [TolgeeAppLocalizationsDelegate],
/// which is what makes `Localizations` re-resolve every string.
final StateProvider<int> tolgeeRevisionProvider = StateProvider<int>(
  (ref) => 0,
);

/// Owns the Tolgee SDK lifecycle.
///
/// Every entry point is failure-tolerant: if anything goes wrong the bridge
/// stays inactive and the app keeps using its bundled ARB translations.
class TolgeeService {
  TolgeeService._();

  static final AppLogger _logger = AppLogger('Tolgee');

  /// A CDN that accepts the connection but never answers would otherwise leave
  /// the future pending forever.
  static const Duration _networkTimeout = Duration(seconds: 15);

  /// Newest locale the UI has asked for. `localeProvider` restores the stored
  /// language asynchronously, so a change can land while the fetch for the
  /// default locale is still in flight; whichever run finishes last has to
  /// converge on this value rather than on the locale it started with.
  static Locale? _desiredLocale;

  /// App locale whose payload is currently loaded into the bridge.
  static Locale? _loadedLocale;

  /// Serialises loads. One payload is held at a time, so overlapping fetches
  /// would race over shared state.
  static Future<void> _chain = Future<void>.value();

  /// Keeps a misconfigured build from repeating the same warning on every
  /// language change.
  static bool _configIssueLogged = false;

  /// Fetches translations for [locale] and activates the bridge.
  ///
  /// Returns whether over-the-air translations are now live. Safe to call when
  /// Tolgee is unconfigured, in which case it is a no-op.
  static Future<bool> initialize({required Locale locale}) => _sync(locale);

  /// Loads translations for a newly selected [locale].
  ///
  /// Returns whether the caller should refresh the UI. Safe to call before
  /// [initialize] has finished: the request is recorded and the in-flight run
  /// picks it up instead of being dropped.
  static Future<bool> setLocale(Locale locale) => _sync(locale);

  static Future<bool> _sync(Locale locale) {
    _desiredLocale = locale;
    if (!_isConfigured()) {
      return Future<bool>.value(false);
    }
    final Future<bool> run = _chain.then((_) => _load());
    // Swallow so a failed run cannot poison the queue for later language
    // changes, but surface it: callers reach this via `unawaited`, so nothing
    // else would ever report an error that escaped `_load`.
    _chain = run.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        _logger.warning('Tolgee load run failed', error, stackTrace);
      },
    );
    return run;
  }

  static bool _isConfigured() {
    if (!Env.tolgeeEnabled) {
      if (!_configIssueLogged) {
        _configIssueLogged = true;
        _logger.info('Tolgee disabled for this build; using bundled ARB');
      }
      return false;
    }
    final String? apiKey = Env.tolgeeApiKey;
    final String? cdnUrl = Env.tolgeeCdnUrl;
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'Flutter' ||
        cdnUrl == null ||
        cdnUrl.isEmpty) {
      if (!_configIssueLogged) {
        _configIssueLogged = true;
        _logger.warning(
          'Tolgee enabled but TOLGEE_API_KEY or TOLGEE_CDN_URL is missing; '
          'using bundled ARB',
        );
      }
      return false;
    }
    return true;
  }

  /// Brings the SDK onto [_desiredLocale], re-reading it after every await so a
  /// language change that arrives mid-fetch wins instead of being discarded.
  static Future<bool> _load() async {
    while (true) {
      final Locale target = _desiredLocale!;
      if (_loadedLocale == target && TolgeeBridge.active) {
        return true;
      }

      final String cdnTag = TolgeeLocaleMap.cdnTagFor(target);
      final bool isFirstLoad = _loadedLocale == null;
      // Drop the loaded payload up front: the bridge is inert without one, so
      // during the fetch it falls back to the bundled ARB rather than showing
      // the previous language.
      TolgeeBridge.invalidate();

      try {
        final Map<String, String> strings = await TolgeeCdn.fetch(
          cdnUrl: Env.tolgeeCdnUrl!,
          tag: cdnTag,
          timeout: _networkTimeout,
        );

        // The UI moved on while we were fetching; loading now would pin the
        // bridge to a language nothing is asking for.
        if (_desiredLocale != target) {
          continue;
        }

        if (strings.isEmpty) {
          TolgeeBridge.invalidate();
          _logger.warning(
            'Tolgee CDN returned no usable strings for $cdnTag; '
            'using bundled ARB',
          );
          return false;
        }

        TolgeeBridge.load(languageCode: target.languageCode, strings: strings);
        _loadedLocale = target;
        _logger.info(
          isFirstLoad
              ? 'Tolgee ready for ${target.languageCode} '
                  '(CDN tag $cdnTag, ${strings.length} strings)'
              : 'Tolgee switched to ${target.languageCode} '
                  '(CDN tag $cdnTag, ${strings.length} strings)',
        );
        return true;
      } catch (error, stackTrace) {
        TolgeeBridge.invalidate();
        _logger.warning(
          isFirstLoad
              ? 'Tolgee load failed; using bundled ARB'
              : 'Tolgee language switch failed',
          error,
          stackTrace,
        );
        return false;
      }
    }
  }
}
