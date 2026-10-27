import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_profile_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemote extends GroupProfileRemoteDatasource {
  _FakeRemote() : super(dio: Dio());

  int members = 1;
  Exception? error;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetchGroupProfileJson(
    String groupId, {
    required String language,
  }) async {
    calls++;
    if (error != null) throw error!;
    return _profile(groupId, members: members);
  }
}

Map<String, dynamic> _profile(String id, {required int members}) => {
  'id': id,
  'slug': id,
  'group_type': 'COMMUNITY',
  'member_count': members,
};

int? _members(AsyncValue<Either<Failure, GroupProfile>> value) =>
    value.valueOrNull?.fold((_) => null, (p) => p.memberCount);

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  final key = ScreenCacheKey.user(
    'group_profile',
    userId: 'user-1',
    language: 'en',
    params: ['g1'],
  );

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
  });

  List<Override> overrides() => [
    authProvider.overrideWith((ref) => _SignedInAuth()),
    contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
    groupProfileRepositoryProvider.overrideWithValue(
      GroupProfileRepositoryImpl(remote: remote, store: store),
    ),
  ];

  test('stored profile shows first, then the refreshed one', () async {
    store.entries[key] = jsonEncode(_profile('g1', members: 1));
    remote.members = 3;
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    final seen = <int?>[];
    container.listen(groupProfileProvider('g1'), (_, next) {
      if (next.hasValue) seen.add(_members(next));
    }, fireImmediately: true);
    await pumpEventQueue();

    expect(seen, [1, 3]);
    expect(remote.calls, 1);
  });

  test('invalidate after a failure fetches again', () async {
    remote.error = const NetworkException('offline');
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    container.listen(groupProfileProvider('g1'), (_, __) {});
    await pumpEventQueue();
    expect(
      container.read(groupProfileProvider('g1')).valueOrNull?.isLeft(),
      isTrue,
    );

    remote.error = null;
    container.invalidate(groupProfileProvider('g1'));
    await pumpEventQueue();
    expect(_members(container.read(groupProfileProvider('g1'))), 1);
    expect(remote.calls, 2);
  });

  testWidgets('refreshGroupProfilePage bumps the membership epoch on change', (
    tester,
  ) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              captured = ref;
              ref.watch(groupProfileProvider('g1'));
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(_members(captured.read(groupProfileProvider('g1'))), 1);

    remote.members = 2;
    await refreshGroupProfilePage(
      ref: captured,
      groupId: 'g1',
      groupType: GroupType.community,
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(captured.read(groupMembershipEpochProvider('g1')), 1);
    expect(_members(captured.read(groupProfileProvider('g1'))), 2);

    await refreshGroupProfilePage(
      ref: captured,
      groupId: 'g1',
      groupType: GroupType.community,
    );
    expect(captured.read(groupMembershipEpochProvider('g1')), 1);
  });
}
