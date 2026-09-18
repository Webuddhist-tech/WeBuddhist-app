import 'dart:convert';

import 'package:flutter_pecha/core/l10n/tolgee/tolgee_cdn.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _timeout = Duration(seconds: 5);

Future<Map<String, String>> _fetch(
  MockClient client, {
  String cdnUrl = 'https://cdn.example/webuddhist',
  String tag = 'en',
}) {
  return TolgeeCdn.fetch(
    cdnUrl: cdnUrl,
    tag: tag,
    timeout: _timeout,
    client: client,
  );
}

MockClient _serving(String body, {int status = 200, List<Uri>? seen}) {
  return MockClient((http.Request request) async {
    seen?.add(request.url);
    return http.Response.bytes(utf8.encode(body), status);
  });
}

void main() {
  group('TolgeeCdn.fetch', () {
    test('requests {cdn}/{tag}.json', () async {
      final seen = <Uri>[];
      await _fetch(_serving('{}', seen: seen), tag: 'bo-IN');

      expect(
        seen.single.toString(),
        'https://cdn.example/webuddhist/bo-IN.json',
      );
    });

    test('a trailing slash on the base does not double up', () async {
      final seen = <Uri>[];
      await _fetch(
        _serving('{}', seen: seen),
        cdnUrl: 'https://cdn.example/webuddhist/',
        tag: 'hi',
      );

      expect(seen.single.toString(), 'https://cdn.example/webuddhist/hi.json');
    });

    test('parses a flat payload', () async {
      final strings = await _fetch(
        _serving('{"sign_in":"Sign in","logout":"Log out"}'),
      );

      expect(strings, <String, String>{
        'sign_in': 'Sign in',
        'logout': 'Log out',
      });
    });

    test('decodes as UTF-8, not latin1', () async {
      // The whole point of over-the-air translations is the non-Latin ones;
      // reading `response.body` instead of the bytes mangles them.
      final strings = await _fetch(
        _serving('{"calendar_title":"ཟླ་ཐོ།","zh":"日历"}'),
      );

      expect(strings['calendar_title'], 'ཟླ་ཐོ།');
      expect(strings['zh'], '日历');
    });

    test('skips values that are not strings', () async {
      // Tolgee can hold structured keys; those are not something a lookup can
      // return, and letting one through would break the cast at the call site.
      final strings = await _fetch(
        _serving('{"ok":"yes","nested":{"a":"b"},"count":3,"nothing":null}'),
      );

      expect(strings, <String, String>{'ok': 'yes'});
    });

    test('a 404 yields nothing rather than throwing', () async {
      expect(await _fetch(_serving('not found', status: 404)), isEmpty);
    });

    test('a body that is not a JSON object yields nothing', () async {
      expect(await _fetch(_serving('["a","b"]')), isEmpty);
      expect(await _fetch(_serving('nonsense')), isEmpty);
    });

    test('a transport failure yields nothing rather than throwing', () async {
      final client = MockClient((_) async => throw const _Offline());

      expect(await _fetch(client), isEmpty);
    });
  });
}

class _Offline implements Exception {
  const _Offline();
}
