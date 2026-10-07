import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
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

GroupChatRemoteDatasource _datasource(
  Future<ResponseBody> Function(RequestOptions) onFetch,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = _FakeAdapter(onFetch);
  return GroupChatRemoteDatasource(dio: dio);
}

const _message = {
  'id': 'm1',
  'room_id': 'r1',
  'sender_id': 'u1',
  'sender_email': 'u1@example.com',
  'body': 'Please pray',
  'created_at': '2026-09-11T10:04:00+00:00',
  'message_type': 'PRAYER',
  'prayer_count': 0,
  'prayed_by_me': false,
  'recent_prayers': [],
};

void main() {
  group('GroupChatRemoteDatasource prayers', () {
    test('getEventRoom resolves the event room', () async {
      final ds = _datasource((options) async {
        expect(options.method, 'GET');
        expect(options.path, '/chat/events/e1/room');
        return _status(200, {
          'id': 'r1',
          'created_by': 'u1',
          'kind': 'EVENT',
          'event_id': 'e1',
          'name': 'Tara',
          'updated_at': '2026-09-11T10:04:00+00:00',
        });
      });

      final room = await ds.getEventRoom('e1');
      expect(room.id, 'r1');
      expect(room.eventId, 'e1');
    });

    test('sendEventMessage posts the body with its message_type', () async {
      Object? sent;
      final ds = _datasource((options) async {
        sent = options.data;
        expect(options.path, '/chat/events/e1/messages');
        return _status(201, _message);
      });

      final message = await ds.sendEventMessage(
        'e1',
        body: 'Please pray',
        messageType: 'PRAYER',
        intention: 'healing',
      );

      expect(sent, {
        'body': 'Please pray',
        'message_type': 'PRAYER',
        'intention': 'healing',
      });
      expect(message.isPrayerRequest, isTrue);
    });

    test('updateMessage patches body and intention', () async {
      Object? sent;
      final ds = _datasource((options) async {
        sent = options.data;
        expect(options.method, 'PATCH');
        expect(options.path, '/chat/rooms/r1/messages/m1');
        return _status(200, {..._message, 'body': 'Please pray again'});
      });

      final message = await ds.updateMessage(
        'r1',
        messageId: 'm1',
        body: 'Please pray again',
        intention: 'healing',
      );

      expect(sent, {'body': 'Please pray again', 'intention': 'healing'});
      expect(message?.body, 'Please pray again');
    });

    test('updateMessage answers null when the server sends no body', () async {
      final ds = _datasource((options) async => _status(204));

      final message = await ds.updateMessage(
        'r1',
        messageId: 'm1',
        body: 'Please pray again',
      );

      expect(message, isNull);
    });

    test('listIntentions reads the catalog in display order', () async {
      final ds = _datasource((options) async {
        expect(options.method, 'GET');
        expect(options.path, '/intentions');
        return _status(200, [
          {
            'slug': 'protection',
            'label': 'Protection',
            'color': '#2E7D4F',
            'description': 'For safety.',
            'display_order': 1,
          },
          {
            'slug': 'healing',
            'label': 'Healing',
            'color': '#4A78C2',
            'description': 'For illness.',
            'display_order': 0,
          },
        ]);
      });

      final intentions = await ds.listIntentions();
      expect(intentions.map((i) => i.slug), ['healing', 'protection']);
      expect(intentions.first.color, '#4A78C2');
    });

    test('listPrayers pages the who-prayed roster', () async {
      final ds = _datasource((options) async {
        expect(options.method, 'GET');
        expect(options.path, '/chat/messages/a1/prayers');
        expect(options.queryParameters, {'skip': 20, 'limit': 20});
        return _status(200, {
          'message_id': 'a1',
          'total': 21,
          'skip': 20,
          'limit': 20,
          'prayers': [
            {
              'user_id': 'u2',
              'email': 'pema@example.com',
              'name': 'Pema',
              'avatar_url': 'https://a/p.png',
              'created_at': '2026-09-11T10:04:00+00:00',
            },
          ],
        });
      });

      final page = await ds.listPrayers('a1', skip: 20);
      expect(page.messageId, 'a1');
      expect(page.total, 21);
      expect(page.prayers.single.name, 'Pema');
      expect(page.prayers.single.email, 'pema@example.com');
    });

    test('listMessages filters by message_type when asked', () async {
      final ds = _datasource((options) async {
        expect(options.path, '/chat/rooms/r1/messages');
        expect(options.queryParameters['message_type'], 'PRAYER');
        return _status(200, {
          'messages': [_message],
          'skip': 0,
          'limit': 20,
          'total': 1,
        });
      });

      final page = await ds.listMessages('r1', messageType: 'PRAYER');
      expect(page.messages.single.id, 'm1');
      expect(page.total, 1);
    });

    test('listMessages passes sort and intention only when given', () async {
      final seen = <Map<String, dynamic>>[];
      final ds = _datasource((options) async {
        seen.add(Map.of(options.queryParameters));
        return _status(200, {
          'messages': [],
          'skip': 0,
          'limit': 20,
          'total': 0,
        });
      });

      await ds.listMessages('r1', messageType: 'PRAYER');
      await ds.listMessages(
        'r1',
        messageType: 'PRAYER',
        sort: 'needs_prayers',
      );
      await ds.listMessages(
        'r1',
        messageType: 'PRAYER',
        intention: 'protection',
      );

      expect(seen[0].containsKey('sort'), isFalse);
      expect(seen[0].containsKey('intention'), isFalse);
      expect(seen[1]['sort'], 'needs_prayers');
      expect(seen[2]['intention'], 'protection');
      expect(seen[2].containsKey('sort'), isFalse);
    });

    test('listPrayers reads each person\'s count', () async {
      final ds = _datasource((options) async {
        return _status(200, {
          'message_id': 'a1',
          'total': 1,
          'skip': 0,
          'limit': 20,
          'prayers': [
            {
              'user_id': 'u2',
              'name': 'Pema',
              'prayer_count': 9,
              'last_prayed_at': '2026-09-29T10:04:00+00:00',
            },
          ],
        });
      });

      final page = await ds.listPrayers('a1');
      expect(page.prayers.single.prayerCount, 9);
      expect(page.prayers.single.lastPrayedAt, '2026-09-29T10:04:00+00:00');
    });

    test('prayFor posts the selected ids with a count and reads the summaries', () async {
      Object? sent;
      final ds = _datasource((options) async {
        sent = options.data;
        expect(options.method, 'POST');
        expect(options.path, '/chat/rooms/r1/prayers');
        return _status(200, {
          'prayers': [
            {
              'message_id': 'a1',
              'prayer_count': 12,
              'prayed_by_me': true,
              'my_prayer_count': 3,
              'created': true,
            },
            {
              'message_id': 'b2',
              'prayer_count': 4,
              'prayed_by_me': true,
              'created': false,
            },
          ],
        });
      });

      final prayers = await ds.prayFor(
        'r1',
        messageIds: ['a1', 'b2', 'c3'],
        count: 3,
      );

      expect(sent, {
        'message_ids': ['a1', 'b2', 'c3'],
        'count': 3,
      });
      expect(prayers.map((p) => p.messageId), ['a1', 'b2']);
      expect(prayers.first.created, isTrue);
      expect(prayers.first.myPrayerCount, 3);
      expect(prayers.last.created, isFalse);
      expect(prayers.last.myPrayerCount, isNull);
    });

    test('prayFor sends one prayer when no count is given', () async {
      Object? sent;
      final ds = _datasource((options) async {
        sent = options.data;
        return _status(200, {'prayers': []});
      });

      await ds.prayFor('r1', messageIds: ['a1']);
      expect(sent, {
        'message_ids': ['a1'],
        'count': 1,
      });
    });
  });
}
