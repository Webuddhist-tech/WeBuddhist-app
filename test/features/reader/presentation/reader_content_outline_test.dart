import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_content_part.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/text_outline.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/data/models/translation.dart';
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

/// Its Chinese translation, C-zh, has a table of contents of its own: the
/// same chapters under ids of its own.
const _translation = 'C-zh';
String _translatedChapter(int chapter) => '第${chapter + 1}章';

/// The page from the anchor, its verses under their chapters' headings: a
/// page starting partway into a chapter repeats that chapter's heading, as
/// the API does.
ReaderResponse _page(TextDetailsParams params) {
  final isTranslation = params.versionId == _translation;
  final first =
      params.segmentId == null
          ? 1
          : int.parse(params.segmentId!.split('-').last);
  final last = (first + _pageSize - 1).clamp(1, _total);
  final sections = <Section>[];
  for (var n = first; n <= last; n++) {
    final chapter = _chapterOf(n);
    final id = isTranslation ? 'zh-ch$chapter' : 'ch$chapter';
    if (sections.isEmpty || sections.last.id != id) {
      sections.add(
        Section(
          id: id,
          title:
              isTranslation ? _translatedChapter(chapter) : _chapters[chapter],
          titles:
              isTranslation
                  ? {'zh': _translatedChapter(chapter)}
                  : {'en': _chapters[chapter]},
          sectionNumber: chapter + 1,
          segments: [],
          sections: const [],
        ),
      );
    }
    sections.last.segments.add(
      isTranslation
          ? Segment(
            segmentId: '$_translation-$n',
            segmentNumber: n,
            translation: Translation(
              textId: _translation,
              language: 'zh',
              content: '譯文第$n句',
            ),
          )
          : Segment(
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

/// Knows text C's whole table of contents. With [openingVerse] past 1, the
/// verses before it come ahead of any heading.
class _Outlines implements TextsRepository {
  _Outlines({this.openingVerse = 1});

  final int openingVerse;

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
          segmentId: 'C-${c == 0 ? openingVerse : c * 20 + 1}',
          number: c == 0 ? openingVerse : c * 20 + 1,
          endNumber: c * 20 + 20,
          opensText: c == 0 && openingVerse == 1,
        ),
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester, {
  String? openAt,
  int openingVerse = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        readerSettingsRemoteDatasourceProvider.overrideWithValue(
          FakeReaderSettingsDatasource(languages: const [], versions: const {}),
        ),
        textsRepositoryProvider.overrideWithValue(
          _Outlines(openingVerse: openingVerse),
        ),
        textDetailsFutureProvider.overrideWith(
          (ref, params) async => Right<Failure, ReaderResponse>(_page(params)),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReaderContentPart(
            sources: [ReaderParams(textId: 'C', segmentId: openAt)],
          ),
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

  testWidgets('each chapter heading says where it sits, as the pill counts', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('SECTION 1 / 3'), findsOneWidget);

    await tester.tap(find.text('· 1 / 3'));
    await _settle(tester);
    await tester.tap(find.text(_chapters[2]));
    await _settle(tester);
    expect(find.text('SECTION 3 / 3'), findsOneWidget);
  });

  testWidgets('a translation\'s own headings say where they sit too', (
    tester,
  ) async {
    await _pump(tester);
    final ref = tester.element(find.byType(ReaderContentPart)) as WidgetRef;
    final notifier = ref.read(
      readerDualSettingsProvider(
        const ReaderParams(textId: 'C').settingsScope,
      ).notifier,
    );
    notifier.replaceSecondary(
      const ReaderSlotConfig(
        languageCode: 'zh',
        languageLabel: '中文',
        versionId: _translation,
        versionLabel: '中文',
      ),
    );
    notifier.setSecondaryEnabled(true);
    notifier.setOriginalVisible(false);
    await _settle(tester);

    // The heading is the translation's, with an id the pill does not know.
    expect(find.text(_translatedChapter(0)), findsWidgets);
    expect(find.text('SECTION 1 / 3'), findsOneWidget);
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

  testWidgets('a chapter loaded only from partway in opens at its start', (
    tester,
  ) async {
    // Opened at verse 45 (a search result, a bookmark): the last chapter is
    // in only from there, under its repeated heading.
    await _pump(tester, openAt: 'C-45');
    expect(find.text(_chapters[2]), findsWidgets);
    expect(find.textContaining('Verse 41.'), findsNothing);

    await tester.tap(find.textContaining('· '));
    await _settle(tester);
    await tester.tap(find.text(_chapters[2]).last);
    await _settle(tester);

    expect(find.text('Sections'), findsNothing);
    expect(find.textContaining('Verse 41.'), findsOneWidget);
  });

  testWidgets('the text\'s row goes back to its start, before any heading', (
    tester,
  ) async {
    // Verses 1-5 come before the first heading, so no heading names the
    // text's start; opened further in, they are not on the page.
    await _pump(tester, openAt: 'C-45', openingVerse: 6);
    expect(find.textContaining('Verse 1.'), findsNothing);

    await tester.tap(find.textContaining('· '));
    await _settle(tester);
    // The text's row is named by the text.
    await tester.tap(find.text('A Prayer Book').last);
    await _settle(tester);

    expect(find.text('Sections'), findsNothing);
    expect(find.textContaining('Verse 1.'), findsOneWidget);
  });
}
