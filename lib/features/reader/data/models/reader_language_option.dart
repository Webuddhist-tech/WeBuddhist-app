class ReaderLanguageOption {
  final String code;
  final String label;
  final int versionCount;

  /// Versions that can be picked as a translation: [versionCount] less the
  /// root texts, which are only ever the original.
  final int translationCount;

  const ReaderLanguageOption({
    required this.code,
    required this.label,
    required this.versionCount,
    int? translationCount,
  }) : translationCount = translationCount ?? versionCount;

  factory ReaderLanguageOption.fromJson(Map<String, dynamic> json) {
    return ReaderLanguageOption(
      code: json['language_code'] as String? ?? '',
      label: json['language'] as String? ?? '',
      versionCount: json['version_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'language_code': code,
        'language': label,
        'version_count': versionCount,
      };
}

class ReaderLanguagesResponse {
  final String textId;
  final String? title;
  final List<ReaderLanguageOption> availableLanguages;

  const ReaderLanguagesResponse({
    required this.textId,
    required this.title,
    required this.availableLanguages,
  });

  factory ReaderLanguagesResponse.fromJson(Map<String, dynamic> json) {
    return ReaderLanguagesResponse(
      textId: json['text_id'] as String? ?? '',
      title: json['title'] as String?,
      availableLanguages: (json['available_languages'] as List<dynamic>? ?? [])
          .map((e) =>
              ReaderLanguageOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
