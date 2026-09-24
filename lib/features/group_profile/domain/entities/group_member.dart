class GroupMember {
  final String userId;
  final String username;
  final String fullname;
  final String? avatarUrl;

  /// Membership role from the members list. `ADMIN` is the group admin.
  final String? role;

  const GroupMember({
    this.userId = '',
    required this.username,
    required this.fullname,
    this.avatarUrl,
    this.role,
  });

  bool get isAdmin => role?.trim().toUpperCase() == 'ADMIN';

  /// An admin can remove a regular member once the list includes their id.
  bool get canBeRemovedByAdmin => userId.trim().isNotEmpty && !isAdmin;
}
