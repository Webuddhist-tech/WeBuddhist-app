import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_summary_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

ChatMessageDTO _prayer(String id, {int count = 0, bool prayedByMe = false}) {
  return ChatMessageDTO(
    id: id,
    roomId: 'room-1',
    senderId: 'u1',
    senderEmail: 'u1@example.com',
    senderName: 'Tenzin',
    body: 'pray $id',
    createdAt: '2026-09-11T10:04:00+00:00',
    messageType: ChatMessageDTO.typePrayer,
    prayerCount: count,
    prayedByMe: prayedByMe,
  );
}

class _FakeGroupChatRepository implements GroupChatRepository {
  _FakeGroupChatRepository({this.history = const []});

  List<ChatMessageDTO> history;
  Failure? roomFailure;
  Failure? prayFailure;
  final List<String?> listedTypes = [];
  final List<List<String>> prayed = [];
  final List<String> unprayed = [];
  final List<String?> sentTypes = [];
  final List<String?> sentIntentions = [];
  final List<int> prayersSkips = [];
  final List<Map<String, String?>> updates = [];
  ChatMessageDTO? updateResponse;
  final List<String> deleted = [];
  Failure? deleteFailure;
  final List<int> listedSkips = [];

  /// Awaited before a page or an update is answered, to stage a race.
  Completer<void>? listGate;
  Completer<void>? updateGate;
  List<ChatPrayerUserDTO> supporters = const [];

