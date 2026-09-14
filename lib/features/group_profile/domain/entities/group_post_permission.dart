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
}
