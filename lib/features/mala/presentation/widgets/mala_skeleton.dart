import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton shown while the catalogue loads.
///
/// Mirrors the loaded [MalaScreen] body (rendered below the app bar): a 40%
/// mantra-switcher block with side chevrons and centered text, above a 60%
/// block holding the left-aligned counter and the bead arc.
class MalaSkeleton extends StatelessWidget {
  const MalaSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            // Mantra + transliteration switcher: 40% of the space below the
            // header, centered between the chevrons.
            Expanded(flex: 40, child: _SwitcherSkeleton()),
            // Counter lines + bead arc: the remaining 60%.
            Expanded(
              flex: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MalaCounterLinesSkeleton(),
                  SizedBox(height: 16),
                  Expanded(child: _BeadArcSkeleton()),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal-line skeleton for the mala counter while the count is seeding.
///
/// Count only — does not include the bead arc. Wraps its own [Skeletonizer]
/// for use on the loaded [MalaScreen].
class MalaCountSkeleton extends StatelessWidget {
  const MalaCountSkeleton({super.key, this.alignEnd = false});

  /// Right-align the bones (left-handed layout).
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: _MalaCounterLinesSkeleton(alignEnd: alignEnd),
    );
  }
}

/// Two horizontal bones matching [_CounterBlock] (n/108 + rounds row).
class _MalaCounterLinesSkeleton extends StatelessWidget {
  const _MalaCounterLinesSkeleton({this.alignEnd = false});

  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Bone(
            width: 120,
            height: 40,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Bone(
            width: 90,
            height: 24,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

/// Side chevrons flanking a centered mantra (large) + transliteration (small).
class _SwitcherSkeleton extends StatelessWidget {
  const _SwitcherSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Real chevrons read better than bones here.
        Skeleton.ignore(
          child: Icon(
            Icons.chevron_left,
            size: 32,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.25),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Bone(
                width: 200,
                height: 32,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 16),
              Bone(
                width: 140,
                height: 20,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
        Skeleton.ignore(
          child: Icon(
            Icons.chevron_right,
            size: 32,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

/// A diagonal strand of bead-sized circles approximating the bead arc.
///
/// Uses package [Bone.circle] (not custom Containers) so Skeletonizer paints
/// cleanly without zebra warning stripes.
class _BeadArcSkeleton extends StatelessWidget {
  const _BeadArcSkeleton();

  static const _count = 7;
  static const _size = 40.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final diameter = _size.clamp(24.0, width * 0.15);

        return Stack(
          children: [
            for (var i = 0; i < _count; i++)
              Builder(
                builder: (context) {
                  // Strand runs from bottom-left up to top-right.
                  final t = _count == 1 ? 0.0 : i / (_count - 1);
                  final left = (width - diameter) * t;
                  final top = (height - diameter) * (1 - t);
                  return Positioned(
                    left: left,
                    top: top,
                    child: Bone.circle(size: diameter),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
