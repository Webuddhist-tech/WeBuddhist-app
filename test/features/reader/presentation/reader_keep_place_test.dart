import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_text_size_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_verse_numbers_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_text_size.dart';
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

import '../fakes/fake_local_storage.dart';
import '../fakes/fake_reader_settings_datasource.dart';

const _verses = 30;

/// The verse's row stays put; the text in it moves by half the change in
/// the gap over each verse (24 at step 3, 42 at step 7), at most 9.
const double _frameGapShift = 10;

/// Verse [n]'s text: a marker to find it by, and enough words to wrap.
String _verse(int n) =>
    'V$n. May all beings have happiness and its causes, be free of '
    'suffering and its causes, and never be parted from joy.';

ReaderResponse _page(TextDetailsParams params) {
  final segments = [
    for (var n = 1; n <= _verses; n++)
      Segment(segmentId: 'A-$n', segmentNumber: n, content: _verse(n)),
  ];
  return ReaderResponse(
    textDetail: TextDetail(
      id: 'A',
      title: 'Prayer',
      language: 'bo',
      type: 'text',
      groupId: '',
      isPublished: true,
      createdDate: '',
      updatedDate: '',
      publishedDate: '',
      publishedBy: '',
    ),
    content: Toc(
      id: 'A',
      textId: 'A',
      sections: [
        Section(
          id: 'A-gap',
          sectionNumber: 0,
          segments: segments,
          sections: const [],
        ),
      ],
    ),
    size: _verses,
    paginationDirection: 'next',
    currentSegmentPosition: 1,
    lastSegmentPosition: _verses,
    totalSegments: _verses,
  );
}

final _item = PlanTextItem.sources(
  sources: [
    PlanSourceRef(
      textId: 'A',
      segmentIds: [for (var n = 1; n <= _verses; n++) 'A-$n'],
    ),
  ],
  title: 'Prayer',
);

List<ReaderParams> get _sources {
  final ctx = NavigationContext(
    source: NavigationSource.plan,
    planId: 'plan',
    dayNumber: 1,
    targetSegmentId: 'A-1',
    planTextItems: [_item],
    currentTextIndex: 0,
  );
  return [
    for (final source in _item.sources)
      ReaderParams(
        textId: source.textId,
        segmentId: source.firstSegmentId,
        segmentIds: source.segmentIds,
        navigationContext: ctx,
      ),
  ];
}

Future<ProviderContainer> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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
        home: Scaffold(body: ReaderContentPart(sources: _sources)),
      ),
    ),
  );
  await _settle(tester);
  return ProviderScope.containerOf(
    tester.element(find.byType(ReaderContentPart)),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Finder _verseText(int n) =>
    find.textContaining('V$n. ', findRichText: true).first;

/// The top of verse [n] on screen, or null when it is not built.
double? _topOf(WidgetTester tester, int n) {
  final finder = find.textContaining('V$n. ', findRichText: true);
  if (finder.evaluate().isEmpty) return null;
  return tester.getTopLeft(finder.first).dy;
}

/// The second verse whose top shows on screen, as a reader in the middle of
/// the text would be reading it.
int _secondVerseOnScreen(WidgetTester tester) {
  final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;
  final tops = [
    for (var n = 1; n <= _verses; n++)
      if (_topOf(tester, n) case final top? when top >= 0 && top < height) n,
  ];
  return tops[1];
}

/// Scrolls about halfway into the text, as a reader would.
Future<void> _scrollIntoText(WidgetTester tester) async {
  await tester.drag(find.byType(ReaderContentPart), const Offset(0, -1800));
  await _settle(tester);
}

void main() {
  testWidgets('a bigger or smaller size keeps the verse being read in place', (
    tester,
  ) async {
    final container = await _pump(tester);
    await _scrollIntoText(tester);
    final verse = _secondVerseOnScreen(tester);
    final before = tester.getTopLeft(_verseText(verse)).dy;
    final sizes = container.read(readerTextSizeProvider.notifier);

    for (final step in [6, 7, 2, 3]) {
      await sizes.setOriginalStep(step);
      await _settle(tester);
      expect(
        _topOf(tester, verse),
        moreOrLessEquals(before, epsilon: _frameGapShift),
        reason: 'step $step',
      );
    }
  });

  testWidgets('line spacing keeps the verse being read in place', (
    tester,
  ) async {
    final container = await _pump(tester);
    await _scrollIntoText(tester);
    final verse = _secondVerseOnScreen(tester);
    final before = tester.getTopLeft(_verseText(verse)).dy;
    final sizes = container.read(readerTextSizeProvider.notifier);

    for (final spacing in [ReaderSpacing.compact, ReaderSpacing.relaxed]) {
      await sizes.setSpacing(spacing);
      await _settle(tester);
      expect(
        _topOf(tester, verse),
        moreOrLessEquals(before, epsilon: _frameGapShift),
        reason: '$spacing',
      );
    }
  });

  testWidgets('turning verse numbers off keeps the verse being read in place', (
    tester,
  ) async {
    final container = await _pump(tester);
    await _scrollIntoText(tester);
    final verse = _secondVerseOnScreen(tester);
    final before = tester.getTopLeft(_verseText(verse)).dy;

    await container.read(readerVerseNumbersProvider.notifier).setShown(false);
    await _settle(tester);
    expect(_topOf(tester, verse), moreOrLessEquals(before, epsilon: _frameGapShift));
  });
}
