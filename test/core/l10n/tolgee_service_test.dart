import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter_pecha/core/l10n/tolgee/tolgee_bridge.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the Content Delivery CDN: serves [payloads] by tag, or hands
/// the request to [pending] when a test needs to hold a fetch open.
class _FakeCdn {
  final Map<String, Map<String, String>> payloads = {};
  final List<String> requests = [];
  Completer<Map<String, String>>? pending;
  Object? error;

  Future<Map<String, String>> fetch(String tag) {
    requests.add(tag);
    final Completer<Map<String, String>>? held = pending;
    if (held != null) {
      pending = null;
      return held.future;
    }
    final Object? failure = error;
    if (failure != null) {
      error = null;
      return Future<Map<String, String>>.error(failure);
    }
    return Future<Map<String, String>>.value(
      Map<String, String>.of(payloads[tag] ?? const {}),
    );
  }
}

String _signIn(String localeName) =>
    TolgeeBridge.get(localeName, 'sign_in', () => 'bundled');

void main() {
  late _FakeCdn cdn;
  late DateTime now;

  setUp(() {
    TolgeeService.resetForTesting();
    cdn = _FakeCdn();
    now = DateTime(2026, 9, 25, 9);
    TolgeeService.fetchPayload = cdn.fetch;
    TolgeeService.clock = () => now;
  });

  tearDown(TolgeeService.resetForTesting);

  Future<void> loadEnglish(String signIn) async {
    cdn.payloads['en'] = {'sign_in': signIn};
    expect(await TolgeeService.initialize(locale: const Locale('en')), isTrue);
  }

  test('initialize loads the language and serves its strings', () async {
    await loadEnglish('Sign in (Tolgee)');
    expect(_signIn('en'), 'Sign in (Tolgee)');
    expect(cdn.requests, ['en']);
  });

  test('refresh is throttled', () async {
    await loadEnglish('v1');
    cdn.payloads['en'] = {'sign_in': 'v2'};
    now = now.add(const Duration(minutes: 1));

    expect(await TolgeeService.refresh(), isFalse);
    expect(cdn.requests, ['en']);
    expect(_signIn('en'), 'v1');
  });

  test('refresh after the interval picks up an edit', () async {
    await loadEnglish('v1');
    cdn.payloads['en'] = {'sign_in': 'v2'};
    now = now.add(const Duration(minutes: 6));

    expect(await TolgeeService.refresh(), isTrue);
    expect(_signIn('en'), 'v2');
  });

  test('refresh without edits reports no change', () async {
    await loadEnglish('v1');
    now = now.add(const Duration(minutes: 6));

    expect(await TolgeeService.refresh(), isFalse);
    expect(cdn.requests, ['en', 'en']);
    expect(_signIn('en'), 'v1');
  });

  test('keeps the loaded strings while fetching and after a failure', () async {
    await loadEnglish('v1');
    now = now.add(const Duration(minutes: 6));
    final Completer<Map<String, String>> held = Completer();
    cdn.pending = held;

    final Future<bool> refreshing = TolgeeService.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(TolgeeBridge.active, isTrue);
    expect(_signIn('en'), 'v1');

    held.completeError(Exception('offline'));
    expect(await refreshing, isFalse);
    expect(_signIn('en'), 'v1');
  });

  test('an empty payload does not wipe the loaded strings', () async {
    await loadEnglish('v1');
    cdn.payloads['en'] = {};
    now = now.add(const Duration(minutes: 6));

    expect(await TolgeeService.refresh(), isFalse);
    expect(_signIn('en'), 'v1');
  });

  test('refresh before any language was requested does nothing', () async {
    expect(await TolgeeService.refresh(), isFalse);
    expect(cdn.requests, isEmpty);
  });

  test('a failed first load is retried on a later refresh', () async {
    cdn.error = Exception('offline at launch');
    expect(await TolgeeService.initialize(locale: const Locale('en')), isFalse);
    expect(_signIn('en'), 'bundled');

    cdn.payloads['en'] = {'sign_in': 'v1'};
    now = now.add(const Duration(minutes: 6));
    expect(await TolgeeService.refresh(), isTrue);
    expect(_signIn('en'), 'v1');
  });

  test('a language change during a refresh wins', () async {
    await loadEnglish('v1');
    now = now.add(const Duration(minutes: 6));
    final Completer<Map<String, String>> held = Completer();
    cdn.pending = held;
    cdn.payloads['zh-Hant-TW'] = {'sign_in': '登入'};

    final Future<bool> refreshing = TolgeeService.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(cdn.requests.last, 'en');

    final Future<bool> switching = TolgeeService.setLocale(const Locale('zh'));
    held.complete({'sign_in': 'v2'});

    expect(await refreshing, isFalse);
    expect(await switching, isTrue);
    expect(_signIn('zh'), '登入');
    expect(_signIn('en'), 'bundled');
  });
}
