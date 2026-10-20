import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_in_person_count.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class GroupEventInPersonCountModel {
  final String id;
  final String day;
  final int count;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GroupEventInPersonCountModel({
    required this.id,
    required this.day,
    required this.count,
    this.createdAt,
    this.updatedAt,
  });

  factory GroupEventInPersonCountModel.fromJson(Map<String, dynamic> json) {
    return GroupEventInPersonCountModel(
      id: json['id'] as String? ?? '',
      day: json['day'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  GroupEventInPersonCount toEntity() {
    return GroupEventInPersonCount(
      id: id,
      day: day,
      count: count,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class GroupEventInPersonCountListModel {
  final List<GroupEventInPersonCountModel> items;
  final int total;
  final int skip;
  final int limit;
  final int totalCount;
  final String? groupAccumulatorId;
  final String? eventAccumulationId;
  final String? groupAccumulatorTitle;
  final int? groupAccumulatorTotalCount;
  final int? groupAccumulatorTargetCount;
  final Map<String, dynamic>? groupAccumulatorImageJson;
  final String timezone;

  const GroupEventInPersonCountListModel({
    required this.items,
    required this.total,
    required this.skip,
    required this.limit,
    required this.totalCount,
    this.groupAccumulatorId,
    this.eventAccumulationId,
    this.groupAccumulatorTitle,
    this.groupAccumulatorTotalCount,
    this.groupAccumulatorTargetCount,
    this.groupAccumulatorImageJson,
    required this.timezone,
  });

  factory GroupEventInPersonCountListModel.fromJson(Map<String, dynamic> json) {
    return GroupEventInPersonCountListModel(
      items:
          (json['items'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(GroupEventInPersonCountModel.fromJson)
              .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      groupAccumulatorId: json['group_accumulator_id'] as String?,
      eventAccumulationId: json['event_accumulation_id'] as String?,
      groupAccumulatorTitle: json['group_accumulator_title'] as String?,
      groupAccumulatorTotalCount:
          (json['group_accumulator_total_count'] as num?)?.toInt(),
      groupAccumulatorTargetCount:
          (json['group_accumulator_target_count'] as num?)?.toInt(),
      groupAccumulatorImageJson:
          json['group_accumulator_image'] as Map<String, dynamic>?,
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }

  GroupEventInPersonCountList toEntity() {
    final imageJson = groupAccumulatorImageJson;
    return GroupEventInPersonCountList(
      items: items.map((item) => item.toEntity()).toList(),
      total: total,
      skip: skip,
      limit: limit,
      totalCount: totalCount,
      groupAccumulatorId: groupAccumulatorId,
      eventAccumulationId: eventAccumulationId,
      groupAccumulatorTitle: groupAccumulatorTitle,
      groupAccumulatorTotalCount: groupAccumulatorTotalCount,
      groupAccumulatorTargetCount: groupAccumulatorTargetCount,
      groupAccumulatorImage:
          imageJson == null ? null : ResponsiveImage.fromJson(imageJson),
      timezone: timezone,
    );
  }
}
