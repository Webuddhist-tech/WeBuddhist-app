import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/timer/data/datasource/timers_local_datasource.dart';
import 'package:flutter_pecha/features/timer/data/models/preset_timer_model.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/domain/repositories/timers_repository.dart';
import 'package:flutter_pecha/features/timer/presentation/providers/timers_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocal extends TimersLocalDatasource {
  List<PresetTimerModel>? timers;

  @override
  String? get currentUserIdSync => 'user-1';

  @override
  List<PresetTimerModel>? readPresetTimers(
    String userId, {
    required int skip,
    required int limit,
  }) => timers;
}

class _FakeTimers extends Fake implements TimersRepositoryInterface {
  final updates = StreamController<Either<Failure, List<PresetTimer>>>();

  @override
  Stream<Either<Failure, List<PresetTimer>>> watchPresetTimers({
    int skip = 0,
    int limit = kTimersPageLimit,
  }) => updates.stream;
}

void main() {
  test('a stored (empty) list is the state on the very first read', () async {
    final repo = _FakeTimers();
    addTearDown(repo.updates.close);
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        timersLocalDatasourceProvider.overrideWithValue(
          _FakeLocal()..timers = const [],
        ),
        timersDomainRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    container.listen(presetTimersFutureProvider, (_, __) {});

    final first = container.read(presetTimersFutureProvider);
    expect(first.isLoading, isFalse);
    expect(first.requireValue.isRight(), isTrue);
  });

  test('nothing stored loads first', () async {
    final repo = _FakeTimers();
    addTearDown(repo.updates.close);
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        timersLocalDatasourceProvider.overrideWithValue(_FakeLocal()),
        timersDomainRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    container.listen(presetTimersFutureProvider, (_, __) {});
    expect(container.read(presetTimersFutureProvider).isLoading, isTrue);
  });
}
