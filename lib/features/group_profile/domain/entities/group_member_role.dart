/// Group membership roles as sent by the backend (`AuthorGroupMemberRole`):
/// `OWNER`, `ADMIN`, `AUTHOR`, `VIEWER`.
///
/// Both the members list and `GET /users/me/permission/{groupId}` use this
/// enum, so role checks live here instead of being repeated per entity.
abstract final class GroupMemberRole {
  static const String owner = 'OWNER';
  static const String admin = 'ADMIN';

  /// Upper-cased, trimmed role, or null when missing or blank.
  static String? normalize(String? role) {
    final value = role?.trim().toUpperCase();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// `OWNER` and `ADMIN` both manage the group: they see admin controls and
  /// cannot be removed by another admin.
  static bool isAdminTier(String? role) {
    final value = normalize(role);
    return value == owner || value == admin;
  }
}
