import 'package:flutter_pecha/core/l10n/l10n.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_cdn.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_locale_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/tolgee_sync.dart'
    show tolgeeCdnBase, tolgeeSyncLanguageTags;

void main() {
  test('sync tool language tags match the runtime Tolgee locale map', () {
    expect(tolgeeSyncLanguageTags.keys, <String>[
      'en',
      'bo',
      'zh',
      'zh_Hans',
      'hi',
      'mn',
      'ne',
      'th',
      'my',
      'vi',
    ]);

    for (final MapEntry<String, String> entry
        in tolgeeSyncLanguageTags.entries) {
      expect(
        entry.value,
        TolgeeLocaleMap.cdnTagFor(L10n.localeFor(entry.key)),
        reason: 'Tag drifted for app locale ${entry.key}',
      );
    }
  });

  test('sync tool CDN base matches the app', () {
    expect(tolgeeCdnBase, TolgeeCdn.baseUrl);
  });
}
