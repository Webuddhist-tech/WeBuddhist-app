import 'package:flutter_pecha/features/texts/data/models/segment.dart';

/// Identifies a secondary reader fetch by the (textId, versionId) pair.
///
/// `versionId` is required because the secondary stream is always pinned to
/// a specific text version chosen by the user from the reader settings.
///
/// `initialSegmentId` is a creation-time hint (e.g. align with primary when
/// navigating from plans) consumed once during the notifier's initial fetch.
/// It is intentionally excluded from `==`/`hashCode` so the Riverpod family
/// resolves the same notifier across rebuilds — otherwise viewport changes
/// would tear down and re-create the secondary provider on every scroll.
///
/// `initialSize` is part of identity: it is fixed per screen, and overlapping
/// readers (plan `pushReplacement`) must not share a differently sized window.
class SecondaryReaderKey {
  final String textId;
  final String versionId;
  final String? initialSegmentId;
  final int? initialSize;

  const SecondaryReaderKey({
    required this.textId,
    required this.versionId,
    this.initialSegmentId,
    this.initialSize,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SecondaryReaderKey &&
          other.textId == textId &&
          other.versionId == versionId &&
          other.initialSize == initialSize);

  @override
  int get hashCode => Object.hash(textId, versionId, initialSize);

  @override
  String toString() =>
      'SecondaryReaderKey(textId: $textId, versionId: $versionId, initialSegmentId: $initialSegmentId, initialSize: $initialSize)';
}

/// State for the secondary (translation/companion) text shown beneath the
/// primary in the interlinear reader.
///
/// Segments are aligned to the primary by `segment_number`, so the lookup
/// surface that the UI cares about is a `Map<int, String>` keyed by
/// segment_number. The full ordered `loadedSegments` list is also kept so
/// pagination can use the secondary's own `segment_id` boundaries.
class SecondaryReaderState {
  final Map<int, String> contentBySegmentNumber;
  final List<Segment> loadedSegments;
  final int totalSegments;
  final bool isLoading;
  final bool isLoadingNext;
  final bool isLoadingPrevious;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String? errorMessage;

  const SecondaryReaderState({
    this.contentBySegmentNumber = const {},
    this.loadedSegments = const [],
    this.totalSegments = 0,
    this.isLoading = false,
    this.isLoadingNext = false,
    this.isLoadingPrevious = false,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.errorMessage,
  });

  factory SecondaryReaderState.initial() => const SecondaryReaderState();

  bool get isAnyLoading => isLoading || isLoadingNext || isLoadingPrevious;

  String? get firstLoadedSegmentId =>
      loadedSegments.isEmpty ? null : loadedSegments.first.segmentId;

  String? get lastLoadedSegmentId =>
      loadedSegments.isEmpty ? null : loadedSegments.last.segmentId;

  String? contentFor(int segmentNumber) =>
      contentBySegmentNumber[segmentNumber];

  SecondaryReaderState copyWith({
    Map<int, String>? contentBySegmentNumber,
    List<Segment>? loadedSegments,
    int? totalSegments,
    bool? isLoading,
    bool? isLoadingNext,
    bool? isLoadingPrevious,
    bool? hasNextPage,
    bool? hasPreviousPage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SecondaryReaderState(
      contentBySegmentNumber:
          contentBySegmentNumber ?? this.contentBySegmentNumber,
      loadedSegments: loadedSegments ?? this.loadedSegments,
      totalSegments: totalSegments ?? this.totalSegments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingNext: isLoadingNext ?? this.isLoadingNext,
      isLoadingPrevious: isLoadingPrevious ?? this.isLoadingPrevious,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
