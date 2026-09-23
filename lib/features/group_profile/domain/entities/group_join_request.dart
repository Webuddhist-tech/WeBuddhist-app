import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

class GroupJoinRequest {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String email;
  final String message;
  final GroupJoinRequestStatus status;
  final DateTime? createdAt;

  const GroupJoinRequest({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.email = '',
    this.message = '',
    required this.status,
    this.createdAt,
  });
}

/// Result of approving or rejecting a join request.
class GroupJoinRequestDecision {
  final String id;
  final GroupJoinRequestStatus status;

  const GroupJoinRequestDecision({required this.id, required this.status});
}
