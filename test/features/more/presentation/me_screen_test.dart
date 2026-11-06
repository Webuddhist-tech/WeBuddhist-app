import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/domain/repositories/user_stats_repository.dart';
import 'package:flutter_pecha/features/more/presentation/me_screen.dart';
import 'package:flutter_pecha/features/more/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/more/presentation/providers/user_stats_provider.dart';
import 'package:flutter_pecha/features/more/presentation/utils/me_analytics.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/me_prayer_requests_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/recording_analytics_service.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User extends StateNotifier<UserState> implements UserNotifier {
  _User(User? user) : super(UserState(user: user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The screen refreshes stats on open; this answers with no stats.
class _StatsRepository implements UserStatsRepositoryInterface {
  @override
  Future<Either<Failure, UserStats>> refreshUserStats() async =>
      Right(UserStats.empty);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpMeScreen(
  WidgetTester tester, {
  required AuthState auth,
  User? user,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _Auth(auth)),
        userProvider.overrideWith((ref) => _User(user)),
        userStatsRepositoryProvider.overrideWithValue(_StatsRepository()),
        userStatsFutureProvider.overrideWith(
          () => ScreenCacheNotifier((ref, bind) => Right(UserStats.empty)),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MeScreen(),
      ),
    ),
  );
  await tester.pump();
}

/// With routes for the pages the Me page pushes, and analytics recorded.
Future<void> _pumpRoutedMeScreen(
  WidgetTester tester,
  RecordingAnalyticsService analytics,
) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const MeScreen()),
      GoRoute(
        path: '/home/settings',
        builder: (_, _) => const Text('settings page'),
      ),
      GoRoute(
        path: AppRoutes.myPrayerRequests,
        builder: (_, _) => const Text('prayer requests page'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analyticsServiceProvider.overrideWithValue(analytics),
        authProvider.overrideWith(
          (ref) => _Auth(const AuthState(isLoggedIn: true)),
        ),
        userProvider.overrideWith(
          (ref) => _User(const User(id: 'me', username: 'tenzin')),
        ),
        userStatsRepositoryProvider.overrideWithValue(_StatsRepository()),
        userStatsFutureProvider.overrideWith(
          () => ScreenCacheNotifier((ref, bind) => Right(UserStats.empty)),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pump();
}

Finder _appBarText(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

void main() {
  const signedIn = AuthState(isLoggedIn: true);

  testWidgets('app bar shows the username when signed in', (tester) async {
    await _pumpMeScreen(
      tester,
      auth: signedIn,
      user: const User(
        id: 'me',
        displayName: 'Tenzin Dolma',
        username: 'tenzin',
        email: 'tenzin@example.com',
      ),
    );

    expect(_appBarText('tenzin'), findsOneWidget);
    expect(_appBarText('Me'), findsNothing);
    expect(find.text('tenzin@example.com'), findsNothing);
  });

  testWidgets('app bar shows "Me" when the user has no username', (
    tester,
  ) async {
    await _pumpMeScreen(
      tester,
      auth: signedIn,
      user: const User(id: 'me', displayName: 'Tenzin Dolma', username: '  '),
    );

    expect(_appBarText('Me'), findsOneWidget);
  });

  testWidgets('app bar shows "Me" for guests', (tester) async {
    await _pumpMeScreen(
      tester,
      auth: const AuthState(isLoggedIn: true, isGuest: true),
      user: const User(id: 'me', username: 'tenzin'),
    );

    expect(_appBarText('Me'), findsOneWidget);
    expect(_appBarText('tenzin'), findsNothing);
  });

  testWidgets('tapping settings is tracked and still opens it', (tester) async {
    final analytics = RecordingAnalyticsService();
    await _pumpRoutedMeScreen(tester, analytics);

    await tester.tap(find.byIcon(AppAssets.settings));
    await tester.pumpAndSettle();

    expect(find.text('settings page'), findsOneWidget);
    expect(analytics.eventNames, [AnalyticsEvents.meItemTapped]);
    expect(analytics.events.single.properties, {'item': 'settings'});
  });

  testWidgets('tapping prayer requests is tracked and still opens it', (
    tester,
  ) async {
    final analytics = RecordingAnalyticsService();
    await _pumpRoutedMeScreen(tester, analytics);

    await tester.ensureVisible(find.byType(MePrayerRequestsRow));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MePrayerRequestsRow));
    await tester.pumpAndSettle();

    expect(find.text('prayer requests page'), findsOneWidget);
    expect(analytics.events.single.properties, {'item': 'prayer_requests'});
  });

  test('every Me item sends its name, and nothing else', () {
    const expected = {
      MeItem.streak: 'streak',
      MeItem.practiceDays: 'practice_days',
      MeItem.accumulation: 'accumulation',
      MeItem.prayerRequests: 'prayer_requests',
      MeItem.settings: 'settings',
      MeItem.editProfile: 'edit_profile',
    };
    expect(expected.keys, containsAll(MeItem.values));

    expected.forEach((item, name) {
      final analytics = RecordingAnalyticsService();
      MeAnalytics(analytics).itemTapped(item);

      expect(analytics.eventNames, [AnalyticsEvents.meItemTapped]);
      expect(analytics.events.single.properties, {'item': name});
    });
  });
}
