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
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_cover_image.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_embedded_host.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/activity_list.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/plan_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

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
  NavigatorObserver get routeObserver => NavigatorObserver();
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

UserPlanDayDetailResponse _makeDay() => UserPlanDayDetailResponse(
  id: 'day-1',
  dayNumber: 1,
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
}) async {
  // Phone portrait: the pinned 16:9 stream must leave room for the list.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final day = _makeDay();
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
          (ref, planId) => Stream.value(const Right({1: false})),
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
          // Started today, so no missed-days badge crowds the narrow row.
          startDate: DateTime.now(),
          eventId: 'event-1',
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
    // Online readers stay off the live socket: the stream's overlays carry
    // the text, and sync would lag behind the video.
    expect(_activityList(tester).eventId, isNull);

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
}
