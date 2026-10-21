import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/chat_moderation.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('ChatLiveClient', () {
    test('liveUri uses wss and /chat/live under the REST base path', () {
      final uri = ChatLiveClient.liveUri(
        restBaseUrl: 'https://api.example.com/api/v1',
        token: 'tok',
        groupId: 'g1',
      );
      expect(uri.scheme, 'wss');
      expect(uri.host, 'api.example.com');
      expect(uri.path, '/api/v1/chat/live');
      expect(uri.queryParameters['token'], 'tok');
      expect(uri.queryParameters['group_id'], 'g1');
      expect(uri.queryParameters.containsKey('room_id'), isFalse);
    });

    test('liveUri includes room_id when provided', () {
      final uri = ChatLiveClient.liveUri(
        restBaseUrl: 'https://api.example.com/api/v1',
        token: 'tok',
        groupId: 'g1',
        roomId: 'r9',
      );
      expect(uri.queryParameters['group_id'], 'g1');
      expect(uri.queryParameters['room_id'], 'r9');
    });

    test('liveUri maps http to ws', () {
      final uri = ChatLiveClient.liveUri(
        restBaseUrl: 'http://localhost:8000/api/v1',
        token: 'tok',
        groupId: 'g1',
      );
      expect(uri.scheme, 'ws');
    });

    test('liveUri scopes a direct chat by the other person', () {
      final uri = ChatLiveClient.liveUri(
        restBaseUrl: 'https://api.example.com/api/v1',
        token: 'tok',
        receiverId: 'u2',
      );
      expect(uri.path, '/api/v1/chat/live');
      expect(uri.queryParameters['receiver_id'], 'u2');
      expect(uri.queryParameters.containsKey('group_id'), isFalse);
      expect(uri.queryParameters.containsKey('event_id'), isFalse);
    });

    test('liveUri refuses more than one scope', () {
      expect(
        () => ChatLiveClient.liveUri(
          restBaseUrl: 'https://api.example.com/api/v1',
          token: 'tok',
          groupId: 'g1',
          receiverId: 'u2',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('ping is a bare ping frame', () {
      expect(ChatLiveClient.encodePing(), '{"type":"ping"}');
    });

    test('closeCode reports how the server closed the channel', () {
      final channel = _ClosedChannel(1008);
      final client = ChatLiveClient(connect: (_) => channel);

      expect(client.closeCode, isNull);
      client.connect(Uri.parse('wss://example.test/chat/live'));
      expect(client.closeCode, 1008);
    });

    test('parses a message_deleted frame', () {
      final event = ChatLiveClient.parseFrame(
        '{"type":"message_deleted","message_id":"m1",'
        '"deleted_by":"u9","deleted_at":"2026-09-03T10:00:00Z"}',
      );

      expect(event, isA<ChatLiveMessageDeleted>());
      final deleted = event! as ChatLiveMessageDeleted;
      expect(deleted.messageId, 'm1');
      expect(deleted.deletedAt, '2026-09-03T10:00:00Z');
      // Carried even though the label does not need it yet: the day a
      // moderator can delete, this is what tells the two apart.
      expect(deleted.deletedBy, 'u9');
    });

    test('parses a message_updated frame', () {
      final event = ChatLiveClient.parseFrame(
        '{"type":"message_updated","message":{"id":"m1","body":"again"}}',
      );

      expect(event, isA<ChatLiveMessageUpdated>());
      final updated = event! as ChatLiveMessageUpdated;
      expect(updated.message['id'], 'm1');
      expect(updated.message['body'], 'again');
    });

    test('a message_deleted frame missing fields does not throw', () {
      final event = ChatLiveClient.parseFrame('{"type":"message_deleted"}');

      expect(event, isA<ChatLiveMessageDeleted>());
      final deleted = event! as ChatLiveMessageDeleted;
      expect(deleted.messageId, isEmpty);
      expect(deleted.deletedAt, isEmpty);
    });

    test('parses error frames including INAPPROPRIATE_LANGUAGE', () {
      final event = ChatLiveClient.parseFrame(
        '{"type":"error","code":"INAPPROPRIATE_LANGUAGE","message":"blocked"}',
      );
      expect(event, isA<ChatLiveError>());
      final error = event! as ChatLiveError;
      expect(error.code, ChatModeration.inappropriateLanguage);
      expect(error.message, 'blocked');
    });
  });

  group('shared profanity code', () {
    test(
      'WS error and REST ValidationFailure share INAPPROPRIATE_LANGUAGE',
      () {
        final ws =
            ChatLiveClient.parseFrame(
              '{"type":"error","code":"INAPPROPRIATE_LANGUAGE","message":"no"}',
            )!;
        const rest = ValidationFailure(
          'no',
          code: ChatModeration.inappropriateLanguage,
        );
        expect(chatSendErrorCode(rest), chatSendErrorCode(ws));
        expect(
          ChatModeration.isInappropriateLanguage(chatSendErrorCode(rest)),
          isTrue,
        );
      },
    );

    test('ExceptionMapper keeps validation code', () {
      const exception = ValidationException(
        'blocked',
        code: ChatModeration.inappropriateLanguage,
      );
      final failure = ExceptionMapper.map(exception);
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).code,
        ChatModeration.inappropriateLanguage,
      );
    });
  });
}

/// A channel the server has already closed with [closeCode].
class _ClosedChannel implements WebSocketChannel {
  _ClosedChannel(this.closeCode);

  @override
  final int? closeCode;

  @override
  Stream<dynamic> get stream => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
