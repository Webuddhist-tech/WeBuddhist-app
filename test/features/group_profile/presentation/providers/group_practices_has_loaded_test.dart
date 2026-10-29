import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeRepository extends Fake implements GroupProfileRepositoryInterface {
  Completer<Either<Failure, GroupPracticesPage>> page = Completer();

  @override
  Future<Either<Failure, GroupPracticesPage>> getGroupPractices(
    String groupId, {
    required String language,
    required int skip,
    required int limit,
  }) => page.future;
}

final _refProvider = Provider<Ref>((ref) => ref);

const _emptyPage = GroupPracticesPage(
  practices: [],
  total: 0,
  skip: 0,
  limit: 20,
);

void main() {
  late ProviderContainer container;
  late _FakeRepository repository;

  setUp(() {
    container = ProviderContainer();
    repository = _FakeRepository();
  });

  tearDown(() => container.dispose());

  GroupPracticesNotifier notifier({GroupPracticesPage? stored}) =>
      GroupPracticesNotifier(
        repository: repository,
        ref: container.read(_refProvider),
        groupId: 'g1',
        stored: stored,
      );

  test('a stored empty page counts as loaded while it refreshes', () {
    final n = notifier(stored: _emptyPage);
    unawaited(n.loadInitial());

    expect(n.state.hasLoaded, isTrue);
    expect(n.state.practices, isEmpty);
    n.dispose();
  });

  test('nothing stored is not loaded until the fetch settles', () async {
    final n = notifier();
    final load = n.loadInitial();
    expect(n.state.hasLoaded, isFalse);

    repository.page.complete(const Left(NetworkFailure('offline')));
    await load;

    expect(n.state.hasLoaded, isTrue);
    expect(n.state.error, 'offline');
    n.dispose();
  });
}
