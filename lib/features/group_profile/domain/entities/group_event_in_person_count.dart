import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

/// A count made at an event in person, by people not using the app: one row
/// per day in the event's timezone, added to the linked group accumulation.
class GroupEventInPersonCount {
  final String id;

  /// YYYY-MM-DD in the event's timezone.
  final String day;
  final int count;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GroupEventInPersonCount({
    required this.id,
    required this.day,
    required this.count,
    this.createdAt,
    this.updatedAt,
  });

  /// The day as a calendar date, not an instant.
  DateTime get date {
    final parts = day.split('-').map(int.tryParse).toList();
    if (parts.length == 3 && !parts.contains(null)) {
      return DateTime(parts[0]!, parts[1]!, parts[2]!);
    }
    return DateTime.tryParse(day) ?? DateTime.now();
  }
}

/// One page of an accumulation's in-person counts with its totals.
class GroupEventInPersonCountList {
  final List<GroupEventInPersonCount> items;
  final int total;
  final int skip;
  final int limit;

  /// Sum of every in-person count in the group accumulation.
  final int totalCount;

  /// Null when the event has no group accumulation linked.
  final String? groupAccumulatorId;
  final String? eventAccumulationId;
  final String? groupAccumulatorTitle;

  /// Everyone's total, in-person counts included.
  final int? groupAccumulatorTotalCount;
  final int? groupAccumulatorTargetCount;
  final ResponsiveImage? groupAccumulatorImage;
  final String timezone;

  const GroupEventInPersonCountList({
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
    this.groupAccumulatorImage,
    required this.timezone,
  });

  bool get hasMore => skip + items.length < total;

  /// Counts logged through the app, the rest of the accumulation's total.
  int get appCount {
    final all = groupAccumulatorTotalCount;
    if (all == null) return 0;
    return all - totalCount < 0 ? 0 : all - totalCount;
  }
}
