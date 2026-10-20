import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';

/// An event from the CMS list: the parsed entity plus its status and the raw
/// payload, which the composer reads back when a draft is edited.
class GroupEventCmsItem {
  final GroupEvent event;
  final String status;
  final Map<String, dynamic> raw;

  const GroupEventCmsItem({
    required this.event,
    required this.status,
    required this.raw,
  });

  /// Events from before statuses existed are live.
  bool get isDraft => status == 'draft';

  factory GroupEventCmsItem.fromJson(Map<String, dynamic> json) {
    return GroupEventCmsItem(
      event: GroupEventModel.fromJson(json).toEntity(),
      status: (json['status'] as String? ?? 'published').toLowerCase(),
      raw: json,
    );
  }
}
