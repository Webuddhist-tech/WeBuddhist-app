import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_hero_card.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

GroupAccumulatorDetail _detail({String? textId, String? mantraId}) {
  return GroupAccumulatorDetail(
    id: 'acc-1',
    presetAccumulatorId: 'preset-1',
    textId: textId,
    mantraId: mantraId,
    groupId: 'group-1',
    title: '1,00,000 recitations of the 21 Taras',
    memberCount: 12,
    targetCount: 100000,
    totalCount: 5000,
  );
}

ReaderResponse _reader(String title) {
  return ReaderResponse(
    textDetail: TextDetail(
      id: 'text-1',
      title: title,
      language: 'en',
      type: 'text',
      groupId: 'group-1',
      isPublished: true,
      createdDate: '',
      updatedDate: '',
      publishedDate: '',
      publishedBy: '',
    ),
    content: Toc(id: 'toc', textId: 'text-1', sections: const []),
    size: 1,
    paginationDirection: 'next',
    currentSegmentPosition: 0,
    totalSegments: 0,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required GroupAccumulatorDetail detail,
  VoidCallback? onTextTap,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GroupAccumulatorHeroCard(
            detail: detail,
            hasJoined: true,
            isDark: false,
            onTextTap: onTextTap,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('text pill shows the text title and opens the reader', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      detail: _detail(textId: 'text-1'),
      onTextTap: () => taps++,
      overrides: [
        textDetailsFutureProvider.overrideWith(
          (ref, params) async => Right(_reader('Praise to the 21 Taras')),
        ),
      ],
    );

    expect(find.text('1,00,000 recitations of the 21 Taras'), findsOneWidget);
    expect(find.text('Praise to the 21 Taras'), findsOneWidget);
    expect(find.text('12 participants'), findsOneWidget);
    expect(find.text('Recite now'), findsOneWidget);

    await tester.tap(find.text('Praise to the 21 Taras'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('mantra line shows the pronunciation and is not a button', (
    tester,
  ) async {
    await _pump(
      tester,
      detail: _detail(mantraId: 'mantra-1'),
      overrides: [
        malaCatalogueProvider.overrideWith(
          () => ScreenCacheNotifier.fixed(const Right([
            Mantra(
              presetId: 'preset-1',
              mantra: MantraText(
                id: 'mantra-1',
                text: 'ཨོཾ་ཨཱཿ་ཧཱུྃ',
                pronunciation: 'Om Ah Hung Vajra Guru Padma Siddhi Hung',
              ),
            ),
          ])),
        ),
      ],
    );

    expect(
      find.text('Om Ah Hung Vajra Guru Padma Siddhi Hung'),
      findsOneWidget,
    );
    expect(find.text('12 participants'), findsOneWidget);
    expect(find.text('Praise to the 21 Taras'), findsNothing);

    await tester.tap(find.text('Om Ah Hung Vajra Guru Padma Siddhi Hung'));
    await tester.pump();
  });

  testWidgets('mantra line falls back to the script', (tester) async {
    await _pump(
      tester,
      detail: _detail(mantraId: 'mantra-1'),
      overrides: [
        malaCatalogueProvider.overrideWith(
          () => ScreenCacheNotifier.fixed(const Right([
            Mantra(
              presetId: 'preset-1',
              mantra: MantraText(id: 'mantra-1', text: 'ཨོཾ་ཨཱཿ་ཧཱུྃ'),
            ),
          ])),
        ),
      ],
    );

    expect(find.text('ཨོཾ་ཨཱཿ་ཧཱུྃ'), findsOneWidget);
  });
}
