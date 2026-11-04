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

/// The first of [active], in order, that [content] lacks and [skipped] does
/// not name: where the next page is fetched. Null once every verse is in.
///
/// Only those after the first verse [content] holds: a text opened at the
/// live verse holds none before it, and those come in as pages above
/// ([earlierSegmentMissing]), since a next page lands after the loaded ones.
String? nextSegmentToLoad(
  FlattenedContent content,
  List<String> active, {
  Set<String> skipped = const {},
}) {
  final first = active.indexWhere(content.containsSegment);
  for (var i = first < 0 ? 0 : first; i < active.length; i++) {
    final id = active[i];
    if (!content.containsSegment(id) && !skipped.contains(id)) return id;
  }
  return null;
}

/// Whether verses of a source come before its loaded ones: for a whole
/// text, while it [hasPreviousPage]; for picked verses ([active]), while one
/// before the first [content] holds is neither in nor [skipped].
bool earlierSegmentMissing(
  FlattenedContent content,
  List<String> active, {
  required bool hasPreviousPage,
  Set<String> skipped = const {},
}) {
  if (!hasPreviousPage) return false;
  if (active.isEmpty) return true;
  final first = active.indexWhere(content.containsSegment);
  if (first < 0) return false;
  for (var i = 0; i < first; i++) {
    if (!skipped.contains(active[i])) return true;
  }
  return false;
}

/// [items] without the verses numbered below [from], and without headings
/// left with no verse under them: rows loaded above the reading position,
/// held back until the list is still (see `ReaderContentPart`).
List<FlattenedItem> itemsFromVerse(List<FlattenedItem> items, int from) {
  int? numberOf(FlattenedItem item) => item.segment?.segmentNumber;
  final kept = <FlattenedItem>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final number = numberOf(item);
    if (number != null) {
      if (number >= from) kept.add(item);
      continue;
    }
    if (!item.isHeader) {
      kept.add(item);
      continue;
    }
    // A heading stays while a verse it heads is drawn.
    for (var j = i + 1; j < items.length; j++) {
      final next = items[j];
      if (next.isHeader && next.depth <= item.depth) break;
      if ((numberOf(next) ?? -1) >= from) {
        kept.add(item);
        break;
      }
    }
  }
  return kept;
}

/// Whether [source], whose last drawn entry is at [end], may fetch its next
/// page: only while that end is on screen or within [threshold] below it.
/// A source ending above the screen waits, since its new rows would land
/// above the top entry and push the reading position down. So does one
/// before [liveSource], the text holding the live verse while the page
/// follows it: its rows would land above that verse and push it off
/// screen. A source that draws nothing yet ([end] below 0) may fetch.
bool sourceMayLoadForward({
  required int source,
  required int end,
  required int firstVisibleIndex,
  required int lastVisibleIndex,
  required int threshold,
  int? liveSource,
}) {
  if (liveSource != null && source < liveSource) return false;
  if (end < 0) return true;
  return end >= firstVisibleIndex && lastVisibleIndex >= end - threshold;
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
