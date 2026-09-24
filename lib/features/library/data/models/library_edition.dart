/// An edition from `GET /v2/editions/{id}`; [source] feeds the panel metadata.
class LibraryEdition {
  final String id;
  final String textId;
  final String? type;
  final String? source;

  const LibraryEdition({
    required this.id,
    required this.textId,
    this.type,
    this.source,
  });

  factory LibraryEdition.fromJson(Map<String, dynamic> json) {
    return LibraryEdition(
      id: json['id'] as String,
      textId: json['text_id'] as String? ?? '',
      type: json['type'] as String?,
      source: json['source'] as String?,
    );
  }
}
