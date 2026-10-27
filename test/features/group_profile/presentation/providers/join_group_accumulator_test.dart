import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/connect/domain/repositories/connect_repository.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_accumulator_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_join_requests_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_reports_page.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Holds the join request open until the test completes [join].
class _SlowJoinRepository extends Fake
    implements GroupAccumulatorRepositoryInterface {
  @override
  Future<GroupAccumulatorMembersPage?> readStoredGroupAccumulatorMembers(
    String accumulatorId, {
    required GroupAccumulatorMemberSort sortBy,
  }) async => null;
  final join = Completer<Either<Failure, void>>();

  @override
  Future<Either<Failure, void>> joinGroupAccumulator(String accumulatorId) =>
      join.future;
}

class _FakeProfileRepository extends Fake
    implements GroupProfileRepositoryInterface {
  @override
  Future<GroupPracticesPage?> readStoredGroupPractices(
    String groupId, {
    required String language,
  }) async => null;

  @override
  Future<GroupMembersPage?> readStoredGroupMembers(String groupId) async =>
      null;

  @override
  Future<GroupEventParticipantsPage?> readStoredGroupEventParticipants(
    String eventId,
  ) async => null;

  @override
  Future<GroupJoinRequestsPage?> readStoredGroupJoinRequests(
    String groupId,
  ) async => null;

  @override
  Future<GroupReportsPage?> readStoredGroupReports(String groupId) async =>
      null;

  @override
  Future<Either<Failure, bool>> checkFollowStatus(
    String groupId,
    GroupType groupType,
  ) async => const Right(true);

  @override
  Future<Either<Failure, GroupPracticesPage>> getGroupPractices(
    String groupId, {
    required String language,
    required int skip,
    required int limit,
  }) async => const Left(NetworkFailure('test'));
}

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConnectRepository extends Fake implements ConnectRepository {}

const _group = GroupProfile(id: 'group-1', title: 'Lodhen Sangha');

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
          (ref, id) => Stream.value(const Right(_detail)),
        ),
        groupProfileProvider.overrideWith(
          (ref, id) => Stream.value(const Left(NetworkFailure('test'))),
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

  // Greptile review on #944: also cover the group-join step and the default
  // awaited refresh, with the profile and detail still loading when the
  // screen closes.
  testWidgets('a join that finishes after the screen closes still joins the '
      'group app-wide and waits for the refresh', (tester) async {
    final repository = _SlowJoinRepository();
    final profile = Completer<Either<Failure, GroupProfile>>();
    final detail = Completer<Either<Failure, GroupAccumulatorDetail>>();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        connectRepositoryProvider.overrideWithValue(_FakeConnectRepository()),
        groupAccumulatorRepositoryProvider.overrideWithValue(repository),
        groupProfileRepositoryProvider.overrideWithValue(
          _FakeProfileRepository(),
        ),
        groupAccumulatorDetailProvider.overrideWith(
          (ref, id) => detail.future.asStream(),
        ),
        groupProfileProvider.overrideWith((ref, id) => profile.future.asStream()),
      ],
    );
    addTearDown(container.dispose);

    late Future<bool> joinResult;
    var finished = false;
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
                    )..whenComplete(() => finished = true);
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
    await tester.pump();
    profile.complete(const Right(_group));
    await tester.pump();

    // The group is now joined app-wide, in state that outlives any screen.
    expect(
      container.read(pendingJoinedGroupsProvider).map((g) => g.id),
      contains('group-1'),
    );
    // The default awaitRefresh keeps the join pending until the detail
    // reloads.
    expect(finished, isFalse);

    detail.complete(const Right(_detail));
    await tester.pump();

    expect(finished, isTrue);
    expect(await joinResult, isTrue);
    expect(tester.takeException(), isNull);
  });
}
