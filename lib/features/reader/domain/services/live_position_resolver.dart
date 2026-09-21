import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_live_position.dart';

/// Decides whether a live position belongs to the text the reader shows.
class LivePositionResolver {
  const LivePositionResolver._();

  /// True when [position] is in the text on screen. The text id is compared
  /// against every id the reader knows for it — the navigated id, the loaded
  /// detail id, a picked version — and a segment that resolves in [content]
  /// settles it even when the ids differ (another language of the same text).
  static bool textMatches(
    RecitationLivePosition position, {
    required Iterable<String?> loadedTextIds,
    FlattenedContent? content,
  }) {
    for (final id in loadedTextIds) {
      if (id != null && id.isNotEmpty && id == position.textId) return true;
    }
    return content?.resolveSegmentIndex(position.segmentId) != null;
  }
}
