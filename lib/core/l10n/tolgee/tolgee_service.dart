import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Loads over-the-air translations from Tolgee Content Delivery.
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

  /// Minimum gap between two [refresh] fetches. Resume fires often (every
  /// share sheet, permission dialog, app switch) and edits are rare.
  static const Duration _refreshInterval = Duration(minutes: 5);

  /// When the loaded language was last fetched, for [refresh] throttling.
  static DateTime? _lastFetchAt;

  /// Fetches the Content Delivery payload for a CDN tag. Swapped in tests.
  @visibleForTesting
  static Future<Map<String, String>> Function(String tag) fetchPayload =
      _fetchFromCdn;

  /// Clock for [refresh] throttling. Swapped in tests.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  static Future<Map<String, String>> _fetchFromCdn(String tag) {
    return TolgeeCdn.fetch(
      cdnUrl: TolgeeCdn.baseUrl,
      tag: tag,
      timeout: _networkTimeout,
    );
  }

  /// Restores the initial state. Tests only.
  @visibleForTesting
  static void resetForTesting() {
    _desiredLocale = null;
    _loadedLocale = null;
    _chain = Future<void>.value();
    _lastFetchAt = null;
    fetchPayload = _fetchFromCdn;
    clock = DateTime.now;
    TolgeeBridge.reset();
  }

  /// Fetches translations for [locale] and activates the bridge.
  ///
  /// Returns whether over-the-air translations are now live; on false the app
  /// keeps its bundled ARB translations.
  static Future<bool> initialize({required Locale locale}) => _sync(locale);

  /// Loads translations for a newly selected [locale].
  ///
  /// Returns whether the caller should refresh the UI. Safe to call before
  /// [initialize] has finished: the request is recorded and the in-flight run
  /// picks it up instead of being dropped.
  static Future<bool> setLocale(Locale locale) => _sync(locale);

  /// Re-fetches the loaded language so edits published in Tolgee reach an app
  /// that stays in memory for days without a cold start. Called on every
  /// return to the foreground, so it is throttled to [_refreshInterval].
  ///
  /// Unlike a language change it keeps the current strings on screen while
  /// fetching, and keeps them if the fetch fails. Returns whether the strings
  /// changed, i.e. whether the caller should refresh the UI.
  static Future<bool> refresh() => _enqueue(_refresh);

  static Future<bool> _sync(Locale locale) {
    _desiredLocale = locale;
    return _enqueue(_load);
  }

  static Future<bool> _enqueue(Future<bool> Function() task) {
    final Future<bool> run = _chain.then((_) => task());
    // Swallow so a failed run cannot poison the queue for later language
    // changes, but surface it: callers reach this via `unawaited`, so nothing
    // else would ever report an error that escaped the run.
    _chain = run.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        _logger.warning('Tolgee run failed', error, stackTrace);
      },
    );
    return run;
  }

  /// Brings the bridge onto [_desiredLocale], re-reading it after every await so a
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
      _lastFetchAt = clock();

      try {
        final Map<String, String> strings = await fetchPayload(cdnTag);

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

  /// Re-fetches the language on screen; see [refresh].
  static Future<bool> _refresh() async {
    final Locale? target = _desiredLocale;
    // Nothing has asked for a language yet; [initialize] owns the first load.
    if (target == null) {
      return false;
    }
    final DateTime? last = _lastFetchAt;
    if (last != null && clock().difference(last) < _refreshInterval) {
      return false;
    }
    // The last load failed (offline at launch, say), so there is nothing on
    // screen to keep and a normal load retries it.
    if (_loadedLocale != target || !TolgeeBridge.active) {
      return _load();
    }

    final String cdnTag = TolgeeLocaleMap.cdnTagFor(target);
    _lastFetchAt = clock();
    try {
      final Map<String, String> strings = await fetchPayload(cdnTag);
      // A language change queued behind this run owns the bridge now, and an
      // empty payload is a bad response rather than a reason to drop every
      // string on screen.
      if (_desiredLocale != target ||
          strings.isEmpty ||
          TolgeeBridge.holds(
            languageCode: target.languageCode,
            strings: strings,
          )) {
        return false;
      }
      TolgeeBridge.load(languageCode: target.languageCode, strings: strings);
      _logger.info(
        'Tolgee refreshed ${target.languageCode} '
        '(CDN tag $cdnTag, ${strings.length} strings)',
      );
      return true;
    } catch (error, stackTrace) {
      _logger.warning(
        'Tolgee refresh failed; keeping the loaded strings',
        error,
        stackTrace,
      );
      return false;
    }
  }
}
