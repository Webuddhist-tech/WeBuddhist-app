import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_palette.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_live_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The reader's Live pill: red "Live" while the reader follows the room's
/// position, grey "Paused" once the person scrolls or opens a verse. Tapping
/// Paused jumps back to the live verse and follows again; tapping Live does
/// nothing. Shown only while the room has a position to follow.
class RecitationLiveSyncToggle extends ConsumerWidget {
  final String eventId;

  const RecitationLiveSyncToggle({super.key, required this.eventId});

  static const _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (hasPosition, isFollowing) = ref.watch(
      recitationLiveProvider(
        eventId,
      ).select((s) => (s.hasPosition, s.isFollowing)),
    );
    if (!hasPosition) return const SizedBox.shrink();

    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    final fill = isFollowing ? palette.livePill : palette.pausedPill;
    final ink = isFollowing ? palette.livePillText : palette.pausedPillText;
    final label =
        isFollowing
            ? context.l10n.recitation_live_label
            : context.l10n.reader_live_paused;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Tooltip(
          message: context.l10n.recitation_live_sync,
          child: Material(
            color: fill,
            borderRadius: _radius,
            child: InkWell(
              borderRadius: _radius,
              onTap:
                  isFollowing
                      ? null
                      : () =>
                          ref
                              .read(recitationLiveProvider(eventId).notifier)
                              .resumeFollowing(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
