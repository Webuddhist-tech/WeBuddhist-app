import 'dart:convert';

import 'package:flutter_pecha/features/library/data/models/library_segment.dart';

const HtmlEscape _htmlEscape = HtmlEscape(HtmlEscapeMode.element);

/// Class the reader styles yigchung (small text) runs with.
const String libraryYigchungClass = 'yigchung';

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

/// The same lines as one escaped HTML block (blank lines dropped, `<br>`
/// between the rest), with the parts inside [yigchungs] wrapped in a
/// `<span class="yigchung">`. Span ends are exclusive; [yigchungs] must be
/// sorted by start.
String sliceLibraryHtml(
  String content,
  List<LibraryLineSpan> lines, {
  int spanStart = 0,
  List<LibraryLineSpan> yigchungs = const [],
}) {
  if (lines.isEmpty) return '';
  final runes = content.runes.toList(growable: false);
  final parts = <String>[];
  for (final line in lines) {
    var start = _clamp(line.start - spanStart, 0, runes.length);
    var end = _clamp(line.end - spanStart, start, runes.length);
    // Trim like [sliceLibraryLines]; whitespace is always one code point.
    final raw = String.fromCharCodes(runes, start, end);
    start += raw.length - raw.trimLeft().length;
    end -= raw.length - raw.trimRight().length;
    if (start >= end) continue;
    parts.add(_lineHtml(runes, start, end, spanStart, yigchungs));
  }
  return parts.join('<br>');
}

String _lineHtml(
  List<int> runes,
  int start,
  int end,
  int spanStart,
  List<LibraryLineSpan> marks,
) {
  final buffer = StringBuffer();
  var cursor = start;
  for (final mark in marks) {
    if (mark.start - spanStart >= end) break;
    final from = _clamp(mark.start - spanStart, cursor, end);
    final to = _clamp(mark.end - spanStart, from, end);
    if (from >= to) continue;
    buffer
      ..write(_escape(runes, cursor, from))
      ..write('<span class="$libraryYigchungClass">')
      ..write(_escape(runes, from, to))
      ..write('</span>');
    cursor = to;
  }
  buffer.write(_escape(runes, cursor, end));
  return buffer.toString();
}

String _escape(List<int> runes, int start, int end) {
  if (start >= end) return '';
  return _htmlEscape.convert(String.fromCharCodes(runes, start, end));
}

int _clamp(int value, int min, int max) =>
    value < min ? min : (value > max ? max : value);
