import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/notifications/data/datasource/notification_preferences_remote_datasource.dart';
import 'package:flutter_pecha/features/notifications/data/repositories/notification_preferences_repository_impl.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._onFetch);

  final Future<ResponseBody> Function(RequestOptions options) _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _onFetch(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _status(int statusCode, [Object? body]) {
  return ResponseBody.fromString(
    body == null ? '' : jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

NotificationPreferencesRemoteDatasource _datasource(
  Future<ResponseBody> Function(RequestOptions) onFetch,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
  dio.httpClientAdapter = _FakeAdapter(onFetch);
  return NotificationPreferencesRemoteDatasource(dio: dio);
}

Map<String, dynamic> _entry(String type, bool enabled, String source) => {
  'notification_type': type,
  'enabled': enabled,
  'muted_until': null,
  'source': source,
};

/// The backend's response, shaped like its own docs
/// (documentation/notification-preferences-api.md §4): every v1 type in
/// render order, resolved over the defaults, plus the group override index.
final _response = {
  'channel': 'PUSH',
  'preferences': [
    _entry('CHAT_MESSAGE', true, 'GLOBAL'),
    _entry('GROUP_POST', false, 'GLOBAL'),
    _entry('EVENT', true, 'DEFAULT'),
    _entry('EVENT_REMINDER', true, 'DEFAULT'),
    _entry('ACCUMULATION', true, 'DEFAULT'),
    _entry('SERIES', true, 'DEFAULT'),
    _entry('PRAYER_RECEIVED', true, 'DEFAULT'),
    _entry('PRAYER_REQUEST', false, 'DEFAULT'),
  ],
  'group_overrides': [
    {
      'group_id': '3f2b0000-0000-0000-0000-00000000c91a',
      'group_title': 'Morning Practice',
      'overridden_types': ['EVENT', 'GROUP_POST'],
      'muted_until': null,
    },
  ],
};

const _expected = NotificationPreferences(
  groupPosts: false,
  groupChats: true,
  prayerReceived: true,
  prayerRequest: false,
);

void main() {
  group('NotificationPreferencesRemoteDatasource', () {
    test('fetch reads the account-wide preferences, uncached', () async {
      final ds = _datasource((options) async {
        expect(options.method, 'GET');
        expect(
          options.uri.toString(),
          'https://example.test/api/v1/users/me/notification-preferences',
        );
        expect(options.queryParameters, isEmpty, reason: 'PUSH is the default');
        expect(options.extra['no_cache'], isTrue);
        return _status(200, _response);
      });

      expect((await ds.fetch()).toEntity(), _expected);
    });

    test(
      'update PATCHes only the flipped switch and parses the reply',
      () async {
        late RequestOptions sent;
        final ds = _datasource((options) async {
          sent = options;
          return _status(200, _response);
        });

        final model = await ds.update({
          ConnectNotificationToggle.prayerRequest: true,
        });

        expect(sent.method, 'PATCH');
        expect(
          sent.uri.toString(),
          'https://example.test/api/v1/users/me/notification-preferences',
        );
        expect(sent.queryParameters, isEmpty);
        // What goes over the wire, explicit null included: it lifts a snooze.
        expect(
          jsonDecode(jsonEncode(sent.data)),
          {
            'preferences': [
              {
                'notification_type': 'PRAYER_REQUEST',
                'enabled': true,
                'muted_until': null,
              },
            ],
          },
        );
        expect(model.toEntity(), _expected);
      },
    );

    test('turning a switch off sends no muted_until at all', () async {
      late RequestOptions sent;
      final ds = _datasource((options) async {
        sent = options;
        return _status(200, _response);
      });

      await ds.update({ConnectNotificationToggle.groupChats: false});

      expect(jsonDecode(jsonEncode(sent.data)), {
        'preferences': [
          {'notification_type': 'CHAT_MESSAGE', 'enabled': false},
        ],
      });
    });
  });

  group('NotificationPreferencesRepositoryImpl', () {
    test('an HTTP failure comes back as a Failure, never a throw', () async {
      final repository = NotificationPreferencesRepositoryImpl(
        remote: _datasource((_) async => _status(403, {'detail': 'nope'})),
      );

      expect((await repository.get()).isLeft(), isTrue);
      expect(
        (await repository.update({
          ConnectNotificationToggle.groupPosts: true,
        })).isLeft(),
        isTrue,
      );
    });

    test('a success maps to the entity', () async {
      final repository = NotificationPreferencesRepositoryImpl(
        remote: _datasource((_) async => _status(200, _response)),
      );

      expect(
        (await repository.get()).getOrElse((_) => throw StateError('left')),
        _expected,
      );
    });
  });
}
