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
final joinedAccumulatorGroupsProvider = FutureProvider.autoDispose
    .family<List<AccumulatorGroup>, String>((ref, presetId) async {
      // Re-fetches when the app language changes so group and event names are
      // localized, as the catalogue is.
      final language = ref.watch(localeProvider).languageCode;
      final result = await ref
          .watch(malaRepositoryProvider)
          .getJoinedAccumulatorGroups(presetId, language: language);
      return result.fold((_) => const [], (groups) => groups);
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
      final entries = await Future.wait(
        groups.map((group) async {
          final result = await repository.getGroupAccumulator(
            group.groupAccumulatorId,
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
