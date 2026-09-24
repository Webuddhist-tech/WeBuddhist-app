import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/datasource/reader_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/data/repositories/texts_repository.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'fakes/fake_local_storage.dart';

/// E1 is the English translation of the Tibetan root edition E2.
class _FakeSettings implements ReaderSettingsRemoteDatasource {
  @override
  Future<ReaderVersionDetail> fetchVersionInfo({
    required String versionId,
  }) async {
    switch (versionId) {
      case 'E1':
        return const ReaderVersionDetail(
          id: 'E1',
          title: 'Tara Essence',
          language: 'en',
          parentId: 'E2',
        );
      case 'E2':
        return const ReaderVersionDetail(
          id: 'E2',
          title: 'ཟབ་ཏིག',
          language: 'bo',
        );
    }
    throw NotFoundException('Edition $versionId not found');
  }

  @override
  Future<ReaderLanguagesResponse> fetchLanguages({required String textId}) =>
      throw UnimplementedError();

  @override
  Future<ReaderScriptsResponse> fetchScripts({
    required String textId,
    required String language,
  }) => throw UnimplementedError();

  @override
  Future<ReaderVersionsResponse> fetchVersions({
    required String textId,
    required String language,
  }) => throw UnimplementedError();
}

/// Aligns the translation's verses en-N to the root's E2-N.
class _FakeTexts implements TextsRepository {
  final aligned = <(String, String, String)>[];

