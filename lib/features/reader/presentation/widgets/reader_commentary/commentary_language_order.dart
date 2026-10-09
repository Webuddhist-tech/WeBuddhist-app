/// Language-section order for the commentary list.
///
/// The text's own language always comes first, even when that segment has
/// none (the section then says so). The rest follow A→Z.
///
/// Chinese (`zh` / `lzh`) stays a pair: on a Chinese text the partner is
/// always listed second, even when empty; otherwise `zh` is kept
/// immediately after `lzh`.
List<String> orderedCommentaryLanguageCodes({
  required Iterable<String> languages,
  required String textLanguage,
}) {
  final present = languages.toSet();

  if (_chinesePair.contains(textLanguage)) {
    final partner = textLanguage == 'zh' ? 'lzh' : 'zh';
    final others =
        present.where((code) => !_chinesePair.contains(code)).toList()..sort();
    return [textLanguage, partner, ...others];
  }

  final others = present.where((code) => code != textLanguage).toList()..sort();
  _keepChinesePairAdjacent(others);
  return [textLanguage, ...others];
}

const _chinesePair = {'zh', 'lzh'};

void _keepChinesePairAdjacent(List<String> codes) {
  if (!codes.contains('lzh') || !codes.contains('zh')) return;
  codes.remove('zh');
  codes.insert(codes.indexOf('lzh') + 1, 'zh');
}
