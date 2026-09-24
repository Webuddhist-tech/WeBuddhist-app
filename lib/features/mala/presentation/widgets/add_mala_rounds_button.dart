import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/group_accumulation_counts_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_accumulation_selection_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/utils/mala_analytics.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/add_mala_rounds_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Circular `+` entry point for adding mala rounds counted outside the app.
///
/// Sits below the bead strand, opposite the group accumulations pill, and runs
/// the same flow the mala settings sheet used to host: pick a round count in
/// [showAddMalaRoundsDialog], then add it to whichever accumulation is
/// selected (personal or group).
///
/// Disabled — dimmed and unresponsive — while the count is seeding, after a
/// seed failure, or when no accumulation is selected, mirroring the bead tap.
class AddMalaRoundsButton extends ConsumerWidget {
  const AddMalaRoundsButton({super.key, required this.mantra});

  final Mantra mantra;

  static const size = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final counter = ref.watch(malaCounterProvider(mantra));
    final selection = ref.watch(
      malaAccumulationSelectionProvider(mantra.presetId),
    );
    final enabled =
        !counter.isSeeding &&
        !counter.seedFailed &&
        (selection.isPersonal || selection.groupAccumulatorId != null);
    final backgroundColor =
        isDark ? const Color(0xCC454545) : AppColors.grey100;

    return Opacity(
      opacity: enabled ? 1.0 : 0.38,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? () => _onAddMalaRound(context, ref) : null,
          child: Tooltip(
            message: context.l10n.mala_add_mala_round,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                AppAssets.plus,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAddMalaRound(BuildContext context, WidgetRef ref) async {
    final rounds = await showAddMalaRoundsDialog(context);
    if (rounds == null || rounds <= 0 || !context.mounted) return;

    final selection = ref.read(
      malaAccumulationSelectionProvider(mantra.presetId),
    );
    final counter = ref.read(malaCounterProvider(mantra));

    if (selection.isPersonal) {
      final added =
          ref.read(malaCounterProvider(mantra).notifier).addRounds(rounds);
      if (added) _trackAdded(ref, rounds);
      return;
    }

    final groupId = selection.groupAccumulatorId;
    if (groupId == null) return;
    final groups =
        ref
            .read(joinedAccumulatorGroupsProvider(mantra.presetId))
            .valueOrNull ??
        const [];
    final added = ref
        .read(groupAccumulationCountsProvider(mantra.presetId).notifier)
        .addRounds(
          groupAccumulatorId: groupId,
          groups: groups,
          rounds: rounds,
          beadsPerRound: counter.beadsPerRound,
        );
    if (added) _trackAdded(ref, rounds);
  }

  void _trackAdded(WidgetRef ref, int rounds) {
    ref
        .read(malaAnalyticsProvider)
        .offlineRoundsAdded(presetId: mantra.presetId, rounds: rounds);
  }
}
