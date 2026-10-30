import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_local_datasource.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/user_plans_repository.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocal extends PlansLocalDatasource {
  Map<int, bool>? status;

  @override
  String? get currentUserIdSync => 'user-1';

  @override
  Map<int, bool>? readCompletionStatus(String userId, String planId) => status;
}

class _FakeUserPlans extends Fake implements UserPlansRepositoryInterface {
  final updates = StreamController<Either<Failure, Map<int, bool>>>();

  @override
  Stream<Either<Failure, Map<int, bool>>> watchPlanDaysCompletionStatus(
    String planId,
  ) => updates.stream;
}

void main() {
  test('stored completion status is the state on the very first read',
      () async {
    final repo = _FakeUserPlans();
    addTearDown(repo.updates.close);
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        plansLocalDatasourceProvider.overrideWithValue(
          _FakeLocal()..status = {1: true},
        ),
        userPlansDomainRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    container.listen(userPlanDaysCompletionStatusProvider('p1'), (_, __) {});

    final first = container.read(userPlanDaysCompletionStatusProvider('p1'));
    expect(first.isLoading, isFalse);
    expect(first.requireValue.getRight().toNullable(), {1: true});

    repo.updates.add(const Right({1: true, 2: false}));
    await pumpEventQueue();
    expect(
      container
          .read(userPlanDaysCompletionStatusProvider('p1'))
          .requireValue
          .getRight()
          .toNullable(),
      {1: true, 2: false},
    );
  });
}
