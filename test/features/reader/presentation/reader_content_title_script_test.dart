import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_fonts_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_fonts.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_script.dart';
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

/// A Tibetan text with two titled sections.
const _first = 'མཚན་དོན་དང་འགྱུར་ཕྱག';
const _second = 'བསྟོད་པ་དངོས།';

ReaderResponse _page(TextDetailsParams params) {
  Section section(String id, String title, int number, int from) => Section(
    id: id,
    title: title,
    titles: {'bo': title},
    sectionNumber: number,
    segments: [
      for (var n = from; n < from + 3; n++)
        Segment(segmentId: 'T-$n', segmentNumber: n, content: 'ཀ་ཁ་ག། $n'),
    ],
    sections: const [],
  );
  return ReaderResponse(
    textDetail: TextDetail(
      id: 'T',
      title: 'སྒྲོལ་མ་ཉེར་གཅིག་ལ་བསྟོད་པ།',
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
      id: 'T',
      textId: 'T',
      sections: [section('S1', _first, 1, 1), section('S2', _second, 2, 4)],
    ),
    size: 6,
    paginationDirection: 'next',
    currentSegmentPosition: 1,
    lastSegmentPosition: 6,
    totalSegments: 6,
  );
}

Future<WidgetRef> _pump(
  WidgetTester tester, {
  Map<String, Object> stored = const {},
  List<Override> overrides = const [],
  Duration loadTime = Duration.zero,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...overrides,
        localStorageServiceProvider.overrideWithValue(
          FakeLocalStorage()..values.addAll(stored),
        ),
        readerSettingsRemoteDatasourceProvider.overrideWithValue(
          FakeReaderSettingsDatasource(languages: const [], versions: const {}),
        ),
        textDetailsFutureProvider.overrideWith(
          (ref, params) async {
            await Future<void>.delayed(loadTime);
            return Right<Failure, ReaderResponse>(_page(params));
          },
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          // The reader's app bar reads the font picks from the start, through
          // ReaderStyle; the page here stands alone, so this does it.
          body: Consumer(
            builder: (context, ref, child) {
              ref.watch(readerFontsProvider);
              return child!;
            },
            child: ReaderContentPart(sources: const [ReaderParams(textId: 'T')]),
          ),
        ),
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

void main() {
  testWidgets('headings and the pill follow the original\'s script', (
    tester,
  ) async {
    final ref = await _pump(tester);
    // As written: the headings, and the pill naming the first section.
    expect(find.text(_first), findsWidgets);
    expect(find.text(_second), findsOneWidget);
    expect(find.text('· ༡ / ༢'), findsOneWidget);
    expect(find.text('༡'), findsOneWidget);

    // Roman phonetics picked: no Tibetan script left in them, no reload.
    ref
        .read(readerScriptPreferenceProvider.notifier)
        .setScript('bo', 'phonetic');
    await _settle(tester);
    expect(find.text(_first), findsNothing);
    expect(find.text(_second), findsNothing);
    expect(find.text('tsen dön dang gyur chak'), findsWidgets);
    expect(find.text('tö pa ngö'), findsOneWidget);
    // Its numbers too: Western digits, not Tibetan ones.
    expect(find.text('· 1 / 2'), findsOneWidget);
    expect(find.text('SECTION 1 / 2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // And back as written.
    ref.read(readerScriptPreferenceProvider.notifier).setScript('bo', null);
    await _settle(tester);
    expect(find.text(_first), findsWidgets);
    expect(find.text('tö pa ngö'), findsNothing);
  });

  testWidgets('in Roman phonetics, the page waits for the Latin font picked '
      'for the original', (tester) async {
    final loading = Completer<void>();
    await _pump(
      tester,
      stored: {
        StorageKeys.readerScriptPreference: jsonEncode({'bo': 'phonetic'}),
        StorageKeys.readerFonts: const ReaderFontChoices()
            .pick(
              ReaderFontLine.original,
              ReaderScript.latin,
              ReaderFonts.literata,
            )
            .toJson(),
      },
      overrides: [
        readerFontPreloadProvider.overrideWith((ref, key) => loading.future),
      ],
      // As over the network: the stored picks are in before the text.
      loadTime: const Duration(milliseconds: 100),
    );
    // The verses are in Latin letters, so it is Literata they wait for.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('tö pa ngö'), findsNothing);

    loading.complete();
    await _settle(tester);
    expect(find.text('tö pa ngö'), findsOneWidget);
  });
}
