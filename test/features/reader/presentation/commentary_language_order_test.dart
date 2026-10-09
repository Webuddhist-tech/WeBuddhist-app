import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/commentary_language_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> order({
    required List<String> languages,
    required String textLanguage,
  }) {
    return orderedCommentaryLanguageCodes(
      languages: languages,
      textLanguage: textLanguage,
    );
  }

  test('the text language comes first, the rest A to Z', () {
    expect(
      order(languages: ['en', 'sa', 'bo', 'lzh', 'zh'], textLanguage: 'bo'),
      ['bo', 'en', 'lzh', 'zh', 'sa'],
    );
  });

  test('English is not moved ahead of the text language', () {
    expect(order(languages: ['sa', 'bo', 'en'], textLanguage: 'bo'), [
      'bo',
      'en',
      'sa',
    ]);
  });

  test('the text language section stays when it has no commentaries', () {
    expect(order(languages: ['bo', 'sa'], textLanguage: 'en'), [
      'en',
      'bo',
      'sa',
    ]);
  });

  test('a Chinese text pins its partner second', () {
    expect(order(languages: ['bo', 'zh'], textLanguage: 'zh'), [
      'zh',
      'lzh',
      'bo',
    ]);
    expect(order(languages: ['sa', 'lzh', 'en'], textLanguage: 'lzh'), [
      'lzh',
      'zh',
      'en',
      'sa',
    ]);
  });
}
