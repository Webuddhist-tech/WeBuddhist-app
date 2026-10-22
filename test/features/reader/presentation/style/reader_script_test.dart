import 'package:flutter_pecha/features/reader/presentation/style/reader_script.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the script from the letters', () {
    expect(ReaderScript.of('སྒྲོལ་མ་ལ་ཕྱག་འཚལ་ལོ།'), ReaderScript.tibetan);
    expect(ReaderScript.of('二十一度母禮讚文'), ReaderScript.chinese);
    expect(ReaderScript.of('नमो तारायै'), ReaderScript.devanagari);
    expect(ReaderScript.of('Дарь эхэд мөргөе'), ReaderScript.cyrillic);
    expect(ReaderScript.of('om je tsün ma pak ma drölma'), ReaderScript.latin);
    expect(ReaderScript.of('Āryā Tārā'), ReaderScript.latin);
  });

  test('a transliterated line is its target script, not its language', () {
    expect(
      ReaderScript.of('नमो तारायै', language: 'bo'),
      ReaderScript.devanagari,
    );
    expect(ReaderScript.of('om tare tuttare', language: 'bo'), ReaderScript.latin);
  });

  test('tags, class names and entities do not vote', () {
    expect(
      ReaderScript.of(
        '<span class="yigchung">སྒྲོལ་མ</span>&nbsp;<br/>ཕྱག',
      ),
      ReaderScript.tibetan,
    );
  });

  test('a line with no letters takes its language\'s script', () {
    expect(ReaderScript.of('1.12 ། ', language: 'bo'), ReaderScript.tibetan);
    expect(ReaderScript.of('', language: 'zh-Hant'), ReaderScript.chinese);
    expect(ReaderScript.of(null, language: 'mn'), ReaderScript.cyrillic);
    expect(ReaderScript.of(null, language: 'hi'), ReaderScript.devanagari);
    expect(ReaderScript.of(null), ReaderScript.latin);
  });
}
