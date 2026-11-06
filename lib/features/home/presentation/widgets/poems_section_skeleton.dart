import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/poems/presentation/widgets/poem_preview_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PoemsSectionSkeleton extends StatelessWidget {
  const PoemsSectionSkeleton({super.key});

  static const _horizontalPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionBackgroundColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            _horizontalPadding,
            0,
            _horizontalPadding,
            0,
          ),
          child: Skeletonizer(
            enabled: true,
            child: Row(
              children: [
                Expanded(child: Bone.text(words: 1, fontSize: 18)),
                Bone.text(words: 2, fontSize: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: sectionBackgroundColor,
          child: Skeletonizer(
            enabled: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Bone(
                      width: double.infinity,
                      height:
                          constraints.maxWidth *
                          PoemPreviewCard.coverHeight /
                          PoemPreviewCard.coverWidth,
                      borderRadius: BorderRadius.circular(0),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _horizontalPadding,
                    14,
                    _horizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Bone.text(words: 3, fontSize: 18),
                      const SizedBox(height: 8),
                      Bone.text(words: 6, fontSize: 14),
                      const SizedBox(height: 4),
                      Bone.text(words: 5, fontSize: 14),
                      const SizedBox(height: 12),
                      Bone.text(words: 2, fontSize: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
