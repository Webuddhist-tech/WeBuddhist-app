import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/slide_away_header.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_fonts_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_content_part.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_live_follow.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_client.dart';
import 'package:flutter_pecha/features/recitation/data/models/edition_live_settings.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_live_notifier.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_live_settings_providers.dart';
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

String _position(
  int verse, {
  int round = 1,
  String text = 'A',
  int? revision,
}) =>
    '{"type":"position","event_id":"ev1","text_id":"$text",'
    '"segment_id":"$text-$verse","revision":${revision ?? verse},'
    '"round_number":$round}';

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

/// The same verses under two titled sections: "Opening" (1-15) and
/// "Praises" (16-30), so each heading carries "SECTION n / 2".
ReaderResponse _titledPage(TextDetailsParams params) {
  Section section(String id, String title, int first, int last) => Section(
    id: id,
    title: title,
    titles: {'en': title},
    sectionNumber: id == 'S1' ? 1 : 2,
    segments: [
      for (var n = first; n <= last; n++)
        Segment(
          segmentId: 'A-$n',
          segmentNumber: n,
          content: 'Verse $n. ${'Om tare tuttare ture soha. ' * 4}',
        ),
    ],
    sections: const [],
  );
  final plain = _page(params);
  return ReaderResponse(
    textDetail: plain.textDetail,
    content: Toc(
      id: 'A',
      textId: 'A',
      sections: [
        section('S1', 'Opening', 1, 15),
        section('S2', 'Praises', 16, _verses),
      ],
    ),
    size: plain.size,
    paginationDirection: plain.paginationDirection,
    currentSegmentPosition: plain.currentSegmentPosition,
    lastSegmentPosition: plain.lastSegmentPosition,
    totalSegments: plain.totalSegments,
  );
}

/// A reader following event ev1's live recitation over a socket the test
/// feeds by hand, its live verse at [verse], then each of [then] in turn.
/// [bars] records each time focus mode hides (true) or shows (false) the
/// reader's bars.
Future<RecitationLiveNotifier> _pumpLiveReader(
  WidgetTester tester, {
  int verse = 5,
  int round = 1,
  List<int> then = const [],
  List<bool>? bars,
  ReaderResponse Function(TextDetailsParams params) page = _page,
  List<ReturnJump> jumps = const [],
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
          (ref, params) async => Right<Failure, ReaderResponse>(page(params)),
        ),
        recitationLiveProvider.overrideWith((ref, id) => live),
        readerPendingFontsProvider.overrideWithValue(() async {}),
        editionReturnJumpsProvider.overrideWith((ref, id) async => jumps),
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
  channel.incoming.add(_position(verse, round: round));
  await _settle(tester);
  for (final next in then) {
    channel.incoming.add(_position(next, round: round));
    await _settle(tester);
  }
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

/// Text X is another edition of B, verse for verse; A is unrelated to both.
class _SiblingEditionAligner implements TextsRepository {
  @override
  Future<String?> alignSegment({
    required String segmentId,
    required String sourceTextId,
    required String targetTextId,
  }) async =>
      sourceTextId == 'X' && targetTextId == 'B'
          ? 'B-${segmentId.split('-').last}'
          : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _pageSize = 20;

/// Verses per text in a paged plan; ids are `<text>-<number>`.
const _planTotals = {'A': 80, 'B': 20, 'C': 20, 'D': 20};

/// A page of [_pageSize] verses from the anchor, like the library serves;
/// going `previous`, the verses before it.
ReaderResponse _planPage(TextDetailsParams params) {
  final textId = params.textId;
  final total = _planTotals[textId]!;
  final anchor =
      params.segmentId == null
          ? 1
          : int.parse(params.segmentId!.split('-').last);
  final previous = params.direction == 'previous';
  final last =
      previous
          ? (anchor - 1).clamp(0, total)
          : (anchor + _pageSize - 1).clamp(1, total);
  final first = previous ? (last - _pageSize + 1).clamp(1, total) : anchor;
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
                content:
                    '$textId verse $n. ${'Om tare tuttare ture soha. ' * 4}',
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
/// a text with its picked verses, or null for the whole text. The live verse
/// is [verse] of [text], then each of [then] in turn. A text in
/// [pageDelays] serves its pages after that delay instead of [pageDelay].
/// Without [connect] the room never sends anything. [onFrame] runs after
/// every frame pumped. [bars] records focus mode as [_pumpLiveReader]'s.
/// [fonts] stands in for loading the fonts the page's lines ask for. Returns the live notifier and every page fetched.
Future<(RecitationLiveNotifier, List<TextDetailsParams>)> _pumpLivePlan(
  WidgetTester tester,
  Map<String, List<String>?> picks, {
  required int verse,
  String text = 'A',
  List<String> then = const [],
  TextsRepository? aligner,
  ValueNotifier<double>? progress,
  Duration pageDelay = Duration.zero,
  Map<String, Duration> pageDelays = const {},
  bool connect = true,
  void Function()? onFrame,
  List<bool>? bars,
  Future<void> Function()? fonts,
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
        textsRepositoryProvider.overrideWithValue(
          aligner ?? _SameTextAligner(),
        ),
        textDetailsFutureProvider.overrideWith((ref, params) async {
          fetches.add(params);
          final delay = pageDelays[params.textId] ?? pageDelay;
          if (delay > Duration.zero) await Future.delayed(delay);
          return Right<Failure, ReaderResponse>(_planPage(params));
        }),
        recitationLiveProvider.overrideWith((ref, id) => live),
        readerPendingFontsProvider.overrideWithValue(fonts ?? () async {}),
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
            onScrollDirectionChanged: bars?.add,
          ),
        ),
      ),
    ),
  );
  await _settle(tester, onFrame: onFrame);
  if (!connect) return (live, fetches);
  channel.incoming.add(_sessionInfo);
  channel.incoming.add(_position(verse, text: text));
  await _settle(tester, onFrame: onFrame);
  for (final position in then) {
    channel.incoming.add(position);
    await _settle(tester, onFrame: onFrame);
  }
  return (live, fetches);
}

