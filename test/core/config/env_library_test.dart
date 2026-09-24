import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Env library settings', () {
    test('reads the configured values', () {
      dotenv.testLoad(
        fileInput:
            'LIBRARY_API_URL=https://lib.test\nLIBRARY_CHANTS_TAG_ID=chants\n',
      );
      expect(Env.libraryApiUrl, 'https://lib.test');
      expect(Env.libraryChantsTagId, 'chants');
    });

    // An unset CI secret is written as `KEY=`, not left out.
    test('a blank value counts as missing', () {
      dotenv.testLoad(fileInput: 'LIBRARY_API_URL=\nLIBRARY_CHANTS_TAG_ID=\n');
      expect(Env.libraryApiUrl, 'https://library.webuddhist.com');
      expect(() => Env.libraryChantsTagId, throwsException);
    });
  });
}
