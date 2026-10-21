import 'package:flutter_pecha/features/group_profile/data/models/group_practice_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses chant recordings and drops ones without a url', () {
    final model = GroupRecitationCollectionModel.fromJson({
      'id': 'collection-1',
      'group_id': 'group-1',
      'name': 'Morning',
      'items': [
        {
          'id': 'chant-1',
          'text_id': 'text-1',
          'title': 'Aspiration',
          'language': 'en',
          'type': null,
          'display_order': 1,
          'audio': [
            {
              'id': 'audio-1',
              'title': 'prayer.mp3',
              'asset_url': 'https://cdn/prayer.mp3',
            },
            {'id': 'audio-blank', 'title': 'missing.mp3', 'asset_url': '  '},
            {
              'id': 'audio-2',
              'file_name': 'fallback.mp3',
              'asset_url': 'https://cdn/fallback.mp3',
            },
          ],
        },
        {
          'id': 'chant-2',
          'text_id': 'text-2',
          'title': 'No audio',
          'display_order': 2,
        },
      ],
    });

    final collection = model.toEntity();
    final first = collection.items.singleWhere((item) => item.id == 'chant-1');
    expect(first.audio.map((audio) => audio.title), [
      'prayer.mp3',
      'fallback.mp3',
    ]);
    expect(first.audio.first.assetUrl, 'https://cdn/prayer.mp3');
    expect(
      collection.items.singleWhere((item) => item.id == 'chant-2').audio,
      isEmpty,
    );
  });
}
