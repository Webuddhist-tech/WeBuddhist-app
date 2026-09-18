import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

/// Response from `GET /users/me/bookmarks/exists`.
class BookmarkExistsResult {
  final bool exists;
  final String? id;

  const BookmarkExistsResult({required this.exists, this.id});

  factory BookmarkExistsResult.fromJson(Map<String, dynamic> json) {
    return BookmarkExistsResult(
      exists: json['exists'] as bool? ?? false,
      id: json['id'] as String?,
    );
  }
}

/// Models for `GET /users/me/bookmarks`.
///
/// Each row embeds a bookmark-specific object for its type (`text` / `plan` /
/// `series` / `accumulator` / `timer`) carrying the title, single image URL,
/// and dates needed to render a rich card. The response is paginated
/// (`total` / `skip` / `limit`).

/// Every bookmark kind the API can return.
///
/// Note the create endpoint ([BookmarkType]) only supports a subset; this
/// fuller enum is used purely for decoding the list response.
enum BookmarkItemType {
  text,
  plan,
  series,
  accumulator,
  timer,
  verse,
  groupRecitationCollection,
  recitationCollection,
  groupAccumulator;

  static BookmarkItemType? tryFromJson(String? value) => switch (value) {
    'TEXT' => BookmarkItemType.text,
    'PLAN' => BookmarkItemType.plan,
    'SERIES' => BookmarkItemType.series,
    'ACCUMULATOR' => BookmarkItemType.accumulator,
    'TIMER' => BookmarkItemType.timer,
    'VERSE' => BookmarkItemType.verse,
    'GROUP_RECITATION_COLLECTION' => BookmarkItemType.groupRecitationCollection,
    'RECITATION_COLLECTION' => BookmarkItemType.recitationCollection,
    'GROUP_ACCUMULATOR' => BookmarkItemType.groupAccumulator,
    _ => null,
  };
}

/// A single saved bookmark, flattened from the type-specific nested object.
class BookmarkDTO {
  /// Bookmark id — the key for `DELETE /users/me/bookmarks/{id}`.
  final String id;
  final BookmarkItemType type;

  /// Id of the bookmarked entity (text, plan, series, timer, …).
  final String sourceId;
  final String? name;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Title from the nested object, preferred over [name].
  final String? nestedTitle;

  /// Verse excerpt (`text.segment.content`).
  final String? excerpt;

  /// Single cover/bead image URL (plan/series cover or accumulator bead).
  final String? imageUrl;

  /// Schedule window for PLAN / SERIES bookmarks (drives the date-range label).
  final DateTime? startDate;
  final DateTime? endDate;

  /// Text id for reader navigation (`text.id`).
  final String? textId;

  /// Duration (ms) for TIMER bookmarks — enough to open the timer.
  final int? timerDurationMs;

  /// Owning group id for GROUP_RECITATION_COLLECTION and GROUP_ACCUMULATOR
  /// bookmarks. Required to open group collections, whose endpoints are all
  /// scoped by group.
  final String? groupId;

  /// Number of chants in a collection bookmark.
  final int? itemCount;

  /// True when the API returned the bookmark row without its type-specific
  /// enrichment object, which means the source content was deleted after the
  /// bookmark was created.
  final bool isOrphaned;

  const BookmarkDTO({
    required this.id,
    required this.type,
    required this.sourceId,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.nestedTitle,
    this.excerpt,
    this.imageUrl,
    this.startDate,
    this.endDate,
    this.textId,
    this.timerDurationMs,
    this.groupId,
    this.itemCount,
    this.isOrphaned = false,
  });

