import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/timer/domain/entities/ambient_sound.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/presentation/providers/timers_providers.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/custom_timer_card.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/preset_timer_card.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/timer_more_bottom_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PresetTimersScreen extends ConsumerWidget {
  const PresetTimersScreen({super.key});

  static const _horizontalPadding = 16.0;
  static const _sectionSpacing = 28.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final timersAsync = ref.watch(presetTimersFutureProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.meditation_timer),
      ),
      body: SafeArea(
        top: false,
        child: timersAsync.when(
          data: (timersEither) {
            return timersEither.fold(
              (failure) => ErrorStateWidget(
                error: failure,
                onRetry: () => _retryPresetTimers(ref),
              ),
              (timers) {
                final presetTimers = _sortedPresetTimers(
                  timers.where((timer) => timer.isPreset).toList(),
                );
                // User-created timers (type == "user_created") sit under
                // the create row, which stays so another timer can be
                // added.
                final customTimers =
                    timers.where((timer) => timer.isUserCreated).toList();

                return RefreshIndicator(
                  onRefresh: () => _refreshPresetTimers(ref),
                  child: _TimersContent(
                    presetTimers: presetTimers,
                    customTimers: customTimers,
                    minLabel: l10n.timer_min,
                  ),
                );
              },
            );
          },
          loading: () => const _TimersContentSkeleton(),
          error:
              (error, _) => ErrorStateWidget(
                error: error,
                onRetry: () => _retryPresetTimers(ref),
              ),
        ),
      ),
    );
  }

  /// Pull-to-refresh: the repository writes the fetched list to Hive, which
  /// makes the already-watched stream emit it. Invalidating
  /// [presetTimersFutureProvider] here would recreate that stream and fetch
  /// the same list a second time.
  Future<void> _refreshPresetTimers(WidgetRef ref) async {
    ref.invalidate(ambientSoundsFutureProvider);
    await ref.read(timersDomainRepositoryProvider).refreshPresetTimers();
  }

  /// Retry after an error, where the stream may have ended (e.g. the auth gate
  /// rejected it) and has to be recreated rather than nudged through Hive.
  void _retryPresetTimers(WidgetRef ref) {
    ref.invalidate(ambientSoundsFutureProvider);
    ref.invalidate(presetTimersFutureProvider);
  }

  List<PresetTimer> _sortedPresetTimers(List<PresetTimer> timers) {
    final sorted = List<PresetTimer>.from(timers)
      ..sort((a, b) => a.durationMs.compareTo(b.durationMs));
    return sorted;
  }
}

class _TimersContent extends ConsumerWidget {
  const _TimersContent({
    required this.presetTimers,
    required this.customTimers,
    required this.minLabel,
  });

  final List<PresetTimer> presetTimers;
  final List<PresetTimer> customTimers;
  final String minLabel;

  void _openMoreSheet(BuildContext context, WidgetRef ref, PresetTimer timer) {
    showTimerMoreBottomSheet(
      context,
      timer: timer,
      onAddToPractices:
          () => context.push(
            AppRoutes.practiceEditRoutine,
            extra: {'initialTimer': timer},
          ),
    );
  }

  PresetTimerCard _buildTimerCard({
    required PresetTimer timer,
    required Map<String, AmbientSound> ambientSoundsById,
    required String noSoundLabel,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    final soundId = timer.ambientSoundId;
    final String? soundLabel;
    if (soundId == null || soundId.isEmpty) {
      soundLabel = noSoundLabel;
    } else {
      soundLabel = ambientSoundsById[soundId]?.name;
    }

    return PresetTimerCard(
      timer: timer,
      minLabel: minLabel,
      soundLabel: soundLabel,
      onPlay: () => context.push('/home/timers/active', extra: timer),
      onMoreTap: () => _openMoreSheet(context, ref, timer),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.watch(ambientSoundsFutureProvider);
    final ambientSoundsById = ref.watch(ambientSoundByIdProvider);
    for (final timer in [...presetTimers, ...customTimers]) {
      ref.watch(
        prefetchBookmarkExistsProvider(
          BookmarkTarget(type: BookmarkType.timer, sourceId: timer.id),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        PresetTimersScreen._horizontalPadding,
        20,
        PresetTimersScreen._horizontalPadding,
        24,
      ),
      children: [
        _SectionTitle(title: l10n.timer_your_timers),
        const SizedBox(height: 12),
        CustomTimerCard(
          title: l10n.timer_create_custom,
          onTap: () => context.push('/home/timers/new'),
        ),
        if (customTimers.isNotEmpty) ...[
          const SizedBox(height: 12),
          _TimerGroup(
            children: [
              for (final timer in customTimers)
                _buildTimerCard(
                  timer: timer,
                  ambientSoundsById: ambientSoundsById,
                  noSoundLabel: l10n.timer_ambient_sound_none,
                  context: context,
                  ref: ref,
                ),
            ],
          ),
        ],
        if (presetTimers.isNotEmpty) ...[
          const SizedBox(height: PresetTimersScreen._sectionSpacing),
          _SectionTitle(title: l10n.preset_timers),
          const SizedBox(height: 12),
          _TimerGroup(
            children: [
              for (final timer in presetTimers)
                _buildTimerCard(
                  timer: timer,
                  ambientSoundsById: ambientSoundsById,
                  noSoundLabel: l10n.timer_ambient_sound_none,
                  context: context,
                  ref: ref,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TimerGroup extends StatelessWidget {
  const _TimerGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey100;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 20,
                endIndent: 20,
                color: dividerColor,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isTibetan = AppFontConfig.isTibetanLanguage(
      Localizations.localeOf(context).languageCode,
    );
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.45);

    return Text(
      isTibetan ? title : title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: isTibetan ? 0 : 1.1,
        color: color,
      ),
    );
  }
}

class _TimersContentSkeleton extends StatelessWidget {
  const _TimersContentSkeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Skeletonizer(
      enabled: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          PresetTimersScreen._horizontalPadding,
          20,
          PresetTimersScreen._horizontalPadding,
          24,
        ),
        children: [
          _SectionTitle(title: l10n.timer_your_timers),
          const SizedBox(height: 12),
          const _RowSkeleton(),
          const SizedBox(height: PresetTimersScreen._sectionSpacing),
          _SectionTitle(title: l10n.preset_timers),
          const SizedBox(height: 12),
          const _TimerGroup(
            children: [
              _RowSkeleton(),
              _RowSkeleton(),
              _RowSkeleton(),
              _RowSkeleton(),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(width: 96, height: 28),
                SizedBox(height: 8),
                Bone(width: 140, height: 14),
              ],
            ),
          ),
          Bone.circle(size: 48),
        ],
      ),
    );
  }
}
