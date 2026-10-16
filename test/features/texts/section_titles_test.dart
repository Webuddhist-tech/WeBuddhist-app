import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_test/flutter_test.dart';

const _section = Section(
  id: 'prayer',
  title: 'སྨོན་ལམ།',
  titles: {'bo': 'སྨོན་ལམ།', 'zh': '祈願文', 'en': ''},
  sectionNumber: 1,
  segments: [],
  sections: [],
);

void main() {
  test('titleIn finds a language whatever its case, never an empty one', () {
    expect(_section.titleIn('ZH'), '祈願文');
    expect(_section.titleIn('bo'), 'སྨོན་ལམ།');
    expect(_section.titleIn('en'), isNull);
    expect(_section.titleIn('fr'), isNull);
  });

  test('the titles survive the page cache', () {
    final restored = Section.fromJson(_section.toJson());
    expect(restored.titles, _section.titles);
    expect(restored.title, _section.title);
  });

  test('a page cached before titles existed has none', () {
    final restored = Section.fromJson({
      'id': 'prayer',
      'title': 'སྨོན་ལམ།',
      'section_number': 1,
      'segments': <Object>[],
    });
    expect(restored.titles, isEmpty);
    expect(restored.titleIn('bo'), isNull);
    expect(restored.copyWith(title: 'x').titles, isEmpty);
  });
}
