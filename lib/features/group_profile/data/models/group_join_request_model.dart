import 'package:flutter_pecha/features/group_profile/domain/entities/group_join_request.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_join_requests_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

class GroupJoinRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String email;
  final String message;
  final GroupJoinRequestStatus status;
  final DateTime? createdAt;

  GroupJoinRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.email = '',
    this.message = '',
    required this.status,
    this.createdAt,
  });

  factory GroupJoinRequestModel.fromJson(Map<String, dynamic> json) {
    final avatar = json['user_avatar_url'] as String?;
    final trimmedAvatar = avatar?.trim();
    final createdRaw = json['created_at'] as String?;

    return GroupJoinRequestModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      userAvatarUrl:
          trimmedAvatar == null || trimmedAvatar.isEmpty ? null : trimmedAvatar,
      email: (json['email'] as String?)?.trim() ?? '',
      message: json['message'] as String? ?? '',
      status:
          GroupJoinRequestStatus.fromApi(json['status'] as String?) ??
          GroupJoinRequestStatus.pending,
      createdAt:
          createdRaw == null || createdRaw.isEmpty
              ? null
              : DateTime.tryParse(createdRaw),
    );
  }

  GroupJoinRequest toEntity() {
    return GroupJoinRequest(
      id: id,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      email: email,
      message: message,
      status: status,
      createdAt: createdAt,
    );
  }
}

class GroupJoinRequestsPageModel {
  final List<GroupJoinRequestModel> requests;
  final int skip;
  final int limit;
  final int total;

  GroupJoinRequestsPageModel({
    required this.requests,
    required this.skip,
    required this.limit,
    required this.total,
  });

  factory GroupJoinRequestsPageModel.fromJson(Map<String, dynamic> json) {
    final requests =
        (json['requests'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(GroupJoinRequestModel.fromJson)
            .toList() ??
        const <GroupJoinRequestModel>[];

    return GroupJoinRequestsPageModel(
      requests: requests,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? requests.length,
    );
  }

  GroupJoinRequestsPage toEntity() {
    return GroupJoinRequestsPage(
      requests: requests.map((request) => request.toEntity()).toList(),
      skip: skip,
      limit: limit,
      total: total,
    );
  }
}

class GroupJoinRequestDecisionModel {
  final String id;
  final GroupJoinRequestStatus status;

  GroupJoinRequestDecisionModel({required this.id, required this.status});

  factory GroupJoinRequestDecisionModel.fromJson(Map<String, dynamic> json) {
    final status = GroupJoinRequestStatus.fromApi(json['status'] as String?);
    if (status == null) {
      throw const FormatException('Unknown join request status');
    }
    return GroupJoinRequestDecisionModel(
      id: json['id'] as String? ?? '',
      status: status,
    );
  }

  GroupJoinRequestDecision toEntity() {
    return GroupJoinRequestDecision(id: id, status: status);
  }
}
