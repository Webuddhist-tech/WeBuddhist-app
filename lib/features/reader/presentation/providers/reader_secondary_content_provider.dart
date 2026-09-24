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
    final segments = _extractSegments(response.content.sections);
    state = state.copyWith(
      contentBySegmentNumber: _buildSegmentNumberMap(segments),
      loadedSegments: segments,
      totalSegments: response.totalSegments,
      isLoading: false,
      hasNextPage: response.hasNextPage,
      hasPreviousPage: response.currentSegmentPosition > 1,
    );
  }

  /// Extend the secondary forward by one page.
  Future<void> loadNext() async {
    if (_disposed || state.isLoadingNext || !state.hasNextPage) return;
    final lastId = state.lastLoadedSegmentId;
    if (lastId == null) return;

    state = state.copyWith(isLoadingNext: true);
    try {
      final response = await _fetch(segmentId: lastId, direction: 'next');
      if (_disposed) return;

      final newSegments = _extractSegments(response.content.sections);
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
        hasNextPage: response.hasNextPage,
        totalSegments: response.totalSegments,
      );
    } catch (e, st) {
      _logger.error('Secondary loadNext failed for ${key.versionId}', e, st);
      if (_disposed) return;
      state = state.copyWith(isLoadingNext: false);
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

      final newSegments = _extractSegments(response.content.sections);
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
        hasPreviousPage: response.currentSegmentPosition > 1,
      );
    } catch (e, st) {
      _logger.error('Secondary loadPrevious failed for ${key.versionId}', e, st);
      if (_disposed) return;
      state = state.copyWith(isLoadingPrevious: false);
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
