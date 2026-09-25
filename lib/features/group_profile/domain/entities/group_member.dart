import 'package:flutter_pecha/features/group_profile/domain/entities/group_member_role.dart';

class GroupMember {
  final String userId;
  final String username;
  final String fullname;
  final String? avatarUrl;

  /// Membership role from the members list. See [GroupMemberRole].
  final String? role;

  const GroupMember({
    this.userId = '',
    required this.username,
    required this.fullname,
    this.avatarUrl,
    this.role,
  });

  /// `OWNER` or `ADMIN`. Both get the admin badge and are never removable.
  bool get isAdmin => GroupMemberRole.isAdminTier(role);

  /// An admin can remove a regular member once the list includes their id.
  bool get canBeRemovedByAdmin => userId.trim().isNotEmpty && !isAdmin;
}