  @override
  Future<Either<Failure, ChatRoomDTO>> getEventRoom(String eventId) async {
    final failure = roomFailure;
    if (failure != null) return Left(failure);
    return const Right(
      ChatRoomDTO(
        id: 'room-1',
        createdBy: 'u1',
        kind: 'EVENT',
        eventId: 'e1',
        name: 'Tara',
        updatedAt: '',
      ),
    );
  }

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
    String? messageType,
  }) async {
    listedTypes.add(messageType);
    listedSkips.add(skip);
    final gate = listGate;
    if (gate != null) await gate.future;
    final end = (skip + limit).clamp(0, history.length);
    final start = skip.clamp(0, history.length);
    return Right(
      ChatMessagesPage(
        messages: history.sublist(start, end),
        skip: skip,
        limit: limit,
        total: history.length,
      ),
    );
  }

  @override
  Future<Either<Failure, ChatMessageDTO>> sendEventMessage(
    String eventId, {
    required String body,
    String? parentMessageId,
    String? messageType,
    String? intention,
  }) async {
    sentTypes.add(messageType);
    sentIntentions.add(intention);
    return Right(_prayer('sent'));
  }

  @override
  Future<Either<Failure, List<ChatPrayerIntentionDTO>>> listIntentions() async =>
      const Right([]);

  @override
  Future<Either<Failure, ChatPrayersPage>> listPrayers(
    String messageId, {
    int skip = 0,
    int limit = 20,
  }) async {
    prayersSkips.add(skip);
    final failure = prayFailure;
    if (failure != null) return Left(failure);
    final end = (skip + limit).clamp(0, supporters.length);
    final start = skip.clamp(0, supporters.length);
    return Right(
      ChatPrayersPage(
        messageId: messageId,
        prayers: supporters.sublist(start, end),
        skip: skip,
        limit: limit,
        total: supporters.length,
      ),
    );
  }

  @override
  Future<Either<Failure, List<ChatPrayerSummaryDTO>>> prayFor(
    String roomId, {
    required List<String> messageIds,
  }) async {
    prayed.add(messageIds);
    final failure = prayFailure;
    if (failure != null) return Left(failure);
    return Right([
      for (final id in messageIds)
        ChatPrayerSummaryDTO(
          messageId: id,
          prayerCount: 7,
          prayedByMe: true,
          created: true,
        ),
    ]);
  }

  @override
  Future<Either<Failure, ChatPrayerSummaryDTO>> removePrayer(
    String messageId,
  ) async {
    unprayed.add(messageId);
    final failure = prayFailure;
    if (failure != null) return Left(failure);
    return Right(
      ChatPrayerSummaryDTO(
        messageId: messageId,
        prayerCount: 6,
        prayedByMe: false,
      ),
    );
  }

  @override
  Future<Either<Failure, ChatRoomsPage>> listRooms({
    int skip = 0,
    int limit = 20,
  }) async =>
      const Right(ChatRoomsPage(rooms: [], skip: 0, limit: 0, total: 0));

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) async =>
      const Left(NotFoundFailure('not used'));

  @override
  Future<Either<Failure, ChatMessageDTO>> sendGroupMessage(
    String groupId, {
    required String body,
    String? parentMessageId,
    String? messageType,
    String? intention,
  }) async => const Left(NotFoundFailure('not used'));

  @override
  Future<Either<Failure, ChatRoomMembersPage>> listRoomMembers(
    String roomId, {
    int skip = 0,
    int limit = 100,
  }) async => const Right(
    ChatRoomMembersPage(members: [], skip: 0, limit: 0, total: 0),
  );

  @override
  Future<Either<Failure, Unit>> markRoomRead(String roomId) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> reportMessage(
    String roomId, {
    required String messageId,
    required String reason,
    String? description,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, ChatMessageDTO?>> updateMessage(
    String roomId, {
    required String messageId,
    required String body,
    String? intention,
  }) async {
    updates.add({
      'roomId': roomId,
      'messageId': messageId,
      'body': body,
      'intention': intention,
    });
    final gate = updateGate;
    if (gate != null) await gate.future;
    return Right(updateResponse);
  }

  @override
  Future<Either<Failure, Unit>> deleteMessage(
    String roomId, {
    required String messageId,
  }) async {
    deleted.add('$roomId/$messageId');
    final failure = deleteFailure;
    if (failure != null) return Left(failure);
    history = history.where((message) => message.id != messageId).toList();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteMessages(
    String roomId, {
    required List<String> messageIds,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> addReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async => const Right([]);

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> removeReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async => const Right([]);
}

PrayerRequestsNotifier _keepAlive(ProviderContainer container) {
  container.listen(prayerRequestsProvider('e1'), (_, _) {});
  return container.read(prayerRequestsProvider('e1').notifier);
}

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ChatMessageDTO _byId(PrayerRequestsNotifier notifier, String id) {
  return notifier.state.requests.firstWhere((request) => request.id == id);
}

void main() {
  late _FakeGroupChatRepository repository;
  late ProviderContainer container;

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [groupChatRepositoryProvider.overrideWithValue(repository)],
    );
  }

  tearDown(() => container.dispose());

  group('PrayerRequestsNotifier', () {
    test('resolves the event room, then lists only prayer requests', () async {
      repository = _FakeGroupChatRepository(
        history: [_prayer('a'), _prayer('b')],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.roomStatus, PrayerRoomStatus.ready);
      expect(notifier.state.roomId, 'room-1');
      expect(notifier.state.hasLoaded, isTrue);
      expect(notifier.state.requests.map((r) => r.id), ['a', 'b']);
      expect(repository.listedTypes, ['PRAYER']);
    });

    test('a 404 on the room means prayer requests are closed', () async {
      repository =
          _FakeGroupChatRepository()
            ..roomFailure = const NotFoundFailure('gone');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.roomStatus, PrayerRoomStatus.closed);
      expect(notifier.state.hasLoaded, isTrue);
      expect(notifier.state.error, isNull);
    });

    test('any other room failure is retryable', () async {
      repository =
          _FakeGroupChatRepository()..roomFailure = const ServerFailure('boom');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      expect(notifier.state.roomStatus, PrayerRoomStatus.failed);

      repository.roomFailure = null;
      await notifier.retry();
      await _settle();
      expect(notifier.state.roomStatus, PrayerRoomStatus.ready);
    });

    test('send posts a PRAYER message and inserts it at the top', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.send('Please pray', intention: 'healing');

      expect(repository.sentTypes, ['PRAYER']);
      expect(repository.sentIntentions, ['healing']);
      expect(notifier.state.requests.first.id, 'sent');
    });

    test('edit patches the row in place and keeps its prayers', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      const healing = ChatPrayerIntentionDTO(
        slug: 'healing',
        label: 'Healing',
        color: '#4A78C2',
      );
      final result = await notifier.edit(
        'a',
        body: 'Please pray again',
        intention: healing,
      );

      expect(result.isRight(), isTrue);
      expect(repository.updates, [
        {
          'roomId': 'room-1',
          'messageId': 'a',
          'body': 'Please pray again',
          'intention': 'healing',
        },
      ]);
      final edited = _byId(notifier, 'a');
      expect(edited.body, 'Please pray again');
      expect(edited.intention, healing);
      expect(edited.prayerCount, 3);
    });

    test('edit prefers what the server answers with', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      const peace = ChatPrayerIntentionDTO(
        slug: 'peace',
        label: 'Peace',
        color: '#FFFFFF',
      );
      repository.updateResponse = _prayer(
        'a',
      ).copyWith(body: 'Trimmed by server', intention: peace);
      await notifier.edit(
        'a',
        body: 'Trimmed by server   ',
        intention: const ChatPrayerIntentionDTO(
          slug: 'peace',
          label: 'Peace',
          color: '#000000',
        ),
      );

      final edited = _byId(notifier, 'a');
      expect(edited.body, 'Trimmed by server');
      expect(edited.intention, peace);
    });

    test('a prayer that lands mid-edit survives the save', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      repository.updateGate = Completer<void>();
      const healing = ChatPrayerIntentionDTO(
        slug: 'healing',
        label: 'Healing',
        color: '#4A78C2',
      );
      final pending = notifier.edit('a', body: 'Edited', intention: healing);
      await _settle();
      notifier.applyPrayersUpdated(
        const [
          ChatLivePrayerUpdate(messageId: 'a', prayerCount: 4, userIds: ['u9']),
        ],
        viewerId: 'u1',
      );
      repository.updateGate!.complete();
      final result = await pending;

      final edited = _byId(notifier, 'a');
      expect(edited.body, 'Edited');
      expect(edited.intention, healing);
      expect(edited.prayerCount, 4);
      expect(result.getOrElse((_) => throw StateError('left')).prayerCount, 4);
    });

    test('applyEdit rewrites body and intention, nothing else', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 2)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      const peace = ChatPrayerIntentionDTO(
        slug: 'peace',
        label: 'Peace',
        color: '#FFFFFF',
      );
      notifier.applyEdit(
        _prayer('a').copyWith(body: 'From elsewhere', intention: peace),
      );

      final edited = _byId(notifier, 'a');
      expect(edited.body, 'From elsewhere');
      expect(edited.intention, peace);
      expect(edited.prayerCount, 2);
    });

    test('a delete during loadMore rereads the shifted page', () async {
      final history = [for (var i = 0; i < 35; i++) _prayer('m$i')];
      repository = _FakeGroupChatRepository(history: history);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      expect(notifier.state.requests.length, 30);

      repository.listGate = Completer<void>();
      final pending = notifier.loadMore();
      await _settle();
      await notifier.delete('m0');
      repository.listGate!.complete();
      await pending;
      await _settle();

      expect(repository.listedSkips, [0, 30, 29]);
      expect(notifier.state.requests.map((r) => r.id), [
        for (var i = 1; i < 35; i++) 'm$i',
      ]);
      expect(notifier.state.hasMore, isFalse);
    });

    test('delete removes the row once the server agrees', () async {
      repository = _FakeGroupChatRepository(
        history: [_prayer('a'), _prayer('b')],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      final result = await notifier.delete('a');

      expect(result.isRight(), isTrue);
      expect(repository.deleted, ['room-1/a']);
      expect(notifier.state.requests.map((r) => r.id), ['b']);
      expect(notifier.state.skip, 1);
    });

    test('a refused delete leaves the row in place', () async {
      repository =
          _FakeGroupChatRepository(history: [_prayer('a')])
            ..deleteFailure = const ServerFailure('boom');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      final result = await notifier.delete('a');

      expect(result.isLeft(), isTrue);
      expect(notifier.state.requests.map((r) => r.id), ['a']);
    });

    test('appendLive ignores TEXT messages and duplicates', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.appendLive(
        const ChatMessageDTO(
          id: 't',
          roomId: 'room-1',
          senderId: 'u2',
          senderEmail: 'u2@example.com',
          body: 'hello',
          createdAt: '',
        ),
      );
      notifier.appendLive(_prayer('a'));
      notifier.appendLive(_prayer('b'));

      expect(notifier.state.requests.map((r) => r.id), ['b', 'a']);
    });

    test('togglePrayer is optimistic and adopts the server count', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      final pending = notifier.togglePrayer('a');
      expect(_byId(notifier, 'a').prayedByMe, isTrue);
      expect(_byId(notifier, 'a').prayerCount, 4);

      await pending;
      expect(repository.prayed, [
        ['a'],
      ]);
      expect(_byId(notifier, 'a').prayerCount, 7);
      expect(_byId(notifier, 'a').prayedByMe, isTrue);

      await notifier.togglePrayer('a');
      expect(repository.unprayed, ['a']);
      expect(_byId(notifier, 'a').prayedByMe, isFalse);
      expect(_byId(notifier, 'a').prayerCount, 6);
    });

    test('the live count follows loads, sends and deletions', () async {
      repository = _FakeGroupChatRepository(
        history: [_prayer('a'), _prayer('b')],
      );
      container = buildContainer();
      // The chip's watch is what keeps the auto-disposed count alive.
      final countSub = container.listen(
        prayerRequestCountProvider('e1'),
        (_, _) {},
      );
      addTearDown(countSub.close);
      int? count() => countSub.read();

      expect(count(), isNull);
      final notifier = _keepAlive(container);
      await _settle();
      expect(count(), 2);

      await notifier.send('Please pray', intention: 'healing');
      expect(count(), 3);

      notifier.applyDeletion('a');
      expect(count(), 2);
    });

    test('leaving a full stack re-reads it from the roster', () async {
      const me = ChatPrayerUserDTO(userId: 'me', name: 'Tenzin');
      const others = [
        ChatPrayerUserDTO(userId: 'u2', name: 'Pema'),
        ChatPrayerUserDTO(userId: 'u3', name: 'Sonam'),
        ChatPrayerUserDTO(userId: 'u4', name: 'Karma'),
      ];
      repository =
          _FakeGroupChatRepository(
              history: [
                _prayer('a', count: 4, prayedByMe: true).copyWith(
                  recentPrayers: [me, others[0], others[1]],
                ),
              ],
            )
            ..supporters = others;
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.togglePrayer('a', viewer: me);
      await _settle();

      expect(_byId(notifier, 'a').recentPrayers, others);
    });

    test('togglePrayer moves the viewer in and out of the avatar stack', () async {
      const pema = ChatPrayerUserDTO(userId: 'u2', name: 'Pema');
      const me = ChatPrayerUserDTO(userId: 'me', name: 'Tenzin');
      repository = _FakeGroupChatRepository(
        history: [
          _prayer('a', count: 1).copyWith(recentPrayers: const [pema]),
        ],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      final pending = notifier.togglePrayer('a', viewer: me);
      expect(_byId(notifier, 'a').recentPrayers, [me, pema]);
      await pending;
      expect(_byId(notifier, 'a').recentPrayers, [me, pema]);

      await notifier.togglePrayer('a', viewer: me);
      expect(_byId(notifier, 'a').recentPrayers, [pema]);
    });

    test('a failed pray restores the avatar stack too', () async {
      const me = ChatPrayerUserDTO(userId: 'me', name: 'Tenzin');
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)])
        ..prayFailure = const ServerFailure('boom');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.togglePrayer('a', viewer: me);

      expect(_byId(notifier, 'a').recentPrayers, isEmpty);
    });

    test('a failed pray rolls the optimistic change back', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)])
        ..prayFailure = const ServerFailure('boom');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.togglePrayer('a');

      expect(_byId(notifier, 'a').prayedByMe, isFalse);
      expect(_byId(notifier, 'a').prayerCount, 3);
    });

    test('applyPrayersUpdated derives prayed_by_me from user_ids', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 1)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.applyPrayersUpdated(const [
        ChatLivePrayerUpdate(
          messageId: 'a',
          prayerCount: 12,
          userIds: ['u9', 'me'],
        ),
      ], viewerId: 'me');
      expect(_byId(notifier, 'a').prayerCount, 12);
      expect(_byId(notifier, 'a').prayedByMe, isTrue);

      // An unknown viewer keeps whatever was shown.
      notifier.applyPrayersUpdated(const [
        ChatLivePrayerUpdate(messageId: 'a', prayerCount: 13, userIds: []),
      ], viewerId: '');
      expect(_byId(notifier, 'a').prayerCount, 13);
      expect(_byId(notifier, 'a').prayedByMe, isTrue);
    });

    test('applyDeletion drops the request', () async {
      repository = _FakeGroupChatRepository(
        history: [_prayer('a'), _prayer('b')],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      notifier.applyDeletion('a');

      expect(notifier.state.requests.map((r) => r.id), ['b']);
    });
  });

  group('PrayerSupportersNotifier', () {
    PrayerSupportersNotifier keepAlive(ProviderContainer container) {
      container.listen(prayerSupportersProvider('a'), (_, _) {});
      return container.read(prayerSupportersProvider('a').notifier);
    }

    test('loads the roster and pages through it', () async {
      repository =
          _FakeGroupChatRepository()
            ..supporters = [
              for (var i = 0; i < 25; i++)
                ChatPrayerUserDTO(userId: 'u$i', name: 'User $i'),
            ];
      container = buildContainer();

      final notifier = keepAlive(container);
      await _settle();

      expect(notifier.state.hasLoaded, isTrue);
      expect(notifier.state.total, 25);
      expect(notifier.state.supporters.length, 20);
      expect(notifier.state.hasMore, isTrue);

      await notifier.loadMore();
      expect(repository.prayersSkips, [0, 20]);
      expect(notifier.state.supporters.length, 25);
      expect(notifier.state.hasMore, isFalse);
    });

    test('a newcomer shifting the roster does not stall paging', () async {
      repository =
          _FakeGroupChatRepository()
            ..supporters = [
              for (var i = 0; i < 21; i++)
                ChatPrayerUserDTO(userId: 'u$i', name: 'User $i'),
            ];
      container = buildContainer();

      final notifier = keepAlive(container);
      await _settle();
      expect(notifier.state.supporters.length, 20);

      // Someone prays before the next page: the roster shifts by one, so
      // page two repeats the last person from page one.
      repository.supporters = [
        const ChatPrayerUserDTO(userId: 'new', name: 'Newcomer'),
        ...repository.supporters,
      ];
      await notifier.loadMore();
      expect(repository.prayersSkips, [0, 20]);
      // Dedup drops the repeat but the offset still advances by the page.
      expect(notifier.state.supporters.length, 21);
      expect(notifier.state.skip, 22);
      expect(notifier.state.hasMore, isFalse);
    });

    test('a failed load is retryable', () async {
      repository =
          _FakeGroupChatRepository()
            ..prayFailure = const ServerFailure('boom');
      container = buildContainer();

      final notifier = keepAlive(container);
      await _settle();
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.hasLoaded, isTrue);

      repository.prayFailure = null;
      repository.supporters = const [ChatPrayerUserDTO(userId: 'u1')];
      await notifier.load();
      expect(notifier.state.error, isNull);
      expect(notifier.state.supporters.length, 1);
    });
  });
}
