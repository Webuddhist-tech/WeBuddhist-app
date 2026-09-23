/// A row of `GET /v2/languages`.
class LibraryLanguage {
  final String code;
  final String name;

  const LibraryLanguage({required this.code, required this.name});

  factory LibraryLanguage.fromJson(Map<String, dynamic> json) {
    return LibraryLanguage(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
