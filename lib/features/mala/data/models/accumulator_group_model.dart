import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';

class AccumulatorGroupModel {
  const AccumulatorGroupModel({
    required this.groupAccumulatorId,
    required this.groupId,
    required this.userTotalCount,
    required this.isJoined,
    this.title,
    this.groupName,
    this.eventTitle,
    this.image,
    this.groupTotalCount = 0,
  });

  final String groupAccumulatorId;
  final String groupId;
  final String? title;
  final String? groupName;
  final String? eventTitle;
  final ImageModel? image;
  final int userTotalCount;
  final int groupTotalCount;
  final bool isJoined;

  factory AccumulatorGroupModel.fromJson(Map<String, dynamic> json) {
    return AccumulatorGroupModel(
      groupAccumulatorId: json['group_accumulator_id'] as String,
      groupId: json['group_id'] as String,
      title: json['title'] as String?,
      groupName: json['group_name'] as String?,
      eventTitle: json['event_title'] as String?,
      image: ImageModel.fromJsonMap(json),
      userTotalCount: (json['user_total_count'] as num?)?.toInt() ?? 0,
      groupTotalCount: (json['group_total_count'] as num?)?.toInt() ?? 0,
      isJoined: json['is_joined'] as bool? ?? false,
    );
  }

  AccumulatorGroup toEntity() {
    return AccumulatorGroup(
      groupAccumulatorId: groupAccumulatorId,
      groupId: groupId,
      title: title,
      groupName: groupName,
      eventTitle: eventTitle,
      image: image?.toResponsiveImage(),
      userTotalCount: userTotalCount,
      groupTotalCount: groupTotalCount,
      isJoined: isJoined,
    );
  }
}

class AccumulatorGroupsResponseModel {
  const AccumulatorGroupsResponseModel({
    required this.groups,
    required this.total,
  });

  final List<AccumulatorGroupModel> groups;
  final int total;

  factory AccumulatorGroupsResponseModel.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'] as List<dynamic>? ?? const [];
    return AccumulatorGroupsResponseModel(
      groups:
          rawGroups
              .whereType<Map<String, dynamic>>()
              .map(AccumulatorGroupModel.fromJson)
              .toList(),
      total: (json['total'] as num?)?.toInt() ?? rawGroups.length,
    );
  }
}
