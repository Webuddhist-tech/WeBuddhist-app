import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeRepository extends Fake implements GroupProfileRepositoryInterface {
  Completer<Either<Failure, bool>> status = Completer();
  Completer<Either<Failure, void>> follow = Completer();
  Completer<Either<Failure, void>> unfollow = Completer();

  @override
  Future<Either<Failure, bool>> checkFollowStatus(
    String groupId,
    GroupType groupType,
  ) => status.future;

  @override
  Future<Either<Failure, void>> followGroup(
    String groupId,
    GroupType groupType,
  ) => follow.future;

  @override
  Future<Either<Failure, void>> unfollowGroup(
    String groupId,
    GroupType groupType,
  ) => unfollow.future;
}

final _refProvider = Provider<Ref>((ref) => ref);

const _key = GroupFollowKey(groupId: 'g1', groupType: GroupType.community);
const _failure = NetworkFailure('offline');

void main() {
  late ProviderContainer container;
  late _FakeRepository repository;

  setUp(() {
    container = ProviderContainer();
    repository = _FakeRepository();
  });

  tearDown(() => container.dispose());

  Future<GroupFollowNotifier> notifierWithStatus(
    Either<Failure, bool> status,
  ) async {
    final notifier = GroupFollowNotifier(
      repository: repository,
      ref: container.read(_refProvider),
      key: _key,
      isAuthenticated: true,
    );
    repository.status.complete(status);
    await pumpEventQueue();
    return notifier;
  }

  bool canPost(GroupFollowState state) =>
      canPublishGroupPosts(canCreateContent: true, followState: state);

  group('initial membership check', () {
    test('holds posting while the check is in flight', () {
      final notifier = GroupFollowNotifier(
        repository: repository,
        ref: container.read(_refProvider),
        key: _key,
        isAuthenticated: true,
      );

      expect(isPrivateGroupMembershipLoading(notifier.state), isTrue);
      expect(canPost(notifier.state), isFalse);
      notifier.dispose();
    });

    test('a confirmed member can post', () async {
      final notifier = await notifierWithStatus(const Right(true));

      expect(canPost(notifier.state), isTrue);
      notifier.dispose();
    });

    test('a failed check is unconfirmed, not a confirmed non-member', () async {
      final notifier = await notifierWithStatus(const Left(_failure));

      expect(notifier.state, isA<GroupFollowFailure>());
      expect(isPrivateGroupMembershipLoading(notifier.state), isFalse);
      expect(canPost(notifier.state), isFalse);
      notifier.dispose();
    });
  });

  group('leaving', () {
    test('a member keeps posting while leave is in flight', () async {
      final notifier = await notifierWithStatus(const Right(true));

      unawaited(notifier.unfollow());

      expect(notifier.state, isA<GroupFollowLoading>());
      expect(canPost(notifier.state), isTrue);
      notifier.dispose();
    });

    test('a failed leave keeps the member able to post', () async {
      final notifier = await notifierWithStatus(const Right(true));

      final left = notifier.unfollow();
      repository.unfollow.complete(const Left(_failure));

      expect(await left, isFalse);
      expect(notifier.state, isA<GroupFollowFailure>());
      expect(canPost(notifier.state), isTrue);
      notifier.dispose();
    });
  });

  group('joining', () {
    test('a non-member cannot post while join is in flight', () async {
      final notifier = await notifierWithStatus(const Right(false));

      unawaited(notifier.follow());

      expect(notifier.state, isA<GroupFollowLoading>());
      expect(canPost(notifier.state), isFalse);
      notifier.dispose();
    });

    test('a failed join keeps a non-member out', () async {
      final notifier = await notifierWithStatus(const Right(false));

      final joined = notifier.follow();
      repository.follow.complete(const Left(_failure));

      expect(await joined, isFalse);
      expect(canPost(notifier.state), isFalse);
      notifier.dispose();
    });

    test('a failed leave then failed join still reflects the member', () async {
      final notifier = await notifierWithStatus(const Right(true));

      final left = notifier.unfollow();
      repository.unfollow.complete(const Left(_failure));
      await left;
      final joined = notifier.follow();
      repository.follow.complete(const Left(_failure));
      await joined;

      expect(canPost(notifier.state), isTrue);
      notifier.dispose();
    });
  });

  test('posting also needs the content permission', () {
    const member = GroupFollowSuccess(isFollowing: true);

    expect(
      canPublishGroupPosts(canCreateContent: false, followState: member),
      isFalse,
    );
  });
}
