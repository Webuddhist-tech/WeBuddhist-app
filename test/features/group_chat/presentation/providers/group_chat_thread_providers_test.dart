import 'dart:async';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/chat_link_preview_service.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const thumbsUp = '\u{1F44D}';
const heart = '\u{2764}\u{FE0F}';
const joy = '\u{1F602}';

ChatMessageDTO _message(String id, {String senderId = 'a'}) {
  return ChatMessageDTO(
    id: id,
    roomId: 'room-1',
    senderId: senderId,
    senderEmail: '$senderId@example.com',
    body: 'body $id',
    createdAt: '2026-08-28T12:00:00Z',
  );
}

/// Serves a fixed newest-first history, sliced by skip/limit like the API.
class _FakeGroupChatRepository implements GroupChatRepository {
  _FakeGroupChatRepository({required this.history});

  List<ChatMessageDTO> history;
  Failure? listFailure;
  int listCallCount = 0;

  /// Holds the next list call until completed, so a later one can overtake it.
  Completer<void>? holdNextList;

  /// Reaction summaries handed back, in call order.
  List<List<ChatMessageReactionDTO>> reactionResponses = const [];
  Failure? reactionFailure;
  Set<int> failReactionCalls = const {};
  bool failFirstReaction = false;
  final List<String> reactionCalls = [];

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
  }) async {
    listCallCount++;
    // Cleared before awaiting, so only this call is held.
    final hold = holdNextList;
    holdNextList = null;
    if (hold != null) await hold.future;
    final failure = listFailure;
    if (failure != null) return Left(failure);
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
  Future<Either<Failure, ChatRoomsPage>> listRooms({
    int skip = 0,
    int limit = 20,
  }) async =>
      const Right(ChatRoomsPage(rooms: [], skip: 0, limit: 0, total: 0));

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) async =>
      Left(const NotFoundFailure('not used'));

  @override
  Future<Either<Failure, ChatMessageDTO>> sendGroupMessage(
    String groupId, {
    required String body,
    String? parentMessageId,
  }) async => Right(_message('sent'));

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

  final List<String> deleteCalls = [];
  Failure? deleteFailure;

  @override
  Future<Either<Failure, Unit>> deleteMessage(
    String roomId, {
    required String messageId,
  }) async {
    deleteCalls.add(messageId);
    final failure = deleteFailure;
    if (failure != null) return Left(failure);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> addReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async => _reaction('POST $emoji');

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> removeReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async => _reaction('DELETE $emoji');

  Either<Failure, List<ChatMessageReactionDTO>> _reaction(String call) {
    reactionCalls.add(call);
    if (failFirstReaction && reactionCalls.length == 1) {
      return const Left(NetworkFailure('offline'));
    }
    if (failReactionCalls.contains(reactionCalls.length)) {
      return const Left(NetworkFailure('offline'));
    }
    final failure = reactionFailure;
    if (failure != null) return Left(failure);
    final index = reactionCalls.length - 1;
    if (index < reactionResponses.length) {
      return Right(reactionResponses[index]);
    }
    return const Right([]);
  }
}

ChatMessageDTO _byId(GroupChatThreadNotifier notifier, String id) {
  return notifier.state.messages.firstWhere((message) => message.id == id);
}

/// autoDispose tears the provider down the moment nothing listens, so tests
/// hold a subscription open for the life of the container.
GroupChatThreadNotifier _keepAlive(ProviderContainer container) {
  container.listen(groupChatThreadProvider('room-1'), (_, _) {});
  return container.read(groupChatThreadProvider('room-1').notifier);
}

