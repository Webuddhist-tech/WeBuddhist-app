import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/event_replays.dart';

/// Replays trigger in the event page's app bar: a history icon with a
/// caret, since the bar also holds the video / audio and language pills.
/// Opens an anchored list of the selected day's recordings; the one that
/// is playing carries a check there, the trigger itself never changes.
class GroupEventReplaysMenu extends StatelessWidget {
  final List<EventReplay> replays;
  final EventReplay? selected;
  final ValueChanged<EventReplay> onSelected;

  const GroupEventReplaysMenu({
    super.key,
    required this.replays,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final current = selected;

    return PopupMenuButton<EventReplay>(
      tooltip: l10n.event_replays,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 36),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 320),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.grey800 : AppColors.grey300),
      ),
      onSelected: onSelected,
      itemBuilder:
          (context) => [
            PopupMenuItem<EventReplay>(
              enabled: false,
              height: 32,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l10n.event_replays,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
                strutStyle: context.tibetanStrutStyle(12, compact: true),
              ),
            ),
            if (replays.isEmpty)
              PopupMenuItem<EventReplay>(
                enabled: false,
                child: Text(
                  l10n.event_replays_empty,
                  style: TextStyle(fontSize: 14, color: secondaryColor),
                  strutStyle: context.tibetanStrutStyle(14, compact: true),
                ),
              ),
            for (final replay in replays)
              PopupMenuItem<EventReplay>(
                value: replay,
                height: 56,
                child: _ReplayRow(
                  replay: replay,
                  label: EventReplays.label(l10n, languageCode, replay),
                  isSelected: replay == current,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                ),
              ),
          ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        // Two pills in the actions can leave the title slot narrow; the
        // icon shrinks a little rather than overflowing.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppAssets.clockCounterClockwise, size: 22, color: textColor),
              const SizedBox(width: 2),
              Icon(AppAssets.caretDown, size: 16, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplayRow extends StatelessWidget {
  final EventReplay replay;
  final String label;
  final bool isSelected;
  final Color textColor;
  final Color secondaryColor;

  const _ReplayRow({
    required this.replay,
    required this.label,
    required this.isSelected,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 56,
            height: 32,
            child: CachedNetworkImageWidget(
              imageUrl: replay.thumbnailUrl,
              width: 56,
              height: 32,
              fit: BoxFit.cover,
              placeholder: const ColoredBox(color: Colors.black12),
              errorWidget: const ColoredBox(color: Colors.black12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                strutStyle: context.tibetanStrutStyle(14, compact: true),
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.event_replay_recording,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: secondaryColor),
                strutStyle: context.tibetanStrutStyle(12, compact: true),
              ),
            ],
          ),
        ),
        if (isSelected) ...[
          const SizedBox(width: 8),
          Icon(AppAssets.check, size: 16, color: textColor),
        ],
      ],
    );
  }
}

/// Red "● Back to live" pill shown under a replay while the stream is live.
class GroupEventBackToLivePill extends StatelessWidget {
  final VoidCallback onTap;

  const GroupEventBackToLivePill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.event_replay_back_to_live,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Colors.white,
                ),
                strutStyle: context.tibetanStrutStyle(13, compact: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
