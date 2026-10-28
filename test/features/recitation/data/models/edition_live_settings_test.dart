import 'package:flutter_pecha/features/recitation/data/models/edition_live_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The CMS sample's shape.
  final json = {
    'edition_id': 'Zt5c',
    'short_titles': [
      {'section_id': 'g', 'title': 'མཎྜལ།', 'icon': '🪷'},
    ],
    'repeated_segments': [
      {'segment_id': 's', 'times': 3},
    ],
    'return_jumps': [
      {
        'key': 'praises_1',
        'after_segment_id': 'kY',
        'to_segment_id': 'Bs',
        'times': 3,
        'label': {'en': '↺ Return to start', 'bo': ''},
      },
    ],
    'updated_at': null,
  };

  test('reads an edition\'s return jumps', () {
    final settings = EditionLiveSettings.fromJson(json);
    expect(settings.editionId, 'Zt5c');
    expect(settings.returnJumps, [
      const ReturnJump(
        key: 'praises_1',
        afterSegmentId: 'kY',
        toSegmentId: 'Bs',
        times: 3,
        label: {'en': '↺ Return to start', 'bo': ''},
      ),
    ]);
  });

  test('round-trips', () {
    final settings = EditionLiveSettings.fromJson(json);
    expect(EditionLiveSettings.fromJson(settings.toJson()), settings);
  });

  test('anything missing or malformed reads as empty', () {
    expect(
      EditionLiveSettings.fromJson(const {}),
      const EditionLiveSettings(editionId: ''),
    );
    final settings = EditionLiveSettings.fromJson({
      'edition_id': 'E',
      'return_jumps': [
        'not a jump',
        {'key': 'k', 'times': 'three', 'label': 'none'},
      ],
    });
    expect(settings.returnJumps, [
      const ReturnJump(key: 'k', afterSegmentId: '', toSegmentId: '', times: 0),
    ]);
  });
}
