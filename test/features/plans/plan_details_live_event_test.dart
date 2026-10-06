import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_live_player.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_live_toggles.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_not_started_card.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_replays_menu.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_video_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_cover_image.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_embedded_host.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/activity_list.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/missed_days_badge.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/plan_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

import '../group_profile/presentation/widgets/fake_in_app_webview_platform.dart';

class _FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object?>? properties,
  }) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> track(String event, {Map<String, Object?>? properties}) async {}

  @override
  Future<void> setSuperProperties(Map<String, Object?> properties) async {}

  @override
  List<NavigatorObserver> get routeObservers => [NavigatorObserver()];
}

class _FakeStorage implements LocalStorageService {
  @override
  Future<void> setUserData(Map<String, dynamic> userData) async {}

  @override
  Future<Map<String, dynamic>?> getUserData() async => null;

  @override
  Future<void> clearUserData() async {}

  @override
  Future<T?> get<T>(String key) async => null;

  @override
  Future<bool> set<T>(String key, T value) async => true;

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> clear() async => true;

  @override
  Future<bool> containsKey(String key) async => false;
}

UserPlansModel _makePlan() => UserPlansModel(
  id: 'plan-1',
  title: 'Green Tara',
  description: 'Test plan',
  language: 'en',
  difficultyLevel: null,
  startedAt: DateTime.now(),
  totalDays: 21,
  tags: null,
);

const _liveVideoId = 'BNDTusn8TO8';
const _session1Id = 'aaaaaaaaaaa';
const _session2Id = 'bbbbbbbbbbb';

/// An event whose stream is on, with its chat (so the prayer chip renders).
GroupEvent _liveEvent() => GroupEvent(
  id: 'event-1',
  groupId: 'group-1',
  chatEnabled: true,
  youtube: const [
    GroupEventLink(
      id: 'y1',
      type: 'youtube',
      url: 'https://youtu.be/$_liveVideoId',
      label: 'live',
    ),
  ],
);

PlanVideoModel _video(String id, String videoId, int order) => PlanVideoModel(
  id: id,
  url: 'https://youtu.be/$videoId',
  videoId: videoId,
  displayOrder: order,
);

UserPlanDayDetailResponse _makeDay({
  List<PlanVideoModel> videos = const [],
}) => UserPlanDayDetailResponse(
  id: 'day-1',
  dayNumber: 1,
  videos: videos,
  tasks: [
    UserTasksDto(
      id: 'task-1',
      title: 'Tara of the day',
      estimatedTime: null,
      displayOrder: 1,
      isCompleted: false,
      subTasks: [
        UserSubtasksDto(
          id: 'sub-1',
          isCompleted: false,
          contentType: 'TEXT',
          content: 'Green Tara is the swift protector.',
        ),
      ],
    ),
  ],
  isCompleted: false,
);

