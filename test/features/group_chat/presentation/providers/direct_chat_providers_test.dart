import 'dart:async';
import 'dart:convert';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/direct_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
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
  final sentTo = <String>[];
  final pages = <int>[];
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
    pages.add(skip);
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
  }) async {
    sentTo.add(userId);
    final sent = _message(
      'rest-sent',
      '2026-10-16T11:00:00Z',
      body: body,
      senderId: 'me',
    );
    messages = [sent, ...messages];
    return Right(sent);
  }

  @override
  Future<Either<Failure, Unit>> markRoomRead(String roomId) async {
    readCount++;
    return const Right(unit);
  }

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

  /// Called for each frame the client sends, on the channel it went out on.
  void Function(_FakeChannel channel, Map<String, dynamic> frame)? onSent;

  DirectChatLiveConfig get config => DirectChatLiveConfig(
    getToken: () async => 'tok',
    restBaseUrl: 'https://api.example.com/api/v1',
    clientFactory:
        () => ChatLiveClient(
          connect: (uri) {
            late final _FakeChannel channel;
            channel =
                _FakeChannel(uri)
                  ..onSent = (frame) => onSent?.call(channel, frame);
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

/// Holds the autoDispose provider open, then waits for its first load.
Future<DirectChatNotifier> _notifier(
  ProviderContainer container, {
  String roomId = 'dm-1',
}) async {
  container.listen(directChatProvider(roomId), (_, _) {});
  final notifier = container.read(directChatProvider(roomId).notifier);
  await pumpEventQueue();
  return notifier;
}

/// REST only: the socket config is overridden away.
ProviderContainer _container(_FakeRepository repository) {
  final container = ProviderContainer(
    overrides: [
      groupChatRepositoryProvider.overrideWithValue(repository),
      directChatLiveConfigProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// A notifier on [sockets], with no lifecycle observer, no backoff delay and
/// a short echo wait.
Future<
  (
    ProviderContainer,
    AutoDisposeStateNotifierProvider<DirectChatNotifier, DirectChatState>,
  )
>
_live(
  _FakeRepository repository,
  _Sockets sockets, {
  Duration echoTimeout = const Duration(milliseconds: 200),
}) async {
  final provider = StateNotifierProvider.autoDispose<
    DirectChatNotifier,
    DirectChatState
  >(
    (ref) => DirectChatNotifier(
      ref: ref,
      roomId: 'dm-1',
      live: sockets.config,
      observeLifecycle: false,
      backoff: (_) => Duration.zero,
      echoTimeout: echoTimeout,
    ),
  );
  final container = ProviderContainer(
    overrides: [groupChatRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  container.listen(provider, (_, _) {});
  container.read(provider);
  await pumpEventQueue();
  return (container, provider);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mergeDirectMessages', () {
    test('one row per message, newest first', () {
      final merged = mergeDirectMessages(
        [_message('a', '2026-10-16T10:00:00Z')],
        [
          _message('c', '2026-10-16T12:00:00Z'),
          _message('a', '2026-10-16T10:00:00Z'),
          _message('b', '2026-10-16T11:00:00Z'),
        ],
      );

      expect(merged.map((m) => m.id), ['c', 'b', 'a']);
    });

    test('the incoming copy wins, so edits and deletes show', () {
      final merged = mergeDirectMessages(
        [_message('a', '2026-10-16T10:00:00Z', body: 'old')],
        [_message('a', '2026-10-16T10:00:00Z', body: 'edited')],
      );

      expect(merged.single.body, 'edited');
    });

    test('same-instant messages keep a stable order', () {
      final first = mergeDirectMessages(
        [_message('a', '2026-10-16T10:00:00Z')],
        [_message('b', '2026-10-16T10:00:00Z')],
      );
      final second = mergeDirectMessages(
        [_message('b', '2026-10-16T10:00:00Z')],
        [_message('a', '2026-10-16T10:00:00Z')],
      );

      expect(first.map((m) => m.id), second.map((m) => m.id));
    });
  });

  test('a message is the viewer\'s when it is not from the other person', () {
    final fromTeam = _message('a', '2026-10-16T10:00:00Z');
    final fromMe = _message('b', '2026-10-16T10:00:00Z', senderId: 'me');

    expect(isOwnDirectMessage(fromTeam, 'team'), isFalse);
    expect(isOwnDirectMessage(fromMe, 'team'), isTrue);
    // Before the room says who the other person is, nothing is anyone's.
    expect(isOwnDirectMessage(fromMe, ''), isFalse);
  });

  group('DirectChatNotifier over REST', () {
    test('loads the room and the newest page, then marks it read', () async {
      final repository = _FakeRepository();
      final container = _container(repository);
      await _notifier(container);

      final state = container.read(directChatProvider('dm-1'));
      expect(state.room, _room);
      expect(state.messages.map((m) => m.id), ['m3', 'm2', 'm1']);
      expect(state.hasLoaded, isTrue);
      expect(state.hasMore, isFalse);
      expect(repository.readCount, 1);
    });

    test('pages on from what it holds', () async {
      final repository = _FakeRepository(messages: _thread(45));
      final container = _container(repository);
      final notifier = await _notifier(container);

      expect(
        container.read(directChatProvider('dm-1')).messages,
        hasLength(30),
      );
      await notifier.loadMore();

      final state = container.read(directChatProvider('dm-1'));
      expect(repository.pages, [0, 30]);
      expect(state.messages, hasLength(45));
      expect(state.hasMore, isFalse);
    });

    test('a reply goes to the other person and shows at once', () async {
      final repository = _FakeRepository();
      final container = _container(repository);
      final notifier = await _notifier(container);

      final result = await notifier.send('Thank you!');

      expect(result.isRight(), isTrue);
      expect(repository.sentTo, ['team']);
      final state = container.read(directChatProvider('dm-1'));
      expect(state.messages.first.body, 'Thank you!');
      expect(state.skip, 4);
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
      final container = _container(repository);
      final notifier = await _notifier(container);

      final result = await notifier.send('Hello?');

      expect(result.isLeft(), isTrue);
      expect(repository.sentTo, isEmpty);
    });

    test('a seeded room shows until the fetched one replaces it', () async {
      final repository = _FakeRepository();
      final container = _container(repository);
      container.listen(directChatProvider('dm-1'), (_, _) {});
      final notifier = container.read(directChatProvider('dm-1').notifier);

      const seeded = ChatRoomDTO(
        id: 'dm-1',
        createdBy: 'team',
        kind: 'PRIVATE',
        name: 'From the list',
        updatedAt: '',
        otherUserId: 'team',
      );
      notifier.seedRoom(seeded);
      expect(container.read(directChatProvider('dm-1')).room, seeded);

      await pumpEventQueue();
      expect(container.read(directChatProvider('dm-1')).room, _room);
    });
  });

  group('DirectChatNotifier over the socket', () {
    test('connects by the other person once the room is known', () async {
      final sockets = _Sockets();
      await _live(_FakeRepository(), sockets);

      expect(sockets.channels, hasLength(1));
      final uri = sockets.channels.single.uri;
      expect(uri.path, '/api/v1/chat/live');
      expect(uri.queryParameters['receiver_id'], 'team');
      expect(uri.queryParameters['token'], 'tok');
    });

    test('a message from the other person shows live and is read', () async {
      final repository = _FakeRepository();
      final sockets = _Sockets();
      final (container, provider) = await _live(repository, sockets);
      final readsBefore = repository.readCount;

      sockets.channels.single.serverSends(
        _created(_message('live', '2026-10-16T12:00:00Z', body: 'Hello!')),
      );
      await pumpEventQueue();

      final state = container.read(provider);
      expect(state.messages.first.body, 'Hello!');
      expect(state.total, 4);
      expect(repository.readCount, readsBefore + 1);
    });

    test('a delete turns the message into a tombstone', () async {
      final sockets = _Sockets();
      final (container, provider) = await _live(_FakeRepository(), sockets);

      sockets.channels.single.serverSends({
        'type': 'message_deleted',
        'message_id': 'm2',
        'deleted_by': 'team',
        'deleted_at': '2026-10-16T12:00:00Z',
      });
      await pumpEventQueue();

      final deleted = container
          .read(provider)
          .messages
          .firstWhere((m) => m.id == 'm2');
      expect(deleted.deletedAt, '2026-10-16T12:00:00Z');
    });

    test('a message for another room is ignored', () async {
      final sockets = _Sockets();
      final (container, provider) = await _live(_FakeRepository(), sockets);

      sockets.channels.single.serverSends(
        _created(
          _message('x', '2026-10-16T12:00:00Z', roomId: 'someone-else'),
        ),
      );
      await pumpEventQueue();

      expect(container.read(provider).messages.map((m) => m.id), [
        'm3',
        'm2',
        'm1',
      ]);
    });

    test('a send goes over the socket and resolves on its echo', () async {
      final repository = _FakeRepository();
      final sockets = _Sockets();
      final (container, provider) = await _live(repository, sockets);
      final channel = sockets.channels.single;
      channel.serverSends({'type': 'room_info', 'room_id': 'dm-1'});
      await pumpEventQueue();
      expect(container.read(provider.notifier).isLive, isTrue);

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
      final result = await container.read(provider.notifier).send('Thanks!');

      expect(result.getRight().toNullable()?.id, 'echo');
      expect(channel.sent.where((f) => f['type'] == 'message'), [
        {'type': 'message', 'body': 'Thanks!'},
      ]);
      expect(repository.sentTo, isEmpty);
      expect(container.read(provider).messages.first.id, 'echo');
    });

    test('a refused send keeps its reason, and is not retried', () async {
      final repository = _FakeRepository();
      final sockets = _Sockets();
      final (container, provider) = await _live(repository, sockets);
      final channel = sockets.channels.single;
      channel.serverSends({'type': 'room_info', 'room_id': 'dm-1'});
      await pumpEventQueue();

      channel.onSent = (frame) {
        if (frame['type'] != 'message') return;
        channel.serverSends({
          'type': 'error',
          'code': 'INAPPROPRIATE_LANGUAGE',
          'message': 'Please keep it kind',
        });
      };
      final result = await container.read(provider.notifier).send('bad');

      final failure = result.getLeft().toNullable();
      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure).code, 'INAPPROPRIATE_LANGUAGE');
      expect(repository.sentTo, isEmpty);
    });

    test('before room_info, a send goes over REST', () async {
      final repository = _FakeRepository();
      final sockets = _Sockets();
      final (container, provider) = await _live(repository, sockets);

      final result = await container.read(provider.notifier).send('Hello');

      expect(result.isRight(), isTrue);
      expect(repository.sentTo, ['team']);
      expect(sockets.channels.single.sent, isEmpty);
    });

    test('with no echo, a message that landed is not sent again', () async {
      final repository = _FakeRepository();
      final sockets = _Sockets();
      final (container, provider) = await _live(repository, sockets);
      final channel = sockets.channels.single;
      channel.serverSends({'type': 'room_info', 'room_id': 'dm-1'});
      await pumpEventQueue();

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
      final result = await container.read(provider.notifier).send('Once');

      expect(result.getRight().toNullable()?.id, 'stored');
      expect(repository.sentTo, isEmpty);
    });

    test('with no echo and nothing stored, it goes over REST', () async {
      final repository = _FakeRepository();
      final sockets = _Sockets();
      final (container, provider) = await _live(repository, sockets);
      sockets.channels.single.serverSends({
        'type': 'room_info',
        'room_id': 'dm-1',
      });
      await pumpEventQueue();

      final result = await container.read(provider.notifier).send('Lost');

      expect(result.getRight().toNullable()?.id, 'rest-sent');
      expect(repository.sentTo, ['team']);
    });

    test('a drop reconnects and catches up on what it missed', () async {
      final repository = _FakeRepository();
      final sockets = _Sockets();
      await _live(repository, sockets);
      final fetchesBefore = repository.pages.length;

      await sockets.channels.single.serverCloses(1011);
      await pumpEventQueue();

      expect(sockets.channels, hasLength(2));
      expect(repository.pages.length, greaterThan(fetchesBefore));
    });

    test('a refused socket (1008) is not retried', () async {
      final sockets = _Sockets();
      final (container, provider) = await _live(_FakeRepository(), sockets);

      await sockets.channels.single.serverCloses(1008);
      await pumpEventQueue();
      // Not even a fetch brings it back.
      await container.read(provider.notifier).refresh();
      await pumpEventQueue();

      expect(sockets.channels, hasLength(1));
    });
  });
}
