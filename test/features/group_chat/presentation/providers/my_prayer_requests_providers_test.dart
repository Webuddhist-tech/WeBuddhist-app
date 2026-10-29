import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/my_prayer_requests_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

ChatMessageDTO _mine(String id, {String room = 'room-1', bool done = false}) {
  return ChatMessageDTO.fromMyPrayerRequestJson({
    'id': id,
    'room_id': room,
    'room_kind': 'EVENT',
    'body': 'pray $id',
    'created_at': '2026-10-23T04:43:48+00:00',
    'prayer_count': 2,
    'total_prayer_count': 5,
    'is_completed': done,
  });
}

const _healing = ChatPrayerIntentionDTO(
  slug: 'healing',
  label: 'Healing',
  color: '#4A78C2',
);

class _FakeRepository extends Fake implements GroupChatRepository {
  _FakeRepository(this.history);

  List<ChatMessageDTO> history;

  /// Awaited before a page is answered, to stage a race.
  Completer<void>? gate;
  final List<int> skips = [];
  final List<String> completed = [];
  final List<String> updated = [];
  final List<String> deleted = [];
  Failure? failure;

  @override
  Future<Either<Failure, ChatMessagesPage>> listMyPrayerRequests({
    int skip = 0,
    int limit = 20,
    String? eventId,
    String? groupId,
    bool? isCompleted,
  }) async {
    skips.add(skip);
    expect(eventId, isNull);
    expect(groupId, isNull);
    final gate = this.gate;
    if (gate != null) await gate.future;
    final failure = this.failure;
    if (failure != null) return Left(failure);
    final end = (skip + limit).clamp(0, history.length);
    return Right(
      ChatMessagesPage(
        messages: history.sublist(skip.clamp(0, history.length), end),
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
    completed.add('$roomId/$messageId=$isCompleted');
    return const Right(null);
  }

  @override
  Future<Either<Failure, ChatMessageDTO?>> updateMessage(
    String roomId, {
    required String messageId,
    required String body,
    String? intention,
  }) async {
    updated.add('$roomId/$messageId:$body:$intention');
    return const Right(null);
  }

  @override
  Future<Either<Failure, Unit>> deleteMessage(
    String roomId, {
    required String messageId,
  }) async {
    deleted.add('$roomId/$messageId');
    return const Right(unit);
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _FakeRepository repository;
  late ProviderContainer container;

  MyPrayerRequestsNotifier start(List<ChatMessageDTO> history) {
    repository = _FakeRepository(history);
    container = ProviderContainer(
      overrides: [groupChatRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(myPrayerRequestsProvider, (_, _) {});
    return container.read(myPrayerRequestsProvider.notifier);
  }

  tearDown(() => container.dispose());

  group(
    'changes during a refresh',
    () => _changesDuringRefresh((made) => container = made),
  );

  test('lists every request without an event filter, split by state', () async {
    final notifier = start([
      _mine('a'),
      _mine('b', done: true),
      _mine('c', room: 'room-2'),
    ]);
    await _settle();

    expect(repository.skips, [0]);
    expect(notifier.state.hasLoaded, isTrue);
    expect(notifier.state.total, 3);
    expect(notifier.state.active.map((r) => r.id), ['a', 'c']);
    expect(notifier.state.accomplished.map((r) => r.id), ['b']);
    expect(notifier.state.requests.first.totalPrayerCount, 5);
  });

  test('pages until the total is reached', () async {
    final notifier = start([for (var i = 0; i < 25; i++) _mine('r$i')]);
    await _settle();
    expect(notifier.state.requests.length, 20);
    expect(notifier.state.hasMore, isTrue);

    await notifier.loadMore();
    expect(repository.skips, [0, 20]);
    expect(notifier.state.requests.length, 25);
    expect(notifier.state.hasMore, isFalse);
  });

  test('a refresh while a page is in flight drops the page', () async {
    final notifier = start([for (var i = 0; i < 25; i++) _mine('r$i')]);
    await _settle();

    repository.gate = Completer<void>();
    final more = notifier.loadMore();
    expect(notifier.state.isLoadingMore, isTrue);

    repository.history = [_mine('fresh')];
    final gate = repository.gate!;
    repository.gate = null;
    final refresh = notifier.load();
    expect(notifier.state.isLoadingMore, isFalse);
    await refresh;
    gate.complete();
    await more;

    // The stale page did not land, and paging still works.
    expect(notifier.state.requests.map((r) => r.id), ['fresh']);
    expect(notifier.state.isLoadingMore, isFalse);
    expect(notifier.state.hasMore, isFalse);
  });

  test('a failed load keeps the error for a retry', () async {
    repository = _FakeRepository([])..failure = const ServerFailure('down');
    container = ProviderContainer(
      overrides: [groupChatRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(myPrayerRequestsProvider, (_, _) {});
    final notifier = container.read(myPrayerRequestsProvider.notifier);
    await _settle();
    expect(notifier.state.error, 'down');

    repository.failure = null;
    repository.history = [_mine('a')];
    await notifier.load();
    expect(notifier.state.error, isNull);
    expect(notifier.state.requests.map((r) => r.id), ['a']);
  });

  test('actions go to the row\'s own room', () async {
    final notifier = start([_mine('a'), _mine('c', room: 'room-2')]);
    await _settle();

    await notifier.setCompleted('c', isCompleted: true);
    expect(repository.completed, ['room-2/c=true']);
    expect(notifier.state.accomplished.map((r) => r.id), ['c']);

    await notifier.edit('a', body: 'new words', intention: _healing);
    expect(repository.updated, ['room-1/a:new words:healing']);
    expect(notifier.state.requests.first.body, 'new words');
    expect(notifier.state.requests.first.intention?.slug, 'healing');

    await notifier.delete('a');
    expect(repository.deleted, ['room-1/a']);
    expect(notifier.state.requests.map((r) => r.id), ['c']);
    expect(notifier.state.total, 1);
  });
}

/// A server whose deletes take effect, and whose gated page is read before
/// the gate opens, as a real request in flight would be.
class _StaleReadRepository extends _FakeRepository {
  _StaleReadRepository(super.history);

  @override
  Future<Either<Failure, ChatMessagesPage>> listMyPrayerRequests({
    int skip = 0,
    int limit = 20,
    String? eventId,
    String? groupId,
    bool? isCompleted,
  }) async {
    final gate = this.gate;
    this.gate = null;
    final snapshot = List.of(history);
    if (gate != null) await gate.future;
    final end = (skip + limit).clamp(0, snapshot.length);
    return Right(
      ChatMessagesPage(
        messages: snapshot.sublist(skip.clamp(0, snapshot.length), end),
        skip: skip,
        limit: limit,
        total: snapshot.length,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> deleteMessage(
    String roomId, {
    required String messageId,
  }) async {
    history = history.where((m) => m.id != messageId).toList();
    return super.deleteMessage(roomId, messageId: messageId);
  }
}

/// [adopt] hands the container to the file's tearDown, which disposes it.
void _changesDuringRefresh(void Function(ProviderContainer) adopt) {
  test('a delete made while page one is re-read is not undone', () async {
    final repository = _StaleReadRepository([_mine('a'), _mine('b')]);
    final container = ProviderContainer(
      overrides: [groupChatRepositoryProvider.overrideWithValue(repository)],
    );
    adopt(container);
    container.listen(myPrayerRequestsProvider, (_, _) {});
    final notifier = container.read(myPrayerRequestsProvider.notifier);
    await _settle();
    expect(notifier.state.requests.map((r) => r.id), ['a', 'b']);

    final gate = Completer<void>();
    repository.gate = gate;
    unawaited(notifier.load());
    await _settle();

    await notifier.delete('a');
    gate.complete();
    await _settle();

    expect(notifier.state.requests.map((r) => r.id), ['b']);
    expect(notifier.state.total, 1);
  });
}
