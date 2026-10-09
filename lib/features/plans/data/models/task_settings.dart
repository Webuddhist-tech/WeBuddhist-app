/// Reader hints on a plan task, from `settings` on a plan-day task.
///
/// Commentary fields drive the reader now. Translation and live are parsed
/// so a cached day keeps them until those behaviors are wired.
class TaskSettings {
  final bool isCommentaryOpen;
  final String? commentaryTextId;
  final bool isTranslationOpen;
  final String? translationTextId;
  final bool isLive;

  const TaskSettings({
    this.isCommentaryOpen = false,
    this.commentaryTextId,
    this.isTranslationOpen = false,
    this.translationTextId,
    this.isLive = false,
  });

  static TaskSettings? tryParse(Object? value) {
    if (value is! Map) return null;
    return TaskSettings.fromJson(Map<String, dynamic>.from(value));
  }

  factory TaskSettings.fromJson(Map<String, dynamic> json) {
    return TaskSettings(
      isCommentaryOpen: json['is_commentary_open'] == true,
      commentaryTextId: _nonBlank(json['commentary_text_id']),
      isTranslationOpen: json['is_translation_open'] == true,
      translationTextId: _nonBlank(json['translation_text_id']),
      isLive: json['is_live'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_commentary_open': isCommentaryOpen,
      'commentary_text_id': commentaryTextId,
      'is_translation_open': isTranslationOpen,
      'translation_text_id': translationTextId,
      'is_live': isLive,
    };
  }

  static String? _nonBlank(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
