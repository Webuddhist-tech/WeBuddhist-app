import 'package:flutter_pecha/features/reader/presentation/widgets/reader_translation/translation_list_order.dart';
import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation.dart';
import 'package:flutter_test/flutter_test.dart';

SegmentTranslation _card(String textId, String language) {
  return SegmentTranslation(
    textId: textId,
    title: textId,
    language: language,
    segments: const [],
  );
}

void main() {
  test('a matching version sits above the language sections', () {
    final match = _card('wanted', 'en');
    final order = orderTranslations(
      translations: [_card('bo-1', 'bo'), match, _card('en-2', 'en')],
      textLanguage: 'bo',
      translationTextId: 'wanted',
    );

    expect(order.pinned, same(match));
    expect(order.groups.first.key, 'bo');
    expect(order.groups.last.value.map((t) => t.textId), ['en-2']);
  });

  test('only the first card with that text id is pinned', () {
    final first = _card('wanted', 'bo');
    final second = _card('wanted', 'en');
    final order = orderTranslations(
      translations: [first, second],
      textLanguage: 'bo',
      translationTextId: 'wanted',
    );

    expect(order.pinned, same(first));
    expect(order.groups.single.value.single, same(second));
  });

  test('a missing id leaves the text language first', () {
    final order = orderTranslations(
      translations: [_card('en-1', 'en'), _card('bo-1', 'bo')],
      textLanguage: 'bo',
    );

    expect(order.pinned, isNull);
    expect(order.groups.map((g) => g.key), ['bo', 'en']);
  });
}
