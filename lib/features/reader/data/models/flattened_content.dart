import 'package:flutter_pecha/features/reader/data/models/flattened_item.dart';

/// Represents flattened content for the reader
/// Contains a flat list of items and a map for O(1) segment lookups
class FlattenedContent {
  final List<FlattenedItem> items;
  final Map<String, int> segmentIndexMap;
  final int totalSegments;

  const FlattenedContent({
    required this.items,
    required this.segmentIndexMap,
    required this.totalSegments,
  });

  /// Creates an empty flattened content
  factory FlattenedContent.empty() {
    return const FlattenedContent(
      items: [],
      segmentIndexMap: {},
      totalSegments: 0,
    );
  }

  /// Get the index of a segment by its ID in O(1) time
  int? getSegmentIndex(String segmentId) => segmentIndexMap[segmentId];

  /// Check if a segment exists in the content
  bool containsSegment(String segmentId) =>
      segmentIndexMap.containsKey(segmentId);

  /// Index of the segment whose `mappings` name [segmentId]: the same line
  /// in another language. Linear, only used after [getSegmentIndex] misses.
  int? findSegmentIndexByAlias(String segmentId) {
    for (var i = 0; i < items.length; i++) {
      final segment = items[i].segment;
      if (segment != null && segment.mappedSegmentIds.contains(segmentId)) {
        return i;
      }
    }
    return null;
  }

  /// [getSegmentIndex], falling back to [findSegmentIndexByAlias].
  int? resolveSegmentIndex(String segmentId) =>
      getSegmentIndex(segmentId) ?? findSegmentIndexByAlias(segmentId);

  /// Check if the content is empty
  bool get isEmpty => items.isEmpty;

  /// Check if the content is not empty
  bool get isNotEmpty => items.isNotEmpty;

  /// Get the number of items
  int get itemCount => items.length;

  /// Get the first segment ID
  String? get firstSegmentId {
    for (final item in items) {
      if (item.isSegment) {
        return item.segmentId;
      }
    }
    return null;
  }

  /// Get the last segment ID
  String? get lastSegmentId {
    for (int i = items.length - 1; i >= 0; i--) {
      if (items[i].isSegment) {
        return items[i].segmentId;
      }
    }
    return null;
  }

  /// Get a segment item by index
  FlattenedItem? getItemAt(int index) {
    if (index < 0 || index >= items.length) return null;
    return items[index];
  }

  /// Get a segment by its ID
  FlattenedItem? getSegmentById(String segmentId) {
    final index = getSegmentIndex(segmentId);
    if (index == null) return null;
    return items[index];
  }

  FlattenedContent copyWith({
    List<FlattenedItem>? items,
    Map<String, int>? segmentIndexMap,
    int? totalSegments,
  }) {
    return FlattenedContent(
      items: items ?? this.items,
      segmentIndexMap: segmentIndexMap ?? this.segmentIndexMap,
      totalSegments: totalSegments ?? this.totalSegments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlattenedContent &&
        other.totalSegments == totalSegments &&
        other.items.length == items.length;
  }

  @override
  int get hashCode => Object.hash(items.length, totalSegments);

  @override
  String toString() {
    return 'FlattenedContent(items: ${items.length}, totalSegments: $totalSegments)';
  }
}
