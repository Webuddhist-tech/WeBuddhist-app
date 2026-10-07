import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/update_user_info_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/update_username_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/data/models/accumulator_group_model.dart';
import 'package:flutter_pecha/features/mala/data/models/accumulator_model.dart';
import 'package:flutter_pecha/features/mala/data/repositories/mala_repository_impl.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/group_accumulations_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/analytics/recording_analytics_service.dart';
import '../../mala_fakes.dart';

const _userId = 'user-1';
const _mantra = Mantra(presetId: 'tara-praises');

/// One `AccumulatorGroupDTO` as `GET /accumulators/{id}/groups` returns it.
Map<String, dynamic> _row({
  required String id,
  required String groupId,
  String? title,
  String? groupName,
  String? eventTitle,
  int userTotal = 0,
  int groupTotal = 0,
}) => {
  'group_accumulator_id': id,
  'group_id': groupId,
  'title': title,
  'group_name': groupName,
  'event_title': eventTitle,
  'image': null,
  'target_count': null,
  'user_total_count': userTotal,
  'group_total_count': groupTotal,
  'is_joined': true,
  'start_date': null,
  'end_date': null,
  'created_at': '2026-09-01T00:00:00Z',
};

/// Answers the groups listing with [rows], parsed as the real data source
/// parses the response, and records how it was asked.
class _ListingRemote extends FakeMalaRemote {
  _ListingRemote(this.rows, {this.fails = false});

  final List<Map<String, dynamic>> rows;
  final bool fails;
  final calls = <({String id, bool joinedOnly, String? language})>[];

  @override
  Future<List<AccumulatorGroupModel>> fetchAccumulatorGroups(
    String accumulatorId, {
    bool joinedOnly = false,
    String? language,
  }) async {
    calls.add((id: accumulatorId, joinedOnly: joinedOnly, language: language));
    if (fails) throw Exception('offline');
    return AccumulatorGroupsResponseModel.fromJson({
      'groups': rows,
      'total': rows.length,
      'skip': 0,
      'limit': 20,
    }).groups;
  }

  /// Offline: the personal counter falls back to its local total.
  @override
  Future<AccumulatorDetailModel?> fetchAccumulatorDetail(String parentId) =>
      throw Exception('offline');
}

class _EmptyLocal extends Fake implements MalaLocalDataSource {
  @override
  LocalMalaState read(String userId, String presetId) => const LocalMalaState();

  @override
  LocalGroupMalaState readGroup(String userId, String groupAccumulatorId) =>
      const LocalGroupMalaState();

  @override
  List<String> groupAccumulatorIdsForUser(String userId) => const [];
}

class _UnusedGetUser extends Fake implements GetCurrentUserUseCase {}

class _UnusedUpdateInfo extends Fake implements UpdateUserInfoUseCase {}

class _UnusedUpdateUsername extends Fake implements UpdateUsernameUseCase {}

class _UnusedUploadAvatar extends Fake implements UploadAvatarUseCase {}

/// No profile loaded: the pill falls back to the default avatar.
class _NoUserNotifier extends UserNotifier {
  _NoUserNotifier()
    : super(
        getCurrentUserUseCase: _UnusedGetUser(),
        updateUserInfoUseCase: _UnusedUpdateInfo(),
        updateUsernameUseCase: _UnusedUpdateUsername(),
        uploadAvatarUseCase: _UnusedUploadAvatar(),
        localStorageService: FakeUserStorage(_userId),
      );
}

