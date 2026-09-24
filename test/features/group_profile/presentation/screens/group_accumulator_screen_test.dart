import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_accumulator_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_accumulator_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

class _GuestAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _GuestAuth() : super(const AuthState(isLoggedIn: false, isGuest: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccumulatorRepository extends Fake
    implements GroupAccumulatorRepositoryInterface {
  @override
  Future<Either<Failure, GroupAccumulatorMembersPage>>
  getGroupAccumulatorMembers(
    String accumulatorId, {
    required int skip,
    required int limit,
    required GroupAccumulatorMemberSort sortBy,
  }) async => const Right(
    GroupAccumulatorMembersPage(
      members: [],
      memberCount: 0,
      total: 0,
      skip: 0,
      limit: 20,
    ),
  );
}

class _FakeProfileRepository extends Fake
    implements GroupProfileRepositoryInterface {}

const _detail = GroupAccumulatorDetail(
  id: 'acc-1',
  presetAccumulatorId: 'preset-1',
  groupId: 'group-1',
  title: 'Green Tara',
  isJoined: false,
);

Future<void> _pump(
  WidgetTester tester,
  RecordingAnalyticsService service,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analyticsServiceProvider.overrideWithValue(service),
        authProvider.overrideWith((ref) => _GuestAuth()),
        groupAccumulatorDetailProvider.overrideWith(
          (ref, id) async => const Right(_detail),
        ),
        groupProfileProvider.overrideWith(
          (ref, id) async => const Left(NetworkFailure('test')),
        ),
        groupAccumulatorRepositoryProvider.overrideWithValue(
          _FakeAccumulatorRepository(),
        ),
        groupProfileRepositoryProvider.overrideWithValue(
          _FakeProfileRepository(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GroupAccumulatorScreen(
          accumulatorId: 'acc-1',
          groupTitle: 'Lodhen Sangha',
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('viewed fires once the detail is on screen, and only once', (
    tester,
  ) async {
    final service = RecordingAnalyticsService();
    await _pump(tester, service);

    // Still loading: nothing reported yet.
    expect(service.events, isEmpty);

    await tester.pump();
    await tester.pump();

    expect(find.text('Green Tara'), findsOneWidget);
    expect(service.eventNames, [AnalyticsEvents.groupAccumulatorViewed]);
    expect(service.events.single.properties, {
      'group_id': 'group-1',
      'accumulator_id': 'acc-1',
    });

    // Rebuilds do not report again.
    await tester.tap(find.text('My Contributions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(service.eventNames, [AnalyticsEvents.groupAccumulatorViewed]);
  });
}