/// Lets the constructor's `loadInitial` (and any pending fetch) settle.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
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

  group('GroupChatThreadNotifier', () {
    test(
      'loadInitial fills the newest page and reports more to come',
      () async {
        repository = _FakeGroupChatRepository(
          history: List.generate(50, (i) => _message('m$i')),
        );
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();

        expect(notifier.state.messages, hasLength(30));
        expect(notifier.state.messages.first.id, 'm0');
        expect(notifier.state.hasLoaded, isTrue);
        expect(notifier.state.hasMore, isTrue);
        expect(notifier.state.total, 50);
      },
    );

    test('loadMore appends older messages and stops at total', () async {
      repository = _FakeGroupChatRepository(
        history: List.generate(50, (i) => _message('m$i')),
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      await notifier.loadMore();

      expect(notifier.state.messages, hasLength(50));
      expect(notifier.state.messages.last.id, 'm49');
      expect(notifier.state.hasMore, isFalse);

      // Exhausted: a further request is not sent.
      final callsBefore = repository.listCallCount;
      await notifier.loadMore();
      expect(repository.listCallCount, callsBefore);
    });

    test('appendLive prepends and dedupes by id', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.appendLive(_message('m2'));
      expect(notifier.state.messages.map((m) => m.id).toList(), ['m2', 'm1']);

      // The socket echo of a message already held changes nothing.
      notifier.appendLive(_message('m2'));
      expect(notifier.state.messages, hasLength(2));
    });

    test('a REST send followed by its socket echo yields one row', () async {
      repository = _FakeGroupChatRepository(history: []);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      // The POST response is inserted directly...
      notifier.appendLive(_message('sent-1'));
      // ...then `message_created` echoes the same id back.
      notifier.appendLive(_message('sent-1'));

      expect(notifier.state.messages, hasLength(1));
      expect(notifier.state.total, 1);
    });

    test(
      'loadInitial surfaces a failure and still marks the fetch settled',
      () async {
        repository = _FakeGroupChatRepository(history: []);
        repository.listFailure = const NetworkFailure('offline');
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();

        expect(notifier.state.error, 'offline');
        expect(notifier.state.hasLoaded, isTrue);
        expect(notifier.state.messages, isEmpty);
      },
    );

    test('refreshLatest merges what was missed without duplicating', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      // Two messages arrived while the socket was down.
      repository.history = [_message('m3'), _message('m2'), _message('m1')];
      await notifier.refreshLatest();

      expect(notifier.state.messages.map((m) => m.id).toList(), [
        'm3',
        'm2',
        'm1',
      ]);
    });

    test('refreshLatest reports a message nothing else delivered', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      repository.history = [_message('m2'), _message('m1')];
      expect(
        await notifier.refreshLatest(),
        ThreadRefreshResult.missedMessages,
      );
    });

    test(
      'refreshLatest reports nothing missed when the page is all held',
      () async {
        repository = _FakeGroupChatRepository(history: [_message('m1')]);
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();

        expect(
          await notifier.refreshLatest(),
          ThreadRefreshResult.nothingMissed,
        );
      },
    );

    test(
      'a message the socket delivers mid-refresh does not count as missed',
      () async {
        repository = _FakeGroupChatRepository(history: [_message('m1')]);
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();

        // The push and the socket frame race the refetch; the socket wins.
        repository.history = [_message('m2'), _message('m1')];
        final hold = repository.holdNextList = Completer<void>();
        final refreshing = notifier.refreshLatest();
        notifier.appendLive(_message('m2'));
        hold.complete();

        expect(await refreshing, ThreadRefreshResult.nothingMissed);
        expect(notifier.state.messages.map((m) => m.id).toList(), ['m2', 'm1']);
      },
    );

    test('a socket frame landing just after the page is not a miss', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      // The push and the socket frame race the refetch; the page wins by
      // a hair, and the frame follows inside the grace window.
      repository.history = [_message('m2'), _message('m1')];
      final refreshing = notifier.refreshLatest(
        socketGrace: const Duration(milliseconds: 50),
      );
      await _settle();
      // The row is already on screen while the verdict is pending.
      expect(notifier.state.messages.map((m) => m.id).toList(), ['m2', 'm1']);
      notifier.appendFromSocket(_message('m2'));

      expect(await refreshing, ThreadRefreshResult.nothingMissed);
      expect(notifier.state.messages.map((m) => m.id).toList(), ['m2', 'm1']);
    });

    test('a socket that stays silent through the grace is a miss', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      repository.history = [_message('m2'), _message('m1')];
      expect(
        await notifier.refreshLatest(
          socketGrace: const Duration(milliseconds: 50),
        ),
        ThreadRefreshResult.missedMessages,
      );
    });

    test('only the socket vouches, not an own send or a refresh', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      repository.history = [_message('m2'), _message('m1')];
      final refreshing = notifier.refreshLatest(
        socketGrace: const Duration(milliseconds: 50),
      );
      await _settle();
      // The POST echo path: the same row, but it says nothing about the
      // socket, so it must not clear the miss.
      notifier.appendLive(_message('m2'));

      expect(await refreshing, ThreadRefreshResult.missedMessages);
    });

    test('a frame for one of several missed rows is not enough', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      repository.history = [_message('m3'), _message('m2'), _message('m1')];
      final refreshing = notifier.refreshLatest(
        socketGrace: const Duration(milliseconds: 50),
      );
      await _settle();
      notifier.appendFromSocket(_message('m3'));

      expect(await refreshing, ThreadRefreshResult.missedMessages);
    });

    test('the grace bookkeeping is released once judged', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      repository.history = [_message('m2'), _message('m1')];
      await notifier.refreshLatest(
        socketGrace: const Duration(milliseconds: 20),
      );
      // A frame after the window has closed neither throws nor duplicates.
      notifier.appendFromSocket(_message('m2'));
      expect(notifier.state.messages.map((m) => m.id).toList(), ['m2', 'm1']);

      // A second refresh with nothing new judges promptly and cleanly.
      expect(
        await notifier.refreshLatest(
          socketGrace: const Duration(milliseconds: 20),
        ),
        ThreadRefreshResult.nothingMissed,
      );
    });

    test('a restart from a full unseen page counts as missed', () async {
      repository = _FakeGroupChatRepository(history: [_message('old')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      repository.history = [
        for (var i = 0; i < 40; i++) _message('new$i'),
        _message('old'),
      ];
      expect(
        await notifier.refreshLatest(),
        ThreadRefreshResult.missedMessages,
      );
    });

    test('a failed refreshLatest says so', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      repository.listFailure = const NetworkFailure('offline');
      expect(await notifier.refreshLatest(), ThreadRefreshResult.failed);
    });
  });

  group('reactions', () {
    ChatMessageDTO reacted(String id, List<ChatMessageReactionDTO> reactions) {
      return _message(id).copyWith(reactions: reactions);
    }

    test('replaceReactions rewrites one message and leaves the rest', () async {
      repository = _FakeGroupChatRepository(
        history: [_message('m2'), _message('m1')],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      notifier.replaceReactions('m1', const [
        ChatMessageReactionDTO(emoji: thumbsUp, count: 1),
      ]);

      final byId = {for (final m in notifier.state.messages) m.id: m};
      expect(byId['m1']!.reactions.single.emoji, thumbsUp);
      expect(byId['m2']!.reactions, isEmpty);
    });

    test('replaceReactions ignores a message outside the window', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      notifier.replaceReactions('gone', const [
        ChatMessageReactionDTO(emoji: thumbsUp, count: 1),
      ]);

      expect(notifier.state.messages.single.reactions, isEmpty);
    });

    test('replaceReactions re-derives reactedByMe for this viewer', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      // A broadcast flag that is about somebody else.
      notifier.replaceReactions('m1', const [
        ChatMessageReactionDTO(
          emoji: thumbsUp,
          count: 1,
          reactedByMe: true,
          users: [
            ChatMessageReactionUserDTO(userId: 'u2', email: 'jack@e.com'),
          ],
        ),
      ], currentUserEmail: 'rena@example.com');

      expect(
        notifier.state.messages.single.reactions.single.reactedByMe,
        isFalse,
      );
    });

    test('toggleReaction posts and adopts the returned summary', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      repository.reactionResponses = const [
        [ChatMessageReactionDTO(emoji: thumbsUp, count: 4)],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final failure = await notifier.toggleReaction(
        'm1',
        thumbsUp,
        roomIdForCall: 'room-1',
      );

      expect(failure, isNull);
      expect(repository.reactionCalls, ['POST $thumbsUp']);
      expect(notifier.state.messages.single.reactions.single.count, 4);
    });

    test('toggleReaction on my own emoji deletes it', () async {
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(
              emoji: thumbsUp,
              count: 1,
              reactedByMe: true,
            ),
          ]),
        ],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      await notifier.toggleReaction('m1', thumbsUp, roomIdForCall: 'room-1');

      expect(repository.reactionCalls, ['DELETE $thumbsUp']);
    });

    test('swapping posts the new emoji before deleting the old', () async {
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(
              emoji: thumbsUp,
              count: 1,
              reactedByMe: true,
            ),
          ]),
        ],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      await notifier.toggleReaction('m1', heart, roomIdForCall: 'room-1');

      // Post first, so the message never flickers through zero reactions.
      expect(repository.reactionCalls, ['POST $heart', 'DELETE $thumbsUp']);
    });

    test('a swap never shows both emoji, even mid-flight', () async {
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(
              emoji: thumbsUp,
              count: 1,
              reactedByMe: true,
            ),
          ]),
        ],
      );
      // The POST response legitimately carries both: the DELETE has not run.
      repository.reactionResponses = const [
        [
          ChatMessageReactionDTO(emoji: thumbsUp, count: 1),
          ChatMessageReactionDTO(emoji: heart, count: 1),
        ],
        [ChatMessageReactionDTO(emoji: heart, count: 1)],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      // A broadcast arriving mid-swap carries the same two.
      final seen = <int>[];
      container.listen(groupChatThreadProvider('room-1'), (_, next) {
        final message = next.messages.firstWhere((m) => m.id == 'm1');
        seen.add(message.reactions.length);
      });

      await notifier.toggleReaction('m1', heart, roomIdForCall: 'room-1');

      expect(notifier.state.messages.single.reactions.single.emoji, heart);
      // Never two entries at any point the UI could have rendered.
      expect(seen, everyElement(lessThanOrEqualTo(1)));
    });

    test('a broadcast mid-swap is ignored', () async {
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(
              emoji: thumbsUp,
              count: 1,
              reactedByMe: true,
            ),
          ]),
        ],
      );
      repository.reactionResponses = const [
        [ChatMessageReactionDTO(emoji: heart, count: 1)],
        [ChatMessageReactionDTO(emoji: heart, count: 1)],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final pending = notifier.toggleReaction(
        'm1',
        heart,
        roomIdForCall: 'room-1',
      );
      // reactions_updated for the POST, before the DELETE lands.
      notifier.replaceReactions('m1', const [
        ChatMessageReactionDTO(emoji: thumbsUp, count: 1),
        ChatMessageReactionDTO(emoji: heart, count: 1),
      ]);
      expect(notifier.state.messages.single.reactions, hasLength(1));

      await pending;
      expect(notifier.state.messages.single.reactions.single.emoji, heart);
    });

    test(
      'a loadMore landing mid-refresh is not counted as an arrival',
      () async {
        // `loadMore` gates on isLoadingMore/isLoading and a refresh sets
        // neither, so the two overlap freely.
        repository = _FakeGroupChatRepository(
          history: [for (var i = 0; i < 60; i++) _message('m$i')],
        );
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();
        expect(notifier.state.messages, hasLength(30));
        expect(notifier.state.total, 60);

        final hold = Completer<void>();
        repository.holdNextList = hold;
        final refreshing = notifier.refreshLatest();
        await Future<void>.delayed(Duration.zero);

        // The older page lands while the refresh is still awaiting its own.
        await notifier.loadMore();
        expect(notifier.state.messages, hasLength(60));

        hold.complete();
        await refreshing;

        // That page is older history the server already counted, not a socket
        // arrival — adding it would leave hasMore true past the real end and
        // send the next loadMore at an empty offset.
        expect(notifier.state.total, 60);
        expect(notifier.state.hasMore, isFalse);
      },
    );

    test(
      'a loadMore landing mid-restart is neither prepended nor counted',
      () async {
        // 60 on the server: the first page holds m0..m29, loadMore can fetch
        // m30..m59.
        repository = _FakeGroupChatRepository(
          history: [for (var i = 0; i < 60; i++) _message('m$i')],
        );
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();

        final hold = Completer<void>();
        repository.holdNextList = hold;
        final refreshing = notifier.refreshLatest();
        await Future<void>.delayed(Duration.zero);

        // Older history lands while the refresh is still awaiting its page.
        await notifier.loadMore();
        expect(notifier.state.messages, hasLength(60));

        // Meanwhile 30 new messages arrived on the server, so the newest page
        // comes back full and shares nothing with what is held: a restart.
        repository.history = [
          for (var i = 0; i < 30; i++) _message('n$i'),
          ...repository.history,
        ];
        hold.complete();
        await refreshing;

        final ids = notifier.state.messages.map((m) => m.id).toList();
        // Only the newest page. The older rows loadMore appended are history
        // the restart walks back through, not arrivals to sit on top of it.
        expect(ids, [for (var i = 0; i < 30; i++) 'n$i']);
        // 90 on the server, and nothing the socket added on top of that.
        expect(notifier.state.total, 90);
        expect(notifier.state.hasMore, isTrue);
      },
    );

    test(
      'a socket arrival mid-restart still sits above the new page',
      () async {
        repository = _FakeGroupChatRepository(
          history: [for (var i = 0; i < 30; i++) _message('m$i')],
        );
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();

        final hold = Completer<void>();
        repository.holdNextList = hold;
        final refreshing = notifier.refreshLatest();
        await Future<void>.delayed(Duration.zero);

        notifier.appendLive(_message('live'));
        repository.history = [
          for (var i = 0; i < 30; i++) _message('n$i'),
          ...repository.history,
        ];
        hold.complete();
        await refreshing;

        final ids = notifier.state.messages.map((m) => m.id).toList();
        expect(ids.first, 'live');
        expect(ids.sublist(1), [for (var i = 0; i < 30; i++) 'n$i']);
        // 60 on the server plus the arrival its count predates.
        expect(notifier.state.total, 61);
      },
    );

    test(
      'a no-op echo arriving after a member update does not shadow it',
      () async {
        repository = _FakeGroupChatRepository(
          history: [
            reacted('m1', const [
              ChatMessageReactionDTO(
                emoji: thumbsUp,
                count: 1,
                reactedByMe: true,
                userIds: ['me'],
              ),
            ]),
          ],
        );
        repository.reactionResponses = const [
          [
            ChatMessageReactionDTO(emoji: thumbsUp, count: 1, userIds: ['me']),
            ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
          ],
          [
            ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
          ],
        ];
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();

        final pending = notifier.toggleReaction(
          'm1',
          heart,
          roomIdForCall: 'room-1',
          currentUserId: 'me',
        );
        // Another member's fuller update arrives first...
        notifier.replaceReactions('m1', const [
          ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
          ChatMessageReactionDTO(emoji: joy, count: 1, userIds: ['other']),
        ], currentUserId: 'me');
        // ...then our own DELETE echo, computed at the same instant as the
        // response the swap already applied, lands after it. It agrees with the
        // settled set too; taking it as "latest" would drop the member's joy.
        notifier.replaceReactions('m1', const [
          ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
        ], currentUserId: 'me');

        await pending;
        final emoji =
            notifier.state.messages.single.reactions
                .map((reaction) => reaction.emoji)
                .toList();
        expect(emoji, containsAll(<String>[heart, joy]));
      },
    );

    test(
      'a replayable broadcast survives a later echo during the swap',
      () async {
        repository = _FakeGroupChatRepository(
          history: [
            reacted('m1', const [
              ChatMessageReactionDTO(
                emoji: thumbsUp,
                count: 1,
                reactedByMe: true,
                userIds: ['me'],
              ),
            ]),
          ],
        );
        repository.reactionResponses = const [
          [
            ChatMessageReactionDTO(emoji: thumbsUp, count: 1, userIds: ['me']),
            ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
          ],
          [
            ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
          ],
        ];
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();

        final pending = notifier.toggleReaction(
          'm1',
          heart,
          roomIdForCall: 'room-1',
          currentUserId: 'me',
        );
        // Another member's summary, computed after our swap settled on the
        // server, arrives first...
        notifier.replaceReactions('m1', const [
          ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
          ChatMessageReactionDTO(emoji: joy, count: 1, userIds: ['other']),
        ], currentUserId: 'me');
        // ...and our own intermediate echo lands after it. Nothing on the wire
        // orders them, and a single deferred slot let the echo overwrite the
        // one summary worth keeping.
        notifier.replaceReactions('m1', const [
          ChatMessageReactionDTO(emoji: thumbsUp, count: 1, userIds: ['me']),
          ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
        ], currentUserId: 'me');

        await pending;
        final emoji =
            notifier.state.messages.single.reactions
                .map((reaction) => reaction.emoji)
                .toList();
        expect(emoji, containsAll(<String>[heart, joy]));
      },
    );

    test(
      'an out-of-order socket arrival mid-refresh is still counted',
      () async {
        // 31 on the server, so the first page of 30 leaves m31 unread.
        repository = _FakeGroupChatRepository(
          history: [for (var i = 1; i <= 31; i++) _message('m$i')],
        );
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();
        expect(notifier.state.hasMore, isTrue);

        final hold = Completer<void>();
        repository.holdNextList = hold;
        final refreshing = notifier.refreshLatest();
        await Future<void>.delayed(Duration.zero);

        // The server gains m0 before its page is computed, so the page carries
        // it. The socket then delivers a brand-new message first and m0 second,
        // leaving the one the page *does* include on top of the one it does
        // not. Cutting at the first shared row would hide `live`.
        repository.history = [_message('m0'), ...repository.history];
        notifier.appendLive(_message('live'));
        notifier.appendLive(_message('m0'));
        hold.complete();
        await refreshing;

        // 32 on the server, plus the arrival its count predates. Cutting at the
        // first shared row gives 32, and with 32 rows held that reads as "all
        // loaded" while m31 is still on the server unread.
        expect(notifier.state.total, 33);
        expect(notifier.state.hasMore, isTrue);
      },
    );

    test(
      'refreshLatest keeps counting messages that arrived mid-request',
      () async {
        repository = _FakeGroupChatRepository(history: [_message('m1')]);
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();
        expect(notifier.state.total, 1);

        // The socket delivers while the refresh is in flight, so the count that
        // comes back with the page was taken before it existed.
        final refreshing = notifier.refreshLatest();
        notifier.appendLive(_message('m2'));
        await refreshing;

        expect(notifier.state.messages, hasLength(2));
        // Overwriting with the page's figure would say 1 for two held rows, and
        // hasMore would latch false with history still unread.
        expect(notifier.state.total, 2);
        expect(notifier.state.messages.length <= notifier.state.total, isTrue);
      },
    );

    test('a summary held mid-fetch survives the row being kept', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final refreshing = notifier.refreshLatest();
      // Arrives for a row outside the loaded window, so it is held for the
      // page to carry...
      notifier.replaceReactions('m2', const [
        ChatMessageReactionDTO(emoji: thumbsUp, count: 1),
      ]);
      // ...and then that row lands over the socket before the page does.
      notifier.appendLive(_message('m2'));
      await refreshing;

      final held = notifier.state.messages.firstWhere(
        (message) => message.id == 'm2',
      );
      expect(held.reactions.single.emoji, thumbsUp);
    });

    test('a broadcast during a swap is applied once the swap settles', () async {
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(
              emoji: thumbsUp,
              count: 1,
              reactedByMe: true,
              userIds: ['me'],
            ),
          ]),
        ],
      );
      repository.reactionResponses = const [
        // POST of the new emoji: the server briefly holds both.
        [
          ChatMessageReactionDTO(emoji: thumbsUp, count: 1, userIds: ['me']),
          ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
        ],
        // DELETE of the old one, computed before the other member commits.
        [
          ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
        ],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final pending = notifier.toggleReaction(
        'm1',
        heart,
        roomIdForCall: 'room-1',
        currentUserId: 'me',
      );
      // Another member reacts mid-swap. This summary is newer than either of
      // our own responses, so it must survive the swap rather than be dropped.
      notifier.replaceReactions('m1', const [
        ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
        ChatMessageReactionDTO(emoji: joy, count: 1, userIds: ['other']),
      ], currentUserId: 'me');

      await pending;
      final emoji =
          notifier.state.messages.single.reactions
              .map((reaction) => reaction.emoji)
              .toList();
      expect(emoji, containsAll(<String>[heart, joy]));
    });

    test('our own mid-swap echo is still discarded', () async {
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(
              emoji: thumbsUp,
              count: 1,
              reactedByMe: true,
              userIds: ['me'],
            ),
          ]),
        ],
      );
      repository.reactionResponses = const [
        [
          ChatMessageReactionDTO(emoji: thumbsUp, count: 1, userIds: ['me']),
          ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
        ],
        [
          ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
        ],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final pending = notifier.toggleReaction(
        'm1',
        heart,
        roomIdForCall: 'room-1',
        currentUserId: 'me',
      );
      // The broadcast the server fans back to us for our own POST: it still
      // carries the emoji being replaced, so it is older than where the swap
      // ends up and must not be replayed over it.
      notifier.replaceReactions('m1', const [
        ChatMessageReactionDTO(emoji: thumbsUp, count: 1, userIds: ['me']),
        ChatMessageReactionDTO(emoji: heart, count: 1, userIds: ['me']),
      ], currentUserId: 'me');

      await pending;
      expect(notifier.state.messages.single.reactions.single.emoji, heart);
    });

    test('overlapping toggles do not undo the newer choice', () async {
      repository = _FakeGroupChatRepository(history: [reacted('m1', const [])]);
      // The first call fails; the second succeeds.
      repository.failFirstReaction = true;
      repository.reactionResponses = const [
        [],
        [ChatMessageReactionDTO(emoji: heart, count: 1, reactedByMe: true)],
        // The swap's trailing DELETE of the phantom thumbs-up.
        [ChatMessageReactionDTO(emoji: heart, count: 1, reactedByMe: true)],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final first = notifier.toggleReaction(
        'm1',
        thumbsUp,
        roomIdForCall: 'room-1',
      );
      final second = notifier.toggleReaction(
        'm1',
        heart,
        roomIdForCall: 'room-1',
      );
      await Future.wait([first, second]);

      // The superseded failure must not roll the newer heart away.
      final reactions = notifier.state.messages.single.reactions;
      expect(reactions.map((r) => r.emoji), [heart]);
    });

    test(
      'a queued swap deletes what the server holds, not the phantom',
      () async {
        const prayer = '🙏';
        repository = _FakeGroupChatRepository(
          history: [
            reacted('m1', const [
              ChatMessageReactionDTO(
                emoji: prayer,
                count: 1,
                reactedByMe: true,
                users: [
                  ChatMessageReactionUserDTO(
                    userId: 'u1',
                    email: 'rena@example.com',
                  ),
                ],
              ),
            ]),
          ],
        );
        // The first POST fails, so the prayer is never dropped and stays on the
        // server while the local state has already moved on.
        repository.failFirstReaction = true;
        repository.reactionResponses = const [
          [],
          // POST heart: the server still holds the prayer too.
          [
            ChatMessageReactionDTO(
              emoji: prayer,
              count: 1,
              users: [
                ChatMessageReactionUserDTO(
                  userId: 'u1',
                  email: 'rena@example.com',
                ),
              ],
            ),
            ChatMessageReactionDTO(emoji: heart, count: 1),
          ],
          [ChatMessageReactionDTO(emoji: heart, count: 1)],
        ];
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();

        final first = notifier.toggleReaction(
          'm1',
          thumbsUp,
          roomIdForCall: 'room-1',
          currentUserEmail: 'rena@example.com',
        );
        final second = notifier.toggleReaction(
          'm1',
          heart,
          roomIdForCall: 'room-1',
          currentUserEmail: 'rena@example.com',
        );
        await Future.wait([first, second]);

        // The prayer is what the server actually had — not the thumbs-up the
        // optimistic state showed.
        expect(repository.reactionCalls.last, 'DELETE $prayer');
        expect(notifier.state.messages.single.reactions.map((r) => r.emoji), [
          heart,
        ]);
      },
    );

    test('a failed queued POST still deletes the real reaction when the '
        'summary cannot identify the viewer', () async {
      const prayer = '🙏';
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(emoji: prayer, count: 1, reactedByMe: true),
          ]),
        ],
      );
      repository.failFirstReaction = true;
      // No users and no user_ids anywhere: the summary cannot say who is who,
      // which is the case that used to fall back to optimistic state.
      repository.reactionResponses = const [
        [],
        [
          ChatMessageReactionDTO(emoji: prayer, count: 1),
          ChatMessageReactionDTO(emoji: heart, count: 1),
        ],
        [ChatMessageReactionDTO(emoji: heart, count: 1)],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      // Two swaps in a burst; the first POST fails, so the prayer is never
      // dropped and the optimistic state names a thumbs-up the server
      // never received.
      final first = notifier.toggleReaction(
        'm1',
        thumbsUp,
        roomIdForCall: 'room-1',
        currentUserEmail: 'rena@example.com',
      );
      final second = notifier.toggleReaction(
        'm1',
        heart,
        roomIdForCall: 'room-1',
        currentUserEmail: 'rena@example.com',
      );
      await Future.wait([first, second]);

      // The prayer is what the server actually held, so that is what goes.
      expect(repository.reactionCalls, [
        'POST $thumbsUp',
        'POST $heart',
        'DELETE $prayer',
      ]);
      expect(notifier.state.messages.single.reactions.map((r) => r.emoji), [
        heart,
      ]);
    });

    test('a later burst clears a duplicate left by a failed cleanup', () async {
      const prayer = '🙏';
      // The state a failed cleanup leaves behind: two reactions, both mine.
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(emoji: prayer, count: 1, reactedByMe: true),
            ChatMessageReactionDTO(
              emoji: thumbsUp,
              count: 1,
              reactedByMe: true,
            ),
          ]),
        ],
      );
      repository.reactionResponses = const [
        // POST heart: the server still holds both of the earlier ones.
        [
          ChatMessageReactionDTO(emoji: prayer, count: 1),
          ChatMessageReactionDTO(emoji: thumbsUp, count: 1),
          ChatMessageReactionDTO(emoji: heart, count: 1),
        ],
        [ChatMessageReactionDTO(emoji: heart, count: 1)],
        [ChatMessageReactionDTO(emoji: heart, count: 1)],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      await notifier.toggleReaction('m1', heart, roomIdForCall: 'room-1');

      // Both leftovers are dropped, not just whichever came first.
      expect(repository.reactionCalls, [
        'POST $heart',
        'DELETE $prayer',
        'DELETE $thumbsUp',
      ]);
      expect(notifier.state.messages.single.reactions.map((r) => r.emoji), [
        heart,
      ]);
    });

    test(
      'a duplicate survives a summary that cannot identify the viewer',
      () async {
        const prayer = '🙏';
        repository = _FakeGroupChatRepository(
          history: [
            reacted('m1', const [
              ChatMessageReactionDTO(
                emoji: prayer,
                count: 1,
                reactedByMe: true,
              ),
            ]),
          ],
        );
        // No users and no user_ids anywhere, so nothing in these payloads can
        // say which reactions are the viewer's.
        repository.reactionResponses = const [
          // POST heart succeeds; the prayer is still there.
          [
            ChatMessageReactionDTO(emoji: prayer, count: 1),
            ChatMessageReactionDTO(emoji: heart, count: 1),
          ],
          [],
          // Second burst.
          [
            ChatMessageReactionDTO(emoji: prayer, count: 1),
            ChatMessageReactionDTO(emoji: joy, count: 1),
          ],
          [],
          [],
        ];
        // The cleanup DELETE of the first burst fails.
        repository.failReactionCalls = const {2};
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();

        await notifier.toggleReaction('m1', heart, roomIdForCall: 'room-1');
        expect(repository.reactionCalls, ['POST $heart', 'DELETE $prayer']);

        // The display cannot tell these are the viewer's, so only the retained
        // record can drive the retry.
        await notifier.toggleReaction('m1', joy, roomIdForCall: 'room-1');

        expect(repository.reactionCalls.sublist(2), [
          'POST $joy',
          'DELETE $prayer',
          'DELETE $heart',
        ]);
      },
    );

    test('refreshLatest updates reactions on messages already held', () async {
      repository = _FakeGroupChatRepository(history: [reacted('m1', const [])]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.messages.single.reactions, isEmpty);

      // A reaction landed while the socket was down.
      repository.history = [
        reacted('m1', const [
          ChatMessageReactionDTO(emoji: thumbsUp, count: 2),
        ]),
      ];
      await notifier.refreshLatest();

      expect(notifier.state.messages.single.reactions.single.count, 2);
    });

    test('refreshLatest derives reactedByMe for this viewer', () async {
      repository = _FakeGroupChatRepository(history: [reacted('m1', const [])]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      repository.history = [
        reacted('m1', const [
          ChatMessageReactionDTO(
            emoji: thumbsUp,
            count: 1,
            users: [
              ChatMessageReactionUserDTO(
                userId: 'u1',
                email: 'rena@example.com',
              ),
            ],
          ),
        ]),
      ];
      await notifier.refreshLatest(currentUserEmail: 'rena@example.com');

      expect(
        notifier.state.messages.single.reactions.single.reactedByMe,
        isTrue,
      );
    });

    test(
      'a failed cleanup reports the error instead of claiming success',
      () async {
        const prayer = '🙏';
        repository = _FakeGroupChatRepository(
          history: [
            reacted('m1', const [
              ChatMessageReactionDTO(
                emoji: prayer,
                count: 1,
                reactedByMe: true,
              ),
            ]),
          ],
        );
        // The POST lands; the cleanup DELETE does not.
        repository.failReactionCalls = const {2};
        repository.reactionResponses = const [
          [
            ChatMessageReactionDTO(emoji: prayer, count: 1),
            ChatMessageReactionDTO(emoji: heart, count: 1),
          ],
        ];
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();

        final failure = await notifier.toggleReaction(
          'm1',
          heart,
          roomIdForCall: 'room-1',
        );

        expect(failure, isA<NetworkFailure>());
        // Both are still on the server, so both are shown rather than hidden.
        expect(notifier.state.messages.single.reactions.map((r) => r.emoji), [
          prayer,
          heart,
        ]);
      },
    );

    test('a refetch in flight across a swap does not overwrite it', () async {
      repository = _FakeGroupChatRepository(history: [reacted('m1', const [])]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      // The refetch is sent while the message has no reactions...
      final refresh = notifier.refreshLatest();
      // ...and a reaction is confirmed before that page comes back.
      notifier.replaceReactions('m1', const [
        ChatMessageReactionDTO(emoji: heart, count: 1),
      ]);
      await refresh;

      // The stale page must not undo it.
      expect(notifier.state.messages.single.reactions.map((r) => r.emoji), [
        heart,
      ]);
    });

    test('a failed call rolls back to the previous reactions', () async {
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(emoji: thumbsUp, count: 2),
          ]),
        ],
      );
      repository.reactionFailure = const NetworkFailure('offline');
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final failure = await notifier.toggleReaction(
        'm1',
        thumbsUp,
        roomIdForCall: 'room-1',
      );

      expect(failure, isA<NetworkFailure>());
      final reactions = notifier.state.messages.single.reactions;
      expect(reactions.single.count, 2);
      expect(reactions.single.reactedByMe, isFalse);
    });
  });

  group('refreshLatest gaps', () {
    test(
      'restarts from the newest page when the gap cannot be stitched',
      () async {
        repository = _FakeGroupChatRepository(
          history: List.generate(40, (i) => _message('old$i')),
        );
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();

        expect(notifier.state.messages, hasLength(30));

        // 40 brand-new messages arrived while the socket was down: a full page
        // with nothing in common with what is held.
        repository.history = List.generate(40, (i) => _message('new$i'));
        await notifier.refreshLatest();

        final ids = notifier.state.messages.map((m) => m.id).toList();
        expect(ids, hasLength(30));
        // Nothing stale is stitched onto a non-contiguous page.
        expect(ids.every((id) => id.startsWith('new')), isTrue);
        // skip matches what is held, so loadMore walks back through the gap.
        expect(notifier.state.skip, 30);
        expect(notifier.state.hasMore, isTrue);
      },
    );

    test('stitches normally when the page overlaps what is held', () async {
      repository = _FakeGroupChatRepository(
        history: [_message('m2'), _message('m1')],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      repository.history = [_message('m3'), _message('m2'), _message('m1')];
      await notifier.refreshLatest();

      expect(notifier.state.messages.map((m) => m.id), ['m3', 'm2', 'm1']);
    });

    test(
      'one live insert during the flight cannot suppress the restart',
      () async {
        repository = _FakeGroupChatRepository(
          history: List.generate(40, (i) => _message('old$i')),
        );
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();

        // More than a page arrived while the socket was down.
        repository.history = List.generate(40, (i) => _message('new$i'));

        // The socket comes back and delivers one of those messages while the
        // refresh is still in flight, so it is held by the time the page
        // lands — and it is in that page.
        final refresh = notifier.refreshLatest();
        notifier.appendLive(_message('new0'));
        await refresh;

        // That single shared id must not stitch the page onto history it is
        // not contiguous with.
        final ids = notifier.state.messages.map((m) => m.id).toList();
        expect(ids.any((id) => id.startsWith('old')), isFalse);
        expect(ids, hasLength(30));
        expect(notifier.state.skip, 30);
      },
    );

    test('the restart keeps messages that arrived during the flight', () async {
      repository = _FakeGroupChatRepository(
        history: List.generate(40, (i) => _message('old$i')),
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      repository.history = List.generate(40, (i) => _message('new$i'));

      // Sent after the server built the page, so it is in neither the page
      // nor the history the request was made against.
      final refresh = notifier.refreshLatest();
      notifier.appendLive(_message('live1'));
      await refresh;

      final ids = notifier.state.messages.map((m) => m.id).toList();
      // Newer than the page, so it stays at the head rather than vanishing.
      expect(ids.first, 'live1');
      expect(ids, hasLength(31));
      expect(notifier.state.skip, 31);
      // The server counted 40 before it existed.
      expect(notifier.state.total, 41);
    });

    test('a reaction that arrives before its message is not lost', () async {
      repository = _FakeGroupChatRepository(history: [_message('m0')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      // m1 is new: it is in the page being fetched, but not yet held.
      repository.history = [
        _message('m1').copyWith(
          reactions: const [ChatMessageReactionDTO(emoji: heart, count: 1)],
        ),
        _message('m0'),
      ];

      final refresh = notifier.refreshLatest();
      // Two more react while the page is in flight, so the page's own count
      // is already stale by the time it arrives.
      notifier.replaceReactions('m1', const [
        ChatMessageReactionDTO(emoji: heart, count: 3),
      ]);
      await refresh;

      final inserted = notifier.state.messages.firstWhere((m) => m.id == 'm1');
      expect(inserted.reactions.single.count, 3);
    });
  });

  group('deleteMessage', () {
    test('tombstones the message once the server confirms', () async {
      repository = _FakeGroupChatRepository(
        history: [_message('m2'), _message('m1')],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final failure = await notifier.deleteMessage('m1');

      expect(failure, isNull);
      expect(repository.deleteCalls, ['m1']);
      // Stamped locally: the 204 carries no body, so there is nothing to adopt
      // until the next fetch brings the server's own value.
      expect(_byId(notifier, 'm1').deletedAt, isNotNull);
      // The row stays: it is the tombstone. Removing it would move the
      // pagination cursor for a message the server already dropped.
      expect(notifier.state.messages.map((m) => m.id), ['m2', 'm1']);
      expect(notifier.state.skip, 2);
    });

    test('a failed delete leaves the message standing', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      repository.deleteFailure = const NetworkFailure('offline');
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final failure = await notifier.deleteMessage('m1');

      // Reported rather than swallowed, and nothing is tombstoned — the
      // message is still there for everyone.
      expect(failure, isA<NetworkFailure>());
      expect(_byId(notifier, 'm1').deletedAt, isNull);
      expect(notifier.state.messages, hasLength(1));
    });

    test('deleting the same message twice sends one request', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      await notifier.deleteMessage('m1');
      await notifier.deleteMessage('m1');

      expect(repository.deleteCalls, ['m1']);
    });

    test('a refresh does not resurrect a tombstoned message', () async {
      repository = _FakeGroupChatRepository(
        history: [_message('m2'), _message('m1')],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      await notifier.deleteMessage('m1');
      // The server no longer returns it.
      repository.history = [_message('m2')];
      await notifier.refreshLatest();

      // Still held, still tombstoned: the refetch that dropped it does not
      // silently turn the row back into a message.
      expect(notifier.state.messages.map((m) => m.id), ['m2', 'm1']);
      expect(_byId(notifier, 'm1').deletedAt, isNotNull);
    });

    test('a refetch adopts the server deleted_at', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      expect(_byId(notifier, 'm1').deletedAt, isNull);

      // Deleted by this member on another device: nothing local marked it, the
      // page simply comes back carrying the timestamp.
      repository.history = [
        _message('m1').copyWith(deletedAt: '2026-09-03T10:00:00Z'),
      ];
      await notifier.refreshLatest();

      expect(_byId(notifier, 'm1').deletedAt, '2026-09-03T10:00:00Z');
    });
  });

  group('applyDeletion', () {
    test('a broadcast tombstones a loaded message', () async {
      repository = _FakeGroupChatRepository(
        history: [_message('m2'), _message('m1')],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      notifier.applyDeletion('m1', deletedAt: '2026-09-03T10:00:00Z');

      expect(_byId(notifier, 'm1').deletedAt, '2026-09-03T10:00:00Z');
      // Nobody else is touched.
      expect(_byId(notifier, 'm2').deletedAt, isNull);
    });

    test('the first timestamp stands', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      notifier.applyDeletion('m1', deletedAt: 'first');
      // Our own delete stamps the row, then the broadcast for it arrives.
      notifier.applyDeletion('m1', deletedAt: 'second');

      expect(_byId(notifier, 'm1').deletedAt, 'first');
    });

    test('a deletion arriving before its message is not lost', () async {
      repository = _FakeGroupChatRepository(history: [_message('m0')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      // m1 is in the page being fetched, but not yet held. That page was built
      // before the deletion, so it carries the message as live.
      repository.history = [_message('m1'), _message('m0')];

      final refresh = notifier.refreshLatest();
      notifier.applyDeletion('m1', deletedAt: '2026-09-03T10:00:00Z');
      await refresh;

      expect(_byId(notifier, 'm1').deletedAt, '2026-09-03T10:00:00Z');
    });

    test('a deletion for a message no page brings back is dropped', () async {
      repository = _FakeGroupChatRepository(history: [_message('m0')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      // No fetch running: a later page would carry deleted_at itself, so
      // holding this would only leak.
      notifier.applyDeletion('gone', deletedAt: '2026-09-03T10:00:00Z');

      repository.history = [_message('gone'), _message('m0')];
      await notifier.refreshLatest();

      expect(_byId(notifier, 'gone').deletedAt, isNull);
    });
  });

  group('deletion vs a page already in flight', () {
    test(
      'own delete survives a stale refresh that still carries the row',
      () async {
        repository = _FakeGroupChatRepository(
          history: [_message('m2'), _message('m1')],
        );
        container = buildContainer();
        final notifier = _keepAlive(container);
        await _settle();

        // A refresh went out before the delete, so its page has m1 as live.
        final hold = Completer<void>();
        repository.holdNextList = hold;
        final refresh = notifier.refreshLatest();

        await notifier.deleteMessage('m1');
        expect(_byId(notifier, 'm1').deletedAt, isNotNull);

        hold.complete();
        await refresh;

        // The page predates the deletion; it must not turn the tombstone
        // back into the message.
        expect(_byId(notifier, 'm1').deletedAt, isNotNull);
      },
    );

    test('a broadcast tombstone survives a stale refresh', () async {
      repository = _FakeGroupChatRepository(
        history: [_message('m2'), _message('m1')],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final hold = Completer<void>();
      repository.holdNextList = hold;
      final refresh = notifier.refreshLatest();

      notifier.applyDeletion('m1', deletedAt: '2026-09-03T10:00:00Z');

      hold.complete();
      await refresh;

      expect(_byId(notifier, 'm1').deletedAt, '2026-09-03T10:00:00Z');
    });
  });

  group('ChatLinkPreviewCache', () {
    test('distinguishes a cached failure from an absent entry', () {
      final cache = ChatLinkPreviewCache();

      expect(cache.contains('https://a.org'), isFalse);
      cache.write('https://a.org', null);
      expect(cache.contains('https://a.org'), isTrue);
      expect(cache.read('https://a.org'), isNull);
    });

    test('evicts the least recently used entry past capacity', () {
      final cache = ChatLinkPreviewCache(capacity: 2);

      cache.write('a', const ChatLinkPreview(url: 'a', title: 'A'));
      cache.write('b', const ChatLinkPreview(url: 'b', title: 'B'));
      cache.read('a'); // 'a' becomes most recently used
      cache.write('c', const ChatLinkPreview(url: 'c', title: 'C'));

      expect(cache.contains('b'), isFalse);
      expect(cache.contains('a'), isTrue);
      expect(cache.contains('c'), isTrue);
    });
  });
}