Future<void> _pumpBar(WidgetTester tester, _ListingRemote remote) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeUserStorage(_userId)),
        malaLocalDataSourceProvider.overrideWithValue(_EmptyLocal()),
        malaRemoteDataSourceProvider.overrideWithValue(remote),
        malaRepositoryProvider.overrideWithValue(
          MalaRepositoryImpl(remote: remote),
        ),
        malaSyncManagerProvider.overrideWithValue(FakeMalaSync()),
        malaSoundPlayerProvider.overrideWithValue(SilentMalaSoundPlayer()),
        analyticsServiceProvider.overrideWithValue(RecordingAnalyticsService()),
        userProvider.overrideWith((ref) => _NoUserNotifier()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Center(
            child: GroupAccumulationsBar(
              mantra: _mantra,
              presetTitle: 'Praises to the 21 Taras',
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _pill => find.descendant(
  of: find.byType(GroupAccumulationsBar),
  matching: find.byType(InkWell),
);

Finder get _barAvatars => find.descendant(
  of: find.byType(GroupAccumulationsBar),
  matching: find.byType(ResponsiveCoverImage),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('asks for the joined accumulations of this mantra', (
    tester,
  ) async {
    final remote = _ListingRemote(const []);
    await _pumpBar(tester, remote);

    expect(remote.calls, hasLength(1));
    expect(remote.calls.single.id, _mantra.presetId);
    expect(remote.calls.single.joinedOnly, isTrue);
    expect(remote.calls.single.language, 'en');
  });

  testWidgets(
    'joined accumulations show in the bar and every one in the sheet',
    (tester) async {
      final remote = _ListingRemote([
        _row(
          id: 'ga-tara',
          groupId: 'g-lobf',
          title: 'Tara praises',
          groupName: 'Light Of Buddhadharma Foundation International',
          eventTitle: 'The praise to the twenty-one Tara',
          userTotal: 23,
          groupTotal: 423,
        ),
        _row(
          id: 'ga-plain',
          groupId: 'g-wb',
          title: 'Daily Tara recitation',
          groupName: 'WeBuddhist',
          userTotal: 4,
          groupTotal: 40,
        ),
        // An unpublished group: the API sends no group name.
        _row(id: 'ga-hidden', groupId: 'g-x', title: 'Quiet circle'),
      ]);
      await _pumpBar(tester, remote);

      // The pill previews two accumulations beside the user.
      expect(_pill, findsOneWidget);
      expect(_barAvatars, findsNWidgets(2));

      await tester.tap(_pill);
      await tester.pumpAndSettle();
      // Lets the personal counter's seed timeout run out.
      await tester.pump(const Duration(seconds: 4));

      expect(find.text('Personal practice'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('The praise to the twenty-one Tara'), findsOneWidget);
      expect(
        find.text('Light Of Buddhadharma Foundation International'),
        findsOneWidget,
      );
      expect(find.text('My total: 23  |  Group total: 423'), findsOneWidget);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.text('Daily Tara recitation'), findsOneWidget);
      expect(find.text('WeBuddhist'), findsOneWidget);
      expect(find.text('My total: 4  |  Group total: 40'), findsOneWidget);
      // The last row sits below the fold of the test screen.
      await tester.scrollUntilVisible(
        find.text('Quiet circle'),
        100,
        scrollable:
            find
                .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable),
                )
                .last,
      );
      expect(find.text('Quiet circle'), findsOneWidget);
      expect(find.text('My total: 0  |  Group total: 0'), findsOneWidget);
      // Header: personal practice (0 offline) plus 23 + 4 + 0.
      expect(find.text('27'), findsOneWidget);
    },
  );

  testWidgets('one joined accumulation still shows the pill', (tester) async {
    final remote = _ListingRemote([
      _row(id: 'ga-plain', groupId: 'g-wb', title: 'Daily Tara recitation'),
    ]);
    await _pumpBar(tester, remote);

    expect(_pill, findsOneWidget);
    expect(_barAvatars, findsOneWidget);
  });

  testWidgets('no joined accumulation hides the pill', (tester) async {
    await _pumpBar(tester, _ListingRemote(const []));

    expect(_pill, findsNothing);
  });

  testWidgets('a failed listing hides the pill', (tester) async {
    await _pumpBar(tester, _ListingRemote(const [], fails: true));

    expect(_pill, findsNothing);
  });
}
