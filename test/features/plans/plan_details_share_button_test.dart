import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/plan_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

/// No-op analytics so PlanDetails' initState tracking is inert in tests.
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

UserPlansModel _makePlan() => UserPlansModel(
  id: 'plan-1',
  title: 'Chapter 1: Benefits of Bodhicitta',
  description: 'Test plan',
  language: 'en',
  difficultyLevel: null,
  startedAt: DateTime(2026, 7, 1),
  totalDays: 14,
  tags: null,
);

UserPlanDayDetailResponse _makeDay({
  required bool isCompleted,
  String? shareableImageUrl,
}) => UserPlanDayDetailResponse(
  id: 'day-1',
  dayNumber: 1,
  tasks: [
    UserTasksDto(
      id: 'task-1',
      title: 'Introduction',
      estimatedTime: null,
      displayOrder: 1,
      isCompleted: isCompleted,
      subTasks: const [],
    ),
  ],
  isCompleted: isCompleted,
  shareableImageUrl: shareableImageUrl,
);

List<Override> _overridesFor(UserPlanDayDetailResponse day) => [
  analyticsServiceProvider.overrideWithValue(_FakeAnalyticsService()),
  userPlanDayContentFutureProvider.overrideWith(
    (ref, params) => Stream.value(Right(day)),
  ),
  userPlanDaysCompletionStatusProvider.overrideWith(
    (ref, planId) => Stream.value(Right({1: day.isCompleted})),
  ),
  planDaysByPlanIdFutureProvider.overrideWith(
    (ref, planId) => Stream.value(const Right(<PlanDaysModel>[])),
  ),
  seriesListFutureProvider.overrideWith(
    (ref) => Stream.value(const Left(NetworkFailure('test'))),
  ),
  userSeriesEnrollmentsProvider.overrideWith((ref) => Stream.value(<String>{})),
];

Future<void> _pumpDetails(
  WidgetTester tester,
  UserPlanDayDetailResponse day,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overridesFor(day),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlanDetails(
          plan: _makePlan(),
          selectedDay: 1,
          startDate: DateTime(2026, 7, 1),
        ),
      ),
    ),
  );
  // Let the overridden streams emit and the UI settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// FilledButton.icon builds a private FilledButton subclass, which
/// find.byType/widgetWithText (exact runtimeType match) would miss.
Finder _buttonWith(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((w) => w is FilledButton),
);

FilledButton _bottomButton(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(_buttonWith(label));

void main() {
  group('bottom button swaps between Practice now and Share', () {
    testWidgets('incomplete day shows Practice now', (tester) async {
      await _pumpDetails(
        tester,
        _makeDay(
          isCompleted: false,
          shareableImageUrl: 'https://example.com/img.png',
        ),
      );

      expect(_buttonWith('Practice now'), findsOneWidget);
      expect(_buttonWith('Share'), findsNothing);
    });

    testWidgets('completed day with shareable image shows Share', (
      tester,
    ) async {
      await _pumpDetails(
        tester,
        _makeDay(
          isCompleted: true,
          shareableImageUrl: 'https://example.com/img.png',
        ),
      );

      expect(_buttonWith('Share'), findsOneWidget);
      expect(_buttonWith('Practice now'), findsNothing);
      expect(_bottomButton(tester, 'Share').onPressed, isNotNull);
    });

    testWidgets('completed day without shareable image keeps Practice now', (
      tester,
    ) async {
      await _pumpDetails(
        tester,
        _makeDay(isCompleted: true, shareableImageUrl: null),
      );

      expect(_buttonWith('Practice now'), findsOneWidget);
      expect(_buttonWith('Share'), findsNothing);
    });

    testWidgets('whitespace-only shareable image keeps Practice now', (
      tester,
    ) async {
      await _pumpDetails(
        tester,
        _makeDay(isCompleted: true, shareableImageUrl: '   '),
      );

      expect(_buttonWith('Practice now'), findsOneWidget);
      expect(_buttonWith('Share'), findsNothing);
    });

    testWidgets(
      'tapping Share surfaces the error and re-enables the button when the '
      'download fails (test env blocks HTTP)',
      (tester) async {
        await _pumpDetails(
          tester,
          _makeDay(
            isCompleted: true,
            shareableImageUrl: 'https://example.com/img.png',
          ),
        );

        await tester.tap(find.text('Share'));
        await tester.pump();
        await tester.pump();

        // Flutter's test HTTP client rejects the request, so the failure
        // path must show the error snackbar and reset the button.
        expect(find.text('Unable to share. Please try again'), findsOneWidget);
        expect(_bottomButton(tester, 'Share').onPressed, isNotNull);

        // Drain the snackbar's dismiss timer.
        await tester.pump(const Duration(seconds: 20));
      },
    );
  });

  group('back button', () {
    GoRouter buildRouter(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder:
              (context, state) =>
                  const Scaffold(body: Center(child: Text('HOME MARKER'))),
        ),
        GoRoute(
          path: '/details',
          builder:
              (context, state) => PlanDetails(
                plan: _makePlan(),
                selectedDay: 1,
                startDate: DateTime(2026, 7, 1),
              ),
        ),
      ],
    );

    Future<void> pumpRouter(WidgetTester tester, GoRouter router) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overridesFor(
            _makeDay(isCompleted: false, shareableImageUrl: null),
          ),
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

    testWidgets('pops back to the previous screen when pushed', (tester) async {
      final router = buildRouter(AppRoutes.home);
      await pumpRouter(tester, router);
      expect(find.text('HOME MARKER'), findsOneWidget);

      router.push('/details');
      await tester.pumpAndSettle();
      expect(find.byIcon(AppAssets.arrowLeft), findsOneWidget);

      await tester.tap(find.byIcon(AppAssets.arrowLeft));
      await tester.pumpAndSettle();

      expect(find.text('HOME MARKER'), findsOneWidget);
    });

    testWidgets('goes home when there is nothing to pop (deep link entry)', (
      tester,
    ) async {
      final router = buildRouter('/details');
      await pumpRouter(tester, router);
      expect(find.text('HOME MARKER'), findsNothing);

      await tester.tap(find.byIcon(AppAssets.arrowLeft));
      await tester.pumpAndSettle();

      expect(find.text('HOME MARKER'), findsOneWidget);
    });
  });
}
