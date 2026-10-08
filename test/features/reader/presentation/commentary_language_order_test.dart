import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/commentary_language_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> order({
    required List<String> languages,
    required String textLanguage,
    required bool pinEnglish,
  }) {
    return orderedCommentaryLanguageCodes(
      languages: languages,
      textLanguage: textLanguage,
      pinEnglish: pinEnglish,
    );
  }

  test('a non-English UI keeps the text language first', () {
    expect(
      order(
        languages: ['en', 'sa', 'bo', 'lzh', 'zh'],
        textLanguage: 'bo',
        pinEnglish: false,
      ),
      ['bo', 'en', 'lzh', 'zh', 'sa'],
    );
  });

  test('an English UI puts English commentaries first, then the text', () {
    expect(
      order(
        languages: ['sa', 'bo', 'en', 'lzh', 'zh'],
        textLanguage: 'bo',
        pinEnglish: true,
      ),
      ['en', 'bo', 'lzh', 'zh', 'sa'],
    );
  });

  test('an English UI does not insert an empty English section', () {
    expect(
      order(
        languages: ['sa', 'bo', 'zh', 'lzh'],
        textLanguage: 'bo',
        pinEnglish: true,
      ),
      ['bo', 'lzh', 'zh', 'sa'],
    );
  });

  test('an English text leads with English when commentaries exist', () {
    expect(
      order(
        languages: ['bo', 'en', 'zh', 'lzh'],
        textLanguage: 'en',
        pinEnglish: true,
      ),
      ['en', 'bo', 'lzh', 'zh'],
    );
  });

  test('an English text with no English commentaries skips that section', () {
    expect(
      order(languages: ['bo', 'sa'], textLanguage: 'en', pinEnglish: true),
      ['bo', 'sa'],
    );
  });

  test(
    'a Chinese text still pins its partner, with English ahead when set',
    () {
      expect(
        order(languages: ['bo', 'zh'], textLanguage: 'zh', pinEnglish: false),
        ['zh', 'lzh', 'bo'],
      );
      expect(
        order(
          languages: ['bo', 'zh', 'en'],
          textLanguage: 'zh',
          pinEnglish: true,
        ),
        ['en', 'zh', 'lzh', 'bo'],
      );
      expect(
        order(
          languages: ['sa', 'lzh', 'en'],
          textLanguage: 'lzh',
          pinEnglish: true,
        ),
        ['en', 'lzh', 'zh', 'sa'],
      );
    },
  );

  test('a Chinese text without English commentaries keeps the pair on top', () {
    expect(
      order(languages: ['bo', 'zh'], textLanguage: 'zh', pinEnglish: true),
      ['zh', 'lzh', 'bo'],
    );
  });
}
