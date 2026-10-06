import 'package:flutter_pecha/features/group_profile/domain/entities/group_report.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_reports_page.dart';

class GroupReportModel {
  final GroupReport report;

  const GroupReportModel(this.report);

  /// Returns null for a kind this client does not know, so the queue skips
  /// it instead of failing the whole page.
  static GroupReportModel? fromJson(Map<String, dynamic> json) {
    final kind = GroupReportKind.fromApi(json['kind'] as String?);
    if (kind == null) return null;

    return GroupReportModel(
      GroupReport(
        id: json['id'] as String? ?? '',
        kind: kind,
        reason: json['reason'] as String? ?? '',
        description: (json['description'] as String?)?.trim() ?? '',
        source: json['source'] as String? ?? '',
        contentText: json['content_text'] as String? ?? '',
        postId: _nonEmpty(json['post_id']),
        commentId: _nonEmpty(json['comment_id']),
        messageId: _nonEmpty(json['message_id']),
        roomId: _nonEmpty(json['room_id']),
        roomName: _nonEmpty(json['room_name']),
        reporter: _userFromJson(json['reporter']),
        reportedUser: _userFromJson(json['reported_user']),
        createdAt: _dateFromJson(json['created_at']),
        resolvedAt: _dateFromJson(json['resolved_at']),
      ),
    );
  }

  GroupReport toEntity() => report;

  static GroupReportUser? _userFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return GroupReportUser(
      id: value['id'] as String? ?? '',
      username: value['username'] as String? ?? '',
      firstname: value['firstname'] as String? ?? '',
      lastname: value['lastname'] as String? ?? '',
    );
  }

  static String? _nonEmpty(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _dateFromJson(Object? value) {
    final raw = _nonEmpty(value);
    return raw == null ? null : DateTime.tryParse(raw);
  }
}

class GroupReportsPageModel {
  final List<GroupReportModel> reports;

  /// Reports on the wire, counting those dropped for an unknown kind.
  final int received;
  final int skip;
  final int limit;
  final int total;

  GroupReportsPageModel({
    required this.reports,
    required this.received,
    required this.skip,
    required this.limit,
    required this.total,
  });

  factory GroupReportsPageModel.fromJson(Map<String, dynamic> json) {
    final raw =
        (json['reports'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];
    final reports =
        raw
            .map(GroupReportModel.fromJson)
            .whereType<GroupReportModel>()
            .toList();

    return GroupReportsPageModel(
      reports: reports,
      received: raw.length,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? raw.length,
    );
  }

  GroupReportsPage toEntity() {
    return GroupReportsPage(
      reports: reports.map((report) => report.toEntity()).toList(),
      received: received,
      skip: skip,
      limit: limit,
      total: total,
    );
  }
}
