import 'package:flutter_pecha/features/library/data/models/library_json.dart';

/// A text from `GET /v2/texts`.
class LibraryText {
  final String id;
  final Map<String, String> title;
  final String language;
  final String? commentaryOf;
  final String? translationOf;
  final String? license;
  final List<String> editions;
  final List<String> translations;
  final List<String> commentaries;
  final List<String> tagIds;

  const LibraryText({
    required this.id,
    required this.title,
    required this.language,
    this.commentaryOf,
    this.translationOf,
    this.license,
    this.editions = const [],
    this.translations = const [],
    this.commentaries = const [],
    this.tagIds = const [],
  });

  factory LibraryText.fromJson(Map<String, dynamic> json) {
    return LibraryText(
      id: json['id'] as String,
      title: stringMapFromJson(json['title']),
      language: json['language'] as String? ?? '',
      commentaryOf: json['commentary_of'] as String?,
      translationOf: json['translation_of'] as String?,
      license: json['license'] as String?,
      editions: stringListFromJson(json['editions']),
      translations: stringListFromJson(json['translations']),
      commentaries: stringListFromJson(json['commentaries']),
      tagIds: stringListFromJson(json['tag_ids']),
    );
  }

  /// Title in the text's own language, else any title, else empty.
  String get displayTitle {
    final own = title[language];
    if (own != null && own.isNotEmpty) return own;
    return title.values.isEmpty ? '' : title.values.first;
  }

  String? get primaryEditionId => editions.isEmpty ? null : editions.first;

  /// Commentaries are the only related texts not shown as versions.
  bool get isCommentary => commentaryOf != null && commentaryOf!.isNotEmpty;

  bool get isTranslation => translationOf != null && translationOf!.isNotEmpty;

  @override
  bool operator ==(Object other) => other is LibraryText && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class LibraryTextPage {
  final List<LibraryText> items;
  final bool hasMore;
  final int offset;
  final int limit;

  const LibraryTextPage({
    required this.items,
    required this.hasMore,
    required this.offset,
    required this.limit,
  });

  factory LibraryTextPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return LibraryTextPage(
      items:
          rawItems
              .whereType<Map<String, dynamic>>()
              .map(LibraryText.fromJson)
              .toList(growable: false),
      hasMore: json['has_more'] as bool? ?? false,
      offset: json['offset'] as int? ?? 0,
      limit: json['limit'] as int? ?? rawItems.length,
    );
  }
}
