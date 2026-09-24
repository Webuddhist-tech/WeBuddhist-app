import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/core.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/group_accumulation_counts_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_accumulation_selection_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_settings_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/utils/mala_analytics.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/add_mala_rounds_button.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/group_accumulations_bar.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mala_beads.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mala_skeleton.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mantra_switcher.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mala_settings_sheet.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MalaScreen extends ConsumerStatefulWidget {
  const MalaScreen({
    super.key,
    this.initialPresetId,
    this.initialGroupAccumulatorId,
    this.source,
  });

  /// Optionally open directly on a specific mantra.
  final String? initialPresetId;

  /// When set (e.g. from a group accumulator screen), pre-select that group
  /// accumulation instead of the last-used personal/group choice.
  final String? initialGroupAccumulatorId;

  /// Where the screen was opened from, carried on `mala_screen_opened`.
  final String? source;

  @override
  ConsumerState<MalaScreen> createState() => _MalaScreenState();
}

class _MalaScreenState extends ConsumerState<MalaScreen> {
  int _index = 0;
  bool _initialisedIndex = false;
  bool _appliedInitialGroupSelection = false;
  bool _trackedOpened = false;
  late final MalaSessionTracker _session;

  @override
  void initState() {
    super.initState();
    _session = MalaSessionTracker(ref.read(malaAnalyticsProvider))..start();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  /// Once per screen, after the persisted selection has loaded so `mode` is
  /// the one the user will count into.
  void _trackOpened(Mantra mantra) {
    if (_trackedOpened) return;
    _trackedOpened = true;
    final presetId = mantra.presetId;
    final selectionProvider = malaAccumulationSelectionProvider(presetId);
    unawaited(
      ref.read(selectionProvider.notifier).loaded.then((_) {
        if (!mounted) return;
        final selection = ref.read(selectionProvider);
        final groups =
            ref.read(joinedAccumulatorGroupsProvider(presetId)).valueOrNull;
        ref
            .read(malaAnalyticsProvider)
            .screenOpened(
              presetId: presetId,
              mantraName: mantra.localizedName('en'),
              mode: selection.analyticsMode,
              groupId: malaGroupIdFor(
                groups ?? const [],
                selection.groupAccumulatorId,
              ),
              source: widget.source,
            );
      }),
    );
  }

  void _switch(List<Mantra> mantras, int next) {
    if (next < 0 || next >= mantras.length || next == _index) return;
    ref
        .read(malaAnalyticsProvider)
        .mantraSwitched(
          fromPresetId: mantras[_index].presetId,
          toPresetId: mantras[next].presetId,
          via: MalaSwitchVia.carousel,
        );
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(malaCatalogueProvider);

    return Scaffold(
      // Clip the page content to its bounds. The bead strand is drawn with an
      // intentional overflow past the arc edges (relied on being clipped); the
      // device-edge clip normally hides it, but during the iOS pop transition
      // the page is composited into a sliding layer where that overflow would
      // otherwise flash onto the incoming screen. This contains it without
      // changing the bead appearance.
      body: ClipRect(
        child: SafeArea(
          child: catalogue.when(
            loading: () => const _MalaAppBarScaffold(child: MalaSkeleton()),
            error:
                (e, _) => _MalaAppBarScaffold(
                  child: _ErrorView(
                    onRetry: () => ref.invalidate(malaCatalogueProvider),
                  ),
                ),
            data:
                (either) => either.fold(
                  (failure) => _MalaAppBarScaffold(
                    child: _ErrorView(
                      message: failure.message,
                      onRetry: () => ref.invalidate(malaCatalogueProvider),
                    ),
                  ),
                  (mantras) => _buildLoaded(context, mantras),
                ),
          ),
        ),
      ),
    );
  }

  void _openMalaSettings(BuildContext context, Mantra mantra) {
    MalaSettingsSheet.show(context, mantra: mantra);
  }

  Widget _buildLoaded(BuildContext context, List<Mantra> mantras) {
    if (mantras.isEmpty) {
      return _MalaAppBarScaffold(
        child: Center(child: Text(context.l10n.mala_no_mantras)),
      );
    }

    if (!_initialisedIndex) {
      _initialisedIndex = true;
      if (widget.initialPresetId != null) {
        final i = mantras.indexWhere(
          (m) => m.presetId == widget.initialPresetId,
        );
        if (i >= 0) _index = i;
      }
    }
    _index = _index.clamp(0, mantras.length - 1);
    final mantra = mantras[_index];

    ref.watch(
      prefetchBookmarkExistsProvider(
        BookmarkTarget(type: BookmarkType.accumulator, sourceId: mantra.presetId),
      ),
    );

    final language = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final counter = ref.watch(malaCounterProvider(mantra));
    final notifier = ref.read(malaCounterProvider(mantra).notifier);
    final settings = ref.watch(malaSettingsProvider);
    final selection = ref.watch(
      malaAccumulationSelectionProvider(mantra.presetId),
    );
    final groupsAsync = ref.watch(
      joinedAccumulatorGroupsProvider(mantra.presetId),
    );
    final groups = groupsAsync.valueOrNull ?? const <AccumulatorGroup>[];
    ref.watch(groupAccumulationCountsProvider(mantra.presetId));
    ref.watch(joinedGroupUserCountsProvider(mantra.presetId));
    final groupCountsNotifier = ref.read(
      groupAccumulationCountsProvider(mantra.presetId).notifier,
    );

    _applyInitialGroupSelectionIfNeeded(mantra.presetId);
    _trackOpened(mantra);

    ref.listen(joinedAccumulatorGroupsProvider(mantra.presetId), (_, next) {
      next.whenData((loadedGroups) {
        ref
            .read(malaAccumulationSelectionProvider(mantra.presetId).notifier)
            .validateAgainst(loadedGroups);
        ref.invalidate(joinedGroupUserCountsProvider(mantra.presetId));
      });
    });

    ref.listen(joinedGroupUserCountsProvider(mantra.presetId), (_, next) {
      next.whenData(groupCountsNotifier.mergeFromServerCounts);
    });

    final groupId = selection.groupAccumulatorId;
    final showCountSkeleton = counter.isSeeding && !counter.seedFailed;
    // While seeding, keep beads at 0 so a stale Hive total does not light the arc.
    final displayTotal =
        showCountSkeleton
            ? 0
            : groupId == null
            ? counter.total
            : groupCountsNotifier.countFor(groupId);
    final beadsPerRound = counter.beadsPerRound;
    final displayBeadInRound = displayTotal % beadsPerRound;
    final displayRounds = displayTotal ~/ beadsPerRound;
    final countingEnabled =
        !counter.isSeeding &&
        (selection.isPersonal || selection.groupAccumulatorId != null);

    void onBead(MalaInput input) {
      if (counter.isSeeding) return;
      final int? total;
      if (selection.isPersonal) {
        total = notifier.incrementBead(
          soundEnabled: settings.soundEnabled,
          vibrationEnabled: settings.vibrationEnabled,
        );
      } else {
        final selectedGroupId = selection.groupAccumulatorId;
        if (selectedGroupId == null || groups.isEmpty) return;
        total = groupCountsNotifier.increment(
          groupAccumulatorId: selectedGroupId,
          groups: groups,
          soundEnabled: settings.soundEnabled,
          vibrationEnabled: settings.vibrationEnabled,
          beadsPerRound: beadsPerRound,
        );
      }
      // Null means the tap was ignored, so no bead was counted.
      if (total == null) return;
      _session.onBead(
        presetId: mantra.presetId,
        mantraName: mantra.localizedName('en'),
        mode: selection.analyticsMode,
        groupId: malaGroupIdFor(groups, selection.groupAccumulatorId),
        total: total,
        roundComplete: total % beadsPerRound == 0,
        input: input,
      );
    }

    return Column(
      children: [
        _MalaAppBar(
          title: mantra.displayTitle(language),
          onMorePressed: () => _openMalaSettings(context, mantra),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 36,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xCC454545)
                              : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: MantraSwitcher(
                        mantras: mantras,
                        language: language,
                        tibetanFontFamily: AppConfig.tibetanContentFont,
                        index: _index,
                        onIndexChanged: (next) => _switch(mantras, next),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (showCountSkeleton)
                  const MalaCountSkeleton()
                else
                  _CounterBlock(
                    beadInRound: displayBeadInRound,
                    beadsPerRound: beadsPerRound,
                    rounds: displayRounds,
                  ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 42,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          height: constraints.maxHeight * 0.85,
                          width: double.infinity,
                          child:
                              counter.seedFailed
                                  ? _ErrorView(
                                    message:
                                        context.l10n.mala_count_load_error,
                                    onRetry: notifier.seed,
                                  )
                                  : MalaBeads(
                                    key: ValueKey(
                                      '${mantra.presetId}_${selection.groupAccumulatorId ?? 'personal'}',
                                    ),
                                    total: displayTotal,
                                    beadInRound: displayBeadInRound,
                                    beadsPerRound: beadsPerRound,
                                    enabled: countingEnabled,
                                    beadImageBytes: counter.beadImageBytes,
                                    beadColor: const Color(0xFF8D6E63),
                                    threadColor: const Color(0xFFC62828),
                                    onTap: () => onBead(MalaInput.tap),
                                    onSwipe: () => onBead(MalaInput.swipe),
                                  ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GroupAccumulationsBar(
                        presetId: mantra.presetId,
                        personalLifetimeCount: notifier.displayLifetimeCount,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AddMalaRoundsButton(mantra: mantra),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _applyInitialGroupSelectionIfNeeded(String presetId) {
    final groupId = widget.initialGroupAccumulatorId;
    if (groupId == null || groupId.isEmpty || _appliedInitialGroupSelection) {
      return;
    }
    _appliedInitialGroupSelection = true;
    ref
        .read(malaAccumulationSelectionProvider(presetId).notifier)
        .applyNavigationIntent(groupId);
  }

}

class _CounterBlock extends StatelessWidget {
  const _CounterBlock({
    required this.beadInRound,
    required this.beadsPerRound,
    required this.rounds,
  });

  final int beadInRound;
  final int beadsPerRound;
  final int rounds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final useTibetan = context.isTibetanLocale;
    final beadLabel =
        useTibetan
            ? '${toTibetanDigits(beadInRound)}/${toTibetanDigits(beadsPerRound)}'
            : '$beadInRound/$beadsPerRound';
    final roundsLabel =
        useTibetan
            ? toTibetanDigits(l10n.mala_rounds_count(rounds))
            : l10n.mala_rounds_count(rounds);
    final color = theme.colorScheme.onSurface;
    return Semantics(
      label: l10n.mala_counter_semantics(
        beadInRound,
        beadsPerRound,
        roundsLabel,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            beadLabel,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            roundsLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// App bar with a back button and the mantra name.
class _MalaAppBar extends StatelessWidget {
  const _MalaAppBar({required this.title, this.onMorePressed});
  final String title;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, size: 24),
            onPressed: onMorePressed,
          ),
        ],
      ),
    );
  }
}

/// Wraps non-loaded states with a minimal back-button app bar.
class _MalaAppBarScaffold extends StatelessWidget {
  const _MalaAppBarScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.message, required this.onRetry});
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? context.l10n.something_went_wrong),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
