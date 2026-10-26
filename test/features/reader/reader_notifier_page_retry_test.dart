import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
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
  // Pages (anchor, direction) that fail this many more times before working.
  late Map<(String?, String?), int> failuresLeft;
  late ProviderContainer container;

  setUp(() {
    fetches = [];
    failuresLeft = {};
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        readerSettingsRemoteDatasourceProvider.overrideWithValue(
          FakeReaderSettingsDatasource(languages: const [], versions: const {}),
        ),
        textDetailsFutureProvider.overrideWith((ref, params) async {
          fetches.add(params);
          final key = (params.segmentId, params.direction);
          final left = failuresLeft[key] ?? 0;
          if (left > 0) {
            failuresLeft[key] = left - 1;
            return const Left<Failure, ReaderResponse>(
              NetworkFailure('offline'),
            );
          }
          return Right<Failure, ReaderResponse>(_page(params));
        }),
      ],
    );
  });

  tearDown(() => container.dispose());

  int fetchCount(String segmentId, String direction) => fetches
      .where((f) => f.segmentId == segmentId && f.direction == direction)
      .length;

  test('a next page that failed once is fetched again on the next try',
      () async {
    final segmentIds = _ids(3, 30);
    final params = ReaderParams(
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
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);
    await _loaded(container, params);
    final notifier = container.read(readerNotifierProvider(params).notifier);
    failuresLeft[('T-23', 'next')] = 1;

    expect(await notifier.loadNextPage(fromSegmentId: 'T-23'), isFalse);
    expect(await notifier.loadNextPage(fromSegmentId: 'T-23'), isTrue);

    expect(fetchCount('T-23', 'next'), 2);
    expect(
      container.read(readerNotifierProvider(params)).content!.lastSegmentId,
      'T-42',
    );
  });

  test('loadPreviousPage reports 0 on failure and retries the page later',
      () async {
    const params = ReaderParams(textId: 'T', segmentId: 'T-21');
    // The pre-load on open fails, and so does the first scroll-up.
    failuresLeft[('T-21', 'previous')] = 2;
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);
    final opened = await _loaded(container, params);
    expect(opened.content!.firstSegmentId, 'T-21');
    expect(opened.hasPreviousPage, isTrue);
    final notifier = container.read(readerNotifierProvider(params).notifier);

    expect(await notifier.loadPreviousPage(), 0);

    final before = container
        .read(readerNotifierProvider(params))
        .content!
        .itemCount;
    final added = await notifier.loadPreviousPage();
    final state = container.read(readerNotifierProvider(params));

    expect(fetchCount('T-21', 'previous'), 3);
    expect(state.content!.firstSegmentId, 'T-1');
    expect(added, state.content!.itemCount - before);
    expect(added, greaterThan(0));
  });
}
