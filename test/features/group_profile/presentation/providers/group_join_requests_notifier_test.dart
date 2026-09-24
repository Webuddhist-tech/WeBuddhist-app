import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_join_request.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_join_requests_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeRepository extends Fake implements GroupProfileRepositoryInterface {
  final List<int> pageSkips = [];
  final List<Completer<Either<Failure, GroupJoinRequestsPage>>> pageHolds = [];
  int approveCalls = 0;
  int rejectCalls = 0;

  @override
  Future<Either<Failure, GroupJoinRequestsPage>> getGroupJoinRequests(
    String groupId, {
    GroupJoinRequestStatus status = GroupJoinRequestStatus.pending,
    required int skip,
    required int limit,
  }) {
    pageSkips.add(skip);
    final hold = Completer<Either<Failure, GroupJoinRequestsPage>>();
    pageHolds.add(hold);
    return hold.future;
  }

  @override
  Future<Either<Failure, GroupJoinRequestDecision>> approveGroupJoinRequest(
    String groupId, {
    required String requestId,
  }) async {
    approveCalls++;
    return Right(
      GroupJoinRequestDecision(
        id: requestId,
        status: GroupJoinRequestStatus.approved,
      ),
    );
  }

  @override
  Future<Either<Failure, GroupJoinRequestDecision>> rejectGroupJoinRequest(
    String groupId, {
    required String requestId,
  }) async {
    rejectCalls++;
    return Right(
      GroupJoinRequestDecision(
        id: requestId,
        status: GroupJoinRequestStatus.rejected,
      ),
    );
  }
}

GroupJoinRequest _request(String id) {
  return GroupJoinRequest(
    id: id,
    userId: 'user-$id',
    userName: 'User $id',
    status: GroupJoinRequestStatus.pending,
  );
}

GroupJoinRequestsPage _page({
  required int skip,
  required int start,
  required int count,
  required int total,
}) {
  return GroupJoinRequestsPage(
    requests: [for (var i = 0; i < count; i++) _request('r${start + i}')],
    skip: skip,
    limit: count,
    total: total,
  );
}

void main() {
  test('approve and reject wait until the in-flight page lands', () async {
    final repository = _FakeRepository();
    final notifier = GroupJoinRequestsNotifier(
      repository: repository,
      groupId: 'group-1',
    );

    final initial = notifier.loadInitial();
    final firstPage = _page(skip: 0, start: 0, count: 20, total: 40);
    repository.pageHolds.single.complete(Right(firstPage));
    await initial;

    final more = notifier.loadMore();
    expect(notifier.state.isLoadingMore, isTrue);
    expect(repository.pageSkips, [0, 20]);

    expect(await notifier.approve('r0'), isFalse);
    expect(await notifier.reject('r1'), isFalse);
    expect(repository.approveCalls, 0);
    expect(repository.rejectCalls, 0);
    expect(notifier.state.requests, hasLength(20));

    repository.pageHolds[1].complete(
      Right(_page(skip: 20, start: 20, count: 20, total: 40)),
    );
    await more;

    expect(notifier.state.isLoadingMore, isFalse);
    expect(notifier.state.requests, hasLength(40));

    expect(await notifier.approve('r0'), isTrue);
    expect(repository.approveCalls, 1);
    expect(
      notifier.state.requests.map((request) => request.id),
      isNot(contains('r0')),
    );
    expect(notifier.state.skip, 39);
  });

  test('stops paging when a page lands empty against a stale total', () async {
    final repository = _FakeRepository();
    final notifier = GroupJoinRequestsNotifier(
      repository: repository,
      groupId: 'group-1',
    );

    final initial = notifier.loadInitial();
    repository.pageHolds.single.complete(
      Right(_page(skip: 0, start: 0, count: 20, total: 40)),
    );
    await initial;
    expect(notifier.state.hasMore, isTrue);

    final more = notifier.loadMore();
    repository.pageHolds[1].complete(
      Right(
        const GroupJoinRequestsPage(
          requests: [],
          skip: 20,
          limit: 20,
          total: 40,
        ),
      ),
    );
    await more;

    expect(notifier.state.requests, hasLength(20));
    expect(notifier.state.hasMore, isFalse);
  });

  test('pages past the first window when the server echoes skip 0', () async {
    final repository = _FakeRepository();
    final notifier = GroupJoinRequestsNotifier(
      repository: repository,
      groupId: 'group-1',
    );

    final initial = notifier.loadInitial();
    repository.pageHolds.single.complete(
      Right(_page(skip: 0, start: 0, count: 20, total: 30)),
    );
    await initial;

    final more = notifier.loadMore();
    expect(repository.pageSkips, [0, 20]);
    // A server that always echoes `skip: 0` used to make `hasMore` true
    // forever; the accumulated count settles it instead.
    repository.pageHolds[1].complete(
      Right(_page(skip: 0, start: 20, count: 10, total: 30)),
    );
    await more;

    expect(notifier.state.requests, hasLength(30));
    expect(notifier.state.skip, 30);
    expect(notifier.state.hasMore, isFalse);
  });
}
