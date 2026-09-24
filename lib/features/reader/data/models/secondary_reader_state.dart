import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';

/// A titled heading of the translation's table of contents, placed at the
/// first verse it holds; [endSegmentNumber] is the last one loaded so far.
class SecondaryHeading {
  final Section section;
  final int depth;
  final int segmentNumber;
  final int endSegmentNumber;

  const SecondaryHeading({
    required this.section,
    required this.depth,
    required this.segmentNumber,
    required this.endSegmentNumber,
  });

  bool holds(int number) =>
      segmentNumber <= number && number <= endSegmentNumber;
}

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

  /// The translation's headings by the verse they open at, outer first.
  final Map<int, List<SecondaryHeading>> headingsBySegmentNumber;
  final List<Segment> loadedSegments;
  final int totalSegments;
  final bool isLoading;
  final bool isLoadingNext;
  final bool isLoadingPrevious;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String? errorMessage;

  /// The last next/previous page failed; verses past the loaded ones then
  /// show their original instead of waiting.
  final bool pagingFailed;

  const SecondaryReaderState({
    this.contentBySegmentNumber = const {},
    this.headingsBySegmentNumber = const {},
    this.loadedSegments = const [],
    this.totalSegments = 0,
    this.isLoading = false,
    this.isLoadingNext = false,
    this.isLoadingPrevious = false,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.errorMessage,
    this.pagingFailed = false,
  });

  factory SecondaryReaderState.initial() => const SecondaryReaderState();

  bool get isAnyLoading => isLoading || isLoadingNext || isLoadingPrevious;

  /// True while the page holding [segmentNumber] is still on its way: the
  /// first page, or a verse past what has loaded in a direction the stream
  /// is loading or still has pages in (it catches up, see [needsToCover]).
  /// A verse the loaded pages skip is not pending.
  bool isPending(int segmentNumber) {
    if (isLoading) return true;
    if (loadedSegments.isEmpty) return isLoadingNext || isLoadingPrevious;
    if (segmentNumber > loadedSegments.last.segmentNumber) {
      return isLoadingNext || (hasNextPage && !pagingFailed);
    }
    if (segmentNumber < loadedSegments.first.segmentNumber) {
      return isLoadingPrevious || (hasPreviousPage && !pagingFailed);
    }
    return false;
  }

  /// True when the primary's verses [first]..[last] reach past what has
  /// loaded in a direction that still has pages, and nothing is in flight.
  bool needsToCover(int first, int last) {
    if (isAnyLoading || pagingFailed || loadedSegments.isEmpty) return false;
    return (hasPreviousPage && loadedSegments.first.segmentNumber > first) ||
        (hasNextPage && loadedSegments.last.segmentNumber < last);
  }

  /// True when the primary's verses [first]..[last] lie wholly outside the
  /// loaded ones (the primary jumped), and nothing is in flight. Paging
  /// would then have to walk the whole gap.
  bool isDetachedFrom(int first, int last) {
    if (isAnyLoading || loadedSegments.isEmpty) return false;
    return last < loadedSegments.first.segmentNumber ||
        first > loadedSegments.last.segmentNumber;
  }

  String? get firstLoadedSegmentId =>
      loadedSegments.isEmpty ? null : loadedSegments.first.segmentId;

  String? get lastLoadedSegmentId =>
      loadedSegments.isEmpty ? null : loadedSegments.last.segmentId;

  String? contentFor(int segmentNumber) =>
      contentBySegmentNumber[segmentNumber];

  /// Whose headings a page showing only this translation uses: its own when
  /// it has a table of contents, and none while its first page loads, so the
  /// original's never flash in. A translation without one keeps the
  /// original's rather than losing the structure.
  bool get headsTranslationOnly =>
      isLoading || headingsBySegmentNumber.isNotEmpty;

  /// The headings whose verses include [segmentNumber], outer first.
  List<SecondaryHeading> headingsEnclosing(int segmentNumber) => [
    for (final list in headingsBySegmentNumber.values)
      for (final heading in list)
        if (heading.holds(segmentNumber)) heading,
  ]..sort((a, b) => a.depth.compareTo(b.depth));

  SecondaryReaderState copyWith({
    Map<int, String>? contentBySegmentNumber,
    Map<int, List<SecondaryHeading>>? headingsBySegmentNumber,
    List<Segment>? loadedSegments,
    int? totalSegments,
    bool? isLoading,
    bool? isLoadingNext,
    bool? isLoadingPrevious,
    bool? hasNextPage,
    bool? hasPreviousPage,
    String? errorMessage,
    bool clearError = false,
    bool? pagingFailed,
  }) {
    return SecondaryReaderState(
      contentBySegmentNumber:
          contentBySegmentNumber ?? this.contentBySegmentNumber,
      headingsBySegmentNumber:
          headingsBySegmentNumber ?? this.headingsBySegmentNumber,
      loadedSegments: loadedSegments ?? this.loadedSegments,
      totalSegments: totalSegments ?? this.totalSegments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingNext: isLoadingNext ?? this.isLoadingNext,
      isLoadingPrevious: isLoadingPrevious ?? this.isLoadingPrevious,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pagingFailed: pagingFailed ?? this.pagingFailed,
    );
  }
}
