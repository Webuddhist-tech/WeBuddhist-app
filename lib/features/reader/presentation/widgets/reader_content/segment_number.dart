import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Segment label shown centered above segment content.
///
/// Shared by [SegmentItem] and [InterlinearSegmentItem] so both render the
/// label with identical padding, scale, and font conventions.
class SegmentNumber extends ConsumerWidget {
  const SegmentNumber({super.key, required this.label, required this.language});

  /// The edition's reference (e.g. `1-12`) or the segment number.
  final String label;
  final String language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ReaderStyle.of(context, ref);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Text(
        label.replaceAll('-', '.'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: style.type.verseNumberSize,
          fontWeight: FontWeight.w500,
          fontFamily: style.type.family(language),
          color: style.palette.verseNumber,
        ),
      ),
    );
  }
}
