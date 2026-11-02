import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_verse_numbers_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_numerals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A verse's number, on its own row at the bottom right of the verse.
///
/// Shared by [SegmentItem] and [InterlinearSegmentItem]. Its numerals follow
/// [language] (see [readerNumeralScript]); nothing is drawn while verse
/// numbers are turned off.
class SegmentNumber extends ConsumerWidget {
  const SegmentNumber({super.key, required this.label, required this.language});

  /// The edition's reference (e.g. `1-12`) or the segment number.
  final String label;

  /// The language the page's numbers are written in.
  final String language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(readerVerseNumbersProvider)) return const SizedBox.shrink();
    final style = ReaderStyle.of(context, ref);
    final script = ReaderScript.ofLanguage(language);
    return Text(
      readerVerseLabel(label, script),
      textAlign: TextAlign.end,
      style: TextStyle(
        fontSize: style.type.verseNumberSize(script),
        fontWeight: FontWeight.w500,
        fontFamily: style.type.family(language, script: script),
        color: style.palette.verseNumber,
      ),
    );
  }
}
