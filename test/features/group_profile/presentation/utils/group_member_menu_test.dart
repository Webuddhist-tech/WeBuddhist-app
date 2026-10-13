import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_member_menu.dart';
import 'package:flutter_test/flutter_test.dart';

bool _shows(GroupFollowState followState, {bool signedIn = true}) =>
    showsGroupMemberMenu(followState: followState, signedIn: signedIn);

void main() {
  group('showsGroupMemberMenu', () {
    test('a confirmed member sees the menu', () {
      expect(_shows(const GroupFollowSuccess(isFollowing: true)), isTrue);
    });

    test('a non-member does not', () {
      expect(_shows(const GroupFollowSuccess(isFollowing: false)), isFalse);
    });

    test('nobody does when signed out or a guest', () {
      expect(
        _shows(const GroupFollowSuccess(isFollowing: true), signedIn: false),
        isFalse,
      );
    });

    test('hidden while the initial membership check runs', () {
      expect(_shows(const GroupFollowLoading(isInitialCheck: true)), isFalse);
    });

    test('a join in flight or a failed join keeps it hidden', () {
      expect(_shows(const GroupFollowLoading()), isFalse);
      expect(
        _shows(const GroupFollowFailure(NetworkFailure('x'))),
        isFalse,
      );
    });

    test('a leave in flight or a failed leave keeps it', () {
      expect(_shows(const GroupFollowLoading(wasFollowing: true)), isTrue);
      expect(
        _shows(
          const GroupFollowFailure(NetworkFailure('x'), wasFollowing: true),
        ),
        isTrue,
      );
    });
  });
}