/// Where the line holding [text] shows: its middle as a fraction of the
/// list's height. Null while no list shows, -1 when the list shows without
/// that line on screen.
double? _shownAt(WidgetTester tester, String text) {
  final list = find.byType(ScrollablePositionedList);
  if (list.evaluate().isEmpty) return null;
  final shown = tester.widget<AnimatedOpacity>(
    find.ancestor(of: list, matching: find.byType(AnimatedOpacity)).first,
  );
  if (shown.opacity == 0) return null;
  final line = find.textContaining(text);
  if (line.evaluate().isEmpty) return -1;
  final area = tester.getRect(list);
  final middle = tester.getRect(line.first).center.dy;
  if (middle < area.top || middle > area.bottom) return -1;
  return (middle - area.top) / area.height;
}

int _listRows(WidgetTester tester) =>
    tester
        .widget<ScrollablePositionedList>(find.byType(ScrollablePositionedList))
        .itemCount;

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

Future<void> _settle(WidgetTester tester, {void Function()? onFrame}) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
    onFrame?.call();
  }
}

void main() {
  group('where the live verse sits', () {
    test('its middle is held a third of the way down', () {
      final target = liveScrollTarget(index: 8, heightFraction: 0.1)!;
      expect(target.index, 8);
      expect(target.alignment, closeTo(1 / 3 - 0.05, 1e-9));
    });

    test('a verse not laid out yet is placed by its top', () {
      expect(liveScrollTarget(index: 8)!.alignment, closeTo(1 / 3, 1e-9));
    });

    test('a long verse starts at the top, so all of it is on screen', () {
      final target = liveScrollTarget(index: 8, heightFraction: 0.8)!;
      expect(target.alignment, closeTo(0, 1e-9));
    });

    test('a verse taller than the screen is aligned by its top', () {
      expect(liveScrollTarget(index: 8, heightFraction: 1.4), (
        index: 8,
        alignment: 0.0,
      ));
    });

    test('near the start the list stays at its top', () {
      expect(
        liveScrollTarget(index: 2, heightFraction: 0.1, distanceFromStart: 0.2),
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
          currentTop: 0.2,
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

  group('the live verse in view', () {
    test('all of it on screen is in view', () {
      expect(liveVerseInView(top: 0.55, bottom: 0.75), isTrue);
    });

    test('pushed past the bottom or the top it is not', () {
      expect(liveVerseInView(top: 0.9, bottom: 1.1), isFalse);
      expect(liveVerseInView(top: 1.3, bottom: 1.5), isFalse);
      expect(liveVerseInView(top: -0.2, bottom: 0.1), isFalse);
    });

    test('taller than the screen, it is in view filling it from the top', () {
      expect(liveVerseInView(top: 0, bottom: 1.4), isTrue);
      expect(liveVerseInView(top: 0.3, bottom: 1.7), isFalse);
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

    test('the last verse\'s section is read from the page while on it', () {
      expect(
        livePreviousSection(verseOnPage: true, current: 'a2', kept: 'a1'),
        'a2',
      );
      expect(
        livePreviousSection(verseOnPage: true, current: null, kept: 'a1'),
        isNull,
      );
    });

    test('once the last verse left the page, its kept section stands in', () {
      final previous = livePreviousSection(verseOnPage: false, kept: 'a');
      expect(previous, 'a');
      expect(
        isLiveSectionJump(
          previousSection: previous,
          section: 'b',
          previousRound: 1,
          round: 1,
        ),
        isTrue,
      );
    });
  });

  group('the round in the live section\'s heading', () {
    const praises = ReturnJump(
      key: 'praises',
      toSegmentId: 'A-16',
      afterSegmentId: 'A-30',
      times: 3,
    );

    // The live verse opens the part, so its heading is on screen.
    testWidgets('reads the round out of the part\'s rounds', (tester) async {
      await _pumpLiveReader(
        tester,
        verse: 16,
        round: 2,
        page: _titledPage,
        jumps: const [praises],
      );
      expect(find.text('SECTION 2 / 2 · ROUND 2 / 3'), findsOneWidget);
      // The other section's heading has no round.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('without a total, just the round', (tester) async {
      await _pumpLiveReader(tester, verse: 16, round: 2, page: _titledPage);
      expect(find.text('SECTION 2 / 2 · ROUND 2'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Paused is the normal heading', (tester) async {
      final live = await _pumpLiveReader(
        tester,
        verse: 16,
        round: 2,
        page: _titledPage,
        jumps: const [praises],
      );
      live.pauseFollowing();
      await _settle(tester);
      expect(find.text('SECTION 2 / 2'), findsOneWidget);
      expect(find.textContaining('ROUND'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('a plan task\'s progress line', () {
    testWidgets('counts the task\'s verses, not only those loaded', (
      tester,
    ) async {
      final progress = ValueNotifier<double>(0);
      // Sixty picked verses; only the first page of twenty is in.
      await _pumpLivePlan(
        tester,
        {
          'A': [for (var n = 1; n <= 60; n++) 'A-$n'],
        },
        verse: 1,
        progress: progress,
      );
      expect(_loadedVerses(tester).length, lessThan(60));

      // A few verses fit on screen: a small share of sixty.
      expect(progress.value, greaterThan(0));
      expect(progress.value, lessThan(0.2));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('loading toward a far live verse', () {
    testWidgets('stops between pages once the reader pauses', (tester) async {
      // A plan task's text on the page already walks to a verse further
      // on page by page; each page takes a while and verse 75 is three
      // pages past those loaded.
      final (live, _) = await _pumpLivePlan(
        tester,
        {
          'A': null,
          'B': ['B-1', 'B-2'],
        },
        verse: 5,
        then: [_position(75)],
        pageDelay: const Duration(seconds: 1),
      );
      expect(_loadedVerses(tester), isNot(contains(75)));

      live.pauseFollowing();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // At most the page already asked for lands; the old verse is never
      // reached, and pausing is not being out of sync.
      expect(_loadedVerses(tester), isNot(contains(75)));
      expect(live.state.outOfSync, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('a live verse past the loaded ones on a plan task', () {
    testWidgets('a whole text opens at it, the page before it with it', (
      tester,
    ) async {
      // Two texts, so the page is collapsed; text A is whole.
      final (live, fetches) = await _pumpLivePlan(tester, {
        'A': null,
        'B': ['B-1', 'B-2'],
      }, verse: 65);

      // Its first page, then the pages before and at verse 65 together:
      // no page in between, and nothing skipped around the verse.
      final loaded = _loadedVerses(tester);
      expect(loaded, [for (var n = 45; n <= 80; n++) n]);
      expect(
        fetches.where((p) => p.textId == 'A' && p.segmentId != null),
        hasLength(2),
      );
      expect(live.state.outOfSync, isFalse);
      expect(find.textContaining('A verse 65.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a room move back before the opened window is followed', (
      tester,
    ) async {
      // Opened at verse 65, text A holds 45-80; verse 5 is before them, so
      // a forward walk would never reach it.
      final (live, _) = await _pumpLivePlan(
        tester,
        {
          'A': null,
          'B': ['B-1', 'B-2'],
        },
        verse: 65,
        then: [_position(5, revision: 66)],
      );

      expect(live.state.outOfSync, isFalse);
      expect(live.state.isFollowing, isTrue);
      expect(_loadedVerses(tester), contains(5));
      expect(find.textContaining('A verse 5.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('picked verses before it come in above, in order', (
      tester,
    ) async {
      final picked = [for (var n = 1; n <= 77; n += 4) 'A-$n'];
      final (live, _) = await _pumpLivePlan(tester, {'A': picked}, verse: 61);

      expect(_loadedVerses(tester), contains(61));
      expect(live.state.outOfSync, isFalse);
      expect(find.textContaining('A verse 61.'), findsOneWidget);

      // Paused and scrolled up, the earlier ones load as pages above.
      live.pauseFollowing();
      for (var i = 0; i < 6; i++) {
        await tester.drag(
          find.byType(ScrollablePositionedList),
          const Offset(0, 400),
        );
        await _settle(tester);
      }
      final loaded = _loadedVerses(tester);
      for (var n = 1; n <= 61; n += 4) {
        expect(loaded, contains(n), reason: 'picked verse A-$n');
      }
      expect(loaded, [...loaded]..sort());
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'pages above come in without moving it, a finger on it or not',
      (tester) async {
        final (live, fetches) = await _pumpLivePlan(
          tester,
          {'A': null, 'B': null},
          verse: 65,
          pageDelay: const Duration(milliseconds: 800),
        );
        live.pauseFollowing();
        await _settle(tester);

        // A finger brings the start of what is loaded, verse 45, into view
        // and stays on the list: the page before is fetched and lands under
        // it.
        final list = find.byType(ScrollablePositionedList);
        final area = tester.getRect(list);
        final line = find.textContaining('A verse 46.');
        final asked = fetches.length;
        final gesture = await tester.startGesture(area.center);
        for (var step = 0; step < 30; step++) {
          if (line.evaluate().isNotEmpty &&
              tester.getRect(line).top > area.top + 60) {
            break;
          }
          await gesture.moveBy(const Offset(0, 150));
          await tester.pump(const Duration(milliseconds: 16));
        }
        // Once the pill the scroll up brought back has slid in.
        await tester.pump(const Duration(milliseconds: 400));
        final top = tester.getRect(line).top;
        Future<void> holdsStill(String when) async {
          for (var frame = 0; frame < 30; frame++) {
            await tester.pump(const Duration(milliseconds: 50));
            expect(
              tester.getRect(line).top,
              closeTo(top, 1),
              reason: '$when, frame $frame',
            );
          }
        }

        await holdsStill('finger down');
        expect(fetches.length, greaterThan(asked));
        await gesture.up();
        await holdsStill('finger up');
        expect(_loadedVerses(tester), contains(30));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('a verse the text lacks ends out of sync, loading stops', (
      tester,
    ) async {
      final (live, fetches) = await _pumpLivePlan(tester, {
        'A': null,
        'B': ['B-1'],
      }, verse: 999);

      expect(live.state.outOfSync, isTrue);
      // Asked for once, at the verse; nothing more is fetched for it.
      expect(_loadedVerses(tester), [for (var n = 1; n <= 20; n++) n]);
      final pages = fetches.length;
      await _settle(tester);
      expect(fetches.length, pages);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('texts that lack the verse are passed over, not loaded', (
      tester,
    ) async {
      // The room is in text B, then in X, another edition of B. Text A
      // comes first and holds neither, so it stays at its first page:
      // pages of it would land above the live verse and push it away.
      final (live, fetches) = await _pumpLivePlan(
        tester,
        {'A': null, 'B': null},
        verse: 3,
        text: 'B',
        then: [_position(5, text: 'X')],
        aligner: _SiblingEditionAligner(),
      );

      expect(fetches.where((p) => p.textId == 'A'), hasLength(1));
      expect(live.state.outOfSync, isFalse);
      expect(find.textContaining('B verse 5.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the text before the live one waits above it until paused', (
      tester,
    ) async {
      // The live verse opens text B. Text A's first page is in, but drawn
      // it would land above the live verse, and a page more of it too.
      final (live, fetches) = await _pumpLivePlan(
        tester,
        {'A': null, 'B': null},
        verse: 2,
        text: 'B',
        aligner: _SiblingEditionAligner(),
      );
      await _settle(tester);

      expect(find.textContaining('A verse 20.'), findsNothing);
      expect(fetches.where((p) => p.textId == 'A'), hasLength(1));
      expect(live.state.isFollowing, isTrue);
      expect(find.textContaining('B verse 2.'), findsOneWidget);

      // Paused, A comes in above, and no frame shows B moved for it.
      final verse = find.textContaining('B verse 1.');
      final top = tester.getRect(verse).top;
      final rows = _listRows(tester);
      live.pauseFollowing();
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.getRect(verse).top, closeTo(top, 1), reason: '$frame');
      }
      expect(_listRows(tester), greaterThan(rows));
      await tester.drag(
        find.byType(ScrollablePositionedList),
        const Offset(0, 300),
      );
      await _settle(tester);
      expect(find.textContaining('A verse 20.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the live text loads first, the texts before it after', (
      tester,
    ) async {
      // Live opens text C. B, between the first text and C, waits until
      // C's page is in, so its own does not hold C's up.
      final (live, fetches) = await _pumpLivePlan(
        tester,
        {'A': null, 'B': null, 'C': null},
        verse: 3,
        text: 'C',
        pageDelay: const Duration(milliseconds: 300),
      );
      await _settle(tester);

      final firstOf = [
        for (final text in ['B', 'C'])
          fetches.indexWhere((p) => p.textId == text),
      ];
      expect(firstOf, everyElement(isNonNegative));
      expect(firstOf[0], greaterThan(firstOf[1]));
      expect(live.state.outOfSync, isFalse);
      expect(find.textContaining('C verse 3.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('texts landing frames apart above the live one leave it be', (
      tester,
    ) async {
      // Live opens text D; B and C land after the page has scrolled to D,
      // a few frames apart, both above the live verse.
      final (live, _) = await _pumpLivePlan(
        tester,
        {'A': null, 'B': null, 'C': null, 'D': null},
        verse: 3,
        text: 'D',
        pageDelays: const {
          'B': Duration(seconds: 3),
          'C': Duration(milliseconds: 3020),
        },
      );
      await _settle(tester);
      await _settle(tester);

      expect(live.state.isFollowing, isTrue);
      expect(find.textContaining('C verse 1.'), findsNothing);
      expect(find.textContaining('D verse 3.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a text arriving late above the live one leaves it in view', (
      tester,
    ) async {
      // Live opens text C, which starts B with it; B's first page lands
      // after the page has scrolled to C, all of it above the live verse.
      final (live, fetches) = await _pumpLivePlan(
        tester,
        {'A': null, 'B': null, 'C': null},
        verse: 3,
        text: 'C',
        pageDelays: const {'B': Duration(seconds: 3)},
      );
      await _settle(tester);
      await _settle(tester);

      expect(fetches.where((p) => p.textId == 'B'), isNotEmpty);
      expect(find.textContaining('B verse 1.'), findsNothing);
      expect(live.state.isFollowing, isTrue);
      expect(find.textContaining('C verse 3.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('opening on the live verse', () {
    testWidgets('no list shows until the verse, then it is in its place', (
      tester,
    ) async {
      // Live is in the task's third text; the texts before it load too.
      final shown = <double?>[];
      await _pumpLivePlan(
        tester,
        {'A': null, 'B': null, 'C': null},
        verse: 10,
        text: 'C',
        pageDelay: const Duration(milliseconds: 300),
        onFrame: () => shown.add(_shownAt(tester, 'C verse 10.')),
      );
      await _settle(
        tester,
        onFrame: () => shown.add(_shownAt(tester, 'C verse 10.')),
      );

      // Every frame that shows the list shows the live verse ⅓ down.
      final visible = shown.whereType<double>().toList();
      expect(visible, isNotEmpty);
      expect(shown.last, isNotNull);
      for (final at in visible) {
        expect(at, closeTo(liveHoldFraction, 0.1));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'a text\'s first page and its page at the verse load together',
      (tester) async {
        // Live opens text A, third on the page, at verse 65, three pages in;
        // each of A's pages takes a second.
        await _pumpLivePlan(
          tester,
          {'B': null, 'C': null, 'A': null},
          verse: 65,
          pageDelays: const {'A': Duration(seconds: 1)},
        );

        // In place within 1.8 s of the position: the time of one page.
        expect(_shownAt(tester, 'A verse 65.'), closeTo(liveHoldFraction, 0.1));
        await _settle(tester);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('the verse waits for its fonts before it shows', (
      tester,
    ) async {
      // Its lines are measured once in the font they stay in, or a font
      // landing later would resize them under the person.
      final fonts = Completer<void>();
      await _pumpLivePlan(
        tester,
        {'A': null, 'B': null},
        verse: 30,
        fonts: () => fonts.future,
      );
      expect(_shownAt(tester, 'A verse 30.'), isNull);

      fonts.complete();
      await _settle(tester);
      expect(_shownAt(tester, 'A verse 30.'), closeTo(liveHoldFraction, 0.1));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a room that sends nothing shows the page after a while', (
      tester,
    ) async {
      final bars = <bool>[];
      await _pumpLivePlan(
        tester,
        {'A': null, 'B': null},
        verse: 1,
        connect: false,
        bars: bars,
      );
      expect(find.byType(ScrollablePositionedList), findsNothing);

      await tester.pump(liveOpenHoldLimit);
      await _settle(tester);
      expect(find.textContaining('A verse 1.'), findsOneWidget);
      // Put away for the wait, and back for the normal page.
      expect(bars, [true, false]);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the bars are away before the verse shows, and stay away', (
      tester,
    ) async {
      // Following puts them away, and the header leaving resizes the text
      // area: done behind the loading circle, nothing moves once shown.
      final bars = <bool>[];
      List<bool>? barsWhenShown;
      bool? pillWhenShown;
      await _pumpLivePlan(
        tester,
        {'A': null, 'B': null},
        verse: 30,
        bars: bars,
        onFrame: () {
          if (barsWhenShown != null ||
              _shownAt(tester, 'A verse 30.') == null) {
            return;
          }
          barsWhenShown = [...bars];
          pillWhenShown =
              tester
                  .widget<SlideAwayHeader>(find.byType(SlideAwayHeader))
                  .visible;
        },
      );

      expect(barsWhenShown, [true]);
      expect(pillWhenShown, isFalse);
      expect(bars, [true]);
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
      final live = await _pumpLiveReader(
        tester,
        verse: 12,
        then: [13],
        bars: bars,
      );
      expect(live.state.isFollowing, isTrue);
      // Opened on the live verse, then following the room down the page
      // hid them.
      expect(bars.last, isTrue);

      await tester.tap(find.textContaining('Verse 13.').first);
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
