import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_member.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeRepository extends Fake implements GroupProfileRepositoryInterface {
  Either<Failure, void> removeResult = const Right(null);
  int removeCalls = 0;
  int? lastBanDays;
  String? lastReason;
  final List<int> requestedSkips = [];
  GroupMembersPage? firstPage;
  Completer<GroupMembersPage>? pendingPage;
  GroupMembersPage? pageAfterRemoval;

  @override
  Future<Either<Failure, GroupMembersPage>> getGroupMembers(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    requestedSkips.add(skip);
    if (firstPage != null && requestedSkips.length == 1) {
      return Right(firstPage!);
    }
    if (pendingPage != null && requestedSkips.length == 2) {
      final page = await pendingPage!.future;
      return Right(page);
    }
    return Right(
      pageAfterRemoval ??
          GroupMembersPage(
            members: const [
              GroupMember(userId: 'u1', username: 'a', fullname: 'A'),
              GroupMember(userId: 'u2', username: 'b', fullname: 'B'),
            ],
            skip: skip,
            limit: limit,
            totalMembers: 2,
          ),
    );
  }

  @override
  Future<Either<Failure, void>> removeJoinedUser(
    String groupId, {
    required String userId,
    required int banDurationDays,
    String? reason,
  }) async {
    removeCalls++;
    lastBanDays = banDurationDays;
    lastReason = reason;
    return removeResult;
  }
}

void main() {
  test('remove drops the member and lowers the count', () async {
    final repository = _FakeRepository();
    final notifier = GroupMembersNotifier(
      repository: repository,
      groupId: 'g1',
    );
    await notifier.loadInitial();

    final removed = await notifier.removeMember(
      userId: 'u1',
      banDurationDays: 7,
      reason: 'note',
    );

    expect(removed, isTrue);
    expect(repository.removeCalls, 1);
    expect(repository.lastBanDays, 7);
    expect(notifier.state.members.map((member) => member.userId), ['u2']);
    expect(notifier.state.totalMembers, 1);
    expect(notifier.state.skip, 1);
    notifier.dispose();
  });

  test('a failed remove leaves the list unchanged', () async {
    final repository = _FakeRepository()
      ..removeResult = const Left(ServerFailure('no'));
    final notifier = GroupMembersNotifier(
      repository: repository,
      groupId: 'g1',
    );
    await notifier.loadInitial();

    final removed = await notifier.removeMember(
      userId: 'u2',
      banDurationDays: 30,
    );

    expect(removed, isFalse);
    expect(notifier.state.members, hasLength(2));
    expect(notifier.state.totalMembers, 2);
    notifier.dispose();
  });

  test('removal discards an in-flight page and reloads from the new offset', () async {
    final first = List<GroupMember>.generate(
      20,
      (index) => GroupMember(
        userId: 'u$index',
        username: 'user$index',
        fullname: 'User $index',
      ),
    );
    final shiftedPage = List<GroupMember>.generate(
      20,
      (index) => GroupMember(
        userId: 'u${index + 21}',
        username: 'user${index + 21}',
        fullname: 'User ${index + 21}',
      ),
    );
    final correctedPage = [
      GroupMember(userId: 'u20', username: 'user20', fullname: 'User 20'),
      ...shiftedPage.take(19),
    ];
    final repository = _FakeRepository()
      ..firstPage = GroupMembersPage(
        members: first,
        skip: 0,
        limit: 20,
        totalMembers: 40,
      )
      ..pendingPage = Completer<GroupMembersPage>()
      ..pageAfterRemoval = GroupMembersPage(
        members: correctedPage,
        skip: 19,
        limit: 20,
        totalMembers: 50,
      );
    var profileRefreshCount = 0;
    final notifier = GroupMembersNotifier(
      repository: repository,
      groupId: 'g1',
      onMemberRemoved: () => profileRefreshCount++,
    );
    await notifier.loadInitial();

    final loading = notifier.loadMore();
    final removed = await notifier.removeMember(userId: 'u0', banDurationDays: 7);
    repository.pendingPage!.complete(
      GroupMembersPage(
        members: shiftedPage,
        skip: 20,
        limit: 20,
        totalMembers: 39,
      ),
    );
    await loading;
    await Future<void>.delayed(Duration.zero);

    expect(removed, isTrue);
    expect(profileRefreshCount, 1);
    expect(repository.requestedSkips, [0, 20, 19]);
    expect(
      notifier.state.members.map((member) => member.userId),
      contains('u20'),
    );
    expect(
      notifier.state.members.map((member) => member.userId),
      isNot(contains('u40')),
    );
    expect(notifier.state.hasMore, isTrue);
    notifier.dispose();
  });
}
