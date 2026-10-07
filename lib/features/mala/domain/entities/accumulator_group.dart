import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

/// A group accumulator linked to a preset, from
/// `GET /accumulators/{accumulator_id}/groups`.
class AccumulatorGroup extends Equatable {
  const AccumulatorGroup({
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

  /// The accumulation's own stored title; not localized by the API.
  final String? title;

  /// Name of the owning group (`group_name`), localized by the request's
  /// `language`. Null when the group is not published.
  final String? groupName;

  /// Title of the latest event linking this accumulation (`event_title`),
  /// localized by the request's `language`. Null when no event links it.
  final String? eventTitle;
  final ResponsiveImage? image;
  /// User's lifetime total for this group accumulator (`user_total_count` from
  /// `GET /accumulators/{id}/groups`). Shown in [GroupAccumulationsSheet].
  /// Active session counting uses [joinedGroupUserCountsProvider] instead.
  final int userTotalCount;

  /// Lifetime total from every member (`group_total_count`), the user's own
  /// synced count included.
  final int groupTotalCount;
  final bool isJoined;

  @override
  List<Object?> get props => [
    groupAccumulatorId,
    groupId,
    title,
    groupName,
    eventTitle,
    image,
    userTotalCount,
    groupTotalCount,
    isJoined,
  ];
}
