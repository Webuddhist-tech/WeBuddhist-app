import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_content_part.dart';
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

import '../fakes/fake_local_storage.dart';
import '../fakes/fake_reader_settings_datasource.dart';

/// Text A has a titled table of contents (Tibetan and English titles); text
/// B has none. Edition A-zh is a translation with a table of contents of its
/// own; A-en and B-zh are translations without one.
const _rootTitleA = 'ཀ';
const _rootTitleB = 'བ';
const _translatedHeading = '譯本標題';

TextDetail _detail(String id, String title, String language) => TextDetail(
  id: id,
  title: title,
  language: language,
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
  final versionId = params.versionId;
  final isTranslation = versionId != null && versionId != textId;
  final language = isTranslation ? versionId.split('-').last : 'bo';
  final segments = [
    for (var n = 1; n <= 2; n++)
      Segment(
        segmentId: isTranslation ? '$versionId-$n' : '$textId-$n',
        segmentNumber: n,
        content: isTranslation ? null : 'verse $n of $textId',
        translation:
            isTranslation
                ? Translation(
                  textId: versionId,
                  language: language,
                  content: 'line $n of $versionId',
                )
                : null,
      ),
  ];
  final Section section;
  if (!isTranslation && textId == 'A') {
    section = Section(
      id: 'A-root',
      title: _rootTitleA,
      titles: const {'bo': _rootTitleA, 'en': 'Alpha'},
      sectionNumber: 1,
      segments: segments,
      sections: const [],
    );
  } else if (versionId == 'A-zh') {
    section = Section(
      id: 'A-zh-root',
      title: _translatedHeading,
      titles: const {'zh': _translatedHeading},
      sectionNumber: 1,
      segments: segments,
      sections: const [],
    );
  } else {
    section = Section(
      id: '${versionId ?? textId}-gap',
      sectionNumber: 0,
      segments: segments,
      sections: const [],
    );
  }
  return ReaderResponse(
    textDetail: _detail(
      isTranslation ? versionId : textId,
      textId == 'A' ? _rootTitleA : _rootTitleB,
      language,
    ),
    content: Toc(id: textId, textId: textId, sections: [section]),
    size: 20,
    paginationDirection: 'next',
    currentSegmentPosition: 1,
    lastSegmentPosition: 2,
    totalSegments: 2,
  );
}

final _item = PlanTextItem.sources(
  sources: const [
    PlanSourceRef(textId: 'A', segmentIds: ['A-1', 'A-2']),
    PlanSourceRef(textId: 'B', segmentIds: ['B-1', 'B-2']),
  ],
  title: 'Two prayers',
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

Future<WidgetRef> _pump(WidgetTester tester) async {
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
  return tester.element(find.byType(ReaderContentPart)) as WidgetRef;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Shows [versionId], titled [label], as the translation of source [index].
Future<void> _showTranslation(
  WidgetTester tester,
  WidgetRef ref,
  int index, {
  required String versionId,
  required String label,
}) async {
  final notifier = ref.read(
    readerDualSettingsProvider(_sources[index].settingsScope).notifier,
  );
  notifier.replaceSecondary(
    ReaderSlotConfig(
      languageCode: versionId.split('-').last,
      languageLabel: label,
      versionId: versionId,
      versionLabel: label,
    ),
  );
  notifier.setSecondaryEnabled(true);
  await _settle(tester);
}

void main() {
  testWidgets('without a translation the headings are the texts\' own', (
    tester,
  ) async {
    await _pump(tester);

    // The pill names the section at the top as well as its heading.
    expect(find.text(_rootTitleA), findsWidgets);
    expect(find.text(_rootTitleB), findsOneWidget);
  });

  testWidgets('a translation with a table of contents heads the text', (
    tester,
  ) async {
    final ref = await _pump(tester);

    await _showTranslation(tester, ref, 0, versionId: 'A-zh', label: 'A Chinese');

    expect(find.text(_translatedHeading), findsWidgets);
    expect(find.text(_rootTitleA), findsNothing);
  });

  testWidgets(
    "a translation without one shows the text's headings in its language",
    (tester) async {
      final ref = await _pump(tester);

      await _showTranslation(tester, ref, 0, versionId: 'A-en', label: 'A English');

      expect(find.text('Alpha'), findsWidgets);
      expect(find.text(_rootTitleA), findsNothing);
    },
  );

  testWidgets("a text without headings is titled by its translation", (
    tester,
  ) async {
    final ref = await _pump(tester);

    await _showTranslation(tester, ref, 1, versionId: 'B-zh', label: 'B Chinese');

    expect(find.text('B Chinese'), findsOneWidget);
    expect(find.text(_rootTitleB), findsNothing);
  });
}
