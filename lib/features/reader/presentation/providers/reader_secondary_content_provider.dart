import 'dart:async';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/secondary_reader_state.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier that owns the secondary (companion) version's pages and exposes
/// a segment_number → content lookup map for the interlinear renderer.
///
/// Aligns with the primary by segment_number. Pagination uses the secondary
/// version's own segment_id boundaries so the API returns the correct page.
class SecondaryReaderNotifier extends StateNotifier<SecondaryReaderState> {
  SecondaryReaderNotifier({
    required Ref ref,
    required this.key,
  })  : _ref = ref,
        super(SecondaryReaderState.initial()) {
    // A page the reader fetched ahead (a translation opened as itself) goes
    // in before the first frame, so the original never shows in between.
    final fetched = _fetchedPage(secondaryInitialParams(key));
    if (fetched != null) {
      _applyInitial(fetched);
    } else {
      _loadInitial();
    }
  }

  final Ref _ref;
  final SecondaryReaderKey key;
  final _logger = AppLogger('SecondaryReader');
  bool _disposed = false;

  ReaderResponse? _fetchedPage(TextDetailsParams params) {
    final cached = _ref.read(textDetailsFutureProvider(params)).valueOrNull;
    return cached?.fold((_) => null, (response) => response);
  }

  Future<void> _loadInitial() async {
    if (_disposed) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _fetchParams(secondaryInitialParams(key));
      if (_disposed) return;
      _applyInitial(response);
      _logger.debug(
        'Secondary initial load (${key.versionId}): '
        '${state.loadedSegments.length} segments, '
        'total=${response.totalSegments}, '
        'startSegmentId=${key.initialSegmentId}',
      );
    } catch (e, st) {
      _logger.error('Secondary initial load failed for ${key.versionId}', e, st);
      if (_disposed) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _applyInitial(ReaderResponse response) {
    final segments = _readPage(response);
    state = state.copyWith(
      contentBySegmentNumber: _buildSegmentNumberMap(segments),
      loadedSegments: segments,
      totalSegments: response.totalSegments,
      isLoading: false,
      hasNextPage: response.hasNextPage,
      hasPreviousPage: response.currentSegmentPosition > 1,
    );
  }

  bool _covering = false;

  /// Pages until the loaded verses span the primary's [first]..[last], so a
  /// primary that loaded more at once (a pre-merged previous page) is not
  /// left a page ahead. Stops on a failure or a page that adds nothing.
  Future<void> cover(int first, int last) async {
    if (_covering) return;
    _covering = true;
    try {
      for (var i = 0; i < _maxCoverPages; i++) {
        if (_disposed || !state.needsToCover(first, last)) return;
        final before = state.loadedSegments.length;
        if (state.hasPreviousPage &&
            state.loadedSegments.first.segmentNumber > first) {
          await loadPrevious();
        } else {
          await loadNext();
        }
        if (_disposed) return;
        if (state.loadedSegments.length == before) {
          // Nothing new: stop asking, and let those verses show the original.
          state = state.copyWith(pagingFailed: true);
          return;
        }
      }
    } finally {
      _covering = false;
    }
  }

  static const _maxCoverPages = 20;

  /// Extend the secondary forward by one page.
  Future<void> loadNext() async {
    if (_disposed || state.isLoadingNext || !state.hasNextPage) return;
    final lastId = state.lastLoadedSegmentId;
    if (lastId == null) return;

    state = state.copyWith(isLoadingNext: true);
    try {
      final response = await _fetch(segmentId: lastId, direction: 'next');
      if (_disposed) return;

      final newSegments = _readPage(response);
      final existingIds =
          state.loadedSegments.map((s) => s.segmentId).toSet();
      final dedupedNew = newSegments
          .where((s) => !existingIds.contains(s.segmentId))
          .toList();

      if (dedupedNew.isEmpty) {
        state = state.copyWith(
          isLoadingNext: false,
          hasNextPage: response.hasNextPage,
          totalSegments: response.totalSegments,
        );
        return;
      }

      final mergedSegments = [...state.loadedSegments, ...dedupedNew];
      final mergedMap = _mergeSegmentContent(
        state.contentBySegmentNumber,
        dedupedNew,
      );

      state = state.copyWith(
        loadedSegments: mergedSegments,
        contentBySegmentNumber: mergedMap,
        isLoadingNext: false,
        pagingFailed: false,
        hasNextPage: response.hasNextPage,
        totalSegments: response.totalSegments,
      );
    } catch (e, st) {
      _logger.error('Secondary loadNext failed for ${key.versionId}', e, st);
      if (_disposed) return;
      state = state.copyWith(isLoadingNext: false, pagingFailed: true);
    }
  }

  /// Extend the secondary backward by one page.
  Future<void> loadPrevious() async {
    if (_disposed || state.isLoadingPrevious || !state.hasPreviousPage) return;
    final firstId = state.firstLoadedSegmentId;
    if (firstId == null) return;

    state = state.copyWith(isLoadingPrevious: true);
    try {
      final response = await _fetch(segmentId: firstId, direction: 'previous');
      if (_disposed) return;

      final newSegments = _readPage(response);
      final existingIds =
          state.loadedSegments.map((s) => s.segmentId).toSet();
      final dedupedNew = newSegments
          .where((s) => !existingIds.contains(s.segmentId))
          .toList();

      if (dedupedNew.isEmpty) {
        state = state.copyWith(
          isLoadingPrevious: false,
          hasPreviousPage: response.currentSegmentPosition > 1,
        );
        return;
      }

      final mergedSegments = [...dedupedNew, ...state.loadedSegments];
      final mergedMap = _mergeSegmentContent(
        state.contentBySegmentNumber,
        dedupedNew,
      );

      state = state.copyWith(
        loadedSegments: mergedSegments,
        contentBySegmentNumber: mergedMap,
        isLoadingPrevious: false,
        pagingFailed: false,
        hasPreviousPage: response.currentSegmentPosition > 1,
      );
    } catch (e, st) {
      _logger.error('Secondary loadPrevious failed for ${key.versionId}', e, st);
      if (_disposed) return;
      state = state.copyWith(isLoadingPrevious: false, pagingFailed: true);
    }
  }

  Future<void> reload() async {
    state = SecondaryReaderState.initial();
    await _loadInitial();
  }

  Future<ReaderResponse> _fetch({
    required String? segmentId,
    required String direction,
    int? size,
  }) {
    return _fetchParams(
      TextDetailsParams(
        textId: key.textId,
        versionId: key.versionId,
        segmentId: segmentId,
        direction: direction,
        size: size,
      ),
    );
  }

  Future<ReaderResponse> _fetchParams(TextDetailsParams params) async {
    final result = await _ref.read(textDetailsFutureProvider(params).future);
    return result.fold(
      (failure) => throw Exception(
        'Failed to fetch secondary text: ${failure.message}',
      ),
      (response) => response,
    );
  }

  /// Headings seen so far by section id; a section spanning pages keeps the
  /// earliest and latest verses it was seen at.
  final Map<String, SecondaryHeading> _headings = {};

  /// A page's segments, recording its headings on the way.
  List<Segment> _readPage(ReaderResponse response) {
    final sections = response.content.sections;
    if (_collectHeadings(sections, 0)) {
      state = state.copyWith(headingsBySegmentNumber: _headingMap());
    }
    return _extractSegments(sections);
  }

  /// True when a heading was added or moved earlier.
  bool _collectHeadings(List<Section> sections, int depth) {
    var changed = false;
    for (final section in sections) {
      final first = _firstSegmentNumber(section);
      final last = _lastSegmentNumber(section);
      final title = section.title;
      if (first != null && last != null && title != null && title.isNotEmpty) {
        final known = _headings[section.id];
        final start =
            known == null || first < known.segmentNumber
                ? first
                : known.segmentNumber;
        final end =
            known == null || last > known.endSegmentNumber
                ? last
                : known.endSegmentNumber;
        if (known == null ||
            start != known.segmentNumber ||
            end != known.endSegmentNumber) {
          _headings[section.id] = SecondaryHeading(
            section: section,
            depth: depth,
            segmentNumber: start,
            endSegmentNumber: end,
          );
          changed = true;
        }
      }
      final nested = section.sections;
      if (nested != null && _collectHeadings(nested, depth + 1)) {
        changed = true;
      }
    }
    return changed;
  }

  static int? _firstSegmentNumber(Section section) {
    if (section.segments.isNotEmpty) return section.segments.first.segmentNumber;
    for (final nested in section.sections ?? const <Section>[]) {
      final first = _firstSegmentNumber(nested);
      if (first != null) return first;
    }
    return null;
  }

  static int? _lastSegmentNumber(Section section) {
    final nested = section.sections ?? const <Section>[];
    for (final child in nested.reversed) {
      final last = _lastSegmentNumber(child);
      if (last != null) return last;
    }
    return section.segments.isEmpty ? null : section.segments.last.segmentNumber;
  }

  Map<int, List<SecondaryHeading>> _headingMap() {
    final map = <int, List<SecondaryHeading>>{};
    for (final heading in _headings.values) {
      map.putIfAbsent(heading.segmentNumber, () => []).add(heading);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.depth.compareTo(b.depth));
    }
    return map;
  }

