import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_item.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/data/models/secondary_reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_secondary_content_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/interlinear_segment_item.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/read_full_text_footer.dart';
// import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/section_header.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_item.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_skeleton.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Main content widget for the reader
/// Uses ScrollablePositionedList for efficient rendering and scrolling
class ReaderContentPart extends ConsumerStatefulWidget {
  final ReaderParams params;
  final String language;
  final String? initialSegmentId;
  final List<String>? visibleSegmentIds;
  final double bottomPadding;
  final void Function(bool isScrollingDown)? onScrollDirectionChanged;
  final void Function(void Function(String segmentId, {double? alignment}))?
  onScrollControllerReady;
  final void Function(VoidCallback scrollToTop)? onScrollToTopReady;
  final Widget? chantSessionFooter;

  const ReaderContentPart({
    super.key,
    required this.params,
    required this.language,
    this.initialSegmentId,
    this.visibleSegmentIds,
    this.bottomPadding = 60,
    this.onScrollDirectionChanged,
    this.onScrollControllerReady,
    this.onScrollToTopReady,
    this.chantSessionFooter,
  });

  @override
  ConsumerState<ReaderContentPart> createState() => _ReaderContentPartState();
}

class _ReaderContentPartState extends ConsumerState<ReaderContentPart> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final _logger = AppLogger('ReaderContent');

  Timer? _debounceTimer;
  bool _hasTriggeredPrevious = false;
  bool _hasTriggeredNext = false;
  bool _hasScrolledToInitial = false;
  int? _positionBeforePreviousLoad;

  // Scroll direction tracking
  double? _lastScrollOffset; // Nullable to detect first measurement
  bool _lastScrollDirection = false; // false = up, true = down

  // User gesture tracking - only track scroll direction when user is actively scrolling
  bool _isUserScrolling = false;
  bool _hasUserInteracted = false;
  bool _isProgrammaticScroll = false;

  // Collapsed view: when the reader opens pointing at a set of "active"
  // segments (plan subtask / deep-link / search target), it first renders ONLY
  // those segments followed by a "Read Full Text" footer. Tapping the footer
  // expands to the full text for the rest of the session — there is no way back
  // to the collapsed view without leaving and re-entering the reader.
  bool _isExpanded = false;

  /// Ordered list of segment ids considered "active" for this navigation: the
  /// plan subtask's segment range, or the single target segment.
  List<String> get _activeSegmentIds {
    final visible = widget.visibleSegmentIds;
    if (visible != null && visible.isNotEmpty) return visible;
    final initial = widget.initialSegmentId;
    if (initial != null) return [initial];
    return const [];
  }

  /// True when the reader was opened pointing at specific segments, so the
  /// collapsed "active segments only" view applies.
  bool get _hasActiveSegments => _activeSegmentIds.isNotEmpty;

  /// Match the primary's plan-sized first window so translations cover the
  /// whole active range, not just the first page of it.
  int? get _secondaryInitialSize =>
      widget.params.navigationContext?.initialPageSize;

  /// True while only the active segments are shown (before "Read Full Text").
  bool get _isCollapsed => _hasActiveSegments && !_isExpanded;

  // Initial alignment segment for the secondary stream. Computed lazily the
  // first time the secondary is needed, then frozen — the secondary notifier
  // only consumes it once during its initial fetch, so recomputing on every
  // build (and on every scroll) would be wasted work and would also defeat
  // Riverpod's family caching.
  String? _secondaryInitialSegmentId;
  bool _hasComputedSecondaryInitial = false;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onScrollPositionChanged);

    // Expose scroll controller to parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onScrollControllerReady?.call(_scrollToSegment);
      widget.onScrollToTopReady?.call(_scrollToTop);
    });
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(
      _onScrollPositionChanged,
    );
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScrollPositionChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(ReaderConstants.scrollDebounce, () {
      _checkPaginationThresholds();
    });

    // Track scroll direction for app bar visibility
    _trackScrollDirection();

    // Disable grey-out on first user scroll
    // if (_hasUserInteracted && _isUserScrolling && _enableGreyOut) {
    //   setState(() {
    //     _enableGreyOut = false;
    //   });
    // }
  }

  void _trackScrollDirection() {
    // Only track scroll direction for user-initiated scrolls
    if (_isProgrammaticScroll) return;
    if (!_hasUserInteracted) return;
    if (!_isUserScrolling) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Calculate approximate scroll offset based on first visible item
    final sortedPositions =
        positions.toList()..sort((a, b) => a.index.compareTo(b.index));
    final firstItem = sortedPositions.first;
    final currentOffset = firstItem.index + (1 - firstItem.itemLeadingEdge);

    // Initialize on first user scroll - don't trigger direction change
    if (_lastScrollOffset == null) {
      _lastScrollOffset = currentOffset;
      return;
    }

    // Determine scroll direction with a small threshold to avoid jitter
    const threshold = 0.5;
    if ((currentOffset - _lastScrollOffset!).abs() > threshold) {
      final isScrollingDown = currentOffset > _lastScrollOffset!;
      if (isScrollingDown != _lastScrollDirection) {
        _lastScrollDirection = isScrollingDown;
        widget.onScrollDirectionChanged?.call(isScrollingDown);
      }
      _lastScrollOffset = currentOffset;
    }
  }

  void _checkPaginationThresholds() {
    // No pagination while collapsed — only the active segments are on screen,
    // so the short list would otherwise immediately trip the next-page
    // threshold and fetch segments the user hasn't asked to see yet.
    if (_isCollapsed) return;
    // Skip pagination during programmatic scroll (e.g. initial scroll animation)
    // to prevent false triggers from stale visible positions
    if (_isProgrammaticScroll) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final sortedPositions =
        positions.toList()..sort((a, b) => a.index.compareTo(b.index));
    final firstVisibleIndex = sortedPositions.first.index;
    final lastVisibleIndex = sortedPositions.last.index;

    final state = ref.read(readerNotifierProvider(widget.params));
    final notifier = ref.read(readerNotifierProvider(widget.params).notifier);
    final totalItems = state.content?.itemCount ?? 0;

    // Check for previous page load
    if (firstVisibleIndex <= ReaderConstants.previousLoadThreshold &&
        state.hasPreviousPage &&
        !state.isLoadingPrevious &&
        !_hasTriggeredPrevious) {
      _hasTriggeredPrevious = true;
      _positionBeforePreviousLoad = firstVisibleIndex;
      _logger.debug(
        'Triggering previous page load at index $firstVisibleIndex',
      );
      notifier.loadPreviousPage().then((_) {
        _hasTriggeredPrevious = false;
        _adjustScrollAfterPreviousLoad();
        _maybeExtendSecondary(direction: PaginationDirection.previous);
      });
    }

    // Check for next page load
    if (lastVisibleIndex >= totalItems - ReaderConstants.nextLoadThreshold &&
        state.hasNextPage &&
        !state.isLoadingNext &&
        !_hasTriggeredNext) {
      _hasTriggeredNext = true;
      _logger.debug(
        'Triggering next page load at index $lastVisibleIndex/$totalItems',
      );
      notifier.loadNextPage().then((_) {
        _hasTriggeredNext = false;
        _maybeExtendSecondary(direction: PaginationDirection.next);
      });
    }
  }

  /// Resolve (and cache) the initial segment_id used to align the secondary
  /// stream when its notifier first loads:
  /// - From plan navigation: use widget.params.segmentId
  /// - Mid-session enable / version switch: use first visible segment from viewport
  /// - Otherwise: null (start from beginning)
  ///
  /// The value is computed once and frozen for the lifetime of this widget
  /// state — the secondary notifier only consumes it during its initial
  /// fetch, and Riverpod's family identity for `SecondaryReaderKey` ignores
  /// it, so recomputing on every build would be pointless work.
  String? _resolveSecondaryInitialSegmentId() {
    if (_hasComputedSecondaryInitial) return _secondaryInitialSegmentId;
    _hasComputedSecondaryInitial = true;

    final navContext = widget.params.navigationContext;
    if (navContext?.source == NavigationSource.plan &&
        widget.params.segmentId != null) {
      _secondaryInitialSegmentId = widget.params.segmentId;
      return _secondaryInitialSegmentId;
    }

    final state = ref.read(readerNotifierProvider(widget.params));
    final content = state.content;
    if (content == null || content.isEmpty) {
      _secondaryInitialSegmentId = null;
      return null;
    }

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      final topIndex = positions
          .where((pos) => pos.itemLeadingEdge >= 0 && pos.itemLeadingEdge < 1.0)
          .map((pos) => pos.index)
          .fold<int?>(
            null,
            (min, index) => min == null || index < min ? index : min,
          );

      if (topIndex != null && topIndex < content.itemCount) {
        final item = content.items[topIndex];
        if (item.isSegment && item.segmentId != null) {
          _secondaryInitialSegmentId = item.segmentId;
          return _secondaryInitialSegmentId;
        }
      }
    }

    _secondaryInitialSegmentId = content.firstSegmentId;
    return _secondaryInitialSegmentId;
  }

  /// Mirror primary pagination on the secondary stream (when enabled).
  /// We read the dual settings lazily so toggling the secondary mid-session
  /// is respected on the next page boundary.
  void _maybeExtendSecondary({required PaginationDirection direction}) {
    if (!mounted) return;
    final dualSettings = ref.read(
      readerDualSettingsProvider(widget.params.textId),
    );
    final versionId = dualSettings.secondary.versionId;
    if (!dualSettings.secondaryEnabled || versionId == null) return;

    // Secondary's path follows the primary's effective text_id: if the user
    // picked a different primary version, the secondary aligns against THAT
    // version, not the navigated URL's text_id.
    final effectivePrimaryTextId =
        dualSettings.primary.versionId ?? widget.params.textId;

    final notifier = ref.read(
      secondaryReaderProvider(
        SecondaryReaderKey(
          textId: effectivePrimaryTextId,
          versionId: versionId,
          initialSegmentId: _resolveSecondaryInitialSegmentId(),
          initialSize: _secondaryInitialSize,
        ),
      ).notifier,
    );
    if (direction == PaginationDirection.next) {
      notifier.loadNext();
    } else {
      notifier.loadPrevious();
    }
  }

  void _adjustScrollAfterPreviousLoad() {
    if (_positionBeforePreviousLoad == null) return;

    final state = ref.read(readerNotifierProvider(widget.params));
    final content = state.content;
    if (content == null) return;

    // Calculate how many items were added at the beginning
    // This is approximate - we adjust based on the position we were at
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemScrollController.isAttached &&
          _positionBeforePreviousLoad != null) {
        // Mark as programmatic scroll to avoid affecting app bar
        _isProgrammaticScroll = true;

        // Estimate the number of new items added
        // For simplicity, we'll use the page size as an approximation
        final newItemsCount = ReaderConstants.pageSize;
        final targetIndex = _positionBeforePreviousLoad! + newItemsCount;
        if (targetIndex >= 0 && targetIndex < content.itemCount) {
          _itemScrollController.jumpTo(index: targetIndex);
          _logger.debug(
            'Adjusted scroll after prepend: $targetIndex (added ~$newItemsCount items)',
          );
        }

        // Clear programmatic scroll flag after a short delay
        Future.delayed(const Duration(milliseconds: 100), () {
          _isProgrammaticScroll = false;
        });
      }
      _positionBeforePreviousLoad = null;
    });
  }

  void _scrollToTop() {
    if (!_itemScrollController.isAttached) return;

    _isProgrammaticScroll = true;
    _itemScrollController.jumpTo(index: 0);
    _logger.debug('Scrolled to top of reader content');
    Future.delayed(const Duration(milliseconds: 100), () {
      _isProgrammaticScroll = false;
    });
  }

  void _scrollToSegment(String segmentId, {double? alignment}) {
    final state = ref.read(readerNotifierProvider(widget.params));
    final content = state.content;
    if (content == null) {
      _logger.debug('No content available for scrolling');
      return;
    }

    final index = _renderedIndexForSegment(segmentId, content);
    if (index == null) {
      _logger.debug('Segment $segmentId not found in content');
      return;
    }

    if (_itemScrollController.isAttached) {
      // Mark as programmatic scroll to avoid affecting app bar
      _isProgrammaticScroll = true;

      _itemScrollController.scrollTo(
        index: index,
        duration: ReaderConstants.scrollAnimationDuration,
        curve: Curves.easeInOutCubic,
        alignment: alignment ?? ReaderConstants.scrollToSegmentAlignment,
      );
      _logger.debug('Scrolling to segment $segmentId at index $index');

      // Clear programmatic scroll flag after animation completes
      Future.delayed(
        ReaderConstants.scrollAnimationDuration +
            const Duration(milliseconds: 100),
        () {
          _isProgrammaticScroll = false;
        },
      );
    }
  }

  /// Resolves a segment id to its index in the list that is *currently
  /// rendered*. In the expanded view this is the full content index. In the
  /// collapsed ("Read Full Text") view only the active segments are rendered,
  /// so the full content index would point far past the short collapsed list
  /// and make [ScrollablePositionedList] overshoot/clamp — here we map to the
  /// segment's position within the collapsed list instead.
  int? _renderedIndexForSegment(String segmentId, FlattenedContent content) {
    if (!_isCollapsed) return content.getSegmentIndex(segmentId);

    final collapsedItems = _buildCollapsedItems(content);
    final index = collapsedItems.indexWhere(
      (item) => item.segmentId == segmentId,
    );
    return index >= 0 ? index : null;
  }

  /// Expand from the collapsed (active-segments-only) view to the full text.
  /// Keeps the active block in view by jumping to the first active segment in
  /// the now-full list, and re-enables normal pagination/scroll behaviour.
  void _expandFullText() {
    if (_isExpanded) return;
    final firstActiveId =
        _activeSegmentIds.isNotEmpty ? _activeSegmentIds.first : null;

    setState(() => _isExpanded = true);

    if (firstActiveId == null) return;
    // Suppress the one-shot initial-scroll effect so it doesn't also fire.
    _hasScrolledToInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_itemScrollController.isAttached) return;
      final content = ref.read(readerNotifierProvider(widget.params)).content;
      final index = content?.getSegmentIndex(firstActiveId);
      if (index == null) return;
      _isProgrammaticScroll = true;
      _itemScrollController.jumpTo(index: index);
      Future.delayed(const Duration(milliseconds: 100), () {
        _isProgrammaticScroll = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerNotifierProvider(widget.params));
    final notifier = ref.read(readerNotifierProvider(widget.params).notifier);
    final dualSettings = ref.watch(
      readerDualSettingsProvider(widget.params.textId),
    );

    // Subscribe to the secondary provider only when the user has enabled
    // the secondary AND picked a version. The autoDispose family means we
    // tear down + free memory the moment either condition stops holding.
    final secondaryVersionId = dualSettings.secondary.versionId;
    final secondaryActive =
        dualSettings.secondaryEnabled && secondaryVersionId != null;
    // Secondary's path follows the primary's effective text_id — when the
    // user changes the primary version, the secondary re-keys to fetch its
    // translation aligned against the new primary.
    final effectivePrimaryTextId =
        dualSettings.primary.versionId ?? widget.params.textId;
    final SecondaryReaderState? secondaryState =
        secondaryActive
            ? ref.watch(
              secondaryReaderProvider(
                SecondaryReaderKey(
                  textId: effectivePrimaryTextId,
                  versionId: secondaryVersionId,
                  initialSegmentId: _resolveSecondaryInitialSegmentId(),
                  initialSize: _secondaryInitialSize,
                ),
              ),
            )
            : null;

    // Handle initial scroll to segment. Skipped while collapsed — the active
    // segments already sit at the top of the collapsed list, and the content
    // indices used for scrolling don't line up with the filtered list anyway.
    if (!_isCollapsed &&
        !_hasScrolledToInitial &&
        state.content != null &&
        state.content!.isNotEmpty &&
        widget.initialSegmentId != null) {
      _hasScrolledToInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_itemScrollController.isAttached) {
          final index = state.content!.getSegmentIndex(
            widget.initialSegmentId!,
          );
          if (index != null) {
            _isProgrammaticScroll = true;
            // Short content at top: instant jump (no animation issues)
            // Otherwise: smooth scroll animation
            if (index <= 5 && !state.hasPreviousPage) {
              _itemScrollController.jumpTo(index: index);
              _logger.debug('Jumped to initial segment at index $index');
              Future.delayed(const Duration(milliseconds: 100), () {
                _isProgrammaticScroll = false;
              });
            } else {
              _itemScrollController.scrollTo(
                index: index,
                duration: ReaderConstants.scrollAnimationDuration,
                curve: Curves.easeInOutCubic,
                alignment: ReaderConstants.scrollToSegmentAlignment,
              );
              _logger.debug('Scrolled to initial segment at index $index');
              Future.delayed(
                ReaderConstants.scrollAnimationDuration +
                    const Duration(milliseconds: 100),
                () => _isProgrammaticScroll = false,
              );
            }
          }
        }
      });
    }

    final content = state.content;
    if (content == null || content.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Collapsed view: render only the active segments + a "Read Full Text"
    // footer. The extra trailing item is the footer.
    final bool isCollapsed = _isCollapsed;
    final List<FlattenedItem> collapsedItems =
        isCollapsed ? _buildCollapsedItems(content) : const [];
    final bool showChantFooter =
        !isCollapsed && widget.chantSessionFooter != null;
    final int listItemCount =
        isCollapsed
            ? collapsedItems.length + 1
            : content.itemCount + (showChantFooter ? 1 : 0);

    return Column(
      children: [
        // Loading previous indicator (never while collapsed)
        if (!isCollapsed && state.isLoadingPrevious)
          const SegmentSkeletonList(count: 1, linesPerSegment: 2),
        // Main content list with user gesture detection
        Expanded(
          child: Listener(
            onPointerDown: (_) {
              _isUserScrolling = true;
              _hasUserInteracted = true;
            },
            onPointerUp: (_) {
              Future.delayed(const Duration(milliseconds: 300), () {
                _isUserScrolling = false;
              });
            },
            onPointerCancel: (_) {
              _isUserScrolling = false;
            },
            child: ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              itemCount: listItemCount,
              padding: EdgeInsets.only(
                top: ReaderConstants.contentTopPadding,
                bottom: widget.bottomPadding,
              ),
              itemBuilder: (context, index) {
                if (isCollapsed) {
                  // Trailing item is the "Read Full Text" footer.
                  if (index >= collapsedItems.length) {
                    return ReadFullTextFooter(
                      textDetail: state.textDetail,
                      onReadFullText: _expandFullText,
                    );
                  }
                  return _buildItem(
                    item: collapsedItems[index],
                    state: state,
                    dualSecondaryEnabled: secondaryActive,
                    secondarySlot: dualSettings.secondary,
                    secondaryState: secondaryState,
                    onSegmentTap:
                        (segment) => notifier.toggleSegmentSelection(segment),
                  );
                }

                if (showChantFooter && index >= content.itemCount) {
                  return widget.chantSessionFooter!;
                }

                final item = content.getItemAt(index);
                if (item == null) return const SizedBox.shrink();

                return _buildItem(
                  item: item,
                  state: state,
                  dualSecondaryEnabled: secondaryActive,
                  secondarySlot: dualSettings.secondary,
                  secondaryState: secondaryState,
                  onSegmentTap:
                      (segment) => notifier.toggleSegmentSelection(segment),
                );
              },
            ),
          ),
        ),

        // Loading next indicator (never while collapsed)
        if (!isCollapsed && state.isLoadingNext)
          const SegmentSkeletonList(count: 1, linesPerSegment: 2),
      ],
    );
  }

  /// The subset of loaded items that are active segments, in reading order.
  /// Used to render the collapsed view before "Read Full Text" is tapped.
  List<FlattenedItem> _buildCollapsedItems(FlattenedContent content) {
    final activeSet = _activeSegmentIds.toSet();
    return content.items
        .where(
          (item) =>
              item.isSegment &&
              item.segmentId != null &&
              activeSet.contains(item.segmentId),
        )
        .toList();
  }

  Widget _buildItem({
    required FlattenedItem item,
    required ReaderState state,
    required bool dualSecondaryEnabled,
    required ReaderSlotConfig secondarySlot,
    required SecondaryReaderState? secondaryState,
    required void Function(Segment) onSegmentTap,
  }) {
    return item.when(
      header: (section, depth) => const SizedBox.shrink(),
      // header: (section, depth) {
      //   if (section.segments[0].segmentNumber == 1) {
      //     return SectionHeader(
      //       section: section,
      //       depth: depth,
      //       language: widget.language,
      //     );
      //   }
      //   return const SizedBox.shrink();
      // },
      segment: (segment, depth, sectionId) {
        final isSelected =
            state.selectedSegment?.segmentId == segment.segmentId;
        final isHighlighted = state.highlightedSegmentId == segment.segmentId;

        if (dualSecondaryEnabled) {
          return InterlinearSegmentItem(
            segment: segment,
            depth: depth,
            primaryLanguage: widget.language,
            secondarySlot: secondarySlot,
            secondaryContentBySegmentNumber:
                secondaryState?.contentBySegmentNumber,
            secondaryIsLoading: secondaryState?.isAnyLoading ?? false,
            isSelected: isSelected,
            isHighlighted: isHighlighted,
            highlightSource: state.highlightSource,
            onTap: () => onSegmentTap(segment),
          );
        }

        return SegmentItem(
          segment: segment,
          depth: depth,
          language: widget.language,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.lightImpact();
            onSegmentTap(segment);
          },
        );
      },
    );
  }
}
