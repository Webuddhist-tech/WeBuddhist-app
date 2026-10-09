import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_event_detail_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_live_player.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_participation_dialog.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/my_plans_paginated_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/activity_list.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/plan_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import '../widgets/fake_in_app_webview_platform.dart';

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

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records every series enrollment instead of calling the API.
class _RecordingEnrollment extends StateNotifier<SeriesEnrollmentState>
    implements SeriesEnrollmentNotifier {
  _RecordingEnrollment(this._seriesId, this._calls)
    : super(const SeriesEnrollmentIdle());

  final String _seriesId;
  final List<String> _calls;

  @override
  Future<bool> enroll({String? groupId}) async {
    _calls.add(_seriesId);
    state = const SeriesEnrollmentSuccess();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records event joins (a participation saved) instead of calling the API.
class _RecordingGroupRepository implements GroupProfileRepositoryInterface {
  _RecordingGroupRepository(this._joins);

  final List<String> _joins;

  @override
  Future<Either<Failure, void>> joinGroupEvent(
    String eventId, {
    GroupEventParticipationType? participationType,
  }) async {
    _joins.add(eventId);
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoParticipants extends StateNotifier<GroupEventParticipantsState>
    implements GroupEventParticipantsNotifier {
  _NoParticipants() : super(const GroupEventParticipantsState(hasMore: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Not enrolled in anything, so the catalog plan is what opens.
class _NoMyPlans extends StateNotifier<MyPlansState>
    implements MyPlansNotifier {
  _NoMyPlans() : super(const MyPlansState(hasMore: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _eventId = 'event-1';
const _seriesId = 'series-1';

GroupEvent _event({required String format, required bool isJoined}) =>
    GroupEvent(
      id: _eventId,
      groupId: 'group-1',
      title: 'Green Tara Puja',
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 2)),
      isJoined: isJoined,
      seriesId: _seriesId,
      series: const GroupEventPracticeRef(id: _seriesId, name: 'Green Tara'),
      eventFormat: format,
    );

final _series = Series(
  id: _seriesId,
  title: 'Green Tara',
  description: '',
  plans: [
    Plan(
      id: 'plan-1',
      title: 'Green Tara',
      description: 'Test plan',
      authorId: 'author-1',
      totalDays: 21,
      difficulty: DifficultyLevel.beginner,
      startDate: DateTime.now(),
    ),
  ],
);

final _day = UserPlanDayDetailResponse(
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

/// The event page under a router whose `/practice/details` builds
/// `PlanDetails` from `extra` the way `app_router.dart` does.
Future<void> _pumpEventPage(
  WidgetTester tester, {
  required GroupEvent event,
  required List<String> enrollments,
  required List<String> joins,
  // A pending stream counts as live, so the online page mounts its header.
  Future<Either<Failure, GroupEvent>> Function()? stream,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  FakeInAppWebViewPlatform.install();

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const GroupEventDetailScreen(eventId: _eventId),
      ),
      GoRoute(
        path: '/practice/details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PlanDetails(
            plan: extra!['plan'] as UserPlansModel,
            selectedDay: extra['selectedDay'] as int? ?? 1,
            startDate: extra['startDate'] as DateTime? ?? DateTime.now(),
            seriesId: extra['seriesId'] as String?,
            eventId: extra['eventId'] as String?,
            showLiveStream: extra['showLiveStream'] as bool? ?? true,
            readOnly: extra['readOnly'] as bool? ?? false,
          );
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analyticsServiceProvider.overrideWithValue(_FakeAnalyticsService()),
        localStorageServiceProvider.overrideWithValue(_FakeStorage()),
        authProvider.overrideWith((ref) => _SignedInAuth()),
        groupProfileRepositoryProvider.overrideWithValue(
          _RecordingGroupRepository(joins),
        ),
        groupEventDetailProvider.overrideWith(
          (ref, id) async => Right(event),
        ),
        groupEventParticipantsProvider.overrideWith(
          (ref, id) => _NoParticipants(),
        ),
        groupProfileProvider.overrideWith(
          (ref, id) async => const Left(NetworkFailure('test')),
        ),
        seriesByIdProvider.overrideWith(
          (ref, id) => Stream.value(Right(_series)),
        ),
        seriesListFutureProvider.overrideWith(
          (ref) => Stream.value(const Left(NetworkFailure('test'))),
        ),
        userSeriesEnrollmentsProvider.overrideWith(
          (ref) => Stream.value(<String>{}),
        ),
        seriesEnrollmentProvider.overrideWith(
          (ref, seriesId) => _RecordingEnrollment(seriesId, enrollments),
        ),
        myPlansPaginatedProvider.overrideWith((ref) => _NoMyPlans()),
        groupEventInLanguageProvider.overrideWith(
          (ref, key) =>
              stream != null
                  ? stream()
                  : Future.value(const Left(NetworkFailure('test'))),
        ),
        userPlanDayContentFutureProvider.overrideWith(
          (ref, params) => Stream.value(Right(_day)),
        ),
        userPlanDaysCompletionStatusProvider.overrideWith(
          (ref, planId) => Stream.value(const Right({1: false})),
        ),
        planDaysByPlanIdFutureProvider.overrideWith(
          (ref, planId) => Stream.value(const Right(<PlanDaysModel>[])),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Taps an action-row button and waits out the push into the plan page.
Future<void> _tapAndEnter(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  // Route transition, then the day's tasks.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

PlanDetails _planDetails(WidgetTester tester) =>
    tester.widget<PlanDetails>(find.byType(PlanDetails));

void main() {
  group('a hybrid event explored before joining', () {
    testWidgets('In-person view opens the plan read-only without enrolling', (
      tester,
    ) async {
      final enrollments = <String>[];
      final joins = <String>[];
      await _pumpEventPage(
        tester,
        event: _event(format: 'hybrid', isJoined: false),
        enrollments: enrollments,
        joins: joins,
      );

      expect(find.text('Join'), findsOneWidget);
      await _tapAndEnter(tester, 'In-person view');

      // Not asked to pick a format, not joined, not enrolled.
      expect(find.byType(GroupEventParticipationDialog), findsNothing);
      expect(joins, isEmpty);
      expect(enrollments, isEmpty);

      expect(find.byType(PlanDetails), findsOneWidget);
      expect(_planDetails(tester).readOnly, isTrue);
      expect(_planDetails(tester).showLiveStream, isFalse);
      expect(_planDetails(tester).eventId, _eventId);
      expect(_planDetails(tester).seriesId, _seriesId);
      // The day's tasks load for someone who is not enrolled, without ticks.
      expect(find.text('Tara of the day'), findsOneWidget);
      expect(
        tester.widget<ActivityList>(find.byType(ActivityList)).readOnly,
        isTrue,
      );
    });

    testWidgets('Online view opens the live layout read-only without '
        'enrolling', (tester) async {
      final enrollments = <String>[];
      final joins = <String>[];
      await _pumpEventPage(
        tester,
        event: _event(format: 'hybrid', isJoined: false),
        enrollments: enrollments,
        joins: joins,
        stream: () => Completer<Either<Failure, GroupEvent>>().future,
      );

      await _tapAndEnter(tester, 'Online view');

      expect(find.byType(GroupEventParticipationDialog), findsNothing);
      expect(joins, isEmpty);
      expect(enrollments, isEmpty);

      expect(_planDetails(tester).readOnly, isTrue);
      expect(_planDetails(tester).showLiveStream, isTrue);
      expect(find.byType(GroupEventLiveHeader), findsOneWidget);
      expect(find.text('Tara of the day'), findsOneWidget);
      expect(
        tester.widget<ActivityList>(find.byType(ActivityList)).readOnly,
        isTrue,
      );
    });
  });

  testWidgets('an attendee\'s Practice in-person enrolls in the series', (
    tester,
  ) async {
    final enrollments = <String>[];
    final joins = <String>[];
    await _pumpEventPage(
      tester,
      event: _event(format: 'offline', isJoined: true),
      enrollments: enrollments,
      joins: joins,
    );

    await _tapAndEnter(tester, 'Practice in-person');

    expect(enrollments, [_seriesId]);
    expect(_planDetails(tester).readOnly, isFalse);
    expect(find.text('Tara of the day'), findsOneWidget);
    expect(
      tester.widget<ActivityList>(find.byType(ActivityList)).readOnly,
      isFalse,
    );
  });
}
