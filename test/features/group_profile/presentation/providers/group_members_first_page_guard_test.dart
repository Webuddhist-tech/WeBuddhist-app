import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_member.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Answers each request with the completer queued for its skip.
class _GatedRepository extends Fake implements GroupProfileRepositoryInterface {
  final Map<int, Completer<GroupMembersPage>> gates = {};
  final List<int> requestedSkips = [];

  Completer<GroupMembersPage> gate(int skip) =>
      gates[skip] ??= Completer<GroupMembersPage>();

  @override
  Future<Either<Failure, GroupMembersPage>> getGroupMembers(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    requestedSkips.add(skip);
    return Right(await gate(skip).future);
  }
}

GroupMembersPage _page(List<String> ids, {required int skip, int total = 6}) {
  return GroupMembersPage(
    members: [
      for (final id in ids) GroupMember(userId: id, username: id, fullname: id),
    ],
    skip: skip,
    limit: 2,
    totalMembers: total,
  );
}

List<String> _ids(GroupMembersNotifier n) =>
    n.state.members.map((m) => m.userId).toList();

void main() {
  late _GatedRepository repository;

  setUp(() => repository = _GatedRepository());

  test('loadMore is ignored while the stored first page is being refreshed',
      () async {
    final notifier = GroupMembersNotifier(
      repository: repository,
      groupId: 'g1',
      stored: _page(['a', 'b'], skip: 0),
    );
    expect(_ids(notifier), ['a', 'b']);
    expect(notifier.state.isLoading, isFalse);

    final first = notifier.loadInitial();
    await pumpEventQueue();
    await notifier.loadMore();

    expect(repository.requestedSkips, [0]);
    expect(notifier.state.isLoadingMore, isFalse);

    repository.gate(0).complete(_page(['a', 'c'], skip: 0));
    await first;
    expect(_ids(notifier), ['a', 'c']);

    unawaited(notifier.loadMore());
    await pumpEventQueue();
    expect(repository.requestedSkips, [0, 2]);
  });

  test('a page-two result that lands after a fresh first page is dropped',
      () async {
    final notifier = GroupMembersNotifier(
      repository: repository,
      groupId: 'g1',
      stored: _page(['a', 'b'], skip: 0),
    );

    // Page two starts from the stored offset before any refresh.
    final more = notifier.loadMore();
    await pumpEventQueue();
    expect(repository.requestedSkips, [2]);
    expect(notifier.state.isLoadingMore, isTrue);

    // The refresh replaces page one while page two is still in flight.
    final first = notifier.loadInitial();
    repository.gate(0).complete(_page(['x', 'y'], skip: 0));
    await first;
    expect(_ids(notifier), ['x', 'y']);

    repository.gate(2).complete(_page(['c', 'd'], skip: 2));
    await more;

    expect(_ids(notifier), ['x', 'y']);
    expect(notifier.state.skip, 2);
    expect(notifier.state.isLoadingMore, isFalse);
  });
}
