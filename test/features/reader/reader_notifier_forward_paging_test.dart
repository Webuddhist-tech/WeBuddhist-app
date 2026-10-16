import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/collapsed_reader_items.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'fakes/fake_local_storage.dart';
import 'fakes/fake_reader_settings_datasource.dart';

const _total = 45;
const _pageSize = 20;

int _number(String segmentId) => int.parse(segmentId.split('-').last);

/// A page of text T, [_pageSize] verses from the anchor (or before it).
ReaderResponse _page(TextDetailsParams params) {
  final anchor = params.segmentId == null ? 1 : _number(params.segmentId!);
  final int first;
  final int last;
  if (params.direction == 'previous') {
    first = (anchor - _pageSize).clamp(1, _total);
    last = anchor - 1;
  } else {
    first = anchor;
    last = (anchor + _pageSize - 1).clamp(1, _total);
  }
  return ReaderResponse(
    textDetail: TextDetail(
      id: 'T',
      title: 'Text',
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
      id: 'T',
      textId: 'T',
      sections: [
        Section(
          id: 'T',
          sectionNumber: 1,
          segments: [
            for (var n = first; n <= last; n++)
              Segment(segmentId: 'T-$n', segmentNumber: n, content: 'v$n'),
          ],
          sections: const [],
        ),
      ],
    ),
    size: _pageSize,
    paginationDirection: params.direction ?? 'next',
    currentSegmentPosition: first,
    lastSegmentPosition: last,
    totalSegments: _total,
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

List<String> _ids(int from, int to) => [
  for (var n = from; n <= to; n++) 'T-$n',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<TextDetailsParams> fetches;
  late ProviderContainer container;

  setUp(() {
    fetches = [];
    container = ProviderContainer(
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
    );
  });

  tearDown(() => container.dispose());

  ReaderParams collapsed(List<String> segmentIds) => ReaderParams(
    textId: 'T',
    segmentId: segmentIds.first,
    segmentIds: segmentIds,
    navigationContext: NavigationContext(
      source: NavigationSource.plan,
      planTextItems: [
        PlanTextItem.sourceReference(
          textId: 'T',
          title: 'Verses',
          segmentIds: segmentIds,
        ),
      ],
      currentTextIndex: 0,
    ),
  );

  test('a collapsed reader loads one page at its first verse, nothing before',
      () async {
    final params = collapsed(_ids(3, 30));
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);

    final state = await _loaded(container, params);

    expect(fetches.map((f) => (f.segmentId, f.direction)), [('T-3', 'next')]);
    expect(state.content!.firstSegmentId, 'T-3');
    expect(state.content!.lastSegmentId, 'T-22');
    expect(state.hasNextPage, isTrue);
    expect(nextSegmentToLoad(state.content!, params.segmentIds!), 'T-23');
  });

  test('a whole text near its top still pre-loads the page before', () async {
    const params = ReaderParams(textId: 'T', segmentId: 'T-3');
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);

    final state = await _loaded(container, params);

    expect(fetches.map((f) => (f.segmentId, f.direction)), [
      ('T-3', 'next'),
      ('T-3', 'previous'),
    ]);
    expect(state.content!.firstSegmentId, 'T-1');
  });

  test('loadNextPage appends the page at the verse asked for', () async {
    final params = collapsed(_ids(3, 30));
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);
    await _loaded(container, params);
    final notifier = container.read(readerNotifierProvider(params).notifier);

    final merged = await notifier.loadNextPage(fromSegmentId: 'T-23');

    expect(merged, isTrue);
    expect(fetches.last.segmentId, 'T-23');
    final state = container.read(readerNotifierProvider(params));
    expect(state.content!.lastSegmentId, 'T-42');
    expect(state.isLoadingNext, isFalse);
    expect(nextSegmentToLoad(state.content!, params.segmentIds!), isNull);
  });

  test('loadNextPage without a verse continues after the loaded window',
      () async {
    final params = collapsed(_ids(30, 45));
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);
    await _loaded(container, params);
    final notifier = container.read(readerNotifierProvider(params).notifier);

    // T-30..T-45 is the end of the text: nothing after it.
    expect(container.read(readerNotifierProvider(params)).hasNextPage, isFalse);
    expect(await notifier.loadNextPage(), isFalse);
    expect(fetches, hasLength(1));
  });
}
