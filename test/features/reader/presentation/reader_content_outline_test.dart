import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_content_part.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/text_outline.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/data/repositories/texts_repository.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../fakes/fake_local_storage.dart';
import '../fakes/fake_reader_settings_datasource.dart';

/// Text C: three chapters of twenty verses, served twenty at a time.
const _chapters = ['Opening the Heart', 'The Middle Way', 'Dedication'];
const _pageSize = 20;
const _total = 60;

int _chapterOf(int verse) => (verse - 1) ~/ 20;

/// The page from the anchor, its verses under their chapters' headings.
ReaderResponse _page(TextDetailsParams params) {
  final first =
      params.segmentId == null
          ? 1
          : int.parse(params.segmentId!.split('-').last);
  final last = (first + _pageSize - 1).clamp(1, _total);
  final sections = <Section>[];
  for (var n = first; n <= last; n++) {
    final chapter = _chapterOf(n);
    if (sections.isEmpty || sections.last.id != 'ch$chapter') {
      sections.add(
        Section(
          id: 'ch$chapter',
          title: _chapters[chapter],
          titles: {'en': _chapters[chapter]},
          sectionNumber: chapter + 1,
          segments: [],
          sections: const [],
        ),
      );
    }
    sections.last.segments.add(
      Segment(
        segmentId: 'C-$n',
        segmentNumber: n,
        content: 'Verse $n. ${'Om mani padme hum. ' * 6}',
      ),
    );
  }
  return ReaderResponse(
    textDetail: TextDetail(
      id: 'C',
      title: 'A Prayer Book',
      language: 'en',
      type: 'text',
      groupId: '',
      isPublished: true,
      createdDate: '',
      updatedDate: '',
      publishedDate: '',
      publishedBy: '',
    ),
    content: Toc(id: 'C', textId: 'C', sections: sections),
    size: _pageSize,
    paginationDirection: 'next',
    currentSegmentPosition: first,
    lastSegmentPosition: last,
    totalSegments: _total,
  );
}

/// Knows text C's whole table of contents.
class _Outlines implements TextsRepository {
  @override
  Future<TextOutline> fetchOutline({
    required String textId,
    String? versionId,
  }) async => TextOutline(
    language: 'en',
    sections: [
      for (var c = 0; c < _chapters.length; c++)
        TextOutlineSection(
          id: 'ch$c',
          depth: 0,
          titles: {'en': _chapters[c]},
          segmentId: 'C-${c * 20 + 1}',
          number: c * 20 + 1,
          endNumber: c * 20 + 20,
          opensText: c == 0,
        ),
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        readerSettingsRemoteDatasourceProvider.overrideWithValue(
          FakeReaderSettingsDatasource(languages: const [], versions: const {}),
        ),
        textsRepositoryProvider.overrideWithValue(_Outlines()),
        textDetailsFutureProvider.overrideWith(
          (ref, params) async => Right<Failure, ReaderResponse>(_page(params)),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReaderContentPart(sources: const [ReaderParams(textId: 'C')]),
        ),
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

void main() {
  testWidgets('the pill counts every chapter before any scrolling', (
    tester,
  ) async {
    await _pump(tester);

    // Only the first chapter's verses are in, yet all three count.
    expect(find.textContaining('Verse 41.'), findsNothing);
    expect(find.text('· 1 / 3'), findsOneWidget);
  });

  testWidgets('the sheet lists every chapter; a tap loads one not yet in', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('· 1 / 3'));
    await _settle(tester);
    expect(find.text('Sections'), findsOneWidget);
    expect(find.text(_chapters[1]), findsOneWidget);
    expect(find.text(_chapters[2]), findsOneWidget);

    await tester.tap(find.text(_chapters[2]));
    await _settle(tester);

    expect(find.text('Sections'), findsNothing);
    expect(find.textContaining('Verse 41.'), findsOneWidget);
    expect(find.text('· 3 / 3'), findsOneWidget);
  });

  testWidgets('the text\'s row goes back to its start once it is unloaded', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('· 1 / 3'));
    await _settle(tester);
    await tester.tap(find.text(_chapters[2]));
    await _settle(tester);
    // The page now starts further in: its opening verses are gone.
    expect(find.textContaining('Verse 1.'), findsNothing);

    await tester.tap(find.text('· 3 / 3'));
    await _settle(tester);
    // The text's row is named by its opening chapter.
    await tester.tap(find.text(_chapters[0]).last);
    await _settle(tester);

    expect(find.textContaining('Verse 1.'), findsOneWidget);
    expect(find.text('· 1 / 3'), findsOneWidget);
  });
}
