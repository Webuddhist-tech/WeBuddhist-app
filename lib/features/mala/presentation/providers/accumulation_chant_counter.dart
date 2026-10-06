import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/group_accumulation_counts_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_accumulation_selection_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `ref.read` of a widget or a container.
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Counts one chant made in the reader into whichever target the accumulation
/// sheet has selected for [mantra] right now: personal practice or one joined
/// accumulation. Chants already counted stay where they were made.
///
/// Returns false when the target ignored it (personal counter still seeding,
/// group count not yet loaded, or no signed-in user), so the caller does not
/// tally it.
bool countChantIntoSelection(ProviderReader read, Mantra mantra) {
  final presetId = mantra.presetId;
  final selection = read(malaAccumulationSelectionProvider(presetId));
  final settings = read(malaSettingsProvider);
  final groupAccumulatorId = selection.groupAccumulatorId;

  final int? total;
  if (groupAccumulatorId == null) {
    total = read(malaCounterProvider(mantra).notifier).incrementBead(
      soundEnabled: settings.soundEnabled,
      vibrationEnabled: settings.vibrationEnabled,
    );
  } else {
    final counts = read(groupAccumulationCountsProvider(presetId).notifier);
    if (!counts.hasServerCount(groupAccumulatorId)) return false;
    total = counts.increment(
      groupAccumulatorId: groupAccumulatorId,
      groups: const [],
      soundEnabled: settings.soundEnabled,
      vibrationEnabled: settings.vibrationEnabled,
      beadsPerRound: mantra.beadsPerRound,
    );
  }
  return total != null;
}

/// True when chants for [mantra] go to [groupAccumulatorId] right now, rather
/// than to personal practice or another accumulation.
bool isChantTarget(
  ProviderReader read,
  Mantra mantra,
  String groupAccumulatorId,
) {
  final selection = read(malaAccumulationSelectionProvider(mantra.presetId));
  return selection.groupAccumulatorId == groupAccumulatorId;
}

/// Adds [count] chants made outside the app to the selected target. Returns
/// false when the target ignored them.
bool addOfflineChantsToSelection(
  ProviderReader read,
  Mantra mantra,
  int count,
) {
  final presetId = mantra.presetId;
  final groupAccumulatorId =
      read(malaAccumulationSelectionProvider(presetId)).groupAccumulatorId;

  if (groupAccumulatorId == null) {
    return read(malaCounterProvider(mantra).notifier).addCount(count);
  }
  final counts = read(groupAccumulationCountsProvider(presetId).notifier);
  if (!counts.hasServerCount(groupAccumulatorId)) return false;
  return counts.addCount(
    groupAccumulatorId: groupAccumulatorId,
    groups: const [],
    count: count,
  );
}
