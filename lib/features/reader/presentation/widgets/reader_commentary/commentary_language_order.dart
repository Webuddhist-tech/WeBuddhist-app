/// Language-section order for the commentary list.
///
/// The text's own language comes first. Chinese (`zh` / `lzh`) stays a pair:
/// on a Chinese text the partner is always listed, even when that segment has
/// none; otherwise `zh` is kept immediately after `lzh`.
///
/// When [pinEnglish] is set and this segment has English commentaries, `en`
/// is placed first. An empty English section is never inserted.
List<String> orderedCommentaryLanguageCodes({
  required Iterable<String> languages,
  required String textLanguage,
  required bool pinEnglish,
}) {
  final present = languages.toSet();
  final showEnglishFirst = pinEnglish && present.contains('en');

  if (_chinesePair.contains(textLanguage)) {
    final partner = textLanguage == 'zh' ? 'lzh' : 'zh';
    final ordered = <String>[if (showEnglishFirst) 'en', textLanguage, partner];
    final reserved = <String>{..._chinesePair, if (showEnglishFirst) 'en'};
    final others =
        present.where((code) => !reserved.contains(code)).toList()..sort();
    return [...ordered, ...others];
  }

  final ordered = <String>[
    if (showEnglishFirst && textLanguage != 'en') 'en',
    if (textLanguage != 'en' || present.contains('en')) textLanguage,
  ];
  final reserved = <String>{textLanguage, if (showEnglishFirst) 'en'};
  final others =
      present.where((code) => !reserved.contains(code)).toList()..sort();
  _keepChinesePairAdjacent(others);
  return [...ordered, ...others];
}

const _chinesePair = {'zh', 'lzh'};

void _keepChinesePairAdjacent(List<String> codes) {
  if (!codes.contains('lzh') || !codes.contains('zh')) return;
  codes.remove('zh');
  codes.insert(codes.indexOf('lzh') + 1, 'zh');
}