Future<void> _pumpLiveEventDetails(
  WidgetTester tester, {
  bool streamKnownAbsent = false,
  bool showLiveStream = true,
  Completer<Either<Failure, GroupEvent>>? stream,
  // Answers every fetch, including the retries a started event makes.
  Future<Either<Failure, GroupEvent>> Function()? fetch,
  // Null opens the same plan outside any event.
  String? eventId = 'event-1',
  // Started today by default, so no missed-days badge crowds the narrow row.
  DateTime? startDate,
  Map<int, bool> completion = const {1: false},
  // Phone portrait: the pinned 16:9 stream must leave room for the list.
  Size viewSize = const Size(390, 844),
  // Recordings of day 1, as the backend copies them onto the plan day.
  List<PlanVideoModel> videos = const [],
}) async {
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  // A live stream or a replay mounts the YouTube player's WebView.
  FakeInAppWebViewPlatform.install();

  final day = _makeDay(videos: videos);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analyticsServiceProvider.overrideWithValue(_FakeAnalyticsService()),
        localStorageServiceProvider.overrideWithValue(_FakeStorage()),
        // Still loading counts as live; a failure means no stream.
        groupEventInLanguageProvider.overrideWith(
          (ref, key) =>
              fetch != null
                  ? fetch()
                  : streamKnownAbsent
                  ? Future.value(const Left(NetworkFailure('test')))
                  : (stream ?? Completer<Either<Failure, GroupEvent>>()).future,
        ),
        userPlanDayContentFutureProvider.overrideWith(
          (ref, params) => Stream.value(Right(day)),
        ),
        userPlanDaysCompletionStatusProvider.overrideWith(
          (ref, planId) => Stream.value(Right(completion)),
        ),
        planDaysByPlanIdFutureProvider.overrideWith(
          (ref, planId) => Stream.value(const Right(<PlanDaysModel>[])),
        ),
        seriesListFutureProvider.overrideWith(
          (ref) => Stream.value(const Left(NetworkFailure('test'))),
        ),
        userSeriesEnrollmentsProvider.overrideWith(
          (ref) => Stream.value(<String>{}),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlanDetails(
          plan: _makePlan(),
          selectedDay: 1,
          startDate: startDate ?? DateTime.now(),
          eventId: eventId,
          showLiveStream: showLiveStream,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Finder _body() => find.textContaining('swift protector', findRichText: true);

ActivityList _activityList(WidgetTester tester) =>
    tester.widget<ActivityList>(find.byType(ActivityList));

// The pending stream shimmers forever, so settle for a fixed time instead.
Future<void> _settle(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 400));

void main() {
  testWidgets('a tapped task opens below the stream and X restores the list', (
    tester,
  ) async {
    await _pumpLiveEventDetails(tester);

    expect(find.byType(GroupEventLiveHeader), findsOneWidget);
    // Stream still loading: neither the title nor the toggles yet.
    expect(find.byType(GroupEventMediaToggle), findsNothing);
    expect(find.text('Green Tara'), findsNothing);
    expect(find.text('Tara of the day'), findsOneWidget);
    // Already practicing via the event, so no "Practice now".
    expect(find.text('Practice now'), findsNothing);
    expect(find.byType(PlanEmbeddedHeader), findsNothing);
    // Online readers keep the event for prayer requests but stay off the
    // live socket: the stream's overlays carry the text, and sync would lag
    // behind the video.
    expect(_activityList(tester).eventId, 'event-1');
    expect(_activityList(tester).isOnlineAttendee, isTrue);

    await tester.tap(find.text('Tara of the day'));
    await _settle(tester);

    // Same page: the stream header is still there, the list is replaced.
    expect(find.byType(GroupEventLiveHeader), findsOneWidget);
    expect(find.byType(PlanEmbeddedHeader), findsOneWidget);
    expect(_body(), findsOneWidget);
    expect(find.text('Practice now'), findsNothing);
    expect(find.byType(PlanDetails), findsOneWidget);

    await tester.tap(find.byIcon(AppAssets.x));
    await _settle(tester);

    expect(find.byType(PlanEmbeddedHeader), findsNothing);
    expect(_body(), findsNothing);
    expect(find.text('Tara of the day'), findsOneWidget);
    expect(find.text('Practice now'), findsNothing);

    // Let the deferred refresh after closing run out.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('without a stream the page shows the plain plan layout', (
    tester,
  ) async {
    await _pumpLiveEventDetails(tester, streamKnownAbsent: true);

    // An event page carries no plan title.
    expect(find.text('Green Tara'), findsNothing);
    expect(find.byType(GroupEventMediaToggle), findsNothing);
    expect(find.byType(GroupEventLanguageToggle), findsNothing);
    expect(find.byType(PlanEmbeddedHeader), findsNothing);
    expect(find.text('Tara of the day'), findsOneWidget);
    // No cover image: the header says the puja has not started.
    expect(find.byType(GroupEventNotStartedCard), findsOneWidget);
    expect(find.text('Puja not started yet'), findsOneWidget);
    expect(find.byType(PlanCoverImage), findsNothing);
  });

  testWidgets('an in-person attendee gets the plain layout despite a stream', (
    tester,
  ) async {
    await _pumpLiveEventDetails(
      tester,
      showLiveStream: false,
      fetch:
          () async => Right(
            GroupEvent(
              id: 'event-1',
              groupId: 'group-1',
              chatEnabled: true,
              youtube: const [
                GroupEventLink(
                  id: 'y1',
                  type: 'youtube',
                  url: 'https://youtu.be/BNDTusn8TO8',
                  label: 'live',
                ),
              ],
            ),
          ),
    );
    await _settle(tester);

    // Static cover, no stream, no countdown, no toggles.
    expect(find.byType(PlanCoverImage), findsOneWidget);
    expect(find.byType(GroupEventLiveHeader), findsNothing);
    expect(find.byType(GroupEventNotStartedCard), findsNothing);
    expect(find.byType(GroupEventMediaToggle), findsNothing);
    expect(find.text('Green Tara'), findsNothing);
    // Prayer requests still belong to the event, now in the app bar.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Prayer requests'),
      ),
      findsOneWidget,
    );

    // No embedded scope, so a tapped task pushes its own route.
    expect(find.byType(PlanEmbeddedScope), findsNothing);
    expect(find.text('Tara of the day'), findsOneWidget);
    // That route follows the event's live recitation.
    expect(_activityList(tester).eventId, 'event-1');
    expect(_activityList(tester).isOnlineAttendee, isFalse);
  });

  testWidgets('an event without a stream counts down to its start', (
    tester,
  ) async {
    final stream = Completer<Either<Failure, GroupEvent>>();
    await _pumpLiveEventDetails(tester, stream: stream);

    final startsAt = DateTime.now().add(
      const Duration(hours: 2, minutes: 14, seconds: 30),
    );
    stream.complete(
      Right(GroupEvent(id: 'event-1', groupId: 'group-1', startDate: startsAt)),
    );
    await _settle(tester);

    expect(find.byType(GroupEventNotStartedCard), findsOneWidget);
    expect(find.text('Puja starts in'), findsOneWidget);
    expect(find.text('02 : 14 : 30'), findsOneWidget);
    final local = startsAt.toLocal();
    final date = DateFormat('EEE d MMM').format(local);
    final time = DateFormat.jm().format(local).toLowerCase();
    expect(find.text('$date · $time ${local.timeZoneName}'), findsOneWidget);
    expect(find.byType(PlanCoverImage), findsNothing);
  });

  testWidgets('a started event without a stream keeps asking for its link', (
    tester,
  ) async {
    var fetches = 0;
    final now = DateTime.now();
    await _pumpLiveEventDetails(
      tester,
      fetch: () async {
        fetches++;
        return Right(
          GroupEvent(
            id: 'event-1',
            groupId: 'group-1',
            startDate: now.subtract(const Duration(minutes: 5)),
          ),
        );
      },
    );
    await _settle(tester);
    expect(fetches, 1);
    expect(find.text('Puja not started yet'), findsOneWidget);

    // The link is usually attached a little after the start, so poll for it.
    await tester.pump(const Duration(seconds: 31));
    await _settle(tester);
    expect(fetches, 2);
  });

  testWidgets('an event that has ended stops asking for a stream', (
    tester,
  ) async {
    var fetches = 0;
    final now = DateTime.now();
    await _pumpLiveEventDetails(
      tester,
      fetch: () async {
        fetches++;
        return Right(
          GroupEvent(
            id: 'event-1',
            groupId: 'group-1',
            startDate: now.subtract(const Duration(days: 2)),
            endDate: now.subtract(const Duration(days: 1)),
          ),
        );
      },
    );
    await _settle(tester);
    expect(fetches, 1);

    // No link is ever coming, so no request goes out however long we stay.
    await tester.pump(const Duration(minutes: 2));
    await _settle(tester);
    expect(fetches, 1);
  });

  testWidgets('a failed stream request keeps an open task in place', (
    tester,
  ) async {
    final stream = Completer<Either<Failure, GroupEvent>>();
    await _pumpLiveEventDetails(tester, stream: stream);

    await tester.tap(find.text('Tara of the day'));
    await _settle(tester);
    expect(_body(), findsOneWidget);

    // A retryable failure must not throw the user out of the task.
    stream.complete(const Left(NetworkFailure('test')));
    await _settle(tester);
    expect(_body(), findsOneWidget);
    expect(find.byType(PlanEmbeddedHeader), findsOneWidget);

    // Closing it hands over to the plain layout with the retry row.
    await tester.tap(find.byIcon(AppAssets.x));
    await _settle(tester);
    expect(_body(), findsNothing);
    expect(find.text('Tara of the day'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the page back arrow closes an open task before leaving', (
    tester,
  ) async {
    await _pumpLiveEventDetails(tester);

    await tester.tap(find.text('Tara of the day'));
    await _settle(tester);
    expect(_body(), findsOneWidget);

    await tester.tap(find.byIcon(AppAssets.arrowLeft));
    await _settle(tester);

    expect(_body(), findsNothing);
    expect(find.byType(PlanDetails), findsOneWidget);
    expect(find.text('Tara of the day'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
  });

  // Three scheduled days went by unticked; today is Day 4. Stepped back by
  // calendar date: 72 hours can land on another date across a DST change.
  final today = DateTime.now();
  final threeDaysIn = DateTime(today.year, today.month, today.day - 3);
  const threeMissed = {1: false, 2: false, 3: false};

  testWidgets('an online attendee sees no missed days on the event page', (
    tester,
  ) async {
    await _pumpLiveEventDetails(
      tester,
      startDate: threeDaysIn,
      completion: threeMissed,
    );
    await _settle(tester);

    expect(find.text('Day 1 of 21'), findsOneWidget);
    expect(find.byType(MissedDaysBadge), findsNothing);
    expect(find.textContaining('missed'), findsNothing);
  });

  testWidgets('an in-person attendee sees no missed days on the event page', (
    tester,
  ) async {
    await _pumpLiveEventDetails(
      tester,
      showLiveStream: false,
      startDate: threeDaysIn,
      completion: threeMissed,
    );
    await _settle(tester);

    expect(find.byType(PlanCoverImage), findsOneWidget);
    expect(find.text('Day 1 of 21'), findsOneWidget);
    expect(find.byType(MissedDaysBadge), findsNothing);
    expect(find.textContaining('missed'), findsNothing);
  });

  testWidgets('the same plan outside an event still counts its missed days', (
    tester,
  ) async {
    await _pumpLiveEventDetails(
      tester,
      eventId: null,
      startDate: threeDaysIn,
      completion: threeMissed,
      // The square test glyphs make the title and badge overflow a phone.
      viewSize: const Size(600, 844),
    );
    await _settle(tester);

    expect(find.text('Day 1 of 21'), findsOneWidget);
    expect(find.byType(MissedDaysBadge), findsOneWidget);
    expect(find.text('3 missed days'), findsOneWidget);
  });

  GroupEventLivePlayer player(WidgetTester tester) =>
      tester.widget<GroupEventLivePlayer>(find.byType(GroupEventLivePlayer));

  // The trigger is a history icon until a recording is picked.
  final replaysTrigger = find.byIcon(AppAssets.clockCounterClockwise);

  // The popup's opening animation starts a frame after the tap, and the
  // player's shimmer never settles, so pump twice instead of pumpAndSettle.
  Future<void> openReplays(WidgetTester tester) async {
    await tester.tap(replaysTrigger);
    await _settle(tester);
    await _settle(tester);
  }

  Future<void> pick(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await _settle(tester);
    await _settle(tester);
  }

  group('replays', () {
    final twoSessions = [
      _video('v2', _session2Id, 2),
      _video('v1', _session1Id, 1),
    ];

    testWidgets('the Replays menu lists the selected day\'s recordings', (
      tester,
    ) async {
      await _pumpLiveEventDetails(
        tester,
        fetch: () async => Right(_liveEvent()),
        videos: twoSessions,
      );
      await _settle(tester);

      // Live plays; the menu waits in the title slot, no way "back" yet.
      expect(player(tester).videoId, _liveVideoId);
      expect(player(tester).isReplay, isFalse);
      expect(find.byType(GroupEventReplaysMenu), findsOneWidget);
      expect(replaysTrigger, findsOneWidget);
      expect(find.text('Replays'), findsNothing);
      expect(find.byType(GroupEventBackToLivePill), findsNothing);
      // Prayer requests sit at the right margin even with nothing on the
      // left.
      final chip = tester.getRect(
        find
            .ancestor(
              of: find.text('Prayer requests'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(chip.right, 390 - 16);
      // The recordings moved out of the shorts carousel (which hides itself
      // when it is handed no videos).
      expect(_activityList(tester).videos, isEmpty);

      await openReplays(tester);

      // The menu names itself; the sessions follow display order, not
      // list order.
      expect(find.text('Replays'), findsOneWidget);
      expect(find.text('Day 1 · Session 1'), findsOneWidget);
      expect(find.text('Day 1 · Session 2'), findsOneWidget);
      expect(find.text('Recording'), findsNWidgets(2));
      final first = tester.getTopLeft(find.text('Day 1 · Session 1'));
      final second = tester.getTopLeft(find.text('Day 1 · Session 2'));
      expect(first.dy, lessThan(second.dy));
    });

    testWidgets('a picked recording plays until "Back to live"', (
      tester,
    ) async {
      await _pumpLiveEventDetails(
        tester,
        fetch: () async => Right(_liveEvent()),
        videos: twoSessions,
      );
      await _settle(tester);

      await openReplays(tester);
      await pick(tester, 'Day 1 · Session 1');

      expect(player(tester).videoId, _session1Id);
      expect(player(tester).isReplay, isTrue);
      expect(player(tester).isLive, isFalse);
      // The trigger stays the icon; the list is where the pick shows.
      expect(replaysTrigger, findsOneWidget);
      expect(find.byType(GroupEventBackToLivePill), findsOneWidget);
      // One line under the player: the pill at the left margin, prayer
      // requests flush with the right margin.
      expect(find.text('Prayer requests'), findsOneWidget);
      final pill = tester.getRect(find.byType(GroupEventBackToLivePill));
      final chip = tester.getRect(
        find
            .ancestor(
              of: find.text('Prayer requests'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(pill.left, 16);
      expect(chip.right, 390 - 16);
      expect(chip.left, greaterThan(pill.right));
      expect(chip.center.dy, closeTo(pill.center.dy, 1));
      // Video / audio stays; the language switch belongs to the stream.
      expect(find.byType(GroupEventMediaToggle), findsOneWidget);
      expect(find.byType(GroupEventLanguageToggle), findsOneWidget);

      // Reopened, the list checks the session that is playing.
      await openReplays(tester);
      final checkedRow =
          find
              .ancestor(
                of: find.byIcon(AppAssets.check),
                matching: find.byType(Row),
              )
              .first;
      expect(
        find.descendant(
          of: checkedRow,
          matching: find.text('Day 1 · Session 1'),
        ),
        findsOneWidget,
      );
      // Tap the barrier to close it again.
      await tester.tapAt(const Offset(20, 820));
      await _settle(tester);
      await _settle(tester);
      expect(find.text('Day 1 · Session 1'), findsNothing);

      await pick(tester, 'Back to live');

      expect(player(tester).videoId, _liveVideoId);
      expect(player(tester).isReplay, isFalse);
      expect(replaysTrigger, findsOneWidget);
      expect(find.byType(GroupEventBackToLivePill), findsNothing);
      // Nothing checked once the stream is back.
      await openReplays(tester);
      expect(find.byIcon(AppAssets.check), findsNothing);
      await tester.tapAt(const Offset(20, 820));
      await _settle(tester);
      await _settle(tester);
    });

    testWidgets('the stream that is live is not offered as a replay', (
      tester,
    ) async {
      await _pumpLiveEventDetails(
        tester,
        fetch: () async => Right(_liveEvent()),
        videos: [
          // The sync copied today's live link onto today's day as well.
          _video('live', _liveVideoId, 1),
          _video('v1', _session1Id, 2),
        ],
      );
      await _settle(tester);

      await openReplays(tester);

      expect(find.text('Day 1 · Session 1'), findsOneWidget);
      expect(find.text('Day 1 · Session 2'), findsNothing);
    });

    testWidgets('without a stream a day with recordings plays its first', (
      tester,
    ) async {
      final now = DateTime.now();
      await _pumpLiveEventDetails(
        tester,
        fetch:
            () async => Right(
              GroupEvent(
                id: 'event-1',
                groupId: 'group-1',
                chatEnabled: true,
                startDate: now.subtract(const Duration(days: 2)),
                endDate: now.subtract(const Duration(days: 1)),
              ),
            ),
        videos: twoSessions,
      );
      await _settle(tester);

      // The slot keeps a player, not the countdown or the cover image.
      expect(player(tester).videoId, _session1Id);
      expect(player(tester).isReplay, isTrue);
      expect(find.byType(GroupEventNotStartedCard), findsNothing);
      expect(find.byType(PlanCoverImage), findsNothing);
      expect(replaysTrigger, findsOneWidget);
      // Nothing live to go back to.
      expect(find.byType(GroupEventBackToLivePill), findsNothing);
      // Audio mode still offered; no stream language to switch.
      expect(find.byType(GroupEventMediaToggle), findsOneWidget);
      expect(find.byType(GroupEventLanguageToggle), findsNothing);
      // Prayer requests under the player only, not doubled in the bar.
      expect(find.text('Prayer requests'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Prayer requests'),
        ),
        findsNothing,
      );
    });

    testWidgets('a day with no recordings says so in the menu', (
      tester,
    ) async {
      await _pumpLiveEventDetails(
        tester,
        fetch: () async => Right(_liveEvent()),
      );
      await _settle(tester);

      expect(replaysTrigger, findsOneWidget);
      await openReplays(tester);

      expect(find.text('No recordings yet'), findsOneWidget);
      expect(find.text('Recording'), findsNothing);
    });

    testWidgets('an in-person attendee keeps the plain page, no menu', (
      tester,
    ) async {
      await _pumpLiveEventDetails(
        tester,
        showLiveStream: false,
        fetch: () async => Right(_liveEvent()),
        videos: twoSessions,
      );
      await _settle(tester);

      expect(find.byType(GroupEventReplaysMenu), findsNothing);
      expect(find.byType(GroupEventLivePlayer), findsNothing);
      expect(find.byType(PlanCoverImage), findsOneWidget);
      // Their recordings still come as the shorts carousel.
      expect(_activityList(tester).videos, hasLength(2));
    });

    testWidgets('the menu and both pills fit a narrow phone', (tester) async {
      await _pumpLiveEventDetails(
        tester,
        fetch: () async => Right(_liveEvent()),
        videos: twoSessions,
        viewSize: const Size(360, 780),
      );
      await _settle(tester);

      expect(replaysTrigger, findsOneWidget);
      expect(find.byType(GroupEventMediaToggle), findsOneWidget);
      expect(find.byType(GroupEventLanguageToggle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the menu waits for the stream before listing recordings', (
      tester,
    ) async {
      final stream = Completer<Either<Failure, GroupEvent>>();
      await _pumpLiveEventDetails(
        tester,
        stream: stream,
        videos: [
          // The sync copied today's live link onto today's day as well.
          _video('live', _liveVideoId, 1),
          _video('v1', _session1Id, 2),
        ],
      );
      await _settle(tester);

      // Nothing to pick from until the event says which link is live;
      // otherwise today's copy of it could be picked as a recording.
      expect(find.byType(GroupEventReplaysMenu), findsNothing);
      expect(replaysTrigger, findsNothing);

      stream.complete(Right(_liveEvent()));
      await _settle(tester);

      expect(player(tester).videoId, _liveVideoId);
      expect(player(tester).isReplay, isFalse);
      await openReplays(tester);
      expect(find.text('Day 1 · Session 1'), findsOneWidget);
      expect(find.text('Day 1 · Session 2'), findsNothing);
    });

    testWidgets('a stream whose link is gone yields to the first recording', (
      tester,
    ) async {
      var fetches = 0;
      final now = DateTime.now();
      await _pumpLiveEventDetails(
        tester,
        // The English stream is on at first; every later answer, in any
        // language, says the link has been taken down.
        fetch: () async {
          fetches++;
          return Right(
            fetches == 1
                ? _liveEvent()
                : GroupEvent(
                  id: 'event-1',
                  groupId: 'group-1',
                  startDate: now.subtract(const Duration(hours: 1)),
                ),
          );
        },
        videos: [
          _video('v1', _session1Id, 1),
          _video('live', _liveVideoId, 2),
        ],
      );
      await _settle(tester);
      expect(player(tester).videoId, _liveVideoId);
      expect(player(tester).isReplay, isFalse);

      // No Tibetan stream: the page stays live so the toggles stay
      // reachable, and the English stream is still kept out of the list.
      // A language switch fetches on the next frame and renders the answer
      // on the one after, so settle twice.
      await tester.tap(find.text('བོད'));
      await _settle(tester);
      await _settle(tester);
      expect(fetches, 2);
      expect(find.byType(GroupEventLanguageToggle), findsOneWidget);
      await openReplays(tester);
      expect(find.text('Day 1 · Session 1'), findsOneWidget);
      expect(find.text('Day 1 · Session 2'), findsNothing);
      await tester.tapAt(const Offset(20, 820));
      await _settle(tester);
      await _settle(tester);

      // Back in English the link is gone for good: the day's first
      // recording plays, and the stream that ended joins the list.
      await tester.tap(find.text('En'));
      await _settle(tester);
      await _settle(tester);
      expect(fetches, 3);
      expect(player(tester).videoId, _session1Id);
      expect(player(tester).isReplay, isTrue);
      expect(find.byType(GroupEventLanguageToggle), findsNothing);
      expect(find.byType(GroupEventBackToLivePill), findsNothing);
      await openReplays(tester);
      expect(find.text('Day 1 · Session 1'), findsOneWidget);
      expect(find.text('Day 1 · Session 2'), findsOneWidget);
    });

    testWidgets('before the event starts, today keeps its countdown', (
      tester,
    ) async {
      final startsAt = DateTime.now().add(const Duration(hours: 2));
      await _pumpLiveEventDetails(
        tester,
        fetch:
            () async => Right(
              GroupEvent(
                id: 'event-1',
                groupId: 'group-1',
                startDate: startsAt,
              ),
            ),
        videos: twoSessions,
      );
      await _settle(tester);

      // Recordings do not pre-empt the countdown; they wait in the menu.
      expect(find.byType(GroupEventNotStartedCard), findsOneWidget);
      expect(find.text('Puja starts in'), findsOneWidget);
      expect(find.byType(GroupEventLivePlayer), findsNothing);
      expect(replaysTrigger, findsOneWidget);

      await openReplays(tester);
      await pick(tester, 'Day 1 · Session 2');

      expect(player(tester).videoId, _session2Id);
      expect(player(tester).isReplay, isTrue);
      expect(find.byType(GroupEventNotStartedCard), findsNothing);
      // Nothing live to go back to.
      expect(find.byType(GroupEventBackToLivePill), findsNothing);
    });
  });
}
