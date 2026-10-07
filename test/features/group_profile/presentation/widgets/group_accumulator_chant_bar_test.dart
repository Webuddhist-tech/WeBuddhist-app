import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_chant_bar.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/repositories/mala_repository.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/analytics/recording_analytics_service.dart';
import '../../../mala/mala_fakes.dart';

const _userId = 'user-1';
const _mantra = Mantra(presetId: 'tara-praises');

/// Local counts without Hive; nothing counted yet.
class _EmptyLocal extends Fake implements MalaLocalDataSource {
  @override
  LocalMalaState read(String userId, String presetId) =>
      const LocalMalaState();

  @override
  LocalGroupMalaState readGroup(String userId, String groupAccumulatorId) =>
      const LocalGroupMalaState();

  @override
  List<String> groupAccumulatorIdsForUser(String userId) => const [];
}

/// Offline: the personal counter falls back to its local lifetime total.
class _OfflineRepository extends Fake implements MalaRepository {
  @override
  Future<Either<Failure, MalaCount>> getAccumulatorDetail(
    String parentId,
  ) async => const Left(NetworkFailure('offline'));
}

/// Answers each request for the joined list with the next of [responses]; the
/// last one repeats.
class _JoinedList {
  _JoinedList(this.responses);

  final List<List<AccumulatorGroup>> responses;
  int requests = 0;

  List<AccumulatorGroup> next() {
    final index = requests < responses.length ? requests : responses.length - 1;
    requests++;
    return responses[index];
  }
}

const _taraEvent = AccumulatorGroup(
  groupAccumulatorId: 'ga-tara',
  groupId: 'g-lobf',
  title: 'Tara praises',
  groupName: 'Light Of Buddhadharma Foundation International',
  eventTitle: 'The praise to the twenty-one Tara',
  userTotalCount: 23,
  groupTotalCount: 423,
  isJoined: true,
);

Future<void> _pumpBar(WidgetTester tester, _JoinedList joined) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeUserStorage(_userId)),
        malaLocalDataSourceProvider.overrideWithValue(_EmptyLocal()),
        malaRepositoryProvider.overrideWithValue(_OfflineRepository()),
        malaRemoteDataSourceProvider.overrideWithValue(FakeMalaRemote()),
        malaSyncManagerProvider.overrideWithValue(FakeMalaSync()),
        malaSoundPlayerProvider.overrideWithValue(SilentMalaSoundPlayer()),
        analyticsServiceProvider.overrideWithValue(RecordingAnalyticsService()),
        joinedAccumulatorGroupsProvider.overrideWith(
          (ref, presetId) async => joined.next(),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: GroupAccumulatorChantBar(
              mantra: _mantra,
              sessionCount: 3,
              chantTitle: 'Praises to the 21 Taras',
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapPill(WidgetTester tester) async {
  // The second '+3' is the invisible twin that keeps the title centred.
  await tester.tap(find.text('+3').first);
  await tester.pumpAndSettle();
  // Lets the personal counter's seed timeout run out.
  await tester.pump(const Duration(seconds: 4));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the pill opens the sheet while no accumulation is listed', (
    tester,
  ) async {
    await _pumpBar(tester, _JoinedList(const [[]]));

    await _tapPill(tester);

    expect(find.text('Personal practice'), findsOneWidget);
  });

  testWidgets('opening on an empty list asks again and fills the rows in', (
    tester,
  ) async {
    // The first request failed, which the provider reports as no groups.
    final joined = _JoinedList(const [
      [],
      [_taraEvent],
    ]);
    await _pumpBar(tester, joined);
    expect(joined.requests, 1);

    await _tapPill(tester);

    expect(joined.requests, 2);
    expect(find.text('Personal practice'), findsOneWidget);
    expect(find.text('The praise to the twenty-one Tara'), findsOneWidget);
  });

  testWidgets('a loaded list is not requested again on opening', (
    tester,
  ) async {
    final joined = _JoinedList(const [
      [_taraEvent],
    ]);
    await _pumpBar(tester, joined);

    await _tapPill(tester);

    expect(joined.requests, 1);
    expect(find.text('The praise to the twenty-one Tara'), findsOneWidget);
  });
}
