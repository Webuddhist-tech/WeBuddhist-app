import 'package:flutter_pecha/features/group_profile/domain/entities/group_post_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GroupPostPermission permission({String? role, bool isSuperAdmin = false}) {
    return GroupPostPermission(
      groupId: 'g1',
      role: role,
      isSuperAdmin: isSuperAdmin,
    );
  }

  test('ADMIN role is a group admin', () {
    expect(permission(role: 'ADMIN').isGroupAdmin, isTrue);
    expect(permission(role: 'admin').isGroupAdmin, isTrue);
  });

  test('OWNER role is a group admin', () {
    expect(permission(role: 'OWNER').isGroupAdmin, isTrue);
    expect(permission(role: ' owner ').isGroupAdmin, isTrue);
  });

  test('author, viewer and missing roles are not group admin', () {
    expect(permission().isGroupAdmin, isFalse);
    expect(permission(role: 'AUTHOR').isGroupAdmin, isFalse);
    expect(permission(role: 'VIEWER').isGroupAdmin, isFalse);
    expect(permission(role: 'MEMBER').isGroupAdmin, isFalse);
    expect(permission(role: '  ').isGroupAdmin, isFalse);
  });

  test('platform super admin without ADMIN role is not group admin', () {
    expect(permission(isSuperAdmin: true).isGroupAdmin, isFalse);
  });
}
