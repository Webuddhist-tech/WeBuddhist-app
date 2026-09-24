import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_analytics.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/analytics/recording_analytics_service.dart';
import 'fakes/fake_local_storage.dart';

ReaderResponse _page() => ReaderResponse(
  textDetail: TextDetail(
    id: 'v1',
    title: 'Heart Sutra',
    language: 'bo',
    type: 'text',
    groupId: 'g1',
    isPublished: true,
    createdDate: '',
    updatedDate: '',
    publishedDate: '',
    publishedBy: '',
  ),
  content: Toc(
    id: 'toc',
    textId: 't1',
    sections: [
      Section(
        id: 's1',
        sectionNumber: 1,
        segments: const [
          Segment(segmentId: 'a', segmentNumber: 1, content: 'a'),
          Segment(segmentId: 'b', segmentNumber: 2, content: 'b'),
        ],
        sections: [
          Section(
            id: 's2',
            sectionNumber: 2,
            segments: const [
              Segment(segmentId: 'c', segmentNumber: 3, content: 'c'),
            ],
          ),
        ],
      ),
    ],
  ),
  size: 3,
  paginationDirection: 'next',
  currentSegmentPosition: 3,
  totalSegments: 12,
);

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingAnalyticsService service;
  late ProviderContainer container;
  const params = ReaderParams(
    textId: 't1',
    navigationContext: NavigationContext(
      source: NavigationSource.recitationList,
    ),
  );

  setUp(() {
    service = RecordingAnalyticsService();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        readerAnalyticsProvider.overrideWithValue(ReaderAnalytics(service)),
        textDetailsFutureProvider.overrideWith((ref, params) => right(_page())),
      ],
    );
  });

  test('the first page fires reader_page_loaded then reader_opened', () async {
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);
    await _settle();
    expect(
      container.read(readerNotifierProvider(params)).status,
      ReaderStatus.loaded,
    );

    expect(service.eventNames, [
      AnalyticsEvents.readerPageLoaded,
      AnalyticsEvents.readerOpened,
    ]);
    final page = service.events.first.properties;
    expect(page['text_id'], 't1');
    expect(page['page_number'], 1);
    expect(page['segment_count'], 3);
    expect(page['load_ms'], isA<int>());
    expect(service.events.last.properties, {
      'text_id': 't1',
      'text_title': 'Heart Sutra',
      'source': 'recitation',
      'language': 'bo',
      'version_id': 'v1',
      'script': null,
      'layout': 'single',
      'entry_segment': null,
    });
    container.dispose();
  });

  test('disposing the reader ends the session with its reach', () async {
    final sub = container.listen(readerNotifierProvider(params), (_, __) {});
    addTearDown(sub.close);
    await _settle();
    final notifier = container.read(readerNotifierProvider(params).notifier);
    notifier.markSegmentReached(6);
    notifier.markSegmentReached(2);
    // A short trip to the background is not the end of the session.
    notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
    notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(
      service.eventNames,
      isNot(contains(AnalyticsEvents.readerSessionEnded)),
    );

    container.dispose();

    expect(service.eventNames.last, AnalyticsEvents.readerSessionEnded);
    final ended = service.events.last.properties;
    expect(ended['text_id'], 't1');
    expect(ended['duration_s'], isA<int>());
    expect(ended['pages_loaded'], 1);
    expect(ended['max_segment_number'], 6);
    expect(ended['segments_total'], 12);
    expect(ended['pct_reached'], 50);
  });
}
