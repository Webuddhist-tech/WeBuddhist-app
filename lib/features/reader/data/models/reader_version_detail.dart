class ReaderVersionDetail {
  final String id;
  final String title;
  final String? parentId;
  final int? priority;
  final String language;
  final String? type;
  final String? groupId;
  final List<String> tableOfContents;
  final bool isPublished;
  final String? createdDate;
  final String? updatedDate;
  final String? publishedDate;
  final String? publishedBy;
  final String? sourceLink;
  final int? ranking;
  final String? license;
  final bool isSelected;

  /// A root text (neither a translation nor a commentary): an original, never
  /// offered as a translation.
  final bool isRoot;

  const ReaderVersionDetail({
    required this.id,
    required this.title,
    this.parentId,
    this.priority,
    required this.language,
    this.type,
    this.groupId,
    this.tableOfContents = const [],
    this.isPublished = true,
    this.createdDate,
    this.updatedDate,
    this.publishedDate,
    this.publishedBy,
    this.sourceLink,
    this.ranking,
    this.license,
    this.isSelected = false,
    this.isRoot = false,
  });

  factory ReaderVersionDetail.fromJson(Map<String, dynamic> json) {
    return ReaderVersionDetail(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      priority: json['priority'] as int?,
      language: json['language'] as String? ?? '',
      type: json['type'] as String?,
      groupId: json['group_id'] as String?,
      tableOfContents: (json['table_of_contents'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      isPublished: json['is_published'] as bool? ?? true,
      createdDate: json['created_date'] as String?,
      updatedDate: json['updated_date'] as String?,
      publishedDate: json['published_date'] as String?,
      publishedBy: json['published_by'] as String?,
      sourceLink: json['source_link'] as String?,
      ranking: json['ranking'] as int?,
      license: json['license'] as String?,
      isSelected: json['is_selected'] as bool? ?? false,
    );
  }
}

class ReaderVersionsResponse {
  final String textId;
  final String language;
  final List<ReaderVersionDetail> availableVersions;

  const ReaderVersionsResponse({
    required this.textId,
    required this.language,
    required this.availableVersions,
  });

  factory ReaderVersionsResponse.fromJson(Map<String, dynamic> json) {
    return ReaderVersionsResponse(
      textId: json['text_id'] as String? ?? '',
      language: json['language'] as String? ?? '',
      availableVersions: (json['available_versions'] as List<dynamic>? ?? [])
          .map((e) => ReaderVersionDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
