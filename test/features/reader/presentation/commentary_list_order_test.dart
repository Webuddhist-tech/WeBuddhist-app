import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/commentary_list_order.dart';
import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary.dart';
import 'package:flutter_test/flutter_test.dart';

SegmentCommentary _card(
  String textId,
  String language, {
  List<SegmentCommentary> translations = const [],
}) {
  return SegmentCommentary(
    textId: textId,
    title: textId,
    segments: const [],
    language: language,
    count: 1,
    translations: translations,
  );
}

CommentaryListOrder _order(
  List<SegmentCommentary> commentaries, {
  String? commentaryTextId,
  String textLanguage = 'bo',
  bool pinEnglish = true,
}) {
  return orderCommentaries(
    commentaries: commentaries,
    textLanguage: textLanguage,
    pinEnglish: pinEnglish,
    commentaryTextId: commentaryTextId,
  );
}

void main() {
  test('a matching commentary sits above the language sections', () {
    final match = _card('wanted', 'bo');
    final order = _order([
      _card('en-1', 'en'),
      match,
      _card('bo-2', 'bo'),
    ], commentaryTextId: 'wanted');

    expect(order.pinned, same(match));
    expect(order.languageCodes.first, 'en');
    expect(order.byLanguage['bo']!.map((c) => c.textId), ['bo-2']);
  });

  test('a matching translation edition is the card that is pinned', () {
    final translation = _card('wanted', 'en');
    final parent = _card('parent', 'bo', translations: [translation]);
    final order = _order([parent], commentaryTextId: 'wanted');

    expect(order.pinned, same(translation));
    expect(order.byLanguage['bo']!.single.textId, 'parent');
    expect(order.byLanguage['en'], isNull);
  });

  test('only the first card with that text id is pinned', () {
    final first = _card('wanted', 'bo');
    final second = _card('wanted', 'en');
    final order = _order([first, second], commentaryTextId: 'wanted');

    expect(order.pinned, same(first));
    expect(order.byLanguage['en']!.single, same(second));
  });

  test('a missing or blank id leaves the existing order', () {
    final commentaries = [_card('en-1', 'en'), _card('bo-1', 'bo')];

    for (final id in [null, '', '   ']) {
      final order = _order(commentaries, commentaryTextId: id);
      expect(order.pinned, isNull);
      expect(order.byLanguage['en']!.single.textId, 'en-1');
      expect(order.byLanguage['bo']!.single.textId, 'bo-1');
    }
  });

  test('no match leaves every card in its language section', () {
    final order = _order([
      _card('en-1', 'en'),
      _card('bo-1', 'bo'),
    ], commentaryTextId: 'missing');

    expect(order.pinned, isNull);
    expect(order.languageCodes, ['en', 'bo']);
  });
}
