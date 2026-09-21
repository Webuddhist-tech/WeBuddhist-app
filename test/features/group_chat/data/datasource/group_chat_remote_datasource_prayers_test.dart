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
      );

      expect(sent, {'body': 'Please pray', 'message_type': 'PRAYER'});
      expect(message.isPrayerRequest, isTrue);
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

    test('prayFor posts the selected ids and reads the summaries', () async {
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

      final prayers = await ds.prayFor('r1', messageIds: ['a1', 'b2', 'c3']);

      expect(sent, {
        'message_ids': ['a1', 'b2', 'c3'],
      });
      expect(prayers.map((p) => p.messageId), ['a1', 'b2']);
      expect(prayers.first.created, isTrue);
      expect(prayers.last.created, isFalse);
    });

    test('removePrayer deletes the caller\'s own prayer', () async {
      final ds = _datasource((options) async {
        expect(options.method, 'DELETE');
        expect(options.path, '/chat/messages/a1/prayers/me');
        return _status(200, {
          'message_id': 'a1',
          'prayer_count': 11,
          'prayed_by_me': false,
        });
      });

      final summary = await ds.removePrayer('a1');
      expect(summary.prayerCount, 11);
      expect(summary.prayedByMe, isFalse);
    });
  });
}
