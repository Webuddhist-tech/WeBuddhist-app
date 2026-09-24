import 'package:flutter_pecha/features/group_profile/data/models/group_member_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses user id and admin role', () {
    final member =
        GroupMemberModel.fromJson({
          'user_id': 'c9957b3d-43ea-4f37-bd60-a7dd37a10c6a',
          'username': 'pema',
          'fullname': 'Pema Chödrön',
          'avatar_url': 'https://example.com/a.webp',
          'role': 'admin',
        }).toEntity();

    expect(member.userId, 'c9957b3d-43ea-4f37-bd60-a7dd37a10c6a');
    expect(member.username, 'pema');
    expect(member.isAdmin, isTrue);
    expect(member.canBeRemovedByAdmin, isFalse);
  });

  test('a member without id or role cannot be removed yet', () {
    final member =
        GroupMemberModel.fromJson({
          'username': 'ani',
          'fullname': 'Ani Tenzin',
          'avatar_url': '',
          'role': null,
        }).toEntity();

    expect(member.userId, isEmpty);
    expect(member.avatarUrl, isNull);
    expect(member.isAdmin, isFalse);
    expect(member.canBeRemovedByAdmin, isFalse);
  });

  test('a regular member with an id can be removed', () {
    final member =
        GroupMemberModel.fromJson({
          'user_id': 'u1',
          'username': 'dipa',
          'fullname': 'Dipa Ma',
          'role': 'MEMBER',
        }).toEntity();

    expect(member.canBeRemovedByAdmin, isTrue);
  });
}
