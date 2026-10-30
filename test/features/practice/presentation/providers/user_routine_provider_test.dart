import 'dart:convert';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/data/repositories/routine_repository.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

class _FakeRemote implements RoutineRemoteDatasource {
  RoutineResponse? response;
  Exception? error;
  int calls = 0;

  @override
  Future<RoutineResponse?> getUserRoutine({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    calls++;
    if (error != null) throw error!;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  final key = ScreenCacheKey.user('user_routine', userId: 'user-1', language: 'en');

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
  });

  ProviderContainer build() {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        routineApiRepositoryProvider.overrideWithValue(
          RoutineApiRepositoryImpl(datasource: remote, store: store),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('the stored routine is the state on the very first read', () async {
    store.entries[key] = jsonEncode({'blocks': [], 'apiRoutineId': 'old'});
    remote.response = const RoutineResponse(
      id: 'new',
      timeBlocks: [],
      skip: 0,
      limit: 20,
      total: 0,
    );
    final container = build();
    container.listen(userRoutineProvider, (_, __) {});

    final first = container.read(userRoutineProvider);
    expect(first.isLoading, isFalse);
    expect(first.requireValue?.apiRoutineId, 'old');

    await pumpEventQueue();
    expect(container.read(userRoutineProvider).requireValue?.apiRoutineId, 'new');
    expect(remote.calls, 1);
  });

  test('a failed refresh keeps the stored routine', () async {
    store.entries[key] = jsonEncode({'blocks': [], 'apiRoutineId': 'old'});
    remote.error = const NetworkException('offline');
    final container = build();
    container.listen(userRoutineProvider, (_, __) {});
    await pumpEventQueue();
    final state = container.read(userRoutineProvider);
    expect(state.hasError, isFalse);
    expect(state.requireValue?.apiRoutineId, 'old');
  });
}
