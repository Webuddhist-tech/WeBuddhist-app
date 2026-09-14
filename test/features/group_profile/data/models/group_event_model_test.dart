import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupEventModel youtube', () {
    test('parses youtube links and picks the first by display order', () {
      final event =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'youtube': [
              {
                'id': 'y2',
                'url': 'https://youtu.be/gs18skkubuI',
                'label': 'tibetan live',
                'language': 'BO',
                'display_order': 2,
              },
              {
                'id': 'y1',
                'url': 'https://youtu.be/BNDTusn8TO8',
                'label': 'live',
                'language': 'EN',
                'display_order': 1,
              },
            ],
          }).toEntity();

      expect(event.youtube.map((link) => link.id), ['y2', 'y1']);
      expect(event.youtube.first.language, 'BO');
      expect(event.liveYoutubeLink?.id, 'y1');
      expect(event.liveYoutubeLink?.url, 'https://youtu.be/BNDTusn8TO8');
    });

    test('skips youtube entries without a url', () {
      final event =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'youtube': [
              {'id': 'y1', 'url': '', 'display_order': 1},
              {'id': 'y2', 'url': 'https://youtu.be/gs18skkubuI'},
            ],
          }).toEntity();

      expect(event.liveYoutubeLink?.id, 'y2');
    });

    test('defaults to no youtube links', () {
      final event =
          GroupEventModel.fromJson({'id': 'e1', 'group_id': 'g1'}).toEntity();

      expect(event.youtube, isEmpty);
      expect(event.liveYoutubeLink, isNull);
    });

    test('keeps the language on regular links', () {
      final event =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'links': [
              {
                'id': 'l1',
                'type': 'zoom',
                'url': 'https://meet.google.com/abc',
                'language': 'EN',
              },
            ],
          }).toEntity();

      expect(event.links.single.language, 'EN');
    });
  });
}