  /// Lenient parser: returns `null` when the payload is missing required fields
  /// or carries a type this build doesn't understand, so one bad row can't
  /// break the whole list.
  static BookmarkDTO? tryFromJson(Map<String, dynamic> json) {
    final type = BookmarkItemType.tryFromJson(json['type'] as String?);
    final id = json['id'] as String?;
    final sourceId = json['source_id'] as String?;
    final createdAt = _parseDate(json['created_at']);
    if (type == null || id == null || sourceId == null || createdAt == null) {
      return null;
    }

    final text = json['text'] as Map<String, dynamic>?;
    final plan = json['plan'] as Map<String, dynamic>?;
    final series = json['series'] as Map<String, dynamic>?;
    final accumulator = json['accumulator'] as Map<String, dynamic>?;
    final timer = json['timer'] as Map<String, dynamic>?;
    final groupCollection =
        json['group_recitation_collection'] as Map<String, dynamic>?;
    final recitationCollection =
        json['recitation_collection'] as Map<String, dynamic>?;
    // Title, image and item count read from whichever kind is present — the
    // two payloads carry the same shape for those. `group_id` deliberately
    // does NOT: only a group collection has one, and reading it from the
    // merged value would hand a personal row a group id it has no business
    // carrying.
    final collection = groupCollection ?? recitationCollection;
    final groupAccumulator = json['group_accumulator'] as Map<String, dynamic>?;

    final planMeta = plan?['metadata'] as Map<String, dynamic>?;
    final segment = text?['segment'] as Map<String, dynamic>?;

    DateTime? startDate;
    DateTime? endDate;
    if (plan != null) {
      startDate = _parseDate(plan['start_date']);
      endDate = _parseDate(plan['end_date']);
    } else if (series != null) {
      startDate = _parseDate(series['start_date']);
      endDate = _parseDate(series['end_date']);
    }

    return BookmarkDTO(
      id: id,
      type: type,
      sourceId: sourceId,
      name: json['name'] as String?,
      createdAt: createdAt,
      updatedAt: _parseDate(json['updated_at']) ?? createdAt,
      nestedTitle:
          (text?['title'] as String?) ??
          (planMeta?['title'] as String?) ??
          _seriesTitle(series) ??
          (accumulator?['title'] as String?) ??
          (timer?['title'] as String?) ??
          (collection?['title'] as String?) ??
          (collection?['name'] as String?) ??
          (groupAccumulator?['title'] as String?),
      excerpt: segment?['content'] as String?,
      // Group collections serialize their cover under `image`/`image_url`,
      // personal ones under `img_url`; try each before giving up.
      imageUrl:
          (plan?['image'] as String?) ??
          (series?['image'] as String?) ??
          (accumulator?['image'] as String?) ??
          ImageModel.fromFields(
            image: collection?['image'],
            imageUrl: collection?['image_url'] as String?,
          )?.displayUrl ??
          (collection?['img_url'] as String?) ??
          ImageModel.fromFields(image: groupAccumulator?['image'])?.displayUrl,
      startDate: startDate,
      endDate: endDate,
      textId: text?['id'] as String?,
      timerDurationMs: (timer?['duration'] as num?)?.toInt(),
      groupId:
          (groupCollection?['group_id'] as String?) ??
          (groupAccumulator?['group_id'] as String?),
      itemCount: (collection?['item_count'] as num?)?.toInt(),
      isOrphaned:
          (type == BookmarkItemType.groupRecitationCollection &&
              groupCollection == null) ||
          (type == BookmarkItemType.recitationCollection &&
              recitationCollection == null) ||
          (type == BookmarkItemType.groupAccumulator &&
              groupAccumulator == null),
    );
  }

  bool get isText =>
      type == BookmarkItemType.text || type == BookmarkItemType.verse;

  /// Title shown on the card, preferring the nested object's title and falling
  /// back to [name], then a type label.
  String get displayTitle {
    final preferred = nestedTitle ?? name;
    if (preferred != null && preferred.trim().isNotEmpty) {
      return preferred.trim();
    }
    return switch (type) {
      BookmarkItemType.timer => 'Timer',
      BookmarkItemType.text || BookmarkItemType.verse => 'Untitled text',
      BookmarkItemType.plan => 'Plan',
      BookmarkItemType.series => 'Series',
      BookmarkItemType.accumulator => 'Mala',
      BookmarkItemType.groupRecitationCollection ||
      BookmarkItemType.recitationCollection => 'Chant collection',
      BookmarkItemType.groupAccumulator => 'Group accumulation',
    };
  }

  /// Whether this bookmark can still be opened. Neither collection kind may be
  /// orphaned; a group collection additionally needs its group id, because
  /// every group-collection endpoint is group-scoped. A personal collection is
  /// reachable from its id alone.
  bool get isOpenable => switch (type) {
    BookmarkItemType.plan => false,
    BookmarkItemType.groupRecitationCollection =>
      !isOrphaned && (groupId?.isNotEmpty ?? false),
    BookmarkItemType.recitationCollection => !isOrphaned,
    BookmarkItemType.groupAccumulator => !isOrphaned,
    _ => true,
  };

  /// Leading artwork, if any. Accumulators render as a round bead; plans and
  /// series render as a rounded square.
  ResponsiveImage? get leadingImage {
    final url = imageUrl;
    return (url != null && url.isNotEmpty) ? ResponsiveImage.uniform(url) : null;
  }

  bool get isRoundLeading => type == BookmarkItemType.accumulator;

  // ─── Parse helpers ───

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// Series metadata may be a single object or a (localized) array.
  static String? _seriesTitle(Map<String, dynamic>? series) {
    final meta = series?['metadata'];
    if (meta is Map) return meta['title'] as String?;
    if (meta is List && meta.isNotEmpty && meta.first is Map) {
      return (meta.first as Map)['title'] as String?;
    }
    return null;
  }
}

/// Wrapper for the paginated `{ "bookmarks": [...], "total", "skip", "limit" }`
/// response body.
class BookmarksResponse {
  final List<BookmarkDTO> bookmarks;
  final int total;
  final int skip;
  final int limit;

  const BookmarksResponse({
    required this.bookmarks,
    this.total = 0,
    this.skip = 0,
    this.limit = 0,
  });

  factory BookmarksResponse.fromJson(Map<String, dynamic> json) {
    final raw = (json['bookmarks'] as List<dynamic>?) ?? const [];
    return BookmarksResponse(
      bookmarks:
          raw
              .whereType<Map<String, dynamic>>()
              .map(BookmarkDTO.tryFromJson)
              .whereType<BookmarkDTO>()
              .toList(),
      total: (json['total'] as num?)?.toInt() ?? raw.length,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? raw.length,
    );
  }
}
