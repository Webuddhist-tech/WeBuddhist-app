import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_profile_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_post_permission.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_post_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_post_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoUser extends StateNotifier<UserState> implements UserNotifier {
  _NoUser() : super(const UserState.initial());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopAnalytics implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _FakePostRepository extends Fake implements GroupPostRepositoryInterface {}

class _FakeRemote extends GroupProfileRemoteDatasource {
  _FakeRemote() : super(dio: Dio());

  List<String> members = const [];
  int memberCalls = 0;
  bool isMember = true;

  @override
  Future<Map<String, dynamic>> fetchGroupProfileJson(
    String groupId, {
    required String language,
  }) async => throw const NetworkException('offline');

  @override
  Future<Map<String, dynamic>> fetchGroupEventsJson(
    String groupId, {
    required String language,
  }) async => {'events': [], 'total': 0, 'skip': 0, 'limit': 20};

  @override
  Future<Map<String, dynamic>> fetchPracticesJson({
    String? groupId,
    required bool includeUnfollowed,
    required String language,
    required int skip,
    required int limit,
  }) async => {'practices': [], 'total': 0, 'skip': 0, 'limit': 20};

  @override
  Future<Map<String, dynamic>> fetchGroupMembersJson(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    memberCalls++;
    return {
      'list': [
        for (final name in members)
          {'user_id': name, 'username': name, 'fullname': name},
      ],
      'skip': skip,
      'limit': limit,
      'total_members': members.length,
    };
  }

  @override
  Future<bool> checkFollowStatus(String groupId, GroupType groupType) async =>
      isMember;

  @override
  Future<void> unfollowGroup(String groupId, GroupType groupType) async {
    isMember = false;
  }

  @override
  Future<void> followGroup(String groupId, GroupType groupType) async {
    isMember = true;
  }
}

const _profile = GroupProfile(
  id: 'g1',
  title: 'Semkyed',
  groupType: GroupType.community,
  isPublic: true,
  isFollowing: true,
  joinerCount: 2,
);

const _followKey = GroupFollowKey(
  groupId: 'g1',
  groupType: GroupType.community,
);

void main() {
  late _FakeRemote remote;
  late ProviderContainer container;

  setUp(() {
    remote = _FakeRemote();
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        userProvider.overrideWith((ref) => _NoUser()),
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        analyticsServiceProvider.overrideWithValue(_NoopAnalytics()),
        groupProfileRepositoryProvider.overrideWithValue(
          GroupProfileRepositoryImpl(
            remote: remote,
            store: FakeScreenCacheStore(),
          ),
        ),
        groupMyPermissionProvider.overrideWith(
          () => GroupMyPermissionNotifier(
            (ref, groupId, bind) =>
                GroupPostPermission(groupId: groupId, role: null),
          ),
        ),
        groupPostsProvider.overrideWith(
          (ref, groupId) => GroupPostsNotifier(
            repository: _FakePostRepository(),
            groupId: groupId,
            stored: ConnectPostsPage(posts: const [], skip: 0, limit: 20, total: 0),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: GroupProfileBody(profile: _profile, isDark: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The body schedules work from deactivate; unmount it inside the test so
  // that timer fires before the framework checks for leaks.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('Members as the only tab counts as active without a swipe', (
    tester,
  ) async {
    remote.members = ['Tenzin Delek', 'Tashi Dolma'];
    await pump(tester);

    expect(container.read(groupMembersTabActiveProvider('g1')), isTrue);
    expect(find.text('Tenzin Delek'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('leaving refetches the members list in place', (tester) async {
    remote.members = ['Tenzin Delek', 'Tashi Dolma'];
    await pump(tester);
    final callsBefore = remote.memberCalls;

    remote.members = ['Tashi Dolma'];
    await container.read(groupFollowProvider(_followKey).notifier).unfollow();
    await tester.pumpAndSettle();

    expect(remote.memberCalls, greaterThan(callsBefore));
    expect(find.text('Tenzin Delek'), findsNothing);
    expect(find.text('Tashi Dolma'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('joining refetches the members list in place', (tester) async {
    remote.isMember = false;
    remote.members = ['Tashi Dolma'];
    await pump(tester);
    final callsBefore = remote.memberCalls;

    remote.members = ['Tenzin Delek', 'Tashi Dolma'];
    await container.read(groupFollowProvider(_followKey).notifier).follow();
    await tester.pumpAndSettle();

    expect(remote.memberCalls, greaterThan(callsBefore));
    expect(find.text('Tenzin Delek'), findsOneWidget);
    await unmount(tester);
  });
}
