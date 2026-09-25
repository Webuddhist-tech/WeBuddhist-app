import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

void main() {
  group('readerOpenSourceFor', () {
    test('maps every navigation source to a tracking plan source', () {
      const expected = {
        NavigationSource.plan: 'plan',
        NavigationSource.routine: 'routine',
        NavigationSource.recitationList: 'recitation',
        NavigationSource.search: 'search',
        NavigationSource.deepLink: 'deep_link',
        NavigationSource.groupRecitationCollection: 'collection',
        NavigationSource.myRecitationCollection: 'collection',
        NavigationSource.groupAccumulatorChant: 'group_chant',
        NavigationSource.normal: 'library',
      };
      for (final source in NavigationSource.values) {
        expect(
          readerOpenSourceFor(source).key,
          expected[source],
          reason: '$source',
        );
      }
      expect(readerOpenSourceFor(null).key, 'library');
    });

    test('multi-word sources are snake_case', () {
      expect(ReaderOpenSource.aiSearch.key, 'ai_search');
      expect(ReaderOpenSource.bookmark.key, 'bookmark');
    });
  });

  group('readerLayoutFor', () {
    test('follows the parallel translation toggle', () {
      final off = ReaderDualLayoutSettings.initial();
      expect(readerLayoutFor(off), ReaderLayout.single);
      expect(
        readerLayoutFor(off.copyWith(secondaryEnabled: true)),
        ReaderLayout.interlinear,
      );
    });
  });

  group('ReaderSessionTracker', () {
    late DateTime now;
    late ReaderSessionTracker tracker;

    setUp(() {
      now = DateTime(2026, 9, 24, 10);
      tracker = ReaderSessionTracker(now: () => now);
    });

    test('a session that ends in the background stops at leaving', () {
      tracker.start();
      tracker.pageLoaded();
      tracker.pageLoaded();
      tracker.segmentReached(7);
      tracker.segmentReached(3);
      now = now.add(const Duration(seconds: 90));
      tracker.background();
      now = now.add(const Duration(seconds: 45));
      expect(tracker.backgroundedFor, const Duration(seconds: 45));

      final summary = tracker.end()!;
      expect(summary.duration, const Duration(seconds: 90));
      expect(summary.pagesLoaded, 2);
      expect(summary.maxSegmentNumber, 7);
      expect(tracker.isActive, isFalse);
      expect(tracker.end(), isNull);
    });

    test('coming back within the grace keeps the session going', () {
      tracker.start();
      now = now.add(const Duration(seconds: 10));
      tracker.background();
      now = now.add(const Duration(seconds: 5));
      tracker.foreground();
      expect(tracker.backgroundedFor, Duration.zero);
      now = now.add(const Duration(seconds: 15));

      expect(tracker.end()!.duration, const Duration(seconds: 30));
    });

    test('a new session keeps the furthest segment but not the pages', () {
      tracker.start();
      tracker.pageLoaded();
      tracker.segmentReached(40);
      tracker.end();

      tracker.start();
      final summary = tracker.end()!;
      expect(summary.pagesLoaded, 0);
      expect(summary.maxSegmentNumber, 40);
    });
  });

  group('ReaderAnalytics', () {
    late RecordingAnalyticsService service;
    late ReaderAnalytics analytics;

    setUp(() {
      service = RecordingAnalyticsService();
      analytics = ReaderAnalytics(service);
    });

    test('readerOpened carries the text, where from and how it is shown', () {
      analytics.readerOpened(
        textId: 't1',
        textTitle: 'Heart Sutra',
        source: ReaderOpenSource.deepLink,
        language: 'bo',
        versionId: 'v1',
        script: 'wylie',
        layout: ReaderLayout.interlinear,
        entrySegment: 's9',
      );

      expect(service.eventNames, [AnalyticsEvents.readerOpened]);
      expect(service.events.single.properties, {
        'text_id': 't1',
        'text_title': 'Heart Sutra',
        'source': 'deep_link',
        'language': 'bo',
        'version_id': 'v1',
        'script': 'wylie',
        'layout': 'interlinear',
        'entry_segment': 's9',
      });
    });

    test('readerPageLoaded carries the page and how long it took', () {
      analytics.readerPageLoaded(
        textId: 't1',
        pageNumber: 2,
        segmentCount: 20,
        loadMs: 340,
      );

      expect(service.eventNames, [AnalyticsEvents.readerPageLoaded]);
      expect(service.events.single.properties, {
        'text_id': 't1',
        'page_number': 2,
        'segment_count': 20,
        'load_ms': 340,
      });
    });

    test('readerSessionEnded sends the reach only with a known total', () {
      const session = ReaderSessionSummary(
        duration: Duration(seconds: 125),
        pagesLoaded: 3,
        maxSegmentNumber: 30,
      );
      analytics.readerSessionEnded(
        textId: 't1',
        session: session,
        segmentsTotal: 120,
      );
      analytics.readerSessionEnded(textId: 't1', session: session);
      analytics.readerSessionEnded(
        textId: 't1',
        session: session,
        segmentsTotal: 0,
      );

      expect(service.events.first.properties, {
        'text_id': 't1',
        'duration_s': 125,
        'pages_loaded': 3,
        'max_segment_number': 30,
        'segments_total': 120,
        'pct_reached': 25,
      });
      for (final event in service.events.skip(1)) {
        expect(event.name, AnalyticsEvents.readerSessionEnded);
        expect(event.properties, {
          'text_id': 't1',
          'duration_s': 125,
          'pages_loaded': 3,
          'max_segment_number': 30,
        });
      }
    });

    test('actionTapped names the bar action', () {
      analytics.actionTapped(action: ReaderAction.commentary, textId: 't1');

      expect(service.eventNames, [AnalyticsEvents.readerActionTapped]);
      expect(service.events.single.properties, {
        'action': 'commentary',
        'text_id': 't1',
      });
    });
  });
}
