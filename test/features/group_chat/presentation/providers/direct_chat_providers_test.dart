
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/realtime/realtime_providers.dart';
import 'package:flutter_pecha/core/realtime/signal_paths.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
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

import '../../../../helpers/fake_realtime_signals.dart';

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

  /// How many of the next room fetches fail, with [roomFailure].
  var roomFailures = 0;
  Failure roomFailure = const NetworkFailure('offline');

  /// When set, every page request fails with it.
  Failure? pageFailure;

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) async {
    if (roomFailures > 0) {
      roomFailures--;
      return Left(roomFailure);
    }
    return Right(room);
  }

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
    final failure = pageFailure;
    if (failure != null) return Left(failure);
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
class _Chat {
  _Chat(this.container, this.session, this.signals);

  final ProviderContainer container;
  final AutoDisposeStateNotifierProvider<DirectChatNotifier, DirectChatState>
  session;
  final FakeRealtimeSignals signals;

  DirectChatNotifier get notifier => container.read(session.notifier);
  DirectChatState get state => container.read(session);
  List<ChatMessageDTO> get messages =>
      container.read(groupChatThreadProvider('dm-1')).messages;

  /// The room's signal moves.
  void signal(DateTime at) =>
      signals.emit(SignalPaths.chatRoom('dm-1'), {'messages_changed_at': at});
}

/// Opens a chat on [repository] with no lifecycle observer and an immediate
/// room retry. [signedIn] false leaves the chat on REST alone.
Future<_Chat> _open(
  _FakeRepository repository, {
  bool signedIn = true,
  Duration roomRetry = Duration.zero,
  FakeRealtimeSignals? signals,
}) async {
  final fake = signals ?? FakeRealtimeSignals();
  final session = StateNotifierProvider.autoDispose<
    DirectChatNotifier,
    DirectChatState
  >(
    (ref) => DirectChatNotifier(
      ref: ref,
      roomId: 'dm-1',
      observeLifecycle: false,
      roomRetryDelay: (_) => roomRetry,
    ),
  );
  final container = ProviderContainer(
    overrides: [
      groupChatRepositoryProvider.overrideWithValue(repository),
      userProvider.overrideWith((ref) => _Me()),
      realtimeSignalsProvider.overrideWithValue(fake),
      firebaseSignedInProvider.overrideWith((ref) => signedIn),
    ],
  );
  addTearDown(container.dispose);
  container.listen(groupChatThreadProvider('dm-1'), (_, _) {});
  container.listen(session, (_, _) {});
  await pumpEventQueue();
  return _Chat(container, session, fake);
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
          firebaseSignedInProvider.overrideWith((ref) => false),
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

    test('a room that failed to load is fetched again', () async {
      final repository = _FakeRepository()..roomFailures = 1;
      final chat = await _open(repository);

      // The retry has run: the recipient is known.
      expect(chat.state.room, _room);
      expect(chat.state.unavailable, isFalse);
    });

    test('a room that is gone is not fetched again', () async {
      final repository =
          _FakeRepository()
            ..roomFailures = 5
            ..roomFailure = const NotFoundFailure('gone');
      final chat = await _open(repository);

      expect(chat.state.room, isNull);
      expect(chat.state.unavailable, isTrue);
      // One fetch, no retries.
      expect(repository.roomFailures, 4);
      expect((await chat.notifier.send('Hello')).isLeft(), isTrue);
    });

    test('a room the viewer left is not fetched again', () async {
      final repository =
          _FakeRepository()
            ..roomFailures = 5
            ..roomFailure = const AuthorizationFailure('not a member');
      final chat = await _open(repository);

      expect(chat.state.unavailable, isTrue);
      expect(repository.roomFailures, 4);

      await chat.notifier.refresh();
      expect(repository.roomFailures, 4);
    });

    test('a refresh fetches a room that never loaded', () async {
      final repository = _FakeRepository()..roomFailures = 1;
      // Too long a backoff for the retry timer to be what fetches it.
      final chat = await _open(repository, roomRetry: const Duration(hours: 1));
      expect(chat.state.room, isNull);

      await chat.notifier.refresh();

      expect(chat.state.room, _room);
      final result = await chat.notifier.send('Hello');
      expect(result.isRight(), isTrue);
    });
  });

  group('DirectChatNotifier on the room signal', () {
    test('listens to the room as soon as it opens', () async {
      final signals = FakeRealtimeSignals();
      await _open(_FakeRepository(), signals: signals);

      expect(signals.listeners(SignalPaths.chatRoom('dm-1')), 1);
    });

    test('does not listen before Firebase is signed in', () async {
      final signals = FakeRealtimeSignals();
      await _open(_FakeRepository(), signals: signals, signedIn: false);

      expect(signals.listeners(SignalPaths.chatRoom('dm-1')), 0);
    });

    test('the first snapshot catches the loaded thread up once', () async {
      final repository = _FakeRepository();
      final chat = await _open(repository);
      final pages = repository.pageCount;
      final reads = repository.readCount;

      chat.signal(DateTime.utc(2026, 10, 16, 12));
      await pumpEventQueue();
      expect(repository.pageCount, pages + 1);
      expect(repository.readCount, reads + 1);

      chat.signal(DateTime.utc(2026, 10, 16, 12));
      await pumpEventQueue();
      expect(repository.pageCount, pages + 1);
    });

    test('a refetch in the background leaves the room unread', () async {
      final repository = _FakeRepository();
      final chat = await _open(repository);
      chat.signal(DateTime.utc(2026, 10, 16, 12));
      await pumpEventQueue();
      final reads = repository.readCount;

      chat.notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      chat.signal(DateTime.utc(2026, 10, 16, 12, 1));
      await pumpEventQueue();
      expect(repository.readCount, reads);

      chat.notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(repository.readCount, reads + 1);
    });

    test('a moved signal catches the thread up and marks it read', () async {
      final repository = _FakeRepository();
      final chat = await _open(repository);
      chat.signal(DateTime.utc(2026, 10, 16, 12));
      await pumpEventQueue();
      final reads = repository.readCount;

      repository.messages = [
        _message('live', '2026-10-16T12:00:00Z'),
        ...repository.messages,
      ];
      chat.signal(DateTime.utc(2026, 10, 16, 12, 1));
      await pumpEventQueue();

      expect(chat.messages.first.id, 'live');
      expect(repository.readCount, reads + 1);
    });

    test('a message under another page is marked read on return', () async {
      final repository = _FakeRepository();
      final chat = await _open(repository);
      chat.signal(DateTime.utc(2026, 10, 16, 12));
      await pumpEventQueue();
      final readsBefore = repository.readCount;

      chat.notifier.setOnScreen(false);
      repository.messages = [
        _message('live', '2026-10-16T12:00:00Z'),
        ...repository.messages,
      ];
      chat.signal(DateTime.utc(2026, 10, 16, 12, 1));
      await pumpEventQueue();

      expect(chat.messages.first.id, 'live');
      expect(repository.readCount, readsBefore);

      chat.notifier.setOnScreen(true);
      await pumpEventQueue();
      expect(repository.readCount, readsBefore + 1);
    });

    test('coming back with nothing new does not mark read again', () async {
      final repository = _FakeRepository();
      final chat = await _open(repository);
      final readsBefore = repository.readCount;

      chat.notifier.setOnScreen(false);
      chat.notifier.setOnScreen(true);
      await pumpEventQueue();

      expect(repository.readCount, readsBefore);
    });
  });
}
