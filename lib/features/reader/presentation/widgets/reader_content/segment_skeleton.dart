import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton loading widget for segments during pagination
class SegmentSkeleton extends StatelessWidget {
  final int lineCount;
  final bool showNumber;

  const SegmentSkeleton({
    super.key,
    this.lineCount = ReaderConstants.skeletonLineCount,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ReaderConstants.segmentHorizontalPadding,
          vertical: ReaderConstants.segmentVerticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segment number skeleton, centered above the content
            if (showNumber)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 2),
                  child: SizedBox(
                    width: ReaderConstants.segmentNumberWidth,
                    child: Bone.text(words: 1),
                  ),
                ),
              ),
            // Content lines skeleton
            ...List.generate(
              lineCount,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Bone.text(words: index == lineCount - 1 ? 3 : 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multiple segment skeletons for loading states
class SegmentSkeletonList extends StatelessWidget {
  final int count;
  final int linesPerSegment;

  const SegmentSkeletonList({
    super.key,
    this.count = 3,
    this.linesPerSegment = ReaderConstants.skeletonLineCountShort,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => SegmentSkeleton(lineCount: linesPerSegment),
      ),
    );
  }
}

/// Loading indicator with skeleton for pagination
class PaginationLoadingIndicator extends StatelessWidget {
  final String message;
  final bool showSkeleton;

  const PaginationLoadingIndicator({
    super.key,
    required this.message,
    this.showSkeleton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress indicator with message
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(message, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        // Optional skeleton preview
        if (showSkeleton)
          const SegmentSkeletonList(count: 1, linesPerSegment: 2),
      ],
    );
  }
}