  List<Segment> _extractSegments(List<Section> sections) {
    final result = <Segment>[];
    for (final section in sections) {
      result.addAll(section.segments);
      final nested = section.sections;
      if (nested != null && nested.isNotEmpty) {
        result.addAll(_extractSegments(nested));
      }
    }
    return result;
  }

  Map<int, String> _buildSegmentNumberMap(List<Segment> segments) =>
      _mergeSegmentContent(const {}, segments);

  /// Returns a new map containing every entry of [existing] plus an entry
  /// for each segment in [segments] whose content is non-empty. Prefers
  /// `seg.translation.content` over `seg.content` when both are present.
  Map<int, String> _mergeSegmentContent(
    Map<int, String> existing,
    List<Segment> segments,
  ) {
    final merged = Map<int, String>.from(existing);
    for (final seg in segments) {
      final content = _segmentContent(seg);
      if (content != null) merged[seg.segmentNumber] = content;
    }
    return merged;
  }

  String? _segmentContent(Segment seg) {
    final translation = seg.translation;
    if (translation != null && translation.content.trim().isNotEmpty) {
      return translation.content;
    }
    // Intentionally no fallback to `seg.content`. For the secondary stream
    // `seg.content` is the PRIMARY text (the path is the primary's id), so
    // surfacing it here would render the primary's own content as the
    // "translation" line. Returning null leaves the segment_number absent
    // from the map; the renderer's "unavailable" placeholder takes over.
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// AutoDispose family provider keyed by (textId, versionId). When the user
/// disables the secondary or picks a different version, the old provider is
/// torn down and a fresh one is created on demand.
final secondaryReaderProvider = StateNotifierProvider.autoDispose
    .family<SecondaryReaderNotifier, SecondaryReaderState, SecondaryReaderKey>(
  (ref, key) => SecondaryReaderNotifier(ref: ref, key: key),
);

/// The request a secondary stream makes first. Shared with the reader, which
/// fetches it ahead for a translation opened as itself.
TextDetailsParams secondaryInitialParams(SecondaryReaderKey key) =>
    TextDetailsParams(
      textId: key.textId,
      versionId: key.versionId,
      segmentId: key.initialSegmentId,
      direction: 'next',
      size: key.initialSize,
    );

/// The primary segment the secondary stream first aligns to: the plan's
/// target, else the verse at the top of the viewport (a stream enabled
/// mid-session), else the first loaded one. Null with nothing loaded.
String? secondaryInitialAnchor({
  required NavigationContext? navigationContext,
  required String? segmentId,
  required FlattenedContent? content,
  String? visibleSegmentId,
}) {
  if (navigationContext?.source == NavigationSource.plan && segmentId != null) {
    return segmentId;
  }
  if (content == null || content.isEmpty) return null;
  return visibleSegmentId ?? content.firstSegmentId;
}
