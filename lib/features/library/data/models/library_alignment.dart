import 'package:flutter_pecha/features/library/data/models/library_page.dart';
import 'package:flutter_pecha/features/library/data/models/library_segment.dart';

/// One pair of `/v2/editions/{source}/alignments/{target}`.
class LibraryAlignment {
  final LibrarySegment source;
  final LibrarySegment target;

  const LibraryAlignment({required this.source, required this.target});

  factory LibraryAlignment.fromJson(Map<String, dynamic> json) {
    return LibraryAlignment(
      source: LibrarySegment.fromJson(
        json['source_segment'] as Map<String, dynamic>,
      ),
      target: LibrarySegment.fromJson(
        json['target_segment'] as Map<String, dynamic>,
      ),
    );
  }
}

class LibraryAlignmentPage implements LibraryPage<LibraryAlignment> {
  @override
  final List<LibraryAlignment> items;
  @override
  final bool hasMore;
  final int offset;
  final int limit;

  const LibraryAlignmentPage({
    required this.items,
    required this.hasMore,
    required this.offset,
    required this.limit,
  });

  factory LibraryAlignmentPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return LibraryAlignmentPage(
      items:
          rawItems
              .whereType<Map<String, dynamic>>()
              .where(
                (p) =>
                    p['source_segment'] is Map<String, dynamic> &&
                    p['target_segment'] is Map<String, dynamic>,
              )
              .map(LibraryAlignment.fromJson)
              .toList(growable: false),
      hasMore: json['has_more'] as bool? ?? false,
      offset: json['offset'] as int? ?? 0,
      limit: json['limit'] as int? ?? rawItems.length,
    );
  }
}
