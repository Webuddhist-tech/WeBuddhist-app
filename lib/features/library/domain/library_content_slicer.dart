import 'package:flutter_pecha/features/library/data/models/library_segment.dart';

/// Code-point slices of [content]; spans start at [spanStart], end exclusive.
List<String> sliceLibraryLines(
  String content,
  List<LibraryLineSpan> lines, {
  int spanStart = 0,
}) {
  if (lines.isEmpty) return const [];
  final runes = content.runes.toList(growable: false);
  final result = <String>[];
  for (final line in lines) {
    final start = _clamp(line.start - spanStart, 0, runes.length);
    final end = _clamp(line.end - spanStart, start, runes.length);
    result.add(String.fromCharCodes(runes, start, end).trim());
  }
  return result;
}

int _clamp(int value, int min, int max) =>
    value < min ? min : (value > max ? max : value);
