import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/chat_room_live_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/fake_realtime_signals.dart';

const _path = 'chat_rooms/room-1';

ChatMessageDTO _message(String id) => ChatMessageDTO(
  id: id,
  roomId: 'room-1',
  senderId: 'b',
  senderEmail: 'b@example.com',
  body: id,
  createdAt: '2026-10-29T10:00:00Z',
);

class _FakeRepository implements GroupChatRepository {
  List<ChatMessageDTO> messages = [_message('m1')];
  int pageCount = 0;
  Failure? pageFailure;

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Me extends StateNotifier<UserState> implements UserNotifier {
  _Me() : super(const UserState(user: User(id: 'me', email: 'me@x.org')));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle() => pumpEventQueue();

void main() {
  late _FakeRepository repository;
  late FakeRealtimeSignals signals;
  late ProviderContainer container;
  late StateNotifierProvider<ChatRoomLiveNotifier, ChatRoomLiveState> live;

  /// A controller with a short permission retry; [attempts] overrides it and
  /// [denied] refuses that many listens first.
  void build({
    int attempts = 5,
    bool withSignals = true,
    int denied = 0,
    List<ChatMessageDTO>? messages,
  }) {
    repository = _FakeRepository();
    if (messages != null) repository.messages = messages;
    signals = FakeRealtimeSignals();
    if (denied > 0) signals.permissionDeniedUntil(_path, denied);
    live = StateNotifierProvider<ChatRoomLiveNotifier, ChatRoomLiveState>(
      (ref) => ChatRoomLiveNotifier(
        ref: ref,
        roomId: 'room-1',
        signals: withSignals ? signals : null,
        retryAttempts: attempts,
        retryDelay: const Duration(milliseconds: 10),
      ),
    );
    container = ProviderContainer(
      overrides: [
        groupChatRepositoryProvider.overrideWithValue(repository),
        userProvider.overrideWith((ref) => _Me()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(groupChatThreadProvider('room-1'), (_, _) {});
    container.listen(live, (_, _) {});
  }

  ChatRoomLiveState state() => container.read(live);
  List<String> ids() =>
      container
          .read(groupChatThreadProvider('room-1'))
          .messages
          .map((m) => m.id)
          .toList();

  test(
    'the first snapshot marks the room live and catches the thread up',
    () async {
      build();
      await _settle();
      final pages = repository.pageCount;

      repository.messages = [_message('m2'), _message('m1')];
      signals.emit(_path, {'messages_changed_at': DateTime.utc(2026, 1, 1)});
      await _settle();

      expect(state().live, isTrue);
      expect(state().refreshes, 1);
      expect(repository.pageCount, pages + 1);
      expect(ids(), ['m2', 'm1']);
    },
  );

  test('a change on an older loaded page reaches its row', () async {
    build(messages: [for (var i = 40; i > 0; i--) _message('m$i')]);
    await _settle();
    await container.read(groupChatThreadProvider('room-1').notifier).loadMore();
    signals.emit(_path, {'messages_changed_at': DateTime.utc(2026, 1, 1)});
    await _settle();
    expect(ids(), hasLength(40));

    repository.messages = [
      for (final m in repository.messages)
        m.id == 'm3' ? m.copyWith(deletedAt: '2026-10-29T11:00:00Z') : m,
    ];
    signals.emit(_path, {'messages_changed_at': DateTime.utc(2026, 1, 2)});
    await _settle();

    final m3 = container
        .read(groupChatThreadProvider('room-1'))
        .messages
        .firstWhere((m) => m.id == 'm3');
    expect(m3.deletedAt, isNotNull);
  });

  test('a moved message or reaction field refetches the thread', () async {
    build();
    await _settle();
    signals.emit(_path, {
      'messages_changed_at': DateTime.utc(2026, 1, 1),
      'reactions_changed_at': DateTime.utc(2026, 1, 1),
    });
    await _settle();

    repository.messages = [_message('m2'), _message('m1')];
    signals.emit(_path, {
      'messages_changed_at': DateTime.utc(2026, 1, 2),
      'reactions_changed_at': DateTime.utc(2026, 1, 1),
    });
    await _settle();
    expect(ids(), ['m2', 'm1']);
    expect(state().refreshes, 2);

    signals.emit(_path, {
      'messages_changed_at': DateTime.utc(2026, 1, 2),
      'reactions_changed_at': DateTime.utc(2026, 1, 3),
    });
    await _settle();
    expect(state().refreshes, 3);
  });

  test('an unrelated field moving does nothing', () async {
    build();
    await _settle();
    signals.emit(_path, {'messages_changed_at': DateTime.utc(2026, 1, 1)});
    await _settle();
    final pages = repository.pageCount;

    signals.emit(_path, {
      'messages_changed_at': DateTime.utc(2026, 1, 1),
      'prayers_changed_at': DateTime.utc(2026, 1, 2),
    });
    await _settle();

    expect(repository.pageCount, pages);
  });

  test('a closed room is closed from the first snapshot', () async {
    build();
    await _settle();

    signals.emit(_path, {'closed_at': DateTime.utc(2026, 1, 1)});
    await _settle();

    expect(state().closed, isTrue);
  });

  test('a failed refetch does not count', () async {
    build();
    await _settle();
    signals.emit(_path, {'messages_changed_at': DateTime.utc(2026, 1, 1)});
    await _settle();

    repository.pageFailure = const NetworkFailure('offline');
    signals.emit(_path, {'messages_changed_at': DateTime.utc(2026, 1, 2)});
    await _settle();

    expect(state().refreshes, 1);
  });

  test('a refused listen is retried until the reader exists', () async {
    build(denied: 2);
    await _settle();
    expect(signals.listeners(_path), 0);

    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(signals.listeners(_path), 1);
    expect(state().live, isFalse);

    signals.emit(_path, {'messages_changed_at': DateTime.utc(2026, 1, 1)});
    await _settle();
    expect(state().live, isTrue);
  });

  test('a refusal past the retries gives up quietly', () async {
    build(attempts: 1, denied: 5);
    await _settle();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(signals.listeners(_path), 0);
    expect(state().live, isFalse);
  });

  test('no signals means no listener', () async {
    build(withSignals: false);
    await _settle();

    expect(signals.totalListeners, 0);
    expect(state().live, isFalse);
  });
}
