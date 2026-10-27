import 'dart:async';

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_translation_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_summary_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_mantra_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_requests_filter.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_room_scope.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/pending_prayer_sends.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

ChatMessageDTO _prayer(
  String id, {
  int count = 0,
  bool prayedByMe = false,
  ChatPrayerIntentionDTO? intention,
}) {
  return ChatMessageDTO(
    id: id,
    roomId: 'room-1',
    senderId: 'u1',
    senderEmail: 'u1@example.com',
    senderName: 'Tenzin',
    body: 'pray $id',
    createdAt: '2026-09-11T10:04:00+00:00',
    messageType: ChatMessageDTO.typePrayer,
    intention: intention,
    prayerCount: count,
    prayedByMe: prayedByMe,
  );
}

const _healing = ChatPrayerIntentionDTO(
  slug: 'healing',
  label: 'Healing',
  color: '#4A78C2',
);

const _peace = ChatPrayerIntentionDTO(
  slug: 'peace',
  label: 'Peace',
  color: '#FFFFFF',
);

const _readyTranslation = ChatMessageTranslationDTO(
  targetLanguage: 'EN',
  status: ChatMessageTranslationDTO.statusReady,
  body: 'May the Guru bless us',
);

/// A Chinese request the server has already put into English.
ChatMessageDTO _translated(String id, {int count = 0}) {
  return _prayer(id, count: count).copyWith(
    sourceLanguage: 'ZH',
    translation: _readyTranslation,
    canTranslate: true,
  );
}

const _eventScope = PrayerRoomScope.event('e1');
const _groupScope = PrayerRoomScope.group('g1');

class _FakeGroupChatRepository implements GroupChatRepository {
  _FakeGroupChatRepository({this.history = const []});

  List<ChatMessageDTO> history;
  Failure? roomFailure;

  /// Returned on the event room; null for a room without one.
  ChatRoomMantraDTO? roomMantra;
  Failure? listFailure;

  /// Which room endpoint was asked, `event:<id>` or `group:<id>`.
  final List<String> roomLookups = [];
  final List<String?> roomLanguages = [];

  /// Which send endpoint was used, `event:<id>` or `group:<id>`.
  final List<String> sentTo = [];
  Failure? prayFailure;

  /// Answers the next pray call only, then clears itself.
  Failure? prayFailureOnce;
  final List<String?> listedTypes = [];
  final List<String?> listedSorts = [];
  final List<String?> listedTranslationLanguages = [];
  final List<String?> listedIntentions = [];
  final List<List<String>> prayed = [];
  final List<int> prayedCounts = [];
  final Map<String, int> mine = {};

  /// Awaited before a pray call is answered, to stage a race.
  Completer<void>? prayGate;
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
  Future<Either<Failure, ChatRoomDTO>> getEventRoom(
    String eventId, {
    String? language,
  }) async {
    roomLookups.add('event:$eventId');
    roomLanguages.add(language);
    final failure = roomFailure;
    if (failure != null) return Left(failure);
    return Right(
      ChatRoomDTO(
        id: 'room-1',
        createdBy: 'u1',
        kind: 'EVENT',
        eventId: 'e1',
        name: 'Tara',
        updatedAt: '',
        mantra: roomMantra,
      ),
    );
  }

  @override
  Future<Either<Failure, ChatRoomDTO>> getGroupRoom(
    String groupId, {
    String? language,
  }) async {
    roomLookups.add('group:$groupId');
    roomLanguages.add(language);
    final failure = roomFailure;
    if (failure != null) return Left(failure);
    return const Right(
      ChatRoomDTO(
        id: 'room-1',
        createdBy: 'u1',
        kind: 'GROUP',
        groupId: 'g1',
        name: 'Sangha',
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
    String? sort,
    String? intention,
    String? translationLanguage,
  }) async {
    listedTypes.add(messageType);
    listedSkips.add(skip);
    listedSorts.add(sort);
    listedIntentions.add(intention);
    listedTranslationLanguages.add(translationLanguage);
    final gate = listGate;
    if (gate != null) await gate.future;
    final failure = listFailure;
    if (failure != null) return Left(failure);
    final rows =
        intention == null
            ? history
            : history.where((m) => m.intention?.slug == intention).toList();
    final end = (skip + limit).clamp(0, rows.length);
    final start = skip.clamp(0, rows.length);
    return Right(
      ChatMessagesPage(
        messages: rows.sublist(start, end),
        skip: skip,
        limit: limit,
        total: rows.length,
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
    sentTo.add('event:$eventId');
    sentTypes.add(messageType);
    sentIntentions.add(intention);
    return Right(_prayer('sent'));
  }

  @override
  Future<Either<Failure, ChatMessageDTO>> sendDirectMessage(
    String userId, {
    required String body,
    String? parentMessageId,
  }) async => const Left(NotFoundFailure('not used'));

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
    int count = 1,
  }) async {
    prayed.add(messageIds);
    prayedCounts.add(count);
    final gate = prayGate;
    if (gate != null) await gate.future;
    final once = prayFailureOnce;
    if (once != null) {
      prayFailureOnce = null;
      return Left(once);
    }
    final failure = prayFailure;
    if (failure != null) return Left(failure);
    return Right([
      for (final id in messageIds)
        ChatPrayerSummaryDTO(
          messageId: id,
          prayerCount: 7,
          prayedByMe: true,
          myPrayerCount: mine[id] = (mine[id] ?? 0) + count,
          created: true,
        ),
    ]);
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
  }) async {
    sentTo.add('group:$groupId');
    sentTypes.add(messageType);
    sentIntentions.add(intention);
    return Right(_prayer('sent'));
  }

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

  final List<Map<String, Object?>> myListed = [];
  final List<Map<String, Object?>> completions = [];
  Failure? completeFailure;

  final List<List<String>> randomExcludes = [];
  Failure? randomFailure;

  /// What the random pick answers; null falls back to the first row of
  /// [history] not yet excluded.
  ChatMessageDTO? randomResponse;

