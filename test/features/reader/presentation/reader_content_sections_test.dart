import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/core/widgets/slide_away_header.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_content_part.dart';
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

/// Text A is one prayer book: a root heading over two sections of eight
/// verses each. Text B has two verses and no headings.
const _rootTitle = 'Zangchö Mönlam';
const _refugeTitle = 'The Refuge and Bodhicitta Prayer';
const _kingTitle = 'The King of Aspiration Prayers';

Segment _verse(String textId, int n) => Segment(
  segmentId: '$textId-$n',
  segmentNumber: n,
  // Long enough to wrap, so the page scrolls.
  content: 'Verse $n. ${'Om mani padme hum. ' * 6}',
);

TextDetail _detail(String textId) => TextDetail(
  id: textId,
  title: textId == 'A' ? _rootTitle : 'Short text',
  language: 'en',
  type: 'text',
  groupId: '',
  isPublished: true,
  createdDate: '',
  updatedDate: '',
  publishedDate: '',
  publishedBy: '',
);

ReaderResponse _page(TextDetailsParams params) {
  final textId = params.textId;
  final List<Section> sections;
  if (textId == 'A') {
    sections = [
      Section(
        id: 'A-root',
        title: _rootTitle,
        sectionNumber: 1,
        segments: const [],
        sections: [
          Section(
            id: 'A-refuge',
            title: _refugeTitle,
            sectionNumber: 1,
            parentId: 'A-root',
            segments: [for (var n = 1; n <= 8; n++) _verse('A', n)],
            sections: const [],
          ),
          Section(
            id: 'A-king',
            title: _kingTitle,
            sectionNumber: 2,
            parentId: 'A-root',
            segments: [for (var n = 9; n <= 16; n++) _verse('A', n)],
            sections: const [],
          ),
        ],
      ),
    ];
  } else {
    sections = [
      Section(
        id: 'B-gap',
        sectionNumber: 0,
        segments: [for (var n = 1; n <= 2; n++) _verse('B', n)],
        sections: const [],
      ),
    ];
  }
  final total = textId == 'A' ? 16 : 2;
  return ReaderResponse(
    textDetail: _detail(textId),
    content: Toc(id: textId, textId: textId, sections: sections),
    size: 20,
    paginationDirection: 'next',
    currentSegmentPosition: 1,
    lastSegmentPosition: total,
    totalSegments: total,
  );
}

/// A plan task reading text A twice: its first section, then its second.
List<ReaderParams> _twoRangesOfA() {
  final item = PlanTextItem.sources(
    sources: [
      PlanSourceRef(textId: 'A', segmentIds: [for (var n = 1; n <= 8; n++) 'A-$n']),
      PlanSourceRef(textId: 'A', segmentIds: [for (var n = 9; n <= 16; n++) 'A-$n']),
    ],
    title: 'Two prayers',
  );
  final ctx = NavigationContext(
    source: NavigationSource.plan,
    planId: 'plan',
    dayNumber: 1,
    targetSegmentId: 'A-1',
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

Future<void> _pump(WidgetTester tester, List<ReaderParams> sources) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        readerSettingsRemoteDatasourceProvider.overrideWithValue(
          FakeReaderSettingsDatasource(languages: const [], versions: const {}),
        ),
        textDetailsFutureProvider.overrideWith(
          (ref, params) async => Right<Failure, ReaderResponse>(_page(params)),
        ),
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
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _scrollBy(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(ScrollablePositionedList), Offset(0, dy));
  await _settle(tester);
}

bool _pillVisible(WidgetTester tester) =>
    tester.widget<SlideAwayHeader>(find.byType(SlideAwayHeader)).visible;

void main() {
  testWidgets(
    'the pill names the section at the top and counts the page\'s sections',
    (tester) async {
      await _pump(tester, _twoRangesOfA());

      expect(find.text('· 1 / 2'), findsOneWidget);
      // The pill names the section at the top, as its heading does; the
      // book is named only by its heading.
      expect(find.text(_refugeTitle), findsNWidgets(2));
      expect(find.text(_rootTitle), findsOneWidget);
    },
  );

  testWidgets('the sheet lists the sections and a tap scrolls to one', (
    tester,
  ) async {
    await _pump(tester, _twoRangesOfA());

    await tester.tap(find.text('· 1 / 2'));
    await _settle(tester);
    expect(find.text('Sections'), findsOneWidget);
    expect(find.text('Two prayers'), findsOneWidget);
    // Each text is a row (its heading and two rows name the book), its
    // sections nested under it.
    expect(find.text(_rootTitle), findsNWidgets(3));
    expect(find.text(_kingTitle), findsOneWidget);

    // The second text's row brings its own title heading to the top, and the
    // pill names its section.
    await tester.tap(find.text(_rootTitle).last);
    await _settle(tester);

    expect(find.text('Sections'), findsNothing);
    expect(find.text('· 2 / 2'), findsOneWidget);
    expect(find.text(_kingTitle), findsNWidgets(2));
  });

  testWidgets('the pill slides away on a scroll down and back on a scroll up', (
    tester,
  ) async {
    await _pump(tester, _twoRangesOfA());
    expect(_pillVisible(tester), isTrue);

    // Direction is read from the first item the list still holds, so it takes
    // more than half a page of travel to register.
    await _scrollBy(tester, -400);
    await _scrollBy(tester, -400);
    expect(_pillVisible(tester), isFalse);

    await _scrollBy(tester, 400);
    expect(_pillVisible(tester), isTrue);
  });

  testWidgets('a text read whole counts its chapters and lists them', (
    tester,
  ) async {
    await _pump(tester, const [ReaderParams(textId: 'A')]);

    expect(find.text('· 1 / 2'), findsOneWidget);
    expect(find.text(_rootTitle), findsOneWidget);

    await tester.tap(find.text('· 1 / 2'));
    await _settle(tester);
    expect(find.text('Sections'), findsOneWidget);
    // The pill, the heading and the sheet's row.
    expect(find.text(_refugeTitle), findsNWidgets(3));
    expect(find.text(_kingTitle), findsOneWidget);
  });

  testWidgets('a text with one section has nothing to navigate', (
    tester,
  ) async {
    await _pump(tester, const [ReaderParams(textId: 'B')]);

    expect(find.byType(SlideAwayHeader), findsNothing);
    expect(find.text('B-1'), findsNothing);
  });
}
