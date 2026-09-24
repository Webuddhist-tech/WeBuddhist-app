import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/env.dart';
import 'package:flutter_test/flutter_test.dart';

const _cdn = 'https://cdn.tolg.ee/project/webuddhist';

void main() {
  group('Env Tolgee settings', () {
    // What ci/scripts/create_env_files.sh writes when nothing overrides it.
    test('the CDN URL alone enables Tolgee', () {
      dotenv.testLoad(fileInput: 'TOLGEE_CDN_URL=$_cdn\nTOLGEE_ENABLED=\n');
      expect(Env.tolgeeCdnUrl, _cdn);
      expect(Env.tolgeeEnabled, isTrue);
    });

    test('TOLGEE_ENABLED=false switches it off', () {
      dotenv.testLoad(
        fileInput: 'TOLGEE_CDN_URL=$_cdn\nTOLGEE_ENABLED=false\n',
      );
      expect(Env.tolgeeEnabled, isFalse);
    });

    test('TOLGEE_ENABLED=true keeps it on', () {
      dotenv.testLoad(fileInput: 'TOLGEE_CDN_URL=$_cdn\nTOLGEE_ENABLED=true\n');
      expect(Env.tolgeeEnabled, isTrue);
    });

    test('the flag cannot enable it without a URL', () {
      dotenv.testLoad(fileInput: 'TOLGEE_ENABLED=true\n');
      expect(Env.tolgeeCdnUrl, isNull);
      expect(Env.tolgeeEnabled, isFalse);
    });

    // An unset CI variable is written as `KEY=`, not left out.
    test('a blank URL counts as missing', () {
      dotenv.testLoad(fileInput: 'TOLGEE_CDN_URL=  \nTOLGEE_ENABLED=true\n');
      expect(Env.tolgeeCdnUrl, isNull);
      expect(Env.tolgeeEnabled, isFalse);
    });

    // The key was only ever a feature flag; the CDN fetch never sends it.
    test('an API key without a URL does not enable it', () {
      dotenv.testLoad(fileInput: 'TOLGEE_API_KEY=tgpak_test\n');
      expect(Env.tolgeeEnabled, isFalse);
    });

    test('nothing configured leaves it off', () {
      dotenv.testLoad(fileInput: '');
      expect(Env.tolgeeCdnUrl, isNull);
      expect(Env.tolgeeEnabled, isFalse);
    });
  });
}
