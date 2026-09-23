import 'package:flutter_pecha/features/library/data/models/library_edition.dart';
import 'package:flutter_pecha/features/library/data/models/library_reader_models.dart';
import 'package:flutter_pecha/features/library/data/models/library_segment.dart';
import 'package:flutter_pecha/features/library/data/models/library_text.dart';
import 'package:flutter_pecha/features/library/data/models/library_toc.dart';
import 'package:flutter_test/flutter_test.dart';

const Map<String, dynamic> _textJson = {
  'bdrc': null,
  'title': {'en': 'Aspiration Prayer from the Bodhicharyāvatāra'},
  'alt_titles': null,
  'language': 'en',
  'commentary_of': null,
  'translation_of': '17Ui1qnL3NJCnEowPZ2ZQ',
  'category_id': 'LCorCb2K98p3TICt3UCDm',
  'license': 'public',
  'id': '1JV8GzsC9Q938KzIMd5ul',
  'contributions': [],
  'commentaries': [],
  'translations': [],
  'editions': ['9AcmJNU0rKeRKbBjSmDhf'],
  'tag_ids': ['ZPcgMZgVJxAMQ7rpfW72a', 'FZ5STsdU0eLvo7Nb2CpvH'],
};

void main() {
  group('LibraryText', () {
    test('parses the texts payload', () {
      final text = LibraryText.fromJson(_textJson);
      expect(text.id, '1JV8GzsC9Q938KzIMd5ul');
      expect(
        text.displayTitle,
        'Aspiration Prayer from the Bodhicharyāvatāra',
      );
      expect(text.language, 'en');
      expect(text.translationOf, '17Ui1qnL3NJCnEowPZ2ZQ');
      expect(text.primaryEditionId, '9AcmJNU0rKeRKbBjSmDhf');
      expect(text.license, 'public');
      expect(text.tagIds, contains('FZ5STsdU0eLvo7Nb2CpvH'));
      expect(text.isTranslation, isTrue);
      expect(text.translations, isEmpty);
    });

    test('a root text and a translation are both versions', () {
      final translation = LibraryText.fromJson(_textJson);
      final root = LibraryText.fromJson({
        ..._textJson,
        'translation_of': null,
      });
      expect(translation.isCommentary, isFalse);
      expect(root.isCommentary, isFalse);
    });

    test('commentary_of marks a commentary', () {
      final commentary = LibraryText.fromJson({
        ..._textJson,
        'commentary_of': '17Ui1qnL3NJCnEowPZ2ZQ',
      });
      expect(commentary.isCommentary, isTrue);
    });

    test('falls back to any title when none matches the language', () {
      final text = LibraryText.fromJson({
        ..._textJson,
        'title': {'ne': 'बोधिचर्यावतारको प्रणिधान'},
      });
      expect(text.displayTitle, 'बोधिचर्यावतारको प्रणिधान');
    });

    test('has no edition when the list is empty', () {
      final text = LibraryText.fromJson({..._textJson, 'editions': []});
      expect(text.primaryEditionId, isNull);
    });
  });

  test('LibraryTextPage parses paging fields', () {
    final page = LibraryTextPage.fromJson({
      'items': [_textJson],
      'has_more': true,
      'offset': 0,
      'limit': 20,
    });
    expect(page.items, hasLength(1));
    expect(page.hasMore, isTrue);
    expect(page.offset, 0);
    expect(page.limit, 20);
  });

  group('LibrarySegment', () {
    test('parses lines and exposes the span bounds', () {
      final segment = LibrarySegment.fromJson({
        'lines': [
          {'start': 0, 'end': 37},
          {'start': 37, 'end': 91},
        ],
        'id': 'dxA4tm5T2bOxqwDdnGymO',
        'type': 'verse',
        'reference': '1',
      });
      expect(segment.reference, '1');
      expect(segment.lines, hasLength(2));
      expect(segment.spanStart, 0);
      expect(segment.spanEnd, 91);
      expect(segment.editionId, isNull);
    });

    test('parses related segment ids', () {
      final segment = LibrarySegment.fromJson({
        'lines': [
          {'start': 0, 'end': 28},
        ],
        'id': 'DieBc2Srw8bL2zrK0uHQt',
        'type': 'verse',
        'reference': '1',
        'segmentation_id': 'S9EcFJ7nhnsj8oIVZeKZ2',
        'edition_id': 'f7qs8kKZMFZ30ynqq7cif',
        'text_id': '17Ui1qnL3NJCnEowPZ2ZQ',
        'tag_ids': null,
      });
      expect(segment.editionId, 'f7qs8kKZMFZ30ynqq7cif');
      expect(segment.textId, '17Ui1qnL3NJCnEowPZ2ZQ');
      expect(segment.segmentationId, 'S9EcFJ7nhnsj8oIVZeKZ2');
    });

    test('compares by id', () {
      const a = LibrarySegment(id: 'x', type: '', reference: '', lines: []);
      const b = LibrarySegment(
        id: 'x',
        type: 'verse',
        reference: '2',
        lines: [],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  test('LibraryEdition parses the source', () {
    final edition = LibraryEdition.fromJson({
      'type': 'critical',
      'source': 'https://dharmamitra.org',
      'id': '9AcmJNU0rKeRKbBjSmDhf',
      'text_id': '1JV8GzsC9Q938KzIMd5ul',
    });
    expect(edition.source, 'https://dharmamitra.org');
    expect(edition.textId, '1JV8GzsC9Q938KzIMd5ul');
  });

  group('HTML helpers', () {
    test('escapes markup and joins lines with breaks', () {
      expect(
        libraryLinesToHtml(['a & b', '', '<i>c</i>']),
        'a &amp; b<br>&lt;i&gt;c&lt;/i&gt;',
      );
    });

    test('reader segment exposes html', () {
      const segment = LibraryReaderSegment(
        id: 's',
        reference: '1',
        type: 'verse',
        number: 1,
        lines: ['one', 'two'],
        spanStart: 0,
        spanEnd: 7,
      );
      expect(segment.html, 'one<br>two');
    });
  });

  group('LibraryTableOfContents', () {
    test('parses nested headings with their spans', () {
      final toc = LibraryTableOfContents.fromJson({
        'id': 'Lkvj4CoCjpiOmJPsWd5Ls',
        'edition_id': 'BtqPpZvVCamzWXhjObYka',
        'text_id': 'W5o6Tyq3hhQDxhmvdoS7B',
        'sections': [
          {
            'id': '3DCy0SjQWuUsdyMcjvANE',
            'title': {'en': 'Praises to the Twenty-One Tārās'},
            'span': {'start': 0, 'end': 5048},
            'subsections': [
              {
                'id': '39KdL1g4CwJD0ughZAPbm',
                'title': {'en': 'Meaning of the Title'},
                'span': {'start': 0, 'end': 197},
                'subsections': [],
              },
            ],
          },
        ],
      });

      expect(toc.editionId, 'BtqPpZvVCamzWXhjObYka');
      final top = toc.sections.single;
      expect(top.titleFor('en'), 'Praises to the Twenty-One Tārās');
      expect(top.spanStart, 0);
      expect(top.spanEnd, 5048);
      final sub = top.subsections.single;
      expect(sub.id, '39KdL1g4CwJD0ughZAPbm');
      expect(sub.contains(196), isTrue);
      expect(sub.contains(197), isFalse);
      expect(sub.subsections, isEmpty);
    });

    test('titles fall back to any language and tolerate missing fields', () {
      final section = LibraryTocSection.fromJson({
        'id': 'x',
        'title': {'bo': 'ཀ', 'en': ''},
      });
      expect(section.titleFor('en'), 'ཀ');
      expect(section.spanStart, 0);
      expect(section.spanEnd, 0);
      expect(
        LibraryTocSection.fromJson({'id': 'y', 'title': {}}).titleFor('en'),
        isNull,
      );
    });
  });
}
