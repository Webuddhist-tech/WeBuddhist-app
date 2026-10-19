import 'dart:async';
import 'dart:convert';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/direct_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

ChatMessageDTO _message(
  String id,
  String createdAt, {
  String body = 'hi',
  String senderId = 'team',
  String roomId = 'dm-1',
}) {
  return ChatMessageDTO(
    id: id,
    roomId: roomId,
    senderId: senderId,
    senderEmail: '$senderId@example.com',
    body: body,
    createdAt: createdAt,
  );
}

const _room = ChatRoomDTO(
  id: 'dm-1',
  createdBy: 'team',
  kind: 'PRIVATE',
  name: 'WeBuddhist Team',
  updatedAt: '2026-10-16T10:00:00Z',
  otherUserId: 'team',
  isOfficial: true,
);

/// A thread of [total] messages, newest first, one minute apart.
List<ChatMessageDTO> _thread(int total) => [
  for (var i = total; i > 0; i--)
    _message('m$i', DateTime.utc(2026, 10, 16, 10, i).toIso8601String()),
];

class _FakeRepository implements GroupChatRepository {
  _FakeRepository({this.room = _room, List<ChatMessageDTO>? messages})
    : messages = messages ?? _thread(3);

  ChatRoomDTO room;
  List<ChatMessageDTO> messages;
  final sent = <({String userId, String body, String? parentMessageId})>[];
  var pageCount = 0;
  var readCount = 0;

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) async =>
      Right(room);

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
    String? messageType,
    String? sort,
    String? intention,
    String? translationLanguage,
  }) async {
    pageCount++;
    return Right(
      ChatMessagesPage(
        messages: messages.skip(skip).take(limit).toList(),
        skip: skip,
        limit: limit,
        total: messages.length,
      ),
    );
  }

  @override
  Future<Either<Failure, ChatMessageDTO>> sendDirectMessage(
    String userId, {
    required String body,
    String? parentMessageId,
  }) async {
    sent.add((userId: userId, body: body, parentMessageId: parentMessageId));
    final message = _message(
      'rest-sent',
      '2026-10-16T11:00:00Z',
      body: body,
      senderId: 'me',
    );
    messages = [message, ...messages];
    return Right(message);
  }

  @override
  Future<Either<Failure, Unit>> markRoomRead(String roomId) async {
    readCount++;
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Me extends StateNotifier<UserState> implements UserNotifier {
  _Me() : super(const UserState(user: User(id: 'me', email: 'me@x.org')));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A socket the test drives: frames go in through [serverSends], what the
/// client sends lands in [sent], and [serverCloses] plays the server hanging
/// up.
class _FakeChannel implements WebSocketChannel {
  _FakeChannel(this.uri);

  final Uri uri;
  final _incoming = StreamController<dynamic>();
  final sent = <Map<String, dynamic>>[];
  void Function(Map<String, dynamic> frame)? onSent;

  @override
  int? closeCode;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  late final WebSocketSink sink = _FakeSink(this);

  void serverSends(Map<String, dynamic> frame) =>
      _incoming.add(jsonEncode(frame));

  Future<void> serverCloses([int? code]) async {
    closeCode = code;
    await _incoming.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this.channel);

  final _FakeChannel channel;

  @override
  void add(dynamic data) {
    final frame = jsonDecode(data as String) as Map<String, dynamic>;
    channel.sent.add(frame);
    channel.onSent?.call(frame);
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Hands out a fresh [_FakeChannel] per connection.
class _Sockets {
  final channels = <_FakeChannel>[];

  DirectChatLiveConfig get config => DirectChatLiveConfig(
    getToken: () async => 'tok',
    restBaseUrl: 'https://api.example.com/api/v1',
    clientFactory:
        () => ChatLiveClient(
          connect: (uri) {
            final channel = _FakeChannel(uri);
            channels.add(channel);
            return channel;
          },
        ),
  );
}

Map<String, dynamic> _created(ChatMessageDTO message) => {
  'type': 'message_created',
  'message': message.toJson(),
};

const _roomInfo = {'type': 'room_info', 'room_id': 'dm-1'};

/// One open direct chat: the session and its thread, held the way the screen
/// holds them.
class _Chat {
  _Chat(this.container, this.session);

  final ProviderContainer container;
  final AutoDisposeStateNotifierProvider<DirectChatNotifier, DirectChatState>
  session;

  DirectChatNotifier get notifier => container.read(session.notifier);
  DirectChatState get state => container.read(session);
  List<ChatMessageDTO> get messages =>
      container.read(groupChatThreadProvider('dm-1')).messages;
}

/// Opens a chat on [repository]. With [sockets], over the socket, with no
/// lifecycle observer, no backoff delay and a short echo wait; without, REST
/// only.
Future<_Chat> _open(
  _FakeRepository repository, {
  _Sockets? sockets,
  Duration echoTimeout = const Duration(milliseconds: 200),
}) async {
  final session = StateNotifierProvider.autoDispose<
    DirectChatNotifier,
    DirectChatState
  >(
    (ref) => DirectChatNotifier(
      ref: ref,
      roomId: 'dm-1',
      live: sockets?.config,
      observeLifecycle: false,
      backoff: (_) => Duration.zero,
      echoTimeout: echoTimeout,
    ),
  );
  final container = ProviderContainer(
    overrides: [
      groupChatRepositoryProvider.overrideWithValue(repository),
      userProvider.overrideWith((ref) => _Me()),
    ],
  );
  addTearDown(container.dispose);
  container.listen(groupChatThreadProvider('dm-1'), (_, _) {});
  container.listen(session, (_, _) {});
  await pumpEventQueue();
  return _Chat(container, session);
}

/// Opens a chat over the socket and waits for `room_info`.
Future<(_Chat, _FakeChannel)> _openLive(_FakeRepository repository) async {
  final sockets = _Sockets();
  final chat = await _open(repository, sockets: sockets);
  final channel = sockets.channels.single;
  channel.serverSends(_roomInfo);
  await pumpEventQueue();
  return (chat, channel);
}

void main() {
  // The provider's own notifier observes the app lifecycle.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a message is the viewer\'s when it is not from the other person', () {
    final fromTeam = _message('a', '2026-10-16T10:00:00Z');
    final fromMe = _message('b', '2026-10-16T10:00:00Z', senderId: 'me');

    expect(isOwnDirectMessage(fromTeam, 'team'), isFalse);
    expect(isOwnDirectMessage(fromMe, 'team'), isTrue);
    // Before the room says who the other person is, nothing is anyone's.
    expect(isOwnDirectMessage(fromMe, ''), isFalse);
  });

  group('DirectChatNotifier over REST', () {
    test('loads the room and marks it read', () async {
      final repository = _FakeRepository();
      final chat = await _open(repository);

      expect(chat.state.room, _room);
      expect(chat.messages.map((m) => m.id), ['m3', 'm2', 'm1']);
      expect(repository.readCount, greaterThan(0));
    });

    test('a reply goes to the other person, with its parent', () async {
      final repository = _FakeRepository();
      final chat = await _open(repository);

      final result = await chat.notifier.send('Yes', parentMessageId: 'm2');

      expect(result.isRight(), isTrue);
      expect(repository.sent.single, (
        userId: 'team',
        body: 'Yes',
        parentMessageId: 'm2',
      ));
      expect(chat.messages.first.body, 'Yes');
    });

    test('nothing is sent before the room names the other person', () async {
      final repository = _FakeRepository(
        room: const ChatRoomDTO(
          id: 'dm-1',
          createdBy: 'x',
          kind: 'PRIVATE',
          name: '',
          updatedAt: '',
        ),
      );
      final chat = await _open(repository);

      final result = await chat.notifier.send('Hello?');

      expect(result.isLeft(), isTrue);
      expect(repository.sent, isEmpty);
    });

    test('a seeded room shows until the fetched one replaces it', () async {
      final repository = _FakeRepository();
      final session = directChatProvider('dm-1');
      final container = ProviderContainer(
        overrides: [
          groupChatRepositoryProvider.overrideWithValue(repository),
          userProvider.overrideWith((ref) => _Me()),
          directChatLiveConfigProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      container.listen(session, (_, _) {});

      const seeded = ChatRoomDTO(
        id: 'dm-1',
        createdBy: 'team',
        kind: 'PRIVATE',
        name: 'From the list',
        updatedAt: '',
        otherUserId: 'team',
      );
      container.read(session.notifier).seedRoom(seeded);
      expect(container.read(session).room, seeded);

      await pumpEventQueue();
      expect(container.read(session).room, _room);
    });
  });

  group('DirectChatNotifier over the socket', () {
    test('connects by the other person once the room is known', () async {
      final sockets = _Sockets();
      await _open(_FakeRepository(), sockets: sockets);

      final uri = sockets.channels.single.uri;
      expect(uri.path, '/api/v1/chat/live');
      expect(uri.queryParameters['receiver_id'], 'team');
      expect(uri.queryParameters['token'], 'tok');
    });

    test('a message from the other person lands in the thread', () async {
      final repository = _FakeRepository();
      final (chat, channel) = await _openLive(repository);
      final readsBefore = repository.readCount;

      channel.serverSends(
        _created(_message('live', '2026-10-16T12:00:00Z', body: 'Hello!')),
      );
      await pumpEventQueue();

      expect(chat.messages.first.body, 'Hello!');
      expect(repository.readCount, readsBefore + 1);
    });

    test('a reaction lands on its message', () async {
      final (chat, channel) = await _openLive(_FakeRepository());

      channel.serverSends({
        'type': 'reactions_updated',
        'message_id': 'm2',
        'reactions': [
          {
            'emoji': '🙏',
            'count': 1,
            'user_ids': ['team'],
          },
        ],
      });
      await pumpEventQueue();

      final reacted = chat.messages.firstWhere((m) => m.id == 'm2');
      expect(reacted.reactions.single.emoji, '🙏');
      // Not the viewer's: the other person reacted.
      expect(reacted.reactions.single.reactedByMe, isFalse);
    });

    test('a delete turns the message into a tombstone', () async {
      final (chat, channel) = await _openLive(_FakeRepository());

      channel.serverSends({
        'type': 'message_deleted',
        'message_id': 'm2',
        'deleted_by': 'team',
        'deleted_at': '2026-10-16T12:00:00Z',
      });
      await pumpEventQueue();

      final deleted = chat.messages.firstWhere((m) => m.id == 'm2');
      expect(deleted.deletedAt, '2026-10-16T12:00:00Z');
    });

    test('a message for another room is ignored', () async {
      final (chat, channel) = await _openLive(_FakeRepository());

      channel.serverSends(
        _created(
          _message('x', '2026-10-16T12:00:00Z', roomId: 'someone-else'),
        ),
      );
      await pumpEventQueue();

      expect(chat.messages.map((m) => m.id), ['m3', 'm2', 'm1']);
    });

    test('a send goes over the socket and resolves on its echo', () async {
      final repository = _FakeRepository();
      final (chat, channel) = await _openLive(repository);
      expect(chat.notifier.isLive, isTrue);

      channel.onSent = (frame) {
        if (frame['type'] != 'message') return;
        channel.serverSends(
          _created(
            _message(
              'echo',
              '2026-10-16T12:00:00Z',
              body: frame['body'] as String,
              senderId: 'me',
            ),
          ),
        );
      };
      final result = await chat.notifier.send(
        'Thanks!',
        parentMessageId: 'm3',
      );

      expect(result.getRight().toNullable()?.id, 'echo');
      expect(channel.sent.where((f) => f['type'] == 'message'), [
        {'type': 'message', 'body': 'Thanks!', 'parent_message_id': 'm3'},
      ]);
      expect(repository.sent, isEmpty);
      expect(chat.messages.first.id, 'echo');
    });

    test('a refused send keeps its reason, and is not retried', () async {
      final repository = _FakeRepository();
      final (chat, channel) = await _openLive(repository);

      channel.onSent = (frame) {
        if (frame['type'] != 'message') return;
        channel.serverSends({
          'type': 'error',
          'code': 'INAPPROPRIATE_LANGUAGE',
          'message': 'Please keep it kind',
        });
      };
      final result = await chat.notifier.send('bad');

      final failure = result.getLeft().toNullable();
      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure).code, 'INAPPROPRIATE_LANGUAGE');
      expect(repository.sent, isEmpty);
    });

    test('before room_info, a send goes over REST', () async {
      final repository = _FakeRepository();
      final sockets = _Sockets();
      final chat = await _open(repository, sockets: sockets);

      final result = await chat.notifier.send('Hello');

      expect(result.isRight(), isTrue);
      expect(repository.sent.single.body, 'Hello');
      expect(sockets.channels.single.sent, isEmpty);
    });

    test('with no echo, a message that landed is not sent again', () async {
      final repository = _FakeRepository();
      final (chat, channel) = await _openLive(repository);

      // The server stores it, but the echo never comes back.
      channel.onSent = (frame) {
        if (frame['type'] != 'message') return;
        repository.messages = [
          _message(
            'stored',
            '2026-10-16T12:00:00Z',
            body: frame['body'] as String,
            senderId: 'me',
          ),
          ...repository.messages,
        ];
      };
      final result = await chat.notifier.send('Once');

      expect(result.getRight().toNullable()?.id, 'stored');
      expect(repository.sent, isEmpty);
    });

    test('with no echo and nothing stored, it goes over REST', () async {
      final repository = _FakeRepository();
      final (chat, _) = await _openLive(repository);

      final result = await chat.notifier.send('Lost');

      expect(result.getRight().toNullable()?.id, 'rest-sent');
      expect(repository.sent.single.body, 'Lost');
    });

    test('a drop reconnects and catches up on what it missed', () async {
      final repository = _FakeRepository();
      final sockets = _Sockets();
      await _open(repository, sockets: sockets);
      final pagesBefore = repository.pageCount;

      await sockets.channels.single.serverCloses(1011);
      await pumpEventQueue();

      expect(sockets.channels, hasLength(2));
      expect(repository.pageCount, greaterThan(pagesBefore));
    });

    test('a refused socket (1008) is not retried', () async {
      final sockets = _Sockets();
      final chat = await _open(_FakeRepository(), sockets: sockets);

      await sockets.channels.single.serverCloses(1008);
      await pumpEventQueue();
      // Not even a refresh brings it back.
      await chat.notifier.refresh();
      await pumpEventQueue();

      expect(sockets.channels, hasLength(1));
    });
  });
}
