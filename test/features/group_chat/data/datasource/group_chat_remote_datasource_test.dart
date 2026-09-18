import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/domain/chat_bulk_delete_unsupported.dart';
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

void main() {
  group('GroupChatRemoteDatasource.deleteMessages', () {
    test('sends the ids in a JSON body on the collection, expects 204', () async {
      late RequestOptions sent;
      final ds = _datasource((options) async {
        sent = options;
        return _status(204);
      });

      await expectLater(
        ds.deleteMessages('r1', messageIds: ['m1', 'm2']),
        completes,
      );

      expect(sent.method, 'DELETE');
      expect(sent.path, '/chat/rooms/r1/messages');
      expect(sent.uri.query, isEmpty);
      // `DeleteChatMessagesRequest` in the spec: the body, not the query,
      // which the server answered with 422 "body: Field required".
      expect(sent.data, {
        'message_ids': ['m1', 'm2'],
      });
    });

    test('a 404 or 405 means the route is not deployed', () async {
      for (final status in [404, 405]) {
        final ds = _datasource((_) async => _status(status));
        await expectLater(
          ds.deleteMessages('r1', messageIds: ['m1', 'm2']),
          throwsA(isA<ChatBulkDeleteUnsupportedException>()),
        );
      }
    });

    test('any other refusal surfaces as an ordinary exception', () async {
      final ds = _datasource((_) async => _status(500));
      await expectLater(
        ds.deleteMessages('r1', messageIds: ['m1', 'm2']),
        throwsA(
          allOf(
            isA<Exception>(),
            isNot(isA<ChatBulkDeleteUnsupportedException>()),
          ),
        ),
      );
    });
  });

  group('GroupChatRemoteDatasource.reportMessage', () {
    test(
      'posts the reason, and the description only when there is one',
      () async {
        final bodies = <Object?>[];
        final ds = _datasource((options) async {
          bodies.add(options.data);
          expect(options.path, '/chat/rooms/r1/messages/m1/report');
          return _status(204);
        });

        await ds.reportMessage('r1', messageId: 'm1', reason: 'SPAM');
        await ds.reportMessage(
          'r1',
          messageId: 'm1',
          reason: 'OTHER',
          description: 'keeps posting links',
        );

        expect(bodies, [
          {'reason': 'SPAM'},
          {'reason': 'OTHER', 'description': 'keeps posting links'},
        ]);
      },
    );

    test('a message already reported by this member counts as sent', () async {
      final ds = _datasource(
        (_) async => _status(409, {'detail': 'ALREADY_REPORTED'}),
      );

      await expectLater(
        ds.reportMessage('r1', messageId: 'm1', reason: 'SPAM'),
        completes,
      );
    });

    test('any other refusal still surfaces', () async {
      final ds = _datasource(
        (_) async => _status(400, {'detail': 'CANNOT_REPORT_OWN_MESSAGE'}),
      );

      await expectLater(
        ds.reportMessage('r1', messageId: 'm1', reason: 'SPAM'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
