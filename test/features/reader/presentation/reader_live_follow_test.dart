import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_content_part.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_live_follow.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_client.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_live_notifier.dart';
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
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../fakes/fake_local_storage.dart';
import '../fakes/fake_reader_settings_datasource.dart';

class _FakeChannel implements WebSocketChannel {
  final incoming = StreamController<dynamic>();

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  late final WebSocketSink sink = _FakeSink();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSink implements WebSocketSink {
  @override
  void add(dynamic data) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _sessionInfo =
    '{"type":"session_info","event_id":"ev1","is_operator":false}';

String _position(int verse) =>
    '{"type":"position","event_id":"ev1","text_id":"A",'
    '"segment_id":"A-$verse","revision":$verse,"round_number":1}';

const _verses = 30;

const _params = ReaderParams(
  textId: 'A',
  navigationContext: NavigationContext(
    source: NavigationSource.plan,
    eventId: 'ev1',
  ),
);

ReaderResponse _page(TextDetailsParams params) => ReaderResponse(
  textDetail: TextDetail(
    id: 'A',
    title: 'Praises',
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
    id: 'A',
    textId: 'A',
    sections: [
      Section(
        id: 'A-root',
        sectionNumber: 0,
        segments: [
          for (var n = 1; n <= _verses; n++)
            Segment(
              segmentId: 'A-$n',
              segmentNumber: n,
              content: 'Verse $n. ${'Om tare tuttare ture soha. ' * 4}',
            ),
        ],
        sections: const [],
      ),
    ],
  ),
  size: _verses,
  paginationDirection: 'next',
  currentSegmentPosition: 1,
  lastSegmentPosition: _verses,
  totalSegments: _verses,
);

/// A reader following event ev1's live recitation over a socket the test
/// feeds by hand, its live verse at [verse]. [bars] records each time focus
/// mode hides (true) or shows (false) the reader's bars.
Future<RecitationLiveNotifier> _pumpLiveReader(
  WidgetTester tester, {
  int verse = 5,
  List<bool>? bars,
}) async {
  final channel = _FakeChannel();
  final live = RecitationLiveNotifier(
    eventId: 'ev1',
    restBaseUrl: 'https://api.example.com/api/v1',
    getToken: () async => 'tok',
    clientFactory: () => RecitationLiveClient(connect: (_) => channel),
    observeLifecycle: false,
  );
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
        recitationLiveProvider.overrideWith((ref, id) => live),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReaderContentPart(
            sources: const [_params],
            onScrollDirectionChanged: bars?.add,
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
  channel.incoming.add(_sessionInfo);
  channel.incoming.add(_position(verse));
  await _settle(tester);
  return live;
}

/// The operator reads this very text, so no verse needs aligning.
class _SameTextAligner implements TextsRepository {
  @override
  Future<String?> alignSegment({
    required String segmentId,
    required String sourceTextId,
    required String targetTextId,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _pageSize = 20;

/// Verses per text in a paged plan; ids are `<text>-<number>`.
const _planTotals = {'A': 80, 'B': 20};

/// A page of [_pageSize] verses from the anchor, like the library serves.
ReaderResponse _planPage(TextDetailsParams params) {
  final textId = params.textId;
  final total = _planTotals[textId]!;
  final first =
      params.segmentId == null
          ? 1
          : int.parse(params.segmentId!.split('-').last);
  final last = (first + _pageSize - 1).clamp(1, total);
  return ReaderResponse(
    textDetail: TextDetail(
      id: textId,
      title: 'Text $textId',
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
      id: textId,
      textId: textId,
      sections: [
        Section(
          id: textId,
          sectionNumber: 1,
          segments: [
            for (var n = first; n <= last; n++)
              Segment(
                segmentId: '$textId-$n',
                segmentNumber: n,
                content: '$textId verse $n. ${'Om tare tuttare ture soha. ' * 4}',
              ),
          ],
          sections: const [],
        ),
      ],
    ),
    size: _pageSize,
    paginationDirection: 'next',
    currentSegmentPosition: first,
    lastSegmentPosition: last,
    totalSegments: total,
  );
}

/// A plan task's page, collapsed, following event ev1 live. Each source is
/// a text with its picked verses, or null for the whole text. Returns the
/// live notifier and every page fetched.
Future<(RecitationLiveNotifier, List<TextDetailsParams>)> _pumpLivePlan(
  WidgetTester tester,
  Map<String, List<String>?> picks, {
  required int verse,
  ValueNotifier<double>? progress,
  Duration pageDelay = Duration.zero,
}) async {
  final channel = _FakeChannel();
  final live = RecitationLiveNotifier(
    eventId: 'ev1',
    restBaseUrl: 'https://api.example.com/api/v1',
    getToken: () async => 'tok',
    clientFactory: () => RecitationLiveClient(connect: (_) => channel),
    observeLifecycle: false,
  );
  final item = PlanTextItem.sources(
    sources: [
      for (final MapEntry(key: textId, value: ids) in picks.entries)
        PlanSourceRef(textId: textId, segmentIds: ids),
    ],
    title: 'Prayers',
  );
  final ctx = NavigationContext(
    source: NavigationSource.plan,
    planId: 'plan',
    dayNumber: 1,
    eventId: 'ev1',
    planTextItems: [item],
    currentTextIndex: 0,
  );
  final fetches = <TextDetailsParams>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        readerSettingsRemoteDatasourceProvider.overrideWithValue(
          FakeReaderSettingsDatasource(languages: const [], versions: const {}),
        ),
        textsRepositoryProvider.overrideWithValue(_SameTextAligner()),
        textDetailsFutureProvider.overrideWith((ref, params) async {
          fetches.add(params);
          if (pageDelay > Duration.zero) await Future.delayed(pageDelay);
          return Right<Failure, ReaderResponse>(_planPage(params));
        }),
        recitationLiveProvider.overrideWith((ref, id) => live),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReaderContentPart(
            sources: [
              for (final source in item.sources)
                ReaderParams(
                  textId: source.textId,
                  segmentId: source.firstSegmentId,
                  segmentIds: source.segmentIds,
                  navigationContext: ctx,
                ),
            ],
            progress: progress,
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
  channel.incoming.add(_sessionInfo);
  channel.incoming.add(_position(verse));
  await _settle(tester);
  return (live, fetches);
}

/// The first source's verse numbers as loaded, in list order.
List<int> _loadedVerses(WidgetTester tester) {
  final part = tester.widget<ReaderContentPart>(find.byType(ReaderContentPart));
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ReaderContentPart)),
  );
  final content =
      container.read(readerNotifierProvider(part.sources.first)).content!;
  return [
    for (final item in content.items)
      if (item.segment != null) item.segment!.segmentNumber,
  ];
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  group('where the live verse sits', () {
    test('its middle is held two thirds down', () {
      final target = liveScrollTarget(index: 8, heightFraction: 0.1)!;
      expect(target.index, 8);
      expect(target.alignment, closeTo(2 / 3 - 0.05, 1e-9));
    });

    test('a verse not laid out yet is placed by its top', () {
      expect(liveScrollTarget(index: 8)!.alignment, closeTo(2 / 3, 1e-9));
    });

    test('a long verse still fits on screen', () {
      final target = liveScrollTarget(index: 8, heightFraction: 0.8)!;
      expect(target.alignment, closeTo(0.2, 1e-9));
    });

    test('a verse taller than the screen is aligned by its top', () {
      expect(liveScrollTarget(index: 8, heightFraction: 1.4), (
        index: 8,
        alignment: 0.0,
      ));
    });

    test('near the start the list stays at its top', () {
      expect(
        liveScrollTarget(index: 2, heightFraction: 0.1, distanceFromStart: 0.3),
        (index: 0, alignment: 0.0),
      );
      // Far enough down, the verse is held in its place.
      expect(
        liveScrollTarget(
          index: 6,
          heightFraction: 0.1,
          distanceFromStart: 0.9,
        )!.index,
        6,
      );
    });

    test('under a new section heading the page waits for the verse', () {
      expect(
        liveScrollTarget(
          index: 12,
          heightFraction: 0.1,
          currentTop: 0.3,
          afterSectionJump: true,
        ),
        isNull,
      );
      // Past its place, it is held there.
      expect(
        liveScrollTarget(
          index: 14,
          heightFraction: 0.1,
          currentTop: 0.8,
          afterSectionJump: true,
        ),
        isNotNull,
      );
    });
  });

  group('controller jumps', () {
    test('a new section is a jump', () {
      expect(
        isLiveSectionJump(
          previousSection: 'a',
          section: 'b',
          previousRound: 1,
          round: 1,
        ),
        isTrue,
      );
    });

    test('a new round of the same section is a jump', () {
      expect(
        isLiveSectionJump(
          previousSection: 'a',
          section: 'a',
          previousRound: 1,
          round: 2,
        ),
        isTrue,
      );
    });

    test('the next verse of the same section and round is not', () {
      expect(
        isLiveSectionJump(
          previousSection: 'a',
          section: 'a',
          previousRound: 1,
          round: 1,
        ),
        isFalse,
      );
    });

    test('the first position after joining or rejoining is not', () {
      expect(
        isLiveSectionJump(
          previousSection: null,
          section: 'b',
          previousRound: null,
          round: 3,
        ),
        isFalse,
      );
    });
  });

  group('a plan task\'s progress line', () {
    testWidgets('counts the task\'s verses, not only those loaded', (
      tester,
    ) async {
      final progress = ValueNotifier<double>(0);
      // Sixty picked verses; only the first page of twenty is in.
      await _pumpLivePlan(tester, {
        'A': [for (var n = 1; n <= 60; n++) 'A-$n'],
      }, verse: 1, progress: progress);
      expect(_loadedVerses(tester).length, lessThan(60));

      // A few verses fit on screen: a small share of sixty.
      expect(progress.value, greaterThan(0));
      expect(progress.value, lessThan(0.2));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('loading toward a far live verse', () {
    testWidgets('stops between pages once the reader pauses', (tester) async {
      // A plan task, so live walks page by page; each page takes a while
      // and verse 75 is four pages away.
      final (live, fetches) = await _pumpLivePlan(
        tester,
        {
          'A': null,
          'B': ['B-1', 'B-2'],
        },
        verse: 75,
        pageDelay: const Duration(seconds: 1),
      );
      expect(_loadedVerses(tester), isNot(contains(75)));

      live.pauseFollowing();
      final asked = fetches.length;
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // At most the page already asked for lands; nothing more is fetched
      // toward the old verse, and pausing is not being out of sync.
      expect(fetches.length, lessThanOrEqualTo(asked));
      expect(_loadedVerses(tester), isNot(contains(75)));
      expect(live.state.outOfSync, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('a live verse past the loaded ones on a plan task', () {
    testWidgets('a whole text loads every verse up to it, in order', (
      tester,
    ) async {
      // Two texts, so the page is collapsed; text A is whole.
      final (live, _) = await _pumpLivePlan(tester, {
        'A': null,
        'B': ['B-1', 'B-2'],
      }, verse: 65);

      // Page by page up to the live verse's, with nothing skipped; the rest
      // loads as the reader nears the end.
      final loaded = _loadedVerses(tester);
      expect(loaded, [for (var n = 1; n <= loaded.length; n++) n]);
      expect(loaded, contains(65));
      expect(live.state.outOfSync, isFalse);
      expect(find.textContaining('A verse 65.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('picked verses before it load first and stay in order', (
      tester,
    ) async {
      final picked = [for (var n = 1; n <= 77; n += 4) 'A-$n'];
      final (live, _) = await _pumpLivePlan(tester, {
        'A': picked,
      }, verse: 61);

      final loaded = _loadedVerses(tester);
      for (var n = 1; n <= 61; n += 4) {
        expect(loaded, contains(n), reason: 'picked verse A-$n');
      }
      expect(loaded, [...loaded]..sort());
      expect(live.state.outOfSync, isFalse);
      expect(find.textContaining('A verse 61.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a verse the text lacks ends out of sync, loading stops', (
      tester,
    ) async {
      final (live, fetches) = await _pumpLivePlan(tester, {
        'A': null,
        'B': ['B-1'],
      }, verse: 999);

      expect(live.state.outOfSync, isTrue);
      // Text A ran out, and asks for nothing more.
      expect(_loadedVerses(tester), [for (var n = 1; n <= 80; n++) n]);
      final pages = fetches.length;
      await _settle(tester);
      expect(fetches.length, pages);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('leaving live', () {
    testWidgets('any scroll by the person pauses following', (tester) async {
      final live = await _pumpLiveReader(tester);
      expect(live.state.isFollowing, isTrue);

      await tester.drag(
        find.byType(ScrollablePositionedList),
        const Offset(0, -60),
      );
      await _settle(tester);

      expect(live.state.followMode, RecitationLiveFollowMode.paused);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a scroll after a long jump still pauses following', (
      tester,
    ) async {
      // A verse far down: the list jumps there by swapping its inner lists,
      // which the list's own offset listener does not follow.
      final live = await _pumpLiveReader(tester, verse: 26);
      expect(live.state.isFollowing, isTrue);
      expect(find.textContaining('Verse 26.'), findsOneWidget);

      await tester.drag(
        find.byType(ScrollablePositionedList),
        const Offset(0, 60),
      );
      await _settle(tester);

      expect(live.state.followMode, RecitationLiveFollowMode.paused);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('tapping a verse pauses following and shows the bars', (
      tester,
    ) async {
      final bars = <bool>[];
      final live = await _pumpLiveReader(tester, verse: 12, bars: bars);
      expect(live.state.isFollowing, isTrue);
      // Following the room down the page hid them.
      expect(bars.last, isTrue);

      await tester.tap(find.textContaining('Verse 12.').first);
      await _settle(tester);

      expect(live.state.followMode, RecitationLiveFollowMode.paused);
      // Back, so the Paused pill is there to tap.
      expect(bars.last, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('rejoining closes the verse opened before leaving', (
      tester,
    ) async {
      final live = await _pumpLiveReader(tester, verse: 12);
      await tester.tap(find.textContaining('Verse 12.').first);
      await _settle(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ReaderContentPart)),
      );
      ReaderState reader() => container.read(readerNotifierProvider(_params));
      expect(reader().selectedSegment?.segmentId, 'A-12');

      live.resumeFollowing();
      await _settle(tester);

      expect(live.state.isFollowing, isTrue);
      expect(reader().selectedSegment, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
