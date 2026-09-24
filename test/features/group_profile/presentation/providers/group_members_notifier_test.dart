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

  @override
  Future<Either<Failure, GroupMembersPage>> getGroupMembers(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    return Right(
      GroupMembersPage(
        members: const [
          GroupMember(userId: 'u1', username: 'a', fullname: 'A'),
          GroupMember(userId: 'u2', username: 'b', fullname: 'B'),
        ],
        skip: 0,
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
}