  @override
  Future<String?> alignSegment({
    required String segmentId,
    required String sourceTextId,
    required String targetTextId,
  }) async {
    aligned.add((segmentId, sourceTextId, targetTextId));
    if (!segmentId.startsWith('en-')) return null;
    return 'E2-${segmentId.substring(3)}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReaderResponse _page(String editionId) {
  final language = editionId == 'E2' ? 'bo' : 'en';
  return ReaderResponse(
    textDetail: TextDetail(
      id: editionId,
      title: 'Title $editionId',
      language: language,
      type: 'text',
      groupId: '',
      isPublished: true,
      createdDate: '',
      updatedDate: '',
      publishedDate: '',
      publishedBy: '',
    ),
    content: Toc(
      id: editionId,
      textId: 'T-$editionId',
      sections: [
        Section(
          id: editionId,
          sectionNumber: 1,
          segments: [
            Segment(segmentId: '$editionId-1', segmentNumber: 1, content: 'a'),
          ],
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
}

Future<ReaderState> _loaded(ProviderContainer container, ReaderParams params) async {
  for (var i = 0; i < 50; i++) {
    final state = container.read(readerNotifierProvider(params));
    if (state.status == ReaderStatus.loaded || state.isError) return state;
    await Future<void>.delayed(Duration.zero);
  }
  fail('reader did not finish loading');
}

void main() {
  late FakeLocalStorage storage;
  late List<TextDetailsParams> fetches;
  late _FakeTexts texts;
  late ProviderContainer container;

  setUp(() {
    storage = FakeLocalStorage();
    fetches = [];
    texts = _FakeTexts();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        textsRepositoryProvider.overrideWithValue(texts),
        readerSettingsRemoteDatasourceProvider.overrideWithValue(
          _FakeSettings(),
        ),
        textDetailsFutureProvider.overrideWith((ref, params) async {
          fetches.add(params);
          return Right<Failure, ReaderResponse>(_page(params.textId));
        }),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('a translation loads its root as the original and shows itself as '
      'the translation', () async {
    const params = ReaderParams(textId: 'E1');
    int? fetchesWhenLoaded;
    final sub = container.listen(readerNotifierProvider(params), (_, next) {
      if (next.status == ReaderStatus.loaded) {
        fetchesWhenLoaded ??= fetches.length;
      }
    });
    addTearDown(sub.close);

    final state = await _loaded(container, params);

    expect(state.status, ReaderStatus.loaded);
    // The root's page, then the translation's first page (the request its
    // stream makes), both before the reader reports loaded so the original
    // never shows on its own.
    expect(fetches.map((f) => (f.textId, f.versionId)), [
      ('E2', null),
      ('E2', 'E1'),
    ]);
    expect(fetches.last.segmentId, 'E2-1');
    expect(fetches.last.direction, 'next');
    expect(fetchesWhenLoaded, 2);
    expect(state.textDetail?.id, 'E2');
    expect(state.openedTranslation?.id, 'E1');
    expect(state.openedText?.title, 'Tara Essence');
    expect(state.openedText?.language, 'en');

    final dual = container.read(readerDualSettingsProvider('E1'));
    expect(dual.primary.versionId, 'E2');
    expect(dual.primary.languageCode, 'bo');
    expect(dual.secondary.versionId, 'E1');
    expect(dual.secondary.versionLabel, 'Tara Essence');
    expect(dual.secondaryEnabled, isTrue);
    expect(dual.originalVisible, isFalse);
    expect(storage.values, isEmpty, reason: 'per-text layout only');
  });

  test("a plan's verses of the translation map to the root's", () async {
    final params = ReaderParams(
      textId: 'E1',
      segmentId: 'en-1',
      navigationContext: NavigationContext(
        source: NavigationSource.plan,
        planTextItems: [
          PlanTextItem.sourceReference(
            textId: 'E1',
            title: "Today's Verses",
            segmentIds: const ['en-1', 'en-2', 'loose'],
          ),
        ],
        currentTextIndex: 0,
      ),
    );
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);

    final state = await _loaded(container, params);

    expect(state.segmentAliases, {'en-1': 'E2-1', 'en-2': 'E2-2'});
    expect(texts.aligned.map((a) => (a.$2, a.$3)).toSet(), {('E1', 'E2')});
    expect(state.loadedSegmentId('loose'), 'loose');
    // The root page is fetched at the mapped verse.
    expect(fetches.first.textId, 'E2');
    expect(fetches.first.segmentId, 'E2-1');
    // The translation stream still anchors on its own verse.
    expect(fetches.last.versionId, 'E1');
    expect(fetches.last.segmentId, 'en-1');
  });

  test('a requested verse the root lacks opens the translation as itself',
      () async {
    const params = ReaderParams(textId: 'E1', segmentId: 'loose');
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);

    final state = await _loaded(container, params);

    expect(state.openedTranslation, isNull);
    expect(state.segmentAliases, isEmpty);
    expect(fetches.map((f) => (f.textId, f.segmentId)), [('E1', 'loose')]);
    final dual = container.read(readerDualSettingsProvider('E1'));
    expect(dual.primary.versionId, isNull);
  });

  test('a root edition keeps the loaded text as the original', () async {
    const params = ReaderParams(textId: 'E2');
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);

    final state = await _loaded(container, params);

    expect(fetches.map((f) => f.textId), ['E2']);
    expect(state.openedTranslation, isNull);
    expect(state.openedText?.id, 'E2');
    expect(state.segmentAliases, isEmpty);
    expect(texts.aligned, isEmpty);
    final dual = container.read(readerDualSettingsProvider('E2'));
    expect(dual.primary.versionId, isNull);
    expect(dual.secondaryEnabled, isFalse);
  });

  test('a persisted "translation only" preference does not undo the seed '
      'when it loads late', () async {
    storage.values[StorageKeys.readerOriginalVisible] = true;
    storage.values[StorageKeys.readerSecondaryEnabled] = false;
    const params = ReaderParams(textId: 'E1');
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);

    await _loaded(container, params);
    await Future.wait([
      container.read(readerSecondaryEnabledProvider.notifier).loaded,
      container.read(readerOriginalVisibleProvider.notifier).loaded,
    ]);
    await Future<void>.delayed(Duration.zero);

    final dual = container.read(readerDualSettingsProvider('E1'));
    expect(dual.secondaryEnabled, isTrue);
    expect(dual.originalVisible, isFalse);
  });

  test('an unknown edition still opens as itself', () async {
    const params = ReaderParams(textId: 'E9');
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);

    final state = await _loaded(container, params);

    expect(state.status, ReaderStatus.loaded);
    expect(fetches.map((f) => f.textId), ['E9']);
    expect(state.openedTranslation, isNull);
  });
}
