import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation.dart';

/// How the versions sheet lists its cards.
///
/// [pinned] is the first version whose text id matches the plan task's
/// `translation_text_id`. It is drawn above every language section and left
/// out of [groups]. Later cards with the same id stay in their sections.
class TranslationListOrder {
  const TranslationListOrder({required this.pinned, required this.groups});

  final SegmentTranslation? pinned;
  final List<MapEntry<String, List<SegmentTranslation>>> groups;
}

TranslationListOrder orderTranslations({
  required List<SegmentTranslation> translations,
  required String textLanguage,
  String? translationTextId,
}) {
  final id = translationTextId?.trim();
  SegmentTranslation? pinned;
  if (id != null && id.isNotEmpty) {
    for (final translation in translations) {
      if (translation.textId == id) {
        pinned = translation;
        break;
      }
    }
  }

  final grouped = <String, List<SegmentTranslation>>{};
  for (final translation in translations) {
    if (identical(translation, pinned)) continue;
    grouped.putIfAbsent(translation.language, () => []).add(translation);
  }
  final groups = grouped.entries.toList();
  groups.sort((a, b) {
    final aFirst = a.key == textLanguage ? 0 : 1;
    final bFirst = b.key == textLanguage ? 0 : 1;
    if (aFirst != bFirst) return aFirst.compareTo(bFirst);
    return a.key.compareTo(b.key);
  });
  return TranslationListOrder(pinned: pinned, groups: groups);
}