  @override
  Future<Either<Failure, ChatMessageDTO>> pickRandomPrayerRequest(
    String roomId, {
    List<String> excludeIds = const [],
    String? translationLanguage,
  }) async {
    randomExcludes.add(excludeIds);
    final failure = randomFailure;
    if (failure != null) return Left(failure);
    final picked =
        randomResponse ??
        history.where((m) => !excludeIds.contains(m.id)).firstOrNull;
    if (picked == null) return const Left(NotFoundFailure('none'));
    return Right(picked);
  }

  @override
  Future<Either<Failure, ChatMessagesPage>> listMyPrayerRequests({
    int skip = 0,
    int limit = 20,
    String? eventId,
    String? groupId,
    bool? isCompleted,
  }) async {
    myListed.add({
      'skip': skip,
      'eventId': eventId,
      'groupId': groupId,
      'isCompleted': isCompleted,
    });
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
  Future<Either<Failure, ChatMessageDTO?>> setMessageCompleted(
    String roomId, {
    required String messageId,
    required bool isCompleted,
  }) async {
    completions.add({
      'roomId': roomId,
      'messageId': messageId,
      'isCompleted': isCompleted,
    });
    final failure = completeFailure;
    if (failure != null) return Left(failure);
    return Right(updateResponse);
  }

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
  container.listen(prayerRequestsProvider(_eventScope), (_, _) {});
  return container.read(prayerRequestsProvider(_eventScope).notifier);
}

Future<void> _settle({int ticks = 5}) async {
  for (var i = 0; i < ticks; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Pray calls are timer-driven; zero pacing lets them run under [_settle].
const _instant = PrayerPacing(
  batchWindow: Duration.zero,
  rateWindow: Duration.zero,
  retryAfter: Duration.zero,
);

ChatMessageDTO _byId(PrayerRequestsNotifier notifier, String id) {
  return notifier.state.requests.firstWhere((request) => request.id == id);
}

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage(super.code);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeGroupChatRepository repository;
  late ProviderContainer container;

  ProviderContainer buildContainer({
    PrayerPacing pacing = _instant,
    String translationLanguage = 'EN',
    String mantraLanguage = 'en',
  }) {
    return ProviderContainer(
      overrides: [
        groupChatRepositoryProvider.overrideWithValue(repository),
        prayerPacingProvider.overrideWithValue(pacing),
        prayerTranslationLanguageProvider.overrideWithValue(
          translationLanguage,
        ),
        prayerMantraLanguageProvider.overrideWithValue(mantraLanguage),
      ],
    );
  }

  tearDown(() => container.dispose());

  test('the mantra language is the content language, lowercased', () {
    container = ProviderContainer(
      overrides: [
        contentLanguageProvider.overrideWith(
          (ref) => _FixedContentLanguage('zh-Hans'),
        ),
      ],
    );
    expect(container.read(prayerMantraLanguageProvider), 'zh-hans');
  });

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
      expect(repository.roomLookups, ['event:e1']);
      expect(repository.roomLanguages, ['en']);
    });

