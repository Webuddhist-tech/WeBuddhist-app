import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
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
  static const _gridSpacing = 12.0;
  static const _sectionSpacing = 24.0;
  // TODO(localization): move to l10n once copy is finalized.
  static const _yourTimersTitle = 'Your timers';
  static const _customTimerLabel = 'Custom timer';

  void _onAddCustomTimer(BuildContext context) {
    context.push('/home/timers/new');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final timersAsync = ref.watch(presetTimersFutureProvider);
    final hasUserCreatedTimers = timersAsync.maybeWhen(
      data:
          (timersEither) => timersEither.fold(
            (_) => false,
            (timers) => timers.any((timer) => timer.isUserCreated),
          ),
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton:
          hasUserCreatedTimers
              ? _CustomTimerFab(
                label: _customTimerLabel,
                onPressed: () => _onAddCustomTimer(context),
              )
              : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, l10n.meditation_timer),
            Expanded(
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
                      // User-created timers (type == "user_created"). The
                      // dashed "+ Custom timer" card is shown only until the
                      // first one exists; after that the FAB takes over.
                      final customTimers =
                          timers.where((timer) => timer.isUserCreated).toList();

                      // An empty list falls through rather than showing an
                      // empty-state message: the only useful action on this
                      // screen is creating a timer, so "Your timers" plus the
                      // dashed add card is what belongs on screen. Showing the
                      // message instead left the user with no way to create
                      // one, since the FAB is gated on already having one.
                      return RefreshIndicator(
                        onRefresh: () => _refreshPresetTimers(ref),
                        child: _TimersContent(
                          presetTimers: presetTimers,
                          customTimers: customTimers,
                          minLabel: l10n.timer_min,
                          showAddCard: customTimers.isEmpty,
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
          ],
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

  Widget _buildAppBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
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
    required this.showAddCard,
  });

  final List<PresetTimer> presetTimers;
  final List<PresetTimer> customTimers;
  final String minLabel;
  final bool showAddCard;

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
    required BuildContext context,
    required WidgetRef ref,
  }) {
    final ambientSound =
        timer.ambientSoundId != null
            ? ambientSoundsById[timer.ambientSoundId]
            : null;

    return PresetTimerCard(
      timer: timer,
      minLabel: minLabel,
      ambientSoundName: ambientSound?.name,
      onTap: () => context.push('/home/timers/active', extra: timer),
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

    final yourTimersItemCount = customTimers.length + (showAddCard ? 1 : 0);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        PresetTimersScreen._horizontalPadding,
        PresetTimersScreen._horizontalPadding,
        PresetTimersScreen._horizontalPadding,
        showAddCard ? PresetTimersScreen._horizontalPadding : 88,
      ),
      children: [
        if (yourTimersItemCount > 0) ...[
          _SectionTitle(title: PresetTimersScreen._yourTimersTitle),
          const SizedBox(height: PresetTimersScreen._gridSpacing),
          _TimersGrid(
            itemCount: yourTimersItemCount,
            itemBuilder: (context, index) {
              if (showAddCard && index == 0) {
                return CustomTimerCard(
                  label: PresetTimersScreen._customTimerLabel,
                  onTap: () => context.push('/home/timers/new'),
                );
              }
              final timer = customTimers[index - (showAddCard ? 1 : 0)];
              return _buildTimerCard(
                timer: timer,
                ambientSoundsById: ambientSoundsById,
                context: context,
                ref: ref,
              );
            },
          ),
        ],
        if (presetTimers.isNotEmpty) ...[
          const SizedBox(height: PresetTimersScreen._sectionSpacing),
          _SectionTitle(title: l10n.preset_timers),
          const SizedBox(height: PresetTimersScreen._gridSpacing),
          _TimersGrid(
            itemCount: presetTimers.length,
            itemBuilder: (context, index) {
              final timer = presetTimers[index];
              return _buildTimerCard(
                timer: timer,
                ambientSoundsById: ambientSoundsById,
                context: context,
                ref: ref,
              );
            },
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}

class _TimersGrid extends StatelessWidget {
  const _TimersGrid({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: PresetTimersScreen._gridSpacing,
        mainAxisSpacing: PresetTimersScreen._gridSpacing,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
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
        padding: const EdgeInsets.all(PresetTimersScreen._horizontalPadding),
        children: [
          _SectionTitle(title: PresetTimersScreen._yourTimersTitle),
          const SizedBox(height: PresetTimersScreen._gridSpacing),
          _TimersGrid(
            itemCount: 1,
            itemBuilder: (context, index) => const _CardSkeleton(),
          ),
          const SizedBox(height: PresetTimersScreen._sectionSpacing),
          _SectionTitle(title: l10n.preset_timers),
          const SizedBox(height: PresetTimersScreen._gridSpacing),
          _TimersGrid(
            itemCount: 4,
            itemBuilder: (context, index) => const _CardSkeleton(),
          ),
        ],
      ),
    );
  }
}

class _CustomTimerFab extends StatelessWidget {
  const _CustomTimerFab({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final foregroundColor =
        isDark ? AppColors.textPrimary : AppColors.onPrimary;

    return Material(
      color: backgroundColor,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.25),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(AppAssets.plus, size: 20, color: foregroundColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4E4E4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: const AspectRatio(
        aspectRatio: 1,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Bone(width: 56, height: 58),
                SizedBox(height: 8),
                Bone(width: 36, height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
