import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/more/data/datasource/user_stats_local_datasource.dart';
import 'package:flutter_pecha/features/more/data/datasource/user_stats_remote_datasource.dart';
import 'package:flutter_pecha/features/more/data/repositories/user_stats_repository_impl.dart';
import 'package:flutter_pecha/features/more/domain/entities/mantra_count.dart';
import 'package:flutter_pecha/features/more/presentation/providers/mantra_counts_provider.dart';
import 'package:flutter_pecha/features/more/presentation/providers/use_case_providers.dart';
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

class _FakeRemote extends UserStatsRemoteDatasource {
  _FakeRemote() : super(dio: Dio());

  List<int> counts = const [];

  @override
  Future<Map<String, dynamic>> fetchMantraCountsJson({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async => _page(counts);
}

Map<String, dynamic> _page(List<int> counts) => {
  'counts': [
    for (final c in counts)
      {'mantra_id': 'm$c', 'mantra_title': 'Mantra $c', 'total_count': c},
  ],
};

List<int> _totals(AsyncValue<Either<Failure, MantraCountPage>> v) =>
    v.valueOrNull?.fold(
      (_) => const <int>[],
      (page) => page.counts.map((c) => c.totalCount).toList(),
    ) ??
    const [];

void main() {
  test('stored counts are the state on the very first read', () async {
    final store = FakeScreenCacheStore();
    final remote = _FakeRemote()..counts = [3, 5];
    store.entries[ScreenCacheKey.user(
      'mantra_counts',
      userId: 'user-1',
      language: 'en',
    )] = jsonEncode(_page([3]));
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        userStatsRepositoryProvider.overrideWithValue(
          UserStatsRepositoryImpl(
            remote: remote,
            local: UserStatsLocalDatasource(),
            store: store,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(mantraCountsProvider, (_, __) {});

    final first = container.read(mantraCountsProvider);
    expect(first.isLoading, isFalse);
    expect(_totals(first), [3]);

    await pumpEventQueue();
    expect(_totals(container.read(mantraCountsProvider)), [3, 5]);
  });
}
