import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_content_part.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_item.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../fakes/fake_local_storage.dart';
import '../fakes/fake_reader_settings_datasource.dart';

const _pageSize = 20;

/// Verses per text; ids are `<text>-<number>`.
late Map<String, int> _totals;

int _number(String segmentId) => int.parse(segmentId.split('-').last);

/// A page of [_pageSize] verses from the anchor, like the library serves.
ReaderResponse _page(TextDetailsParams params) {
  final textId = params.textId;
  final total = _totals[textId]!;
  final first = params.segmentId == null ? 1 : _number(params.segmentId!);
  final last = (first + _pageSize - 1).clamp(1, total);
  return ReaderResponse(
    textDetail: TextDetail(
      id: textId,
      title: 'Text $textId',
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
      id: textId,
      textId: textId,
      sections: [
        Section(
          id: textId,
          sectionNumber: 1,
          segments: [
            for (var n = first; n <= last; n++)
              Segment(
                segmentId: '$textId-$n',
                segmentNumber: n,
                // Long enough to wrap, so twenty verses overflow the screen.
                content: 'Verse $n. ${'Om mani padme hum. ' * 6}',
              ),
          ],
          sections: const [],
        ),
      ],
    ),
    size: _pageSize,
    paginationDirection: 'next',
    currentSegmentPosition: first,
    lastSegmentPosition: last,
    totalSegments: total,
  );
}

List<String> _ids(String textId, int from, int to) => [
  for (var n = from; n <= to; n++) '$textId-$n',
];

/// Readers for a task whose sources are text A then text B.
List<ReaderParams> _sources(List<String> aVerses, List<String> bVerses) =>
    _sourcesOf([
      PlanSourceRef(textId: 'A', segmentIds: aVerses),
      PlanSourceRef(textId: 'B', segmentIds: bVerses),
    ]);

List<ReaderParams> _sourcesOf(List<PlanSourceRef> sources) {
  final item = PlanTextItem.sources(sources: sources, title: 'Two prayers');
  final aVerses = sources.first.segmentIds!;
  final ctx = NavigationContext(
    source: NavigationSource.plan,
    planId: 'plan',
    dayNumber: 1,
    targetSegmentId: aVerses.first,
    planTextItems: [item],
    currentTextIndex: 0,
  );
  return [
    for (final source in item.sources)
      ReaderParams(
        textId: source.textId,
        segmentId: source.firstSegmentId,
        segmentIds: source.segmentIds,
        navigationContext: ctx,
      ),
  ];
}

Finder _verse(String segmentId) => find.byWidgetPredicate(
  (w) => w is SegmentItem && w.segment.segmentId == segmentId,
);

Future<List<TextDetailsParams>> _pump(
  WidgetTester tester,
  List<ReaderParams> sources,
) async {
  final fetches = <TextDetailsParams>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        readerSettingsRemoteDatasourceProvider.overrideWithValue(
          FakeReaderSettingsDatasource(languages: const [], versions: const {}),
        ),
        textDetailsFutureProvider.overrideWith((ref, params) async {
          fetches.add(params);
          return Right<Failure, ReaderResponse>(_page(params));
        }),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ReaderContentPart(sources: sources)),
      ),
    ),
  );
  await _settle(tester);
  return fetches;
}

/// Lets fetches land and the scroll debounce fire; the skeletons animate,
/// so pumpAndSettle would never return.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.drag(
    find.byType(ScrollablePositionedList),
    const Offset(0, -4000),
  );
  await _settle(tester);
}

void main() {
  testWidgets(
    'the second source follows the first after a rule, once its verses fit',
    (tester) async {
      _totals = {'A': 3, 'B': 2};
      final fetches = await _pump(
        tester,
        _sources(_ids('A', 1, 2), _ids('B', 1, 1)),
      );

      expect(_verse('A-1'), findsOneWidget);
      expect(_verse('A-2'), findsOneWidget);
      expect(_verse('A-3'), findsNothing, reason: 'not one of the task verses');
      expect(find.byType(Divider), findsOneWidget);
      expect(_verse('B-1'), findsOneWidget);
      expect(_verse('B-2'), findsNothing);
      expect(fetches.map((f) => f.textId), ['A', 'B']);
    },
  );

  testWidgets(
    'a long first source pages forward while reading, then starts the second',
    (tester) async {
      _totals = {'A': 40, 'B': 2};
      final fetches = await _pump(
        tester,
        _sources(_ids('A', 1, 40), _ids('B', 1, 1)),
      );

      expect(_verse('A-1'), findsOneWidget);
      expect(fetches.map((f) => (f.textId, f.segmentId)), [('A', 'A-1')]);
      expect(find.byType(Divider), findsNothing);

      await _scrollToEnd(tester);
      expect(fetches.map((f) => (f.textId, f.segmentId)), [
        ('A', 'A-1'),
        ('A', 'A-21'),
      ]);

      await _scrollToEnd(tester);
      expect(fetches.map((f) => f.textId), ['A', 'A', 'B']);
      // The reader stays where it was read to while the second text starts.
      expect(_verse('A-40'), findsOneWidget);
      expect(_verse('A-1'), findsNothing);

      await tester.dragUntilVisible(
        _verse('B-1'),
        find.byType(ScrollablePositionedList),
        const Offset(0, -200),
      );
      await _settle(tester);
      expect(_verse('A-40'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
      expect(_verse('B-1'), findsOneWidget);
      expect(_verse('B-2'), findsNothing);
    },
  );

  testWidgets(
    'the same verses of one text twice share a reader and show twice',
    (tester) async {
      _totals = {'A': 3};
      final fetches = await _pump(
        tester,
        _sourcesOf([
          PlanSourceRef(textId: 'A', segmentIds: _ids('A', 1, 2)),
          PlanSourceRef(textId: 'A', segmentIds: _ids('A', 1, 2)),
        ]),
      );

      expect(tester.takeException(), isNull);
      expect(_verse('A-1'), findsNWidgets(2));
      expect(_verse('A-2'), findsNWidgets(2));
      expect(find.byType(Divider), findsOneWidget);
      expect(fetches.map((f) => f.textId), ['A']);
    },
  );
}
