enum GroupReportKind {
  chatMessage('CHAT_MESSAGE'),
  post('POST'),
  comment('COMMENT');

  const GroupReportKind(this.apiValue);

  final String apiValue;

  static GroupReportKind? fromApi(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final kind in values) {
      if (kind.apiValue == normalized) return kind;
    }
    return null;
  }
}

class GroupReportUser {
  final String id;
  final String username;
  final String firstname;
  final String lastname;

  const GroupReportUser({
    required this.id,
    this.username = '',
    this.firstname = '',
    this.lastname = '',
  });

  /// Full name, falling back to the username when neither name is set.
  String get displayName {
    final fullName = '${firstname.trim()} ${lastname.trim()}'.trim();
    return fullName.isNotEmpty ? fullName : username.trim();
  }
}

/// One member's report against a chat message, post, or comment.
class GroupReport {
  final String id;
  final GroupReportKind kind;
  final String reason;
  final String description;
  final String source;
  final String contentText;
  final String? postId;
  final String? commentId;
  final String? messageId;
  final String? roomId;
  final String? roomName;
  final GroupReportUser? reporter;
  final GroupReportUser? reportedUser;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const GroupReport({
    required this.id,
    required this.kind,
    this.reason = '',
    this.description = '',
    this.source = '',
    this.contentText = '',
    this.postId,
    this.commentId,
    this.messageId,
    this.roomId,
    this.roomName,
    this.reporter,
    this.reportedUser,
    this.createdAt,
    this.resolvedAt,
  });

  /// The id of the reported content, so reports against the same item group.
  String get targetId => switch (kind) {
    GroupReportKind.chatMessage => messageId ?? id,
    GroupReportKind.post => postId ?? id,
    GroupReportKind.comment => commentId ?? id,
  };
}

/// A reported post, comment, or message with every report filed against it.
class GroupReportedItem {
  final GroupReportKind kind;
  final String targetId;

  /// Newest first, as the queue returns them.
  final List<GroupReport> reports;

  const GroupReportedItem({
    required this.kind,
    required this.targetId,
    required this.reports,
  });

  GroupReport get latest => reports.first;

  String get contentText => latest.contentText;

  GroupReportUser? get reportedUser => latest.reportedUser;
}

/// Groups [reports] by the content they target, keeping the order in which
/// each item first appears so the newest report still leads.
List<GroupReportedItem> groupReportsByTarget(List<GroupReport> reports) {
  final byTarget = <(GroupReportKind, String), List<GroupReport>>{};
  for (final report in reports) {
    byTarget.putIfAbsent((report.kind, report.targetId), () => []).add(report);
  }
  return [
    for (final MapEntry(key: (kind, targetId), value: grouped)
        in byTarget.entries)
      GroupReportedItem(kind: kind, targetId: targetId, reports: grouped),
  ];
}
