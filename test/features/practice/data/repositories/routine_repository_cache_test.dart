import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/repositories/routine_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FakeRemote extends RoutineRemoteDatasource {
  _FakeRemote() : super(dio: Dio());

  RoutineResponse? response;
  int calls = 0;

  @override
  Future<RoutineResponse?> getUserRoutine({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    calls++;
    return response;
  }
}

String? _routineId(Either<Failure, RoutineData> e) =>
    e.fold((_) => 'failure', (data) => data.apiRoutineId);

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  late RoutineApiRepositoryImpl repo;
  final key = ScreenCacheKey.user(
    'user_routine',
    userId: 'user-1',
    language: 'en',
  );

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
    repo = RoutineApiRepositoryImpl(datasource: remote, store: store);
  });

  test('stored routine shows first, then the server routine', () async {
    store.entries[key] = jsonEncode({'blocks': [], 'apiRoutineId': 'old'});
    remote.response = const RoutineResponse(
      id: 'new',
      timeBlocks: [],
      skip: 0,
      limit: 20,
      total: 0,
    );

    final events = <Either<Failure, RoutineData>>[];
    final sub = repo.watchUserRoutine(language: 'en').listen(events.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    expect(events.map(_routineId), ['old', 'new']);
    expect(remote.calls, 1);
  });

  test('signed-out users get an authentication failure, no request', () async {
    store.userId = null;
    final result = await repo.watchUserRoutine(language: 'en').first;
    expect(result.getLeft().toNullable(), isA<AuthenticationFailure>());
    expect(remote.calls, 0);
  });
}
