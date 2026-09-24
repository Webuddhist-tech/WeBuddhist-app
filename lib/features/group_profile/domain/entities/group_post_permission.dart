class GroupPostPermission {
  final String groupId;
  final bool hasPermission;

  /// Gates the composer. `has_permission` alone is not enough to post.
  final bool canCreateContent;
  final String? role;
  final bool isSuperAdmin;
  final String? authorId;

  const GroupPostPermission({
    required this.groupId,
    this.hasPermission = false,
    this.canCreateContent = false,
    this.role,
    this.isSuperAdmin = false,
    this.authorId,
  });

  /// Group-admin from `GET /users/me/permission/{groupId}` when `role` is
  /// `ADMIN` (case-insensitive). Platform super-admin is not used here.
  bool get isGroupAdmin => role?.trim().toUpperCase() == 'ADMIN';
}
