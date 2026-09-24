import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/secondary_reader_state.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_flattener_service.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_secondary_content_provider.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/data/models/translation.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

Segment _verse(int number, {String? translation}) => Segment(
  segmentId: 's$number',
  segmentNumber: number,
  content: 'v$number',
  translation:
      translation == null
          ? null
          : Translation(textId: 'E1', language: 'en', content: translation),
);

FlattenedContent _content(List<Segment> segments) =>
    const SectionFlattenerService().flatten([
      Section(id: 'root', sectionNumber: 1, segments: segments, sections: const []),
    ]);

/// The translation's first page: one verse aligned to the root's verse 1.
ReaderResponse _translationPage() => ReaderResponse(
  textDetail: TextDetail(
    id: 'E1',
    title: 'Tara Essence',
    language: 'en',
    type: 'text',
    groupId: '',
    isPublished: true,
    createdDate: '',
    updatedDate: '',
    publishedDate: '',
    publishedBy: '',
  ),
  content: Toc(
    id: 'E1',
    textId: 'T1',
    sections: [
      Section(
        id: 'E1',
        sectionNumber: 1,
        segments: [_verse(1, translation: 'Homage')],
        sections: const [],
      ),
    ],
  ),
  size: 20,
  paginationDirection: 'next',
  currentSegmentPosition: 1,
  lastSegmentPosition: 1,
  totalSegments: 1,
);

void main() {
  group('SecondaryReaderState.isPending', () {
    final loaded = SecondaryReaderState(
      loadedSegments: [_verse(2), _verse(3), _verse(4)],
      contentBySegmentNumber: const {2: 'b', 3: 'c', 4: 'd'},
    );

    test('every verse while the first page loads', () {
      const state = SecondaryReaderState(isLoading: true);
      expect(state.isPending(1), isTrue);
      expect(state.isPending(99), isTrue);
    });

    test('nothing once the pages are in', () {
      for (final number in [1, 2, 3, 4, 5]) {
        expect(loaded.isPending(number), isFalse);
      }
    });

    test('only the verses past the loaded ones in the loading direction', () {
      final next = loaded.copyWith(isLoadingNext: true);
      expect(next.isPending(5), isTrue);
      expect(next.isPending(3), isFalse, reason: 'loaded, just unaligned');
      expect(next.isPending(1), isFalse, reason: 'not being fetched');

      final previous = loaded.copyWith(isLoadingPrevious: true);
      expect(previous.isPending(1), isTrue);
      expect(previous.isPending(5), isFalse);
    });
  });

  group('secondaryInitialAnchor', () {
    final content = _content([_verse(1), _verse(2)]);

    test('a plan target wins', () {
      expect(
        secondaryInitialAnchor(
          navigationContext: NavigationContext(source: NavigationSource.plan),
          segmentId: 's7',
          content: content,
          visibleSegmentId: 's2',
        ),
        's7',
      );
    });

    test('nothing loaded means no anchor', () {
      expect(
        secondaryInitialAnchor(
          navigationContext: null,
          segmentId: 's7',
          content: null,
        ),
        isNull,
      );
    });

    test('the verse in view, else the first loaded one', () {
      expect(
        secondaryInitialAnchor(
          navigationContext: null,
          segmentId: null,
          content: content,
          visibleSegmentId: 's2',
        ),
        's2',
      );
      expect(
        secondaryInitialAnchor(
          navigationContext: null,
          segmentId: null,
          content: content,
        ),
        's1',
      );
    });
  });

  group('SecondaryReaderNotifier headings', () {
    // Verses 1-2 under "Prayer" > "Homage", verse 3 under "Praise".
    ReaderResponse page() => ReaderResponse(
      textDetail: _translationPage().textDetail,
      content: Toc(
        id: 'E1',
        textId: 'T1',
        sections: [
          Section(
            id: 'prayer',
            title: 'Prayer',
            sectionNumber: 1,
            segments: const [],
            sections: [
              Section(
                id: 'homage',
                title: 'Homage',
                sectionNumber: 1,
                segments: [
                  _verse(1, translation: 'a'),
                  _verse(2, translation: 'b'),
                ],
                sections: const [],
              ),
            ],
          ),
          Section(
            id: 'E1/gap/1',
            sectionNumber: 0,
            segments: [_verse(3, translation: 'c')],
            sections: const [],
          ),
        ],
      ),
      size: 20,
      paginationDirection: 'next',
      currentSegmentPosition: 1,
      lastSegmentPosition: 3,
      totalSegments: 3,
    );

    test('are placed at the verse they open at, outer first', () async {
      final container = ProviderContainer(
        overrides: [
          textDetailsFutureProvider.overrideWith(
            (ref, params) async => Right<Failure, ReaderResponse>(page()),
          ),
        ],
      );
      addTearDown(container.dispose);
      const key = SecondaryReaderKey(textId: 'E2', versionId: 'E1');
      final sub = container.listen(secondaryReaderProvider(key), (_, __) {});
      addTearDown(sub.close);
      expect(
        container.read(secondaryReaderProvider(key)).headsTranslationOnly,
        isTrue,
        reason: "no original headings while the first page loads",
      );

      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      final state = container.read(secondaryReaderProvider(key));
      final headings = state.headingsBySegmentNumber;
      expect(headings.keys, [1], reason: 'untitled runs are not headings');
      expect(headings[1]!.map((h) => (h.section.title, h.depth)), [
        ('Prayer', 0),
        ('Homage', 1),
      ]);
      expect(headings[1]!.map((h) => h.endSegmentNumber), [2, 2]);
      expect(state.headingsEnclosing(2).map((h) => h.section.title), [
        'Prayer',
        'Homage',
      ]);
      expect(state.headingsEnclosing(3), isEmpty);
      expect(state.headsTranslationOnly, isTrue);
    });

    test('a translation without a table of contents keeps the original '
        'headings', () {
      const state = SecondaryReaderState(
        contentBySegmentNumber: {1: 'a'},
      );
      expect(state.headsTranslationOnly, isFalse);
    });
  });

  group('SecondaryReaderNotifier', () {
    late List<TextDetailsParams> fetches;
    late ProviderContainer container;
    const key = SecondaryReaderKey(
      textId: 'E2',
      versionId: 'E1',
      initialSegmentId: 's1',
    );

    setUp(() {
      fetches = [];
      container = ProviderContainer(
        overrides: [
          textDetailsFutureProvider.overrideWith((ref, params) async {
            fetches.add(params);
            return Right<Failure, ReaderResponse>(_translationPage());
          }),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('a page fetched ahead is on screen from the first frame', () async {
      await container.read(
        textDetailsFutureProvider(secondaryInitialParams(key)).future,
      );

      final sub = container.listen(secondaryReaderProvider(key), (_, __) {});
      addTearDown(sub.close);
      final state = container.read(secondaryReaderProvider(key));

      expect(state.isLoading, isFalse);
      expect(state.contentBySegmentNumber, {1: 'Homage'});
      expect(state.isPending(1), isFalse);
      expect(fetches, hasLength(1), reason: 'the same request, once');
    });

    test('otherwise the first page loads and every verse is pending', () async {
      final sub = container.listen(secondaryReaderProvider(key), (_, __) {});
      addTearDown(sub.close);

      final initial = container.read(secondaryReaderProvider(key));
      expect(initial.isLoading, isTrue);
      expect(initial.isPending(1), isTrue);

      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      final loaded = container.read(secondaryReaderProvider(key));
      expect(loaded.isLoading, isFalse);
      expect(loaded.contentBySegmentNumber, {1: 'Homage'});
      expect(fetches.single, secondaryInitialParams(key));
    });
  });
}
