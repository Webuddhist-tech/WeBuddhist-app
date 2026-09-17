import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_live_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Floating "Live" pill over the reader: connection dot, round number, and
/// the one action that makes sense right now (Unsync / Resync / Sync).
class RecitationLivePill extends ConsumerWidget {
  final String eventId;

  const RecitationLivePill({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recitationLiveProvider(eventId));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder:
          (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
      child:
          state.isVisible
              ? _PillBody(
                key: const ValueKey('recitation-live-pill'),
                state: state,
                notifier: ref.read(recitationLiveProvider(eventId).notifier),
              )
              : const SizedBox.shrink(key: ValueKey('recitation-live-none')),
    );
  }
}

enum _Action { unsync, resync, sync }

class _PillBody extends StatelessWidget {
  final RecitationLiveState state;
  final RecitationLiveNotifier notifier;

  const _PillBody({super.key, required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final green = isDark ? AppColors.eventOnlineChipDark : AppColors.eventOnlineChip;
    final amber = isDark ? AppColors.eventInPersonChipDark : AppColors.eventInPersonChip;
    final grey = isDark ? AppColors.grey600 : AppColors.grey500;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final accentColor = isDark ? AppColors.blueDark : AppColors.blue;

    final round = state.position?.roundNumber;
    final liveLabel =
        round == null
            ? l10n.recitation_live_label
            : '${l10n.recitation_live_label} · ${l10n.recitation_live_round(round)}';

    final Color dotColor;
    final bool pulsing;
    final String label;
    final _Action? action;
    if (state.isEnded) {
      dotColor = grey;
      pulsing = false;
      label = l10n.recitation_live_session_ended;
      action = null;
    } else if (state.isReconnecting) {
      dotColor = grey;
      pulsing = true;
      label = l10n.recitation_live_reconnecting;
      action = state.isFollowing ? _Action.unsync : _Action.resync;
    } else if (state.outOfSync && !state.isOff) {
      dotColor = amber;
      pulsing = false;
      label = '${l10n.recitation_live_label} · ${l10n.recitation_live_out_of_sync}';
      action = _Action.resync;
    } else {
      switch (state.followMode) {
        case RecitationLiveFollowMode.following:
          dotColor = green;
          pulsing = true;
          label = liveLabel;
          action = _Action.unsync;
        case RecitationLiveFollowMode.paused:
          dotColor = green;
          pulsing = false;
          label = liveLabel;
          action = _Action.resync;
        case RecitationLiveFollowMode.off:
          dotColor = grey;
          pulsing = false;
          label = liveLabel;
          action = _Action.sync;
      }
    }

    final tapAction = action;
    final actionLabel = switch (tapAction) {
      _Action.unsync => l10n.recitation_live_unsync,
      _Action.resync => l10n.recitation_live_resync,
      _Action.sync => l10n.recitation_live_sync,
      null => null,
    };
    final actionColor =
        tapAction == _Action.unsync ? mutedColor : accentColor;

    return Material(
      color: isDark ? AppColors.chipBackgroundDark : AppColors.surfaceWhite,
      elevation: isDark ? 0 : 3,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: StadiumBorder(
        side: BorderSide(
          color: isDark ? AppColors.grey800 : AppColors.grey300,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tapAction == null ? null : () => _onTap(tapAction),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LiveDot(color: dotColor, pulsing: pulsing),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 14,
                  color: isDark ? AppColors.grey800 : AppColors.grey300,
                ),
                const SizedBox(width: 10),
                Text(
                  actionLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: actionColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(_Action action) {
    switch (action) {
      case _Action.unsync:
        notifier.stopFollowing();
      case _Action.resync:
      case _Action.sync:
        notifier.resumeFollowing();
    }
  }
}

/// Status dot; pulses gently while following so "live" reads as alive.
class _LiveDot extends StatefulWidget {
  final Color color;
  final bool pulsing;

  const _LiveDot({required this.color, required this.pulsing});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _LiveDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulsing != widget.pulsing) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.pulsing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final halo = Curves.easeInOut.transform(_controller.value);
        return SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.pulsing)
                Container(
                  width: 8 + 6 * halo,
                  height: 8 + 6 * halo,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.28 * (1 - halo)),
                  ),
                ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
