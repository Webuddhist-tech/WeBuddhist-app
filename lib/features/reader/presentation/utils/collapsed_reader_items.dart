import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_item.dart';
import 'package:flutter_pecha/features/reader/data/models/secondary_reader_state.dart';

/// The collapsed view's list: the [active] verses in reading order, each
/// preceded by the titled headings that enclose it, every heading once.
List<FlattenedItem> collapsedReaderItems(
  FlattenedContent content,
  Set<String> active,
) {
  final items = <FlattenedItem>[];
  // The heading in effect at each depth, from the last header seen.
  final open = <FlattenedItem>[];
  final shown = <String>{};
  for (final item in content.items) {
    if (item.isHeader) {
      if (open.length > item.depth) open.removeRange(item.depth, open.length);
      while (open.length < item.depth) {
        open.add(item);
      }
      open.add(item);
      continue;
    }
    if (item.segmentId == null || !active.contains(item.segmentId)) continue;
    for (var depth = 0; depth <= item.depth && depth < open.length; depth++) {
      final header = open[depth];
      final section = header.section!;
      final title = section.title;
      if (header.depth != depth || title == null || title.isEmpty) continue;
      if (shown.add(section.id)) items.add(header);
    }
    items.add(item);
  }
  return items;
}

/// The translation's headings to draw above each verse of the collapsed
/// list: those enclosing it that an earlier verse has not shown yet.
Map<String, List<SecondaryHeading>> collapsedTranslationHeadings(
  List<FlattenedItem> items,
  SecondaryReaderState secondary,
) {
  final result = <String, List<SecondaryHeading>>{};
  final shown = <String>{};
  for (final item in items) {
    final segment = item.segment;
    if (segment == null) continue;
    final headings = secondary
        .headingsEnclosing(segment.segmentNumber)
        .where((h) => shown.add(h.section.id))
        .toList(growable: false);
    if (headings.isNotEmpty) result[segment.segmentId] = headings;
  }
  return result;
}
