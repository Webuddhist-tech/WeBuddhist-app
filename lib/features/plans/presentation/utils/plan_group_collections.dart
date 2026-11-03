import 'dart:async';

import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Chant text ids of each collection in [collectionIds]. A stored copy is
/// used at once and refreshed behind; one that cannot load is left out.
Future<PlanGroupCollections> loadPlanGroupCollections(
  WidgetRef ref,
  Set<String> collectionIds,
) async {
  if (collectionIds.isEmpty) return const {};
  final repository = ref.read(groupProfileRepositoryProvider);

  Future<MapEntry<String, List<String>>?> load(String id) async {
    final source = repository.recitationCollectionDetailSource(
      collectionId: id,
    );
    GroupRecitationCollection? collection = source.read();
    if (collection != null) {
      unawaited(source.refresh());
    } else {
      collection = (await source.refresh()).fold((_) => null, (c) => c);
    }
    if (collection == null) return null;
    final textIds = [
      for (final item in collection.items)
        if (item.textId.trim().isNotEmpty) item.textId.trim(),
    ];
    return textIds.isEmpty ? null : MapEntry(id, textIds);
  }

  final entries = await Future.wait(collectionIds.map(load));
  return Map.fromEntries(entries.whereType<MapEntry<String, List<String>>>());
}

/// Collections [prefetchPlanGroupCollections] has asked for this session.
final Set<String> _prefetched = {};

/// Starts loading each collection in [collectionIds] that has no stored
/// copy yet, once a session, while its day's tasks are on screen: the tap
/// that opens one then finds it in hand rather than waiting for it. A tap
/// while it still loads shares the same request (the screen cache store
/// runs one fetch per key at a time).
void prefetchPlanGroupCollections(WidgetRef ref, Set<String> collectionIds) {
  if (collectionIds.isEmpty) return;
  final repository = ref.read(groupProfileRepositoryProvider);
  for (final id in collectionIds) {
    if (!_prefetched.add(id)) continue;
    final source = repository.recitationCollectionDetailSource(
      collectionId: id,
    );
    if (source.read() == null) unawaited(source.refresh());
  }
}

bool _opening = false;

/// [loadPlanGroupCollections] for a tap that opens the reader: null while an
/// earlier tap is still loading, so a second tap cannot open a second reader.
Future<PlanGroupCollections?> loadPlanGroupCollectionsToOpen(
  WidgetRef ref,
  Set<String> collectionIds,
) async {
  if (_opening) return null;
  _opening = true;
  try {
    return await loadPlanGroupCollections(ref, collectionIds);
  } finally {
    _opening = false;
  }
}
