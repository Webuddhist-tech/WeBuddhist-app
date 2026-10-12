import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_accumulator_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Holds the join request open until the test completes [join].
class _SlowJoinRepository extends Fake
    implements GroupAccumulatorRepositoryInterface {
  final join = Completer<Either<Failure, void>>();

  @override
  Future<Either<Failure, void>> joinGroupAccumulator(String accumulatorId) =>
      join.future;
}

class _FakeProfileRepository extends Fake
    implements GroupProfileRepositoryInterface {
  @override
  Future<Either<Failure, GroupPracticesPage>> getGroupPractices(
    String groupId, {
    required String language,
    required int skip,
    required int limit,
  }) async => const Left(NetworkFailure('test'));
}

const _detail = GroupAccumulatorDetail(
  id: 'acc-1',
  presetAccumulatorId: 'preset-1',
  groupId: 'group-1',
  title: 'Green Tara',
  isJoined: false,
);

void main() {
  // Crashlytics 884599c9 (variant cb6bd49c): the join helper read providers
  // through the screen's `ref` after the request returned. If the user had
  // left the screen by then, `ref` threw and the join state was never
  // applied.
  testWidgets('a join that finishes after the screen closes still completes '
      'and marks the accumulator joined', (tester) async {
    final repository = _SlowJoinRepository();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        groupAccumulatorRepositoryProvider.overrideWithValue(repository),
        groupProfileRepositoryProvider.overrideWithValue(
          _FakeProfileRepository(),
        ),
        groupAccumulatorDetailProvider.overrideWith(
          (ref, id) async => const Right(_detail),
        ),
        groupProfileProvider.overrideWith(
          (ref, id) async => const Left(NetworkFailure('test')),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Something else in the app watching the join cache, so its state can be
    // read back after the screen is gone.
    final joinCache = container.listen(
      groupAccumulatorJoinCacheProvider('group-1'),
      (_, __) {},
    );
    addTearDown(joinCache.close);

    late Future<bool> joinResult;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder:
                (context) => TextButton(
                  onPressed: () {
                    joinResult = joinGroupAccumulator(
                      container: ProviderScope.containerOf(
                        context,
                        listen: false,
                      ),
                      accumulatorId: 'acc-1',
                      groupId: 'group-1',
                      awaitRefresh: false,
                    );
                  },
                  child: const Text('Join'),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pump();

    // The user leaves before the server answers.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SizedBox.shrink(),
      ),
    );

    repository.join.complete(const Right(null));
    await tester.runAsync(() => joinResult);
    await tester.pump();

    expect(await tester.runAsync(() => joinResult), isTrue);
    expect(joinCache.read(), contains('acc-1'));
    expect(tester.takeException(), isNull);
  });
}
