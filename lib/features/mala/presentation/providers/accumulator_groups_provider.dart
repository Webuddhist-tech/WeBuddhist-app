import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Joined group accumulators for the current preset
/// (`GET /accumulators/{accumulator_id}/groups?joined_only=true`).
///
/// Metadata only (titles, image, membership, lifetime
/// [AccumulatorGroup.userTotalCount] and [AccumulatorGroup.groupTotalCount]).
/// Active session counts for bead tapping use [joinedGroupUserCountsProvider].
/// Stored list first, refreshed in the background; a failure with nothing
/// stored is an empty list, as before. Keyed by user id, and autoDispose, so
/// it is rebuilt for whoever opens the mala screen next.
final joinedAccumulatorGroupsProvider = StreamProvider.autoDispose
    .family<List<AccumulatorGroup>, String>((ref, presetId) {
      // Re-fetches when the content language changes so group and event names
      // are localized, as the catalogue is.
      final language = ref.watch(contentLanguageProvider);
      return ref
          .watch(malaRepositoryProvider)
          .watchJoinedAccumulatorGroups(presetId, language: language)
          .map(
            (result) =>
                result.fold((_) => const <AccumulatorGroup>[], (groups) => groups),
          );
    });

/// Per-group user session counts keyed by [AccumulatorGroup.groupAccumulatorId].
///
/// Uses [GroupAccumulatorRepositoryInterface.getGroupAccumulator] →
/// `GroupAccumulatorDetail.user.totalCount`. A group whose detail failed to
/// load is left out rather than reported as 0: merged, a 0 would replace the
/// real count and the next chants would be posted below it and dropped.
final joinedGroupUserCountsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, String>((ref, presetId) async {
      final groups = await ref.watch(
        joinedAccumulatorGroupsProvider(presetId).future,
      );
      if (groups.isEmpty) return const {};

      final repository = ref.watch(groupAccumulatorRepositoryProvider);
      final language = ref.read(contentLanguageProvider);
      final entries = await Future.wait(
        groups.map((group) async {
          final result = await repository.getGroupAccumulator(
            group.groupAccumulatorId,
            language: language,
          );
          return result.fold(
            (_) => null,
            (detail) => MapEntry(
              group.groupAccumulatorId,
              detail.user?.totalCount ?? 0,
            ),
          );
        }),
      );
      return Map.fromEntries(entries.nonNulls);
    });
