import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_summary_dto.dart';
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
  }) async {
    sentTypes.add(messageType);
    return Right(_prayer('sent'));
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
  Future<Either<Failure, Unit>> deleteMessage(
    String roomId, {
    required String messageId,
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
      await notifier.send('Please pray');

      expect(repository.sentTypes, ['PRAYER']);
      expect(notifier.state.requests.first.id, 'sent');
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
}
