import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/repositories/mala_repository.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/group_accumulations_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/analytics/recording_analytics_service.dart';
import '../../mala_fakes.dart';

const _userId = 'user-1';
const _mantra = Mantra(presetId: 'tara-praises');

/// Local counts without Hive: a personal lifetime total and, per accumulation,
/// a session total that may be ahead of what has synced.
class _FakeLocal extends Fake implements MalaLocalDataSource {
  _FakeLocal({required this.personal, this.groups = const {}});

  final LocalMalaState personal;
  final Map<String, LocalGroupMalaState> groups;

  @override
  LocalMalaState read(String userId, String presetId) => personal;

  @override
  LocalGroupMalaState readGroup(String userId, String groupAccumulatorId) =>
      groups[groupAccumulatorId] ?? const LocalGroupMalaState();

  @override
  List<String> groupAccumulatorIdsForUser(String userId) =>
      groups.keys.toList();
}

/// Offline: the personal counter falls back to its local lifetime total.
class _OfflineRepository extends Fake implements MalaRepository {
  @override
  Future<Either<Failure, MalaCount>> getAccumulatorDetail(
    String parentId,
  ) async => const Left(NetworkFailure('offline'));
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

const _prayerEvent = AccumulatorGroup(
  groupAccumulatorId: 'ga-100k',
  groupId: 'g-wb',
  title: '100k',
  groupName: 'WeBuddhist',
  eventTitle: 'The 100k prayer of twenty-one Taras',
  userTotalCount: 50,
  groupTotalCount: 189,
  isJoined: true,
);

const _plainGroup = AccumulatorGroup(
  groupAccumulatorId: 'ga-plain',
  groupId: 'g-wb',
  title: 'Daily Tara recitation',
  groupName: 'WeBuddhist',
  userTotalCount: 4,
  groupTotalCount: 40,
  isJoined: true,
);

Future<void> _openSheet(
  WidgetTester tester, {
  required List<AccumulatorGroup> groups,
  int personalLifetime = 143,
  Map<String, LocalGroupMalaState> localGroups = const {},
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) async {
  late BuildContext hostContext;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeUserStorage(_userId)),
        malaLocalDataSourceProvider.overrideWithValue(
          _FakeLocal(
            personal: LocalMalaState(totalCounted: personalLifetime),
            groups: localGroups,
          ),
        ),
        malaRepositoryProvider.overrideWithValue(_OfflineRepository()),
        malaRemoteDataSourceProvider.overrideWithValue(FakeMalaRemote()),
        malaSyncManagerProvider.overrideWithValue(FakeMalaSync()),
        malaSoundPlayerProvider.overrideWithValue(SilentMalaSoundPlayer()),
        analyticsServiceProvider.overrideWithValue(RecordingAnalyticsService()),
        joinedAccumulatorGroupsProvider.overrideWith(
          (ref, presetId) async => groups,
        ),
      ],
      child: MaterialApp(
        locale: locale,
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    ),
  );

  // Not awaited: the sheet has to stay open so the test can drive it.
  unawaited(
    GroupAccumulationsSheet.show(
      hostContext,
      mantra: _mantra,
      presetTitle: 'Praises to the 21 Taras',
      groups: groups,
    ),
  );
  await tester.pumpAndSettle();
  // Lets the personal counter's seed timeout run out.
  await tester.pump(const Duration(seconds: 4));
}

/// The tappable row holding [title].
Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(InkWell));

Finder _checkIn(String title) =>
    find.descendant(of: _row(title), matching: find.byIcon(AppAssets.check));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('header adds personal practice and every accumulation', (
    tester,
  ) async {
    await _openSheet(tester, groups: const [_taraEvent, _prayerEvent]);

    expect(find.text('Praises to the 21 Taras'), findsOneWidget);
    expect(find.text('My all-time accumulation'), findsOneWidget);
    expect(find.text('216'), findsOneWidget);
    expect(find.text('Add recitation to'), findsOneWidget);
    expect(find.text('Personal practice'), findsOneWidget);
    expect(find.text('143'), findsOneWidget);
  });

  testWidgets('an event row shows its event, group and both totals', (
    tester,
  ) async {
    await _openSheet(tester, groups: const [_taraEvent, _prayerEvent]);

    expect(find.text('Events'), findsOneWidget);
    expect(find.text('The praise to the twenty-one Tara'), findsOneWidget);
    expect(
      find.text('Light Of Buddhadharma Foundation International'),
      findsOneWidget,
    );
    expect(find.text('My total: 23  |  Group total: 423'), findsOneWidget);
    expect(find.text('My total: 50  |  Group total: 189'), findsOneWidget);
    // The accumulation's own title gives way to the event's.
    expect(find.text('Tara praises'), findsNothing);
    expect(find.text('Groups'), findsNothing);
  });

  testWidgets('an accumulation without an event is listed under Groups', (
    tester,
  ) async {
    await _openSheet(tester, groups: const [_taraEvent, _plainGroup]);

    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Daily Tara recitation'), findsOneWidget);
    expect(find.text('My total: 4  |  Group total: 40'), findsOneWidget);
  });

  testWidgets('only group accumulations means no Events heading', (
    tester,
  ) async {
    await _openSheet(tester, groups: const [_plainGroup]);

    expect(find.text('Events'), findsNothing);
    expect(find.text('Groups'), findsOneWidget);
  });

  testWidgets('taps not yet synced show in my total, group total and header', (
    tester,
  ) async {
    await _openSheet(
      tester,
      groups: const [_taraEvent, _prayerEvent],
      localGroups: const {
        'ga-tara': LocalGroupMalaState(total: 8, syncedTotal: 3),
      },
    );

    expect(find.text('My total: 28  |  Group total: 428'), findsOneWidget);
    expect(find.text('221'), findsOneWidget);
  });

  testWidgets('the check marks the selected row and follows a tap', (
    tester,
  ) async {
    await _openSheet(tester, groups: const [_taraEvent, _prayerEvent]);

    expect(find.byIcon(AppAssets.check), findsOneWidget);
    expect(_checkIn('Personal practice'), findsOneWidget);

    await tester.tap(find.text('The praise to the twenty-one Tara'));
    await tester.pumpAndSettle();

    expect(find.byIcon(AppAssets.check), findsOneWidget);
    expect(_checkIn('The praise to the twenty-one Tara'), findsOneWidget);
    expect(_checkIn('Personal practice'), findsNothing);

    await tester.tap(find.text('Personal practice'));
    await tester.pumpAndSettle();

    expect(_checkIn('Personal practice'), findsOneWidget);
    expect(_checkIn('The praise to the twenty-one Tara'), findsNothing);
  });

  testWidgets('Tibetan renders the counts in Tibetan digits', (tester) async {
    await _openSheet(
      tester,
      groups: const [_taraEvent, _prayerEvent],
      locale: const Locale('bo'),
    );

    expect(find.text('༢༡༦'), findsOneWidget);
    expect(find.text('༡༤༣'), findsOneWidget);
    expect(find.textContaining('༤༢༣'), findsOneWidget);
    expect(find.textContaining('423'), findsNothing);
  });

  testWidgets('long names fit a narrow phone without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _openSheet(
      tester,
      groups: const [_taraEvent, _prayerEvent, _plainGroup],
      personalLifetime: 1234567,
    );

    // A layout overflow would have failed the pump with a FlutterError.
    expect(find.text('1,234,567'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
