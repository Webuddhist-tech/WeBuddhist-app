import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_practice_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/plan_group_collections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

/// Collections served by hand: each fetch waits for [answer].
class _FakeRepository extends Fake implements GroupProfileRepositoryInterface {
  final store = FakeScreenCacheStore();
  final fetches = <String>[];
  var answer = Completer<void>();

  @override
  ScreenCacheSource<GroupRecitationCollection> recitationCollectionDetailSource({
    required String collectionId,
  }) => ScreenCacheSource(
    store: store,
    key: 'collection:$collectionId',
    fetchJson: () async {
      fetches.add(collectionId);
      await answer.future;
      return {
        'id': collectionId,
        'items': [
          {'id': 'i1', 'text_id': 'T-$collectionId'},
        ],
      };
    },
    fromJson:
        (json) =>
            GroupRecitationCollectionModel.fromJson(
              json as Map<String, dynamic>,
            ).toEntity(),
    failureMessage: 'Failed to load recitation collection',
  );
}

/// A widget that hands its [WidgetRef] to [onRef] on every build.
Future<void> _pumpWithRef(
  WidgetTester tester,
  _FakeRepository repository,
  void Function(WidgetRef ref) onRef,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [groupProfileRepositoryProvider.overrideWithValue(repository)],
      child: Consumer(
        builder: (context, ref, _) {
          onRef(ref);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

void main() {
  testWidgets('a day\'s collections load once while its tasks show', (
    tester,
  ) async {
    final repository = _FakeRepository();
    late WidgetRef ref;
    await _pumpWithRef(tester, repository, (r) => ref = r);

    prefetchPlanGroupCollections(ref, {'once-a', 'once-b'});
    prefetchPlanGroupCollections(ref, {'once-a', 'once-b'});
    expect(repository.fetches, ['once-a', 'once-b']);

    repository.answer.complete();
    await tester.pump();
    expect(repository.store.entries.keys, hasLength(2));
  });

  testWidgets('one already stored is not fetched again', (tester) async {
    final repository = _FakeRepository();
    repository.store.entries['collection:stored'] = jsonEncode({
      'id': 'stored',
      'items': const [],
    });
    late WidgetRef ref;
    await _pumpWithRef(tester, repository, (r) => ref = r);

    prefetchPlanGroupCollections(ref, {'stored'});
    expect(repository.fetches, isEmpty);
  });

  testWidgets('a tap while it loads shares the request and opens with it', (
    tester,
  ) async {
    final repository = _FakeRepository();
    late WidgetRef ref;
    await _pumpWithRef(tester, repository, (r) => ref = r);

    prefetchPlanGroupCollections(ref, {'shared'});
    final opened = loadPlanGroupCollections(ref, {'shared'});
    expect(repository.fetches, ['shared']);

    repository.answer.complete();
    expect(await opened, {
      'shared': ['T-shared'],
    });
    expect(repository.fetches, ['shared']);
  });
}
