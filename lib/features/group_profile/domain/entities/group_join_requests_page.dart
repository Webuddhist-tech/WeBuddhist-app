import 'package:flutter_pecha/features/group_profile/domain/entities/group_join_request.dart';

class GroupJoinRequestsPage {
  final List<GroupJoinRequest> requests;
  final int skip;
  final int limit;
  final int total;

  const GroupJoinRequestsPage({
    required this.requests,
    required this.skip,
    required this.limit,
    required this.total,
  });

  bool get hasMore => skip + requests.length < total;
}
