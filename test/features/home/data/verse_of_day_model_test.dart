import 'package:flutter_pecha/features/home/data/models/verse_of_day_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> payload({String? source}) => {
    'verse_of_day': {
      'id': 'v1',
      'verses': null,
      'verse': 'All phenomena arise from causes.',
      'image_url': 'https://example.com/a.webp',
      'ref_id': null,
      'source': source,
      'ref_type': null,
      'date': '2026-10-05',
      'group_info': [
        {'id': 'g1', 'title': 'Buddha'},
      ],
    },
  };

  test('parses source and keeps it through a cache round trip', () {
    final model = VerseOfDayModel.fromJson(
      payload(source: 'Pratītyasamutpādahṛdaya'),
    );

    expect(model.toEntity().source, 'Pratītyasamutpādahṛdaya');
    expect(
      VerseOfDayModel.fromJson(model.toJson()).toEntity().source,
      'Pratītyasamutpādahṛdaya',
    );
  });

  test('missing source yields an empty source', () {
    final entity = VerseOfDayModel.fromJson(payload()).toEntity();

    expect(entity.source, isEmpty);
    expect(entity.verse, 'All phenomena arise from causes.');
  });
}