    test('a space scope resolves the group room instead', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();

      container.listen(prayerRequestsProvider(_groupScope), (_, _) {});
      final notifier = container.read(
        prayerRequestsProvider(_groupScope).notifier,
      );
      await _settle();

      expect(repository.roomLookups, ['group:g1']);
      expect(repository.roomLanguages, ['en']);
      expect(notifier.state.roomStatus, PrayerRoomStatus.ready);
      expect(notifier.state.roomId, 'room-1');
      expect(notifier.state.requests.map((r) => r.id), ['a']);
      expect(repository.listedTypes, ['PRAYER']);
    });

    test('a space scope posts to the group endpoint and counts it', () async {
      repository = _FakeGroupChatRepository();
      container = buildContainer();

      container.listen(prayerRequestsProvider(_groupScope), (_, _) {});
      container.listen(prayerRequestCountProvider(_groupScope), (_, _) {});
      final notifier = container.read(
        prayerRequestsProvider(_groupScope).notifier,
      );
      await _settle();

      final result = await notifier.send('Please', intention: 'healing');
      expect(result.isRight(), isTrue);
      expect(repository.sentTo, ['group:g1']);
      expect(repository.sentTypes, ['PRAYER']);
      expect(notifier.state.requests.map((r) => r.id), ['sent']);
      expect(container.read(prayerRequestCountProvider(_groupScope)), 1);
      // The event keyed by the same id is a different room.
      expect(container.read(prayerRequestCountProvider(_eventScope)), isNull);
    });

    test('the first page is listed newest, with no intention', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(repository.listedSorts, ['newest']);
      expect(repository.listedIntentions, [null]);
      expect(notifier.state.filter, PrayerRequestsFilter.initial);
      expect(notifier.state.total, 1);
    });

    test('every page is listed in the translation language', () async {
      final history = [for (var i = 0; i < 35; i++) _prayer('m$i')];
      repository = _FakeGroupChatRepository(history: history);
      container = buildContainer(translationLanguage: 'BO');

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.loadMore();
      await notifier.refreshLatest();

      expect(repository.listedSkips, [0, 30, 0]);
      expect(repository.listedTranslationLanguages, ['BO', 'BO', 'BO']);
    });

    test('setFilter re-lists from the top under the new sort', () async {
      repository = _FakeGroupChatRepository(
        history: [_prayer('a'), _prayer('b')],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.loadMore();
      await notifier.setFilter(
        const PrayerRequestsFilter(sort: PrayerSort.needsPrayers),
      );

      expect(repository.listedSorts.last, 'needs_prayers');
      expect(repository.listedSkips.last, 0);
      expect(notifier.state.filter.sort, PrayerSort.needsPrayers);
      expect(notifier.state.requests.map((r) => r.id), ['a', 'b']);
      expect(notifier.state.isLoading, isFalse);
    });

    test('an intention filter sends the slug and drops the sort', () async {
      repository = _FakeGroupChatRepository(
        history: [
          _prayer('a', intention: _healing),
          _prayer('b', intention: _peace),
          _prayer('c', intention: _healing),
        ],
      );
      container = buildContainer();
      final countSub = container.listen(
        prayerRequestCountProvider(_eventScope),
        (_, _) {},
      );
      addTearDown(countSub.close);

      final notifier = _keepAlive(container);
      await _settle();
      expect(countSub.read(), 3);

      await notifier.setFilter(
        const PrayerRequestsFilter(
          sort: PrayerSort.mostPrayed,
          intention: _healing,
        ),
      );

      expect(repository.listedSorts.last, isNull);
      expect(repository.listedIntentions.last, 'healing');
      expect(notifier.state.requests.map((r) => r.id), ['a', 'c']);
      expect(notifier.state.total, 2);
      // The room's own count is not the filtered one.
      expect(countSub.read(), 3);

      await notifier.setFilter(notifier.state.filter.withoutIntention());
      expect(repository.listedSorts.last, 'most_prayed');
      expect(repository.listedIntentions.last, isNull);
      expect(notifier.state.requests.length, 3);
    });

    test('a page from an earlier filter is dropped when it lands', () async {
      repository = _FakeGroupChatRepository(
        history: [_prayer('a', intention: _healing)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      repository.listGate = Completer<void>();
      final slow = notifier.setFilter(
        const PrayerRequestsFilter(sort: PrayerSort.oldest),
      );
      await _settle();
      final slowGate = repository.listGate!;
      repository.listGate = null;
      final fast = notifier.setFilter(
        const PrayerRequestsFilter(intention: _peace),
      );
      await fast;
      expect(notifier.state.requests, isEmpty);
      expect(notifier.state.hasLoaded, isTrue);

      slowGate.complete();
      await slow;
      expect(notifier.state.filter.intention, _peace);
      expect(notifier.state.requests, isEmpty);
    });

    test('a live request outside the intention in view is counted, not shown', () async {
      repository = _FakeGroupChatRepository(
        history: [_prayer('a', intention: _healing)],
      );
      container = buildContainer();
      final countSub = container.listen(
        prayerRequestCountProvider(_eventScope),
        (_, _) {},
      );
      addTearDown(countSub.close);

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.setFilter(
        const PrayerRequestsFilter(intention: _healing),
      );

      notifier.appendLive(_prayer('x', intention: _peace));
      expect(notifier.state.requests.map((r) => r.id), ['a']);
      expect(notifier.state.total, 1);
      expect(countSub.read(), 2);

      notifier.appendLive(_prayer('y', intention: _healing));
      expect(notifier.state.requests.map((r) => r.id), ['y', 'a']);
      expect(notifier.state.total, 2);
      expect(countSub.read(), 3);
    });

    test('a send outside the intention in view is counted once', () async {
      repository = _FakeGroupChatRepository(
        history: [_prayer('a', intention: _healing)],
      );
      container = buildContainer();
      final countSub = container.listen(
        prayerRequestCountProvider(_eventScope),
        (_, _) {},
      );
      addTearDown(countSub.close);

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.setFilter(
        const PrayerRequestsFilter(intention: _healing),
      );

      notifier.appendLive(_prayer('x', intention: _peace));
      // The socket echo of the same request.
      notifier.appendLive(_prayer('x', intention: _peace));
      expect(countSub.read(), 2);
      expect(notifier.state.total, 1);

      notifier.applyDeletion('x');
      expect(countSub.read(), 1);
      expect(notifier.state.total, 1);
    });

    test('under oldest a live request waits for its page', () async {
      final history = [for (var i = 0; i < 35; i++) _prayer('m$i')];
      repository = _FakeGroupChatRepository(history: history);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.setFilter(
        const PrayerRequestsFilter(sort: PrayerSort.oldest),
      );
      expect(notifier.state.requests.length, 30);

      repository.history = [...history, _prayer('new')];
      notifier.appendLive(_prayer('new'));
      notifier.appendLive(_prayer('new'));
      expect(notifier.state.requests.length, 30);
      expect(notifier.state.skip, 30);
      expect(notifier.state.total, 36);

      await notifier.loadMore();
      expect(repository.listedSkips.last, 30);
      expect(notifier.state.requests.last.id, 'new');
      expect(notifier.state.requests.length, 36);
      expect(notifier.state.hasMore, isFalse);

      notifier.appendLive(_prayer('later'));
      expect(notifier.state.requests.last.id, 'later');
      expect(notifier.state.skip, 37);
    });

    test('a request held past the last page is let in when paging ends', () async {
      final history = [for (var i = 0; i < 35; i++) _prayer('m$i')];
      repository = _FakeGroupChatRepository(history: history);
      container = buildContainer();
      final countSub = container.listen(
        prayerRequestCountProvider(_eventScope),
        (_, _) {},
      );
      addTearDown(countSub.close);

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.setFilter(
        const PrayerRequestsFilter(sort: PrayerSort.oldest),
      );

      repository.listGate = Completer<void>();
      final pending = notifier.loadMore();
      await _settle();
      // Created after the server read the page: the reply leaves it out.
      notifier.appendLive(_prayer('new'));
      notifier.applyPrayersUpdated(
        [ChatLivePrayerUpdate(messageId: 'new', prayerCount: 2, userIds: [])],
        viewerId: 'u1',
      );
      repository.listGate!.complete();
      await pending;

      expect(notifier.state.requests.map((r) => r.id).last, 'new');
      expect(notifier.state.requests.last.prayerCount, 2);
      expect(notifier.state.requests.length, 36);
      expect(notifier.state.hasMore, isFalse);
      expect(notifier.state.total, 36);
      expect(notifier.state.skip, 36);
      expect(countSub.read(), 36);

      notifier.applyDeletion('new');
      expect(notifier.state.requests.length, 35);
      expect(notifier.state.total, 35);
      expect(countSub.read(), 35);
    });

    test('a held request that reached the first page can still be deleted', () async {
      final history = [for (var i = 0; i < 35; i++) _prayer('m$i', count: 1)];
      repository = _FakeGroupChatRepository(history: history);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.setFilter(
        const PrayerRequestsFilter(sort: PrayerSort.mostPrayed),
      );

      notifier.appendLive(_prayer('new'));
      expect(notifier.state.requests.length, 30);
      expect(notifier.state.total, 36);

      // It gained prayers before the reconnect, so it leads the first page.
      repository.history = [_prayer('new', count: 5), ...history];
      await notifier.refreshLatest();
      expect(notifier.state.requests.first.id, 'new');
      expect(notifier.state.requests.length, 31);
      expect(notifier.state.total, 36);

      notifier.applyDeletion('new');
      expect(notifier.state.requests.any((r) => r.id == 'new'), isFalse);
      expect(notifier.state.total, 35);
      expect(notifier.state.skip, 30);
    });

    test('a filter change clears a shifted page from before it', () async {
      final history = [for (var i = 0; i < 35; i++) _prayer('m$i')];
      repository = _FakeGroupChatRepository(history: history);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      repository.listGate = Completer<void>();
      final pending = notifier.loadMore();
      await _settle();
      await notifier.delete('m0');
      final gate = repository.listGate!;
      repository.listGate = null;
      final refilter = notifier.setFilter(
        const PrayerRequestsFilter(sort: PrayerSort.oldest),
      );
      gate.complete();
      await pending;
      await refilter;
      await _settle();
      expect(notifier.state.requests.length, 30);

      await notifier.loadMore();
      expect(repository.listedSkips, [0, 30, 0, 30]);
      expect(notifier.state.requests.length, 34);
    });

    test('an edit that leaves the intention in view drops the row', () async {
      repository = _FakeGroupChatRepository(
        history: [
          _prayer('a', intention: _healing),
          _prayer('b', intention: _healing),
        ],
      );
      container = buildContainer();
      final countSub = container.listen(
        prayerRequestCountProvider(_eventScope),
        (_, _) {},
      );
      addTearDown(countSub.close);

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.setFilter(
        const PrayerRequestsFilter(intention: _healing),
      );

      notifier.applyEdit(_prayer('a', intention: _peace));
      expect(notifier.state.requests.map((r) => r.id), ['b']);
      expect(notifier.state.total, 1);
      // Still in the room, so its count stays.
      expect(countSub.read(), 2);
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

    test('a room mantra is kept, and dropped once the room loses it', () async {
      repository =
          _FakeGroupChatRepository()
            ..roomMantra = const ChatRoomMantraDTO(
              id: 'm1',
              pronunciation: ' Om Mani Padme Hum ',
            )
            ..listFailure = const ServerFailure('boom');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      expect(notifier.state.mantra, 'Om Mani Padme Hum');
      expect(notifier.state.error, 'boom');

      repository
        ..roomMantra = null
        ..listFailure = null;
      await notifier.retry();
      await _settle();
      expect(notifier.state.roomStatus, PrayerRoomStatus.ready);
      expect(notifier.state.mantra, isNull);
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

    test('edit with a new body drops the stale translation', () async {
      repository = _FakeGroupChatRepository(
        history: [_translated('a', count: 3)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      expect(_byId(notifier, 'a').translatedBody, 'May the Guru bless us');

      await notifier.edit('a', body: 'Please pray again', intention: _healing);

      final edited = _byId(notifier, 'a');
      expect(edited.body, 'Please pray again');
      expect(edited.translation, isNull);
      expect(edited.sourceLanguage, isNull);
      expect(edited.translatedBody, isNull);
      expect(edited.canTranslate, isFalse);
      expect(edited.prayerCount, 3);
    });

    test('edit takes the translation the server answers with', () async {
      repository = _FakeGroupChatRepository(history: [_translated('a')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      const pendingTranslation = ChatMessageTranslationDTO(
        targetLanguage: 'EN',
        status: ChatMessageTranslationDTO.statusPending,
      );
      repository.updateResponse = _prayer('a').copyWith(
        body: 'Edited',
        intention: _healing,
        translation: pendingTranslation,
        canTranslate: true,
      );
      await notifier.edit('a', body: 'Edited', intention: _healing);

      final edited = _byId(notifier, 'a');
      expect(edited.body, 'Edited');
      expect(edited.translation, pendingTranslation);
      expect(edited.canTranslate, isTrue);
      expect(edited.sourceLanguage, isNull);
      expect(edited.translatedBody, isNull);
    });

    test('an edit of the intention alone keeps the translation', () async {
      repository = _FakeGroupChatRepository(
        history: [_translated('a', count: 2)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      await notifier.edit('a', body: 'pray a', intention: _peace);

      final edited = _byId(notifier, 'a');
      expect(edited.intention, _peace);
      expect(edited.translation, _readyTranslation);
      expect(edited.sourceLanguage, 'ZH');
      expect(edited.canTranslate, isTrue);
      expect(edited.translatedBody, 'May the Guru bless us');
      expect(edited.prayerCount, 2);
    });

    test('applyEdit with a new body drops the translation', () async {
      repository = _FakeGroupChatRepository(
        history: [_translated('a', count: 2)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.applyEdit(_prayer('a').copyWith(body: 'From elsewhere'));

      final edited = _byId(notifier, 'a');
      expect(edited.body, 'From elsewhere');
      expect(edited.translation, isNull);
      expect(edited.sourceLanguage, isNull);
      expect(edited.canTranslate, isFalse);
      expect(edited.prayerCount, 2);
    });

    test('applyEdit with the same body keeps the translation', () async {
      repository = _FakeGroupChatRepository(
        history: [_translated('a', count: 2)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.applyEdit(_prayer('a', intention: _peace));

      final edited = _byId(notifier, 'a');
      expect(edited.intention, _peace);
      expect(edited.translation, _readyTranslation);
      expect(edited.sourceLanguage, 'ZH');
      expect(edited.canTranslate, isTrue);
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

    test('pray is optimistic and adopts the server counts', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.pray('a');
      expect(_byId(notifier, 'a').prayedByMe, isTrue);
      expect(_byId(notifier, 'a').prayerCount, 4);
      expect(_byId(notifier, 'a').myPrayerCount, 1);

      await _settle();
      expect(repository.prayed, [
        ['a'],
      ]);
      expect(repository.prayedCounts, [1]);
      expect(_byId(notifier, 'a').prayerCount, 7);
      expect(_byId(notifier, 'a').prayedByMe, isTrue);
      expect(_byId(notifier, 'a').myPrayerCount, 1);
    });

    test('praying again keeps the prayer and adds to my count', () async {
      repository = _FakeGroupChatRepository(
        history: [_prayer('a', count: 3, prayedByMe: true).copyWith(myPrayerCount: 2)],
      )..mine['a'] = 2;
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.pray('a');
      expect(_byId(notifier, 'a').prayedByMe, isTrue);
      // Already counted among the people praying.
      expect(_byId(notifier, 'a').prayerCount, 3);
      expect(_byId(notifier, 'a').myPrayerCount, 3);

      await _settle();
      expect(repository.prayedCounts, [1]);
      expect(_byId(notifier, 'a').myPrayerCount, 3);
    });

    test('taps inside the batch window go out as one call with a count', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.pray('a');
      notifier.pray('a');
      notifier.pray('a');
      expect(_byId(notifier, 'a').myPrayerCount, 3);
      expect(_byId(notifier, 'a').prayerCount, 4);

      await _settle();
      expect(repository.prayed, [
        ['a'],
      ]);
      expect(repository.prayedCounts, [3]);
      expect(_byId(notifier, 'a').myPrayerCount, 3);
    });

    test('more than ten taps are split into calls of at most ten', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      for (var i = 0; i < 25; i++) {
        notifier.pray('a');
      }
      expect(_byId(notifier, 'a').myPrayerCount, 25);

      await _settle(ticks: 20);
      expect(repository.prayedCounts, [10, 10, 5]);
      expect(_byId(notifier, 'a').myPrayerCount, 25);
    });

    test('taps that land during a call wait for it, then send together', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      repository.prayGate = Completer<void>();
      notifier.pray('a');
      await _settle();
      expect(repository.prayedCounts, [1]);

      notifier.pray('a');
      notifier.pray('a');
      expect(_byId(notifier, 'a').myPrayerCount, 3);
      await _settle();
      expect(repository.prayedCounts, [1]);

      repository.prayGate!.complete();
      await _settle(ticks: 10);
      expect(repository.prayedCounts, [1, 2]);
      expect(_byId(notifier, 'a').myPrayerCount, 3);
    });

    test('a 429 sends the same taps again after the retry delay', () async {
      repository =
          _FakeGroupChatRepository(history: [_prayer('a', count: 3)])
            ..prayFailureOnce = const RateLimitFailure('slow down');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.pray('a');
      notifier.pray('a');
      await _settle(ticks: 10);

      expect(repository.prayedCounts, [2, 2]);
      expect(_byId(notifier, 'a').myPrayerCount, 2);
      expect(_byId(notifier, 'a').prayerCount, 7);
    });

    test('a 429 that never clears gives the taps up', () async {
      repository =
          _FakeGroupChatRepository(history: [_prayer('a', count: 3)])
            ..prayFailure = const RateLimitFailure('slow down');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.pray('a');
      await _settle(ticks: 20);

      expect(repository.prayedCounts.length, PrayerPacing.maxRetries + 1);
      expect(_byId(notifier, 'a').prayedByMe, isFalse);
      expect(_byId(notifier, 'a').myPrayerCount, 0);
      expect(_byId(notifier, 'a').prayerCount, 3);
    });

    test('an older server without my_prayer_count still counts taps', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.pray('a');
      notifier.pray('a');
      await _settle();
      // The fake echoes a running total; a server that omits the field
      // would leave it null and the local tally takes over.
      expect(_byId(notifier, 'a').myPrayerCount, 2);
    });

    test('the live count follows loads, sends and deletions', () async {
      repository = _FakeGroupChatRepository(
        history: [_prayer('a'), _prayer('b')],
      );
      container = buildContainer();
      // The chip's watch is what keeps the auto-disposed count alive.
      final countSub = container.listen(
        prayerRequestCountProvider(_eventScope),
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

    test('the first prayer puts the viewer in the avatar stack once', () async {
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

      notifier.pray('a', viewer: me);
      expect(_byId(notifier, 'a').recentPrayers, [me, pema]);
      await _settle();
      expect(_byId(notifier, 'a').recentPrayers, [me, pema]);

      notifier.pray('a', viewer: me);
      await _settle();
      expect(_byId(notifier, 'a').recentPrayers, [me, pema]);
      expect(_byId(notifier, 'a').myPrayerCount, 2);
    });

    test('a failed pray restores the avatar stack too', () async {
      const me = ChatPrayerUserDTO(userId: 'me', name: 'Tenzin');
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)])
        ..prayFailure = const ServerFailure('boom');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      notifier.pray('a', viewer: me);
      await _settle();

      expect(_byId(notifier, 'a').recentPrayers, isEmpty);
    });

    test('a failed pray rolls the optimistic change back', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)])
        ..prayFailure = const ServerFailure('boom');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      notifier.pray('a');
      notifier.pray('a');
      await _settle();

      expect(_byId(notifier, 'a').prayedByMe, isFalse);
      expect(_byId(notifier, 'a').prayerCount, 3);
      expect(_byId(notifier, 'a').myPrayerCount, 0);
    });

    test('a failed batch keeps what the server already confirmed', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      notifier.pray('a');
      await _settle();
      expect(_byId(notifier, 'a').myPrayerCount, 1);

      repository.prayFailure = const ServerFailure('boom');
      notifier.pray('a');
      notifier.pray('a');
      expect(_byId(notifier, 'a').myPrayerCount, 3);
      await _settle();

      expect(_byId(notifier, 'a').prayedByMe, isTrue);
      expect(_byId(notifier, 'a').prayerCount, 7);
      expect(_byId(notifier, 'a').myPrayerCount, 1);
    });

    test('a socket update while taps are outstanding is merged, not lost', () async {
      const me = ChatPrayerUserDTO(userId: 'me', name: 'Tenzin');
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      repository.prayGate = Completer<void>();
      notifier.pray('a', viewer: me);
      await _settle();
      expect(_byId(notifier, 'a').prayerCount, 4);

      // Someone else prays: the broadcast does not yet list the viewer.
      notifier.applyPrayersUpdated(const [
        ChatLivePrayerUpdate(messageId: 'a', prayerCount: 4, userIds: ['u9']),
      ], viewerId: 'me');
      expect(_byId(notifier, 'a').prayerCount, 5);
      expect(_byId(notifier, 'a').prayedByMe, isTrue);

      // The echo of the viewer's own prayer lands before the reply.
      notifier.applyPrayersUpdated(const [
        ChatLivePrayerUpdate(
          messageId: 'a',
          prayerCount: 9,
          userIds: ['u9', 'me'],
        ),
      ], viewerId: 'me');
      expect(_byId(notifier, 'a').prayerCount, 9);
      expect(_byId(notifier, 'a').recentPrayers, [me]);

      // The reply carries an older count; the newer broadcast wins.
      repository.prayGate!.complete();
      await _settle();
      expect(_byId(notifier, 'a').prayerCount, 9);
      expect(_byId(notifier, 'a').myPrayerCount, 1);
    });

    test('a failed call after the broadcast listed me shows one, not the batch', () async {
      const me = ChatPrayerUserDTO(userId: 'me', name: 'Tenzin');
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      repository.prayGate = Completer<void>();
      notifier.pray('a', viewer: me);
      notifier.pray('a', viewer: me);
      await _settle();
      // Could be this call landing, or the same account on another device.
      notifier.applyPrayersUpdated(const [
        ChatLivePrayerUpdate(messageId: 'a', prayerCount: 4, userIds: ['me']),
      ], viewerId: 'me');

      repository.prayFailure = const NetworkFailure('dropped');
      repository.prayGate!.complete();
      await _settle();

      expect(_byId(notifier, 'a').prayedByMe, isTrue);
      expect(_byId(notifier, 'a').myPrayerCount, 1);
      expect(_byId(notifier, 'a').prayerCount, 4);
      expect(_byId(notifier, 'a').recentPrayers, [me]);
    });

    test('closing the sheet keeps a rate-limited retry on its deadline', () async {
      repository =
          _FakeGroupChatRepository(history: [_prayer('a')])
            ..prayFailureOnce = const RateLimitFailure('slow down');
      container = buildContainer(
        pacing: const PrayerPacing(
          batchWindow: Duration.zero,
          rateWindow: Duration.zero,
          retryAfter: Duration(milliseconds: 80),
        ),
      );

      final notifier = _keepAlive(container);
      await _settle();

      notifier.pray('a');
      await _settle();
      expect(repository.prayedCounts, [1]);

      container.dispose();
      await _settle();
      expect(repository.prayedCounts, [1]);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      await _settle();
      expect(repository.prayedCounts, [1, 1]);
    });

    test('a lost reply with no broadcast still drops the taps', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      repository.prayGate = Completer<void>();
      notifier.pray('a');
      await _settle();
      // Someone else prayed; the broadcast does not list the viewer.
      notifier.applyPrayersUpdated(const [
        ChatLivePrayerUpdate(messageId: 'a', prayerCount: 4, userIds: ['u9']),
      ], viewerId: 'me');

      repository.prayFailure = const NetworkFailure('dropped');
      repository.prayGate!.complete();
      await _settle();

      expect(_byId(notifier, 'a').prayedByMe, isFalse);
      expect(_byId(notifier, 'a').myPrayerCount, 0);
      expect(_byId(notifier, 'a').prayerCount, 4);
    });

    test('closing the sheet sends queued taps without waiting a window', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer(
        pacing: const PrayerPacing(
          batchWindow: Duration(seconds: 5),
          rateWindow: Duration(seconds: 5),
          retryAfter: Duration(seconds: 5),
        ),
      );

      final notifier = _keepAlive(container);
      await _settle();

      notifier.pray('a');
      container.dispose();
      await _settle();

      // Nothing had gone out this window, so the drain did not sit it out.
      expect(repository.prayedCounts, [1]);
    });

    test('closing the sheet still sends the taps left in the queue', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.pray('a');
      notifier.pray('a');
      expect(repository.prayedCounts, isEmpty);
      container.dispose();
      await _settle();

      expect(repository.prayedCounts, [2]);
    });

    test('closing the sheet does not hold ready taps behind a retry', () async {
      repository =
          _FakeGroupChatRepository(history: [_prayer('a'), _prayer('b')])
            ..prayFailureOnce = const RateLimitFailure('slow down');
      container = buildContainer(
        pacing: const PrayerPacing(
          batchWindow: Duration.zero,
          rateWindow: Duration.zero,
          retryAfter: Duration(milliseconds: 200),
        ),
      );

      final notifier = _keepAlive(container);
      await _settle();

      notifier.pray('a');
      await _settle();
      expect(repository.prayed, [
        ['a'],
      ]);

      // b is still queued when the sheet closes; a waits on its deadline.
      notifier.pray('b');
      container.dispose();
      await _settle();
      expect(repository.prayed, [
        ['a'],
        ['b'],
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 250));
      await _settle();
      expect(repository.prayed, [
        ['a'],
        ['b'],
        ['a'],
      ]);
    });

    test('sign-out can wait for the taps a closed sheet is still sending', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();
      final sends = container.read(pendingPrayerSendsProvider);

      final notifier = _keepAlive(container);
      await _settle();

      repository.prayGate = Completer<void>();
      notifier.pray('a');
      container.dispose();
      await _settle();
      expect(repository.prayedCounts, [1]);

      var settled = false;
      unawaited(sends.settle().then((_) => settled = true));
      await _settle();
      expect(settled, isFalse);

      repository.prayGate!.complete();
      await _settle();
      expect(settled, isTrue);
    });

    test('a call still out when the sheet closes keeps its 429 retry', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      repository.prayGate = Completer<void>();
      notifier.pray('a');
      notifier.pray('a');
      await _settle();
      expect(repository.prayedCounts, [2]);

      // The call is answered only after the sheet has closed.
      container.dispose();
      repository.prayFailureOnce = const RateLimitFailure('slow down');
      repository.prayGate!.complete();
      await _settle(ticks: 10);

      expect(repository.prayedCounts, [2, 2]);
      expect(repository.mine['a'], 2);
    });

    test('a retry after closing joins the taps queued behind it', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      repository.prayGate = Completer<void>();
      notifier.pray('a');
      await _settle();
      // One call is out; this tap waits for it and is drained on close.
      notifier.pray('a');
      container.dispose();
      await _settle();
      expect(repository.prayedCounts, [1, 1]);

      repository.prayFailureOnce = const RateLimitFailure('slow down');
      repository.prayGate!.complete();
      await _settle(ticks: 10);

      // The first call was refused and went out again; both taps landed once.
      expect(repository.prayedCounts, [1, 1, 1]);
      expect(repository.mine['a'], 2);
    });

    test('a failed drain call keeps the retry of a call still out', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer(
        pacing: const PrayerPacing(
          batchWindow: Duration.zero,
          rateWindow: Duration.zero,
          retryAfter: Duration(milliseconds: 80),
        ),
      );

      final notifier = _keepAlive(container);
      await _settle();

      repository.prayGate = Completer<void>();
      notifier.pray('a');
      notifier.pray('a');
      await _settle();
      expect(repository.prayedCounts, [2]);
      // Two taps are out; this one waits for them and is drained on close.
      notifier.pray('a');
      container.dispose();
      await _settle();
      expect(repository.prayedCounts, [2, 1]);

      // The call that was out is refused, then the drain's own call is lost.
      repository.prayFailureOnce = const RateLimitFailure('slow down');
      repository.prayFailure = const NetworkFailure('dropped');
      repository.prayGate!.complete();
      await _settle();
      repository.prayFailure = null;

      await Future<void>.delayed(const Duration(milliseconds: 120));
      await _settle();
      // Only the refused taps go out again.
      expect(repository.prayedCounts, [2, 1, 2]);
      expect(repository.mine['a'], 2);
    });

    test('a failed drain call still sends the taps it did not carry', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      for (var i = 0; i < 12; i++) {
        notifier.pray('a');
      }
      repository.prayFailureOnce = const NetworkFailure('dropped');
      container.dispose();
      await _settle(ticks: 10);

      // The first ten are lost with their call; the other two were never sent.
      expect(repository.prayedCounts, [10, 2]);
      expect(repository.mine['a'], 2);
    });

    test('sign-out waits for a call still out, and for its retry', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer(
        pacing: const PrayerPacing(
          batchWindow: Duration.zero,
          rateWindow: Duration.zero,
          retryAfter: Duration(milliseconds: 80),
        ),
      );
      final sends = container.read(pendingPrayerSendsProvider);

      final notifier = _keepAlive(container);
      await _settle();

      repository.prayGate = Completer<void>();
      notifier.pray('a');
      await _settle();
      expect(repository.prayedCounts, [1]);
      container.dispose();

      var settled = false;
      unawaited(sends.settle().then((_) => settled = true));
      await _settle();
      expect(settled, isFalse);

      repository.prayFailureOnce = const RateLimitFailure('slow down');
      repository.prayGate!.complete();
      await _settle();
      // The call is home, but its retry has yet to go out.
      expect(repository.prayedCounts, [1]);
      expect(settled, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      await _settle();
      expect(repository.prayedCounts, [1, 1]);
      expect(settled, isTrue);
    });

    test('a rate-limited retry keeps its own deadline', () async {
      repository =
          _FakeGroupChatRepository(history: [_prayer('a'), _prayer('b')])
            ..prayFailureOnce = const RateLimitFailure('slow down');
      container = buildContainer(
        pacing: const PrayerPacing(
          batchWindow: Duration.zero,
          rateWindow: Duration.zero,
          retryAfter: Duration(milliseconds: 80),
        ),
      );

      final notifier = _keepAlive(container);
      await _settle();

      notifier.pray('a');
      await _settle();
      expect(repository.prayed, [
        ['a'],
      ]);

      // A tap elsewhere flushes at once, but does not drag the retry along.
      notifier.pray('b');
      await _settle();
      expect(repository.prayed, [
        ['a'],
        ['b'],
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      await _settle();
      expect(repository.prayed, [
        ['a'],
        ['b'],
        ['a'],
      ]);
      expect(_byId(notifier, 'a').myPrayerCount, 1);
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

    test(
      'My prayers lists from the my-requests endpoint for the event',
      () async {
      repository = _FakeGroupChatRepository(
        history: [_prayer('a'), _prayer('b')],
      );
      container = buildContainer();
      container.listen(prayerRequestCountProvider(_eventScope), (_, _) {});

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.setFilter(PrayerRequestsFilter.initial.withMine());

      expect(repository.myListed, [
        {'skip': 0, 'eventId': 'e1', 'groupId': null, 'isCompleted': null},
      ]);
      expect(repository.listedSorts, ['newest']);
      expect(notifier.state.filter.mine, isTrue);
      expect(notifier.state.requests.map((r) => r.id), ['a', 'b']);
      expect(notifier.state.total, 2);
      // The viewer's count is not the room's.
      expect(container.read(prayerRequestCountProvider(_eventScope)), 2);
    });

    test(
      'My prayers in a space narrows the my-requests endpoint by group',
      () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();
      container.listen(prayerRequestsProvider(_groupScope), (_, _) {});
      container.listen(prayerRequestCountProvider(_groupScope), (_, _) {});
      final notifier = container.read(
        prayerRequestsProvider(_groupScope).notifier,
      );
      await _settle();
      await notifier.setFilter(PrayerRequestsFilter.initial.withMine());

      expect(repository.myListed, [
        {'skip': 0, 'eventId': null, 'groupId': 'g1', 'isCompleted': null},
      ]);
      expect(notifier.state.filter.mine, isTrue);
      expect(notifier.state.requests.map((r) => r.id), ['a']);
      expect(container.read(prayerRequestCountProvider(_groupScope)), 1);
    });

    test(
      'under My prayers only the viewer\'s own live request is listed',
      () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();
      container.listen(prayerRequestCountProvider(_eventScope), (_, _) {});

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.setFilter(PrayerRequestsFilter.initial.withMine());

      notifier.appendLive(_prayer('theirs'), viewerId: 'someone-else');
      expect(notifier.state.requests.map((r) => r.id), ['a']);
      expect(notifier.state.total, 1);
      expect(container.read(prayerRequestCountProvider(_eventScope)), 2);

      notifier.appendLive(_prayer('mine'), viewerId: 'u1');
      expect(notifier.state.requests.map((r) => r.id), ['mine', 'a']);
      expect(notifier.state.total, 2);
    });

    test('setCompleted flips the row and keeps the server\'s time', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a', count: 3)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      repository.updateResponse = _prayer('a').copyWith(
        isCompleted: true,
        completedAt: '2026-10-23T09:00:00+00:00',
      );
      final done = await notifier.setCompleted('a', isCompleted: true);
      expect(done.isRight(), isTrue);
      expect(repository.completions, [
        {'roomId': 'room-1', 'messageId': 'a', 'isCompleted': true},
      ]);
      expect(_byId(notifier, 'a').isCompleted, isTrue);
      expect(_byId(notifier, 'a').completedAt, '2026-10-23T09:00:00+00:00');
      expect(_byId(notifier, 'a').prayerCount, 3);

      repository.updateResponse = null;
      await notifier.setCompleted('a', isCompleted: false);
      expect(_byId(notifier, 'a').isCompleted, isFalse);
      expect(_byId(notifier, 'a').completedAt, isNull);
    });

    test('setCompleted leaves the row alone when the server refuses', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')])
        ..completeFailure = const ServerFailure('nope');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      final done = await notifier.setCompleted('a', isCompleted: true);
      expect(done.isLeft(), isTrue);
      expect(_byId(notifier, 'a').isCompleted, isFalse);
    });

    test(
      'pickRandom spotlights the listed row and passes the excludes',
      () async {
        repository = _FakeGroupChatRepository(
          history: [_prayer('a', count: 2), _prayer('b')],
        );
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();
        notifier.pray('a');
        await _settle();

        final picked = await notifier.pickRandom(excludeIds: const ['x']);
        expect(repository.randomExcludes, [
          ['x'],
        ]);
        expect(picked.isRight(), isTrue);
        // The listed row, with the viewer's prayer on it, not the server's copy.
        expect(notifier.state.spotlight?.id, 'a');
        expect(notifier.state.spotlight?.prayedByMe, isTrue);
      },
    );

    test('a prayer on a spotlight that is not listed still renders', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')])
        ..randomResponse = _prayer('far', count: 4);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.pickRandom();
      expect(notifier.state.spotlight?.id, 'far');

      notifier.pray('far');
      expect(notifier.state.spotlight?.prayedByMe, isTrue);
      expect(notifier.state.spotlight?.prayerCount, 5);
      expect(notifier.state.spotlight?.myPrayerCount, 1);
      await _settle();
      expect(repository.prayed, [
        ['far'],
      ]);
      expect(notifier.state.requests.map((r) => r.id), ['a']);

      notifier.clearSpotlight();
      expect(notifier.state.spotlight, isNull);
    });

    test('pickRandom answers not found when nobody else has posted', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      final picked = await notifier.pickRandom(excludeIds: const ['a']);
      expect(picked.fold((f) => f is NotFoundFailure, (_) => false), isTrue);
      expect(notifier.state.spotlight, isNull);
    });

    test('deleting the spotlit request clears the spotlight', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.pickRandom();
      expect(notifier.state.spotlight?.id, 'a');

      notifier.applyDeletion('a');
      expect(notifier.state.spotlight, isNull);
    });

    test('deleting a request shown only in the spotlight clears it', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')])
        ..randomResponse = _prayer('far');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.pickRandom();
      expect(notifier.state.spotlight?.id, 'far');

      notifier.applyDeletion('far');
      expect(notifier.state.spotlight, isNull);
      expect(notifier.state.requests.map((r) => r.id), ['a']);
      expect(notifier.state.total, 1);
    });

    test('applyEdit carries a completion made on another device', () async {
      repository = _FakeGroupChatRepository(history: [_prayer('a')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.applyEdit(
        _prayer('a').copyWith(
          isCompleted: true,
          completedAt: '2026-10-23T09:00:00+00:00',
        ),
      );
      expect(_byId(notifier, 'a').isCompleted, isTrue);
      expect(_byId(notifier, 'a').completedAt, '2026-10-23T09:00:00+00:00');
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

  group('PrayerRequestsState.othersHaveActiveRequest', () {
    final mine = _prayer('p1');
    const theirs = ChatMessageDTO(
      id: 'p2',
      roomId: 'room-1',
      senderId: 'u2',
      senderEmail: 'u2@example.com',
      body: 'pray p2',
      createdAt: '2026-09-11T10:05:00+00:00',
      messageType: ChatMessageDTO.typePrayer,
    );
    PrayerRequestsState loaded(
      List<ChatMessageDTO> requests, {
      PrayerRequestsFilter filter = PrayerRequestsFilter.initial,
      bool hasMore = false,
    }) => PrayerRequestsState(
      roomStatus: PrayerRoomStatus.ready,
      requests: requests,
      filter: filter,
      hasLoaded: true,
      hasMore: hasMore,
    );

    test('false for an empty room', () {
      expect(loaded(const []).othersHaveActiveRequest(viewerId: 'u1'), false);
    });

    test('false when every request is the viewer\'s', () {
      expect(loaded([mine]).othersHaveActiveRequest(viewerId: 'u1'), false);
    });

    test('matches the viewer by email when the id is unknown', () {
      expect(
        loaded([mine]).othersHaveActiveRequest(viewerEmail: 'U1@example.com'),
        false,
      );
    });

    test('false when the others\' requests are all accomplished', () {
      final done = theirs.copyWith(isCompleted: true);
      expect(
        loaded([mine, done]).othersHaveActiveRequest(viewerId: 'u1'),
        false,
      );
    });

    test('true once someone else has an active request', () {
      expect(
        loaded([mine, theirs]).othersHaveActiveRequest(viewerId: 'u1'),
        true,
      );
    });

    test('null while pages are left to load', () {
      expect(
        loaded([mine], hasMore: true).othersHaveActiveRequest(viewerId: 'u1'),
        isNull,
      );
    });

    test('null for a filtered list', () {
      final byMine = loaded(
        [mine],
        filter: PrayerRequestsFilter.initial.withMine(),
      );
      expect(byMine.othersHaveActiveRequest(viewerId: 'u1'), isNull);
    });

    test('null before the first page lands', () {
      expect(
        const PrayerRequestsState().othersHaveActiveRequest(viewerId: 'u1'),
        isNull,
      );
    });
  });
}
