import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc.dart';

class ReaderResponse {
  final TextDetail textDetail;
  final Toc content;
  final int size;
  final String paginationDirection;
  final int currentSegmentPosition;

  /// Position of the page's last segment. Null in responses cached before it
  /// existed; [hasNextPage] then falls back to the page's first position.
  final int? lastSegmentPosition;
  final int totalSegments;

  ReaderResponse({
    required this.textDetail,
    required this.content,
    required this.size,
    required this.paginationDirection,
    required this.currentSegmentPosition,
    this.lastSegmentPosition,
    required this.totalSegments,
  });

  /// Whether segments exist after this page. Measured from its last segment,
  /// so the page that reaches the end does not ask for one more.
  bool get hasNextPage =>
      (lastSegmentPosition ?? currentSegmentPosition) < totalSegments;

  factory ReaderResponse.fromJson(Map<String, dynamic> json) {
    return ReaderResponse(
      textDetail: TextDetail.fromJson(json['text_detail']),
      content: Toc.fromJson(json['content']),
      size: json['size'],
      paginationDirection: json['pagination_direction'],
      currentSegmentPosition: json['current_segment_position'],
      lastSegmentPosition: json['last_segment_position'] as int?,
      totalSegments: json['total_segments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text_detail': textDetail.toJson(),
      'content': content.toJson(),
      'size': size,
      'pagination_direction': paginationDirection,
      'current_segment_position': currentSegmentPosition,
      if (lastSegmentPosition != null)
        'last_segment_position': lastSegmentPosition,
      'total_segments': totalSegments,
    };
  }
}
