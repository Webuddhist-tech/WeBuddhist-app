import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_item.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/data/models/secondary_reader_state.dart';
import 'package:flutter_pecha/features/reader/domain/services/live_position_resolver.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_secondary_content_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/collapsed_reader_items.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_initial_layout_applier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/interlinear_segment_item.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/section_header.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_item.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_skeleton.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_live_position.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_live_notifier.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_info.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/segment_provider.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Main content widget for the reader
/// Uses ScrollablePositionedList for efficient rendering and scrolling
///
/// Shows one text, or a plan task's source texts one after another: each
/// source has its own reader and the list runs through them in order.
class ReaderContentPart extends ConsumerStatefulWidget {
  /// The texts shown, in order. One for a whole text; one per source of a
  /// plan task, each restricted to its verses.
  final List<ReaderParams> sources;
  final String? initialSegmentId;
  final double bottomPadding;
  final void Function(bool isScrollingDown)? onScrollDirectionChanged;
  final void Function(void Function(String segmentId, {double? alignment}))?
  onScrollControllerReady;
  final void Function(VoidCallback scrollToTop)? onScrollToTopReady;
  final Widget? chantSessionFooter;

  /// A segment of this source was tapped: the segment actions and panels
  /// follow that text.
  final ValueChanged<ReaderParams>? onSourceSelected;

  const ReaderContentPart({
    super.key,
    required this.sources,
    this.initialSegmentId,
    this.bottomPadding = 60,
    this.onScrollDirectionChanged,
    this.onScrollControllerReady,
    this.onScrollToTopReady,
    this.chantSessionFooter,
    this.onSourceSelected,
  }) : assert(sources.length > 0, 'at least one source is required');

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
  bool _hasScrolledToInitial = false;
  int? _positionBeforePreviousLoad;

  /// Sources whose reader is alive, from the first. The next one starts
  /// once the previous has every verse it shows.
  int _startedCount = 1;

  /// Sources with a next-page request in flight.
  final Set<int> _nextTriggered = {};

  /// Per source, task verses a fetched page did not bring: not in this
  /// edition, so they are not asked for again.
  final Map<int, Set<String>> _skippedSegmentIds = {};

  // Scroll direction tracking
  double? _lastScrollOffset; // Nullable to detect first measurement
  bool _lastScrollDirection = false; // false = up, true = down

  // User gesture tracking - only track scroll direction when user is actively scrolling
  bool _isUserScrolling = false;
  bool _hasUserInteracted = false;
  bool _isProgrammaticScroll = false;

  /// Collapsed view: a plan task's verses of each source, read in turn and
  /// loaded forward from the first; never the text around them.
  bool get _isCollapsed =>
      widget.sources.length > 1 || widget.sources.first.isCollapsed;

  /// Source [index]'s verses in the loaded text's ids: a translation opened
  /// under its original has navigation's ids mapped across
  /// ([ReaderState.segmentAliases]). Empty when the whole text is shown.
  List<String> _activeSegmentIdsOf(int index, ReaderState state) {
    final ids = widget.sources[index].segmentIds;
    if (ids == null || ids.isEmpty) return const [];
    return ids.map(state.loadedSegmentId).toList(growable: false);
  }

  // Initial alignment segment for each secondary stream. Computed lazily the
  // first time the secondary is needed, then frozen — the secondary notifier
  // only consumes it once during its initial fetch, so recomputing on every
  // build (and on every scroll) would be wasted work and would also defeat
  // Riverpod's family caching.
  final Map<int, String?> _secondaryInitialSegmentId = {};
  final Set<int> _hasComputedSecondaryInitial = {};
  final Set<int> _secondarySyncScheduled = {};

  // Live recitation (event puja). The operator's position arrives over the
  // socket held by [recitationLiveProvider]; this widget places it in the
  // loaded texts, scrolls to it while following, and paints the highlight.
  String? get _liveEventId => widget.sources.first.navigationContext?.eventId;
  bool get _isLiveRecitation =>
      widget.sources.first.navigationContext?.isLiveRecitation ?? false;

  /// Rendered index of the live line, for the scrolled-away check.
  int? _liveIndex;
  bool _liveInitialized = false;
  bool _liveJumpInFlight = false;
  RecitationLiveState? _livePending;
  int _liveGeneration = 0;

  /// Operator segment id to this version's id, for live positions read from
  /// another edition or language (see [ReaderNotifier.resolveSegment]).
  final Map<String, String> _liveAliases = {};
  DateTime? _lastUserPointerAt;

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
      _reportFurthestSegment();
    });

    // Track scroll direction for app bar visibility
    _trackScrollDirection();

    if (_isLiveRecitation) _maybePauseLiveFollow();
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

  // ─── Sources and the rendered list ───────────────────────────────────────

  /// Source [index] as the list draws it, read outside build.
  _SourceView _readView(int index) {
    final params = widget.sources[index];
    final state = ref.read(readerNotifierProvider(params));
    return _SourceView(
      index: index,
      params: params,
      state: state,
      items: _itemsOf(index, state),
      dualSettings: ref.read(readerDualSettingsProvider(params.settingsScope)),
    );
  }

  /// The items of source [index] from [state]: its task verses under the
  /// headings that enclose them, or the whole loaded text.
  List<FlattenedItem> _itemsOf(int index, ReaderState state) {
    final content = state.content;
    if (content == null) return const [];
    final active = _activeSegmentIdsOf(index, state);
    if (active.isEmpty) return content.items;
    return collapsedReaderItems(content, active.toSet());
  }

  List<_Entry> _currentEntries() => _entriesFor([
    for (var i = 0; i < _startedCount; i++) _readView(i),
  ]);

  /// The list, source after source: a rule before each one after the first,
  /// its title when its headings do not carry one, its items, or its retry
  /// row when it failed. A source still loading its first page adds
  /// nothing; the tail skeleton stands in for it.
  List<_Entry> _entriesFor(List<_SourceView> views) {
    final entries = <_Entry>[];
    for (final view in views) {
      final items = view.items;
      if (view.index > 0) {
        if (items.isEmpty && !view.state.isError) continue;
        entries.add(_Entry.divider(view.index));
      }
      if (view.state.isError) {
        entries.add(_Entry.error(view.index));
        continue;
      }
      if (views.length > 1 && items.isNotEmpty && !_startsWithTitle(items)) {
        entries.add(_Entry.title(view.index));
      }
      for (var i = 0; i < items.length; i++) {
        entries.add(
          _Entry.item(view.index, items[i], i > 0 ? items[i - 1] : null),
        );
      }
    }
    if (!_isCollapsed && widget.chantSessionFooter != null) {
      entries.add(const _Entry.footer());
    }
    return entries;
  }

  static bool _startsWithTitle(List<FlattenedItem> items) {
    final first = items.first;
    return first.isHeader && (first.section?.title?.isNotEmpty ?? false);
  }

  /// Index in [entries] of [segmentId], within [source] when given.
  int? _entryIndexForSegment(
    List<_Entry> entries,
    String segmentId, {
    int? source,
  }) {
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.item?.segmentId == segmentId &&
          (source == null || entry.source == source)) {
        return i;
      }
    }
    return null;
  }

  // ─── Pagination ──────────────────────────────────────────────────────────

  void _checkPaginationThresholds() {
    if (!mounted) return;
    // Skip pagination during programmatic scroll (e.g. initial scroll animation)
    // to prevent false triggers from stale visible positions
    if (_isProgrammaticScroll) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final sortedPositions =
        positions.toList()..sort((a, b) => a.index.compareTo(b.index));
    final firstVisibleIndex = sortedPositions.first.index;
    final lastVisibleIndex = sortedPositions.last.index;
    final totalItems = _currentEntries().length;

    if (_isCollapsed) {
      _loadForward(lastVisibleIndex, totalItems);
      return;
    }

    final params = widget.sources.first;
    final state = ref.read(readerNotifierProvider(params));
    final notifier = ref.read(readerNotifierProvider(params).notifier);

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
      });
    }

    // Check for next page load
    if (lastVisibleIndex >= totalItems - ReaderConstants.nextLoadThreshold &&
        state.hasNextPage &&
        !state.isLoadingNext &&
        !_nextTriggered.contains(0)) {
      _logger.debug(
        'Triggering next page load at index $lastVisibleIndex/$totalItems',
      );
      _loadNext(0);
    }
  }

  /// Near the end of the list: the last started source fetches its next
  /// verses, and once it has them all the next source starts.
  void _loadForward(int lastVisibleIndex, int totalItems) {
    if (lastVisibleIndex < totalItems - ReaderConstants.nextLoadThreshold) {
      return;
    }
    final index = _startedCount - 1;
    final state = ref.read(readerNotifierProvider(widget.sources[index]));
    final content = state.content;
    if (state.status != ReaderStatus.loaded || content == null) return;
    if (state.isLoadingNext || _nextTriggered.contains(index)) return;

    final active = _activeSegmentIdsOf(index, state);
    final missing = nextSegmentToLoad(
      content,
      active,
      skipped: _skippedSegmentIds[index] ?? const {},
    );
    final wantsMore =
        state.hasNextPage && (active.isEmpty || missing != null);
    if (wantsMore) {
      _logger.debug('Loading source $index forward from ${missing ?? 'end'}');
      _loadNext(index, fromSegmentId: missing);
      return;
    }
    if (_startedCount < widget.sources.length) {
      setState(() => _startedCount++);
    }
  }

  /// Fetches source [index]'s next page, at [fromSegmentId] when given. A
  /// page that arrives without that verse means the edition lacks it: it
  /// is skipped and the search moves on.
  void _loadNext(int index, {String? fromSegmentId}) {
    _nextTriggered.add(index);
    final params = widget.sources[index];
    ref
        .read(readerNotifierProvider(params).notifier)
        .loadNextPage(fromSegmentId: fromSegmentId)
        .then((merged) {
          _nextTriggered.remove(index);
          if (!mounted || !merged || fromSegmentId == null) return;
          final content = ref.read(readerNotifierProvider(params)).content;
          if (content == null || content.containsSegment(fromSegmentId)) return;
          _logger.debug('Segment $fromSegmentId not in source $index');
          (_skippedSegmentIds[index] ??= {}).add(fromSegmentId);
          _checkPaginationThresholds();
        });
  }

  /// The deepest line on screen, for the session's reading depth.
  void _reportFurthestSegment() {
    if (!mounted) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final entries = _currentEntries();
    final furthest = <int, int>{};
    for (final position in positions) {
      if (position.index >= entries.length) continue;
      final entry = entries[position.index];
      final number = entry.item?.segment?.segmentNumber;
      if (number == null) continue;
      if (number > (furthest[entry.source] ?? 0)) {
        furthest[entry.source] = number;
      }
    }
    furthest.forEach((source, number) {
      ref
          .read(readerNotifierProvider(widget.sources[source]).notifier)
          .markSegmentReached(number);
    });
  }

  // ─── Secondary stream ────────────────────────────────────────────────────

  /// The primary segment source [index]'s secondary stream first aligns to
  /// ([secondaryInitialAnchor]), computed once: the notifier only consumes
  /// it during its initial fetch, and `SecondaryReaderKey` identity ignores
  /// it, so recomputing on every build would be pointless work.
  String? _resolveSecondaryInitialSegmentId(int index) {
    if (_hasComputedSecondaryInitial.contains(index)) {
      return _secondaryInitialSegmentId[index];
    }
    _hasComputedSecondaryInitial.add(index);
    final params = widget.sources[index];
    final content = ref.read(readerNotifierProvider(params)).content;
    return _secondaryInitialSegmentId[index] = secondaryInitialAnchor(
      navigationContext: params.navigationContext,
      segmentId: params.segmentId,
      content: content,
      visibleSegmentId: _topVisibleSegmentIdOf(index, content),
    );
  }

  /// The verse of source [index] at the top of the viewport, for a stream
  /// enabled mid-session.
  String? _topVisibleSegmentIdOf(int index, FlattenedContent? content) {
    if (content == null || content.isEmpty) return null;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return null;
    final entries = _currentEntries();
    int? topIndex;
    for (final position in positions) {
      if (position.itemLeadingEdge < 0 || position.itemLeadingEdge >= 1.0) {
        continue;
      }
      if (position.index >= entries.length) continue;
      final entry = entries[position.index];
      if (entry.source != index || !(entry.item?.isSegment ?? false)) continue;
      if (topIndex == null || position.index < topIndex) {
        topIndex = position.index;
      }
    }
    return topIndex == null ? null : entries[topIndex].item!.segmentId;
  }

  /// Has source [index]'s secondary stream page until it spans the primary's
  /// loaded verses, or start over there when the primary jumped clear of
  /// them. Scheduled from build whenever it falls short, so it follows every
  /// primary change: first load, pages either way, a jump.
  void _scheduleSecondarySync(int index, SecondaryReaderState? secondary) {
    if (_secondarySyncScheduled.contains(index) || secondary == null) return;
    final range =
        ref
            .read(readerNotifierProvider(widget.sources[index]))
            .content
            ?.segmentNumberRange;
    if (range == null ||
        !(secondary.needsToCover(range.$1, range.$2) ||
            secondary.isDetachedFrom(range.$1, range.$2))) {
      return;
    }
    _secondarySyncScheduled.add(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _secondarySyncScheduled.remove(index);
      _syncSecondary(index);
    });
  }

  void _syncSecondary(int index) {
    if (!mounted) return;
    final params = widget.sources[index];
    final content = ref.read(readerNotifierProvider(params)).content;
    final range = content?.segmentNumberRange;
    if (range == null) return;
    final dualSettings = ref.read(
      readerDualSettingsProvider(params.settingsScope),
    );
    final versionId = dualSettings.secondary.versionId;
    if (!dualSettings.secondaryEnabled || versionId == null) return;

    // Secondary's path follows the primary's effective text_id: if the user
    // picked a different primary version, the secondary aligns against THAT
    // version, not the navigated URL's text_id.
    final effectivePrimaryTextId =
        dualSettings.primary.versionId ?? params.textId;

    final notifier = ref.read(
      secondaryReaderProvider(
        SecondaryReaderKey(
          textId: effectivePrimaryTextId,
          versionId: versionId,
          initialSegmentId: _resolveSecondaryInitialSegmentId(index),
        ),
      ).notifier,
    );
    notifier.cover(
      range.$1,
      range.$2,
      anchorSegmentId: content?.firstSegmentId,
    );
  }

  // ─── Scrolling ───────────────────────────────────────────────────────────

  void _adjustScrollAfterPreviousLoad() {
    // Runs after an earlier page loads, which can finish after the reader
    // was closed. There is nothing left to scroll, and `ref` is unusable.
    if (!mounted || _positionBeforePreviousLoad == null) return;

    final state = ref.read(readerNotifierProvider(widget.sources.first));
    final content = state.content;
    if (content == null) return;

    // Calculate how many items were added at the beginning
    // This is approximate - we adjust based on the position we were at
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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

  /// Selects [segment] of source [index], the only source with a selection.
  /// A plan task with commentary or versions set to open does that here
  /// once the segment's counts arrive, and the verse is brought to the top
  /// the way those buttons do. Closing that sheet leaves the segment
  /// selected, so the resources sheet is what's left.
  void _onSegmentTap(int index, Segment segment) {
    final params = widget.sources[index];
    for (var i = 0; i < _startedCount; i++) {
      if (i == index) continue;
      final other = ref.read(readerNotifierProvider(widget.sources[i]).notifier);
      other.selectSegment(null);
      other.closeCommentary();
      other.closeTranslation();
    }
    widget.onSourceSelected?.call(params);
    final notifier = ref.read(readerNotifierProvider(params).notifier);
    final before = ref.read(readerNotifierProvider(params));
    final deselecting = before.selectedSegment?.segmentId == segment.segmentId;
    notifier.toggleSegmentSelection(segment);
    if (deselecting) return;

    final item = params.navigationContext?.currentItem;
    if (item == null ||
        (!item.autoOpenCommentary && !item.autoOpenTranslation)) {
      return;
    }
    _autoOpenPlanPanel(index, segment.segmentId);
  }

  /// A segment with no commentaries or versions does not get an empty sheet.
  /// A failed count is not a zero: the sheet opens and shows its own error.
  Future<void> _autoOpenPlanPanel(int index, String segmentId) async {
    SegmentInfo? info;
    try {
      info = await ref.read(segmentInfoFutureProvider(segmentId).future);
    } catch (e, st) {
      _logger.warning('Segment info for $segmentId not loaded', e, st);
    }
    if (!mounted) return;
    final opened = ref
        .read(readerNotifierProvider(widget.sources[index]).notifier)
        .autoOpenPlanPanel(
          segmentId,
          hasCommentaries: info == null || info.relatedText.commentaries > 0,
          hasVersions: info == null || info.translations > 0,
        );
    if (opened) _scrollToSegment(segmentId, alignment: 0.0);
  }

  void _scrollToSegment(String segmentId, {double? alignment}) {
    final index = _entryIndexForSegment(_currentEntries(), segmentId);
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

  // ─── Live recitation ─────────────────────────────────────────────────────

  void _onLiveStateChanged(
    RecitationLiveState? previous,
    RecitationLiveState next,
  ) {
    if (!mounted || next.position == null) return;
    final positionChanged = previous?.position != next.position;
    final followRequested = previous?.followRequest != next.followRequest;
    if (positionChanged || followRequested) unawaited(_applyLive(next));
  }

  /// True when [position] is in a text on this page: one of the started
  /// sources holds it, or a source names the operator's text.
  bool _livePositionIsInThisText(RecitationLivePosition position) {
    for (var i = 0; i < widget.sources.length; i++) {
      final params = widget.sources[i];
      if (params.textId == position.textId) return true;
      if (i >= _startedCount) continue;
      final readerState = ref.read(readerNotifierProvider(params));
      final dualSettings = ref.read(
        readerDualSettingsProvider(params.settingsScope),
      );
      final content = readerState.content;
      if (LivePositionResolver.textMatches(
            position,
            loadedTextIds: [
              readerState.textDetail?.id,
              dualSettings.primary.versionId,
            ],
            content: content,
          ) ||
          (content != null &&
              _localSegmentIdFor(content, position.segmentId) != null)) {
        return true;
      }
    }
    return false;
  }

  /// This text's own id for the live segment: the id itself, the line whose
  /// `mappings` name it, or the verse it was aligned to (the same line in
  /// another edition or language).
  String? _localSegmentIdFor(FlattenedContent content, String segmentId) {
    final alias = _liveAliases[segmentId];
    final index =
        content.resolveSegmentIndex(segmentId) ??
        (alias == null ? null : content.resolveSegmentIndex(alias));
    return index == null ? null : content.items[index].segmentId;
  }

  /// The started source holding [position] and its local id, if loaded.
  (int, String)? _locateLive(RecitationLivePosition position) {
    for (var i = 0; i < _startedCount; i++) {
      final content = ref.read(readerNotifierProvider(widget.sources[i])).content;
      if (content == null) continue;
      final local = _localSegmentIdFor(content, position.segmentId);
      if (local != null) return (i, local);
    }
    return null;
  }

  /// Local id of the line to highlight, or null when it is not in the loaded
  /// content or the user opted out. Also records its rendered index.
  String? _resolveLiveHighlight(
    List<_SourceView> views,
    List<_Entry> entries,
    RecitationLivePosition? position,
    RecitationLiveFollowMode mode,
  ) {
    if (position == null || mode == RecitationLiveFollowMode.off) {
      _liveIndex = null;
      return null;
    }
    for (final view in views) {
      final content = view.state.content;
      if (content == null) continue;
      final localId = _localSegmentIdFor(content, position.segmentId);
      if (localId == null) continue;
      _liveIndex = _entryIndexForSegment(entries, localId, source: view.index);
      return localId;
    }
    _liveIndex = null;
    return null;
  }

  /// Places [live]'s position in this page's texts and, while following,
  /// scrolls to it. [initial] marks the first evaluation after mount.
  Future<void> _applyLive(
    RecitationLiveState live, {
    bool initial = false,
  }) async {
    final position = live.position;
    if (!mounted || position == null) return;
    final eventId = _liveEventId!;
    final liveNotifier = ref.read(recitationLiveProvider(eventId).notifier);

    if (!live.isFollowing) return;
    if (!_livePositionIsInThisText(position)) {
      final items = widget.sources.first.navigationContext?.planTextItems;
      final inSequence =
          items?.any((item) => item.hasSourceText(position.textId)) ?? false;
      if (inSequence) {
        if (initial) {
          // Another text of the sequence, already live before this screen had
          // rendered: the user navigated here themselves, so stop following
          // rather than bounce them away.
          liveNotifier.pauseFollowing();
        }
        // A snapshot on another text falls through: the screen leaves the
        // user where they are (reader_screen skips the switch for it) but
        // keeps following, so the operator's next move carries them along.
        // Nothing marks a frame as the connect snapshot, so it is inferred
        // from arriving before the grace window closes — an operator's first
        // move into that window looks identical. Pausing here would strand
        // such a user off the recitation until they re-armed Sync by hand.
        return;
      }
      // Possibly another edition or language of this text, whose ids match
      // nothing loaded here: the load below aligns it by verse, and reports
      // out of sync when the texts are unrelated.
    }

    final generation = ++_liveGeneration;
    var located = _locateLive(position);
    if (located == null) {
      // Outside the fetched window: load it first. A position arriving
      // meanwhile is applied once this fetch settles.
      if (_liveJumpInFlight) {
        _livePending = live;
        return;
      }
      _liveJumpInFlight = true;
      try {
        located = await _loadLive(position);
      } finally {
        _liveJumpInFlight = false;
      }
      if (!mounted) return;
      final pending = _livePending;
      _livePending = null;
      if (pending != null) {
        unawaited(_applyLive(pending));
        return;
      }
      if (generation != _liveGeneration) return;
      if (located == null) {
        liveNotifier.setOutOfSync(true);
        return;
      }
      // Let the list take the new verses before scrolling into them.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || generation != _liveGeneration) return;
      located = _locateLive(position);
      if (located == null) {
        liveNotifier.setOutOfSync(true);
        return;
      }
    }
    liveNotifier.setOutOfSync(!_scrollToLiveSegment(located.$1, located.$2));
  }

  /// Brings [position] into a loaded text and returns where it landed. A
  /// collapsed page follows it only within a source's own verses, loading
  /// forward to them and starting the source that names the operator's text;
  /// a whole text loads the page around it.
  Future<(int, String)?> _loadLive(RecitationLivePosition position) async {
    if (!_isCollapsed) {
      final notifier = ref.read(
        readerNotifierProvider(widget.sources.first).notifier,
      );
      final jumpedTo = await notifier.jumpToSegment(
        position.segmentId,
        sourceTextId: position.textId,
      );
      if (!mounted || jumpedTo == null) return null;
      _rememberLiveAlias(position.segmentId, jumpedTo);
      return (0, jumpedTo);
    }

    for (var i = 0; i < widget.sources.length; i++) {
      final params = widget.sources[i];
      if (i >= _startedCount) {
        // Only a source naming the operator's text is worth starting early.
        if (params.textId != position.textId) continue;
        setState(() => _startedCount = i + 1);
        // The reader is created by the next build; read it after that.
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return null;
        if (await _awaitLoaded(params) == null) return null;
        if (!mounted) return null;
      }
      final notifier = ref.read(readerNotifierProvider(params).notifier);
      final local = await notifier.resolveSegment(
        position.segmentId,
        sourceTextId: position.textId,
      );
      if (!mounted) return null;
      if (local == null) continue;
      var state = ref.read(readerNotifierProvider(params));
      final active = _activeSegmentIdsOf(i, state);
      if (active.isNotEmpty && !active.contains(local)) continue;
      if (state.content?.containsSegment(local) != true) {
        if (!await notifier.loadNextPage(fromSegmentId: local)) continue;
        if (!mounted) return null;
        state = ref.read(readerNotifierProvider(params));
      }
      final content = state.content;
      if (content == null) continue;
      final found = _localSegmentIdFor(content, local);
      if (found == null) continue;
      _rememberLiveAlias(position.segmentId, found);
      return (i, found);
    }
    return null;
  }

  /// Rebuild so the highlight, which reads the alias, lands on it too.
  void _rememberLiveAlias(String segmentId, String localId) {
    if (segmentId == localId || _liveAliases[segmentId] == localId) return;
    setState(() => _liveAliases[segmentId] = localId);
  }

  /// [params]'s state once its first page is in; null when it failed.
  Future<ReaderState?> _awaitLoaded(ReaderParams params) async {
    bool settled(ReaderState s) => s.status == ReaderStatus.loaded || s.isError;
    var state = ref.read(readerNotifierProvider(params));
    if (!settled(state)) {
      try {
        state = await ref
            .read(readerNotifierProvider(params).notifier)
            .stream
            .firstWhere(settled)
            .timeout(const Duration(seconds: 30));
      } catch (e) {
        _logger.debug('Source ${params.textId} did not load for live: $e');
        return null;
      }
    }
    return state.isError ? null : state;
  }

  /// Scrolls to the rendered line [segmentId] of [source]; false when it is
  /// not on this page (a verse outside the task's).
  bool _scrollToLiveSegment(int source, String segmentId) {
    final index = _entryIndexForSegment(
      _currentEntries(),
      segmentId,
      source: source,
    );
    if (index == null) return false;
    if (!_itemScrollController.isAttached) return true;

    _isProgrammaticScroll = true;
    _itemScrollController.scrollTo(
      index: index,
      duration: ReaderConstants.scrollAnimationDuration,
      curve: Curves.easeInOutCubic,
      alignment: ReaderConstants.liveFollowAlignment,
    );
    Future.delayed(
      ReaderConstants.scrollAnimationDuration +
          const Duration(milliseconds: 100),
      () {
        _isProgrammaticScroll = false;
        // Pull the next page in at the operator's pace, not the user's.
        if (mounted) _checkPaginationThresholds();
      },
    );
    return true;
  }

  /// A user scroll that takes the live line off screen ends follow mode; a
  /// nudge that keeps it visible does not.
  void _maybePauseLiveFollow() {
    if (_isProgrammaticScroll || !_recentUserGesture) return;
    final liveIndex = _liveIndex;
    final eventId = _liveEventId;
    if (liveIndex == null || eventId == null) return;
    if (!ref.read(recitationLiveProvider(eventId)).isFollowing) return;

    final visible = _itemPositionsListener.itemPositions.value.any(
      (p) =>
          p.index == liveIndex &&
          p.itemTrailingEdge > 0 &&
          p.itemLeadingEdge < 1,
    );
    if (!visible) {
      ref.read(recitationLiveProvider(eventId).notifier).pauseFollowing();
    }
  }

  /// True while a finger is down or a fling from one is still running.
  bool get _recentUserGesture {
    if (_isUserScrolling) return true;
    final at = _lastUserPointerAt;
    return at != null &&
        DateTime.now().difference(at) < const Duration(seconds: 2);
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  /// Source [index] as the list draws it, watched in build.
  _SourceView _watchView(int index) {
    final params = widget.sources[index];
    final state = ref.watch(readerNotifierProvider(params));
    final dualSettings = ref.watch(
      readerDualSettingsProvider(params.settingsScope),
    );

    // Subscribe to the secondary provider only when the user has enabled
    // the secondary AND picked a version. The autoDispose family means we
    // tear down + free memory the moment either condition stops holding.
    final secondaryVersionId = dualSettings.secondary.versionId;
    final secondaryActive =
        dualSettings.secondaryEnabled && secondaryVersionId != null;
    // "Translation only": the original can hide behind an active translation,
    // never on its own — and each verse still shows it until that verse's
    // translation has actually arrived (see interlinearLayers).
    final showOriginal = dualSettings.originalVisible || !secondaryActive;
    // Secondary's path follows the primary's effective text_id — when the
    // user changes the primary version, the secondary re-keys to fetch its
    // translation aligned against the new primary.
    final effectivePrimaryTextId =
        dualSettings.primary.versionId ?? params.textId;
    final SecondaryReaderState? secondaryState =
        secondaryActive
            ? ref.watch(
              secondaryReaderProvider(
                SecondaryReaderKey(
                  textId: effectivePrimaryTextId,
                  versionId: secondaryVersionId,
                  initialSegmentId: _resolveSecondaryInitialSegmentId(index),
                ),
              ),
            )
            : null;
    _scheduleSecondarySync(index, secondaryState);

    final items = _itemsOf(index, state);
    final collapsed = _activeSegmentIdsOf(index, state).isNotEmpty;
    return _SourceView(
      index: index,
      params: params,
      state: state,
      items: items,
      dualSettings: dualSettings,
      secondaryActive: secondaryActive,
      showOriginal: showOriginal,
      secondaryState: secondaryState,
      collapsedHeadings:
          collapsed && secondaryState != null
              ? collapsedTranslationHeadings(items, secondaryState)
              : null,
    );
  }

  /// Handle initial scroll to segment. Skipped while collapsed — the first
  /// source's verses already sit at the top of the list.
  void _scheduleInitialScroll(ReaderState state) {
    final content = state.content;
    final initialSegmentId = widget.initialSegmentId;
    if (_isCollapsed ||
        _hasScrolledToInitial ||
        content == null ||
        content.isEmpty ||
        initialSegmentId == null) {
      return;
    }
    _hasScrolledToInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_itemScrollController.isAttached) return;
      final index = content.getSegmentIndex(
        state.loadedSegmentId(initialSegmentId),
      );
      if (index == null) return;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    RecitationLivePosition? livePosition;
    var liveMode = RecitationLiveFollowMode.off;
    final liveEventId = _liveEventId;
    if (_isLiveRecitation && liveEventId != null) {
      ref.listen<RecitationLiveState>(
        recitationLiveProvider(liveEventId),
        _onLiveStateChanged,
      );
      final live = ref.watch(
        recitationLiveProvider(
          liveEventId,
        ).select((s) => (s.position, s.followMode)),
      );
      livePosition = live.$1;
      liveMode = live.$2;
    }

    final views = [for (var i = 0; i < _startedCount; i++) _watchView(i)];
    final first = views.first;
    _scheduleInitialScroll(first.state);

    final content = first.state.content;
    if (content == null || content.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // First live evaluation once content is on screen: lands a late joiner
    // on the live line, or pauses if they opened a different text.
    if (_isLiveRecitation && liveEventId != null && !_liveInitialized) {
      _liveInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          _applyLive(
            ref.read(recitationLiveProvider(liveEventId)),
            initial: true,
          ),
        );
      });
    }

    final entries = _entriesFor(views);
    final liveSegmentId = _resolveLiveHighlight(
      views,
      entries,
      livePosition,
      liveMode,
    );
    final tail = views.last.state;
    final isLoadingTail =
        tail.isLoadingNext ||
        (views.length > 1 && !tail.hasContent && !tail.isError);

    return Column(
      children: [
        // Loading previous indicator (never while collapsed)
        if (!_isCollapsed && first.state.isLoadingPrevious)
          const SegmentSkeletonList(count: 1, linesPerSegment: 2),
        // Main content list with user gesture detection. Keyed so the
        // skeletons and setups coming and going never recreate it, which
        // would drop the scroll position.
        Expanded(
          key: const ValueKey('reader-content-list'),
          child: Listener(
            onPointerDown: (_) {
              _isUserScrolling = true;
              _hasUserInteracted = true;
              _lastUserPointerAt = DateTime.now();
            },
            onPointerMove: (_) => _lastUserPointerAt = DateTime.now(),
            onPointerUp: (_) {
              _lastUserPointerAt = DateTime.now();
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
              itemCount: entries.length,
              padding: EdgeInsets.only(
                top: ReaderConstants.contentTopPadding,
                bottom: widget.bottomPadding,
              ),
              itemBuilder:
                  (context, index) =>
                      _buildEntry(entries[index], views, liveSegmentId),
            ),
          ),
        ),
        // Loading next indicator: a page, or the next source's first one
        if (isLoadingTail)
          const SegmentSkeletonList(count: 1, linesPerSegment: 2),
        // One per distinct text: two sources naming the same verses of a
        // text share a reader, and would share a key.
        for (final params in {for (final view in views) view.params})
          _ReaderSourceSetup(key: ValueKey(params), params: params),
      ],
    );
  }

  Widget _buildEntry(
    _Entry entry,
    List<_SourceView> views,
    String? liveSegmentId,
  ) {
    switch (entry.kind) {
      case _EntryKind.divider:
        return const _SourceDivider();
      case _EntryKind.title:
        final view = views[entry.source];
        return _SourceTitle(
          title: view.state.openedText?.title ?? '',
          language: view.language,
        );
      case _EntryKind.error:
        return _SourceErrorRow(
          onRetry:
              () =>
                  ref
                      .read(
                        readerNotifierProvider(
                          widget.sources[entry.source],
                        ).notifier,
                      )
                      .reload(),
        );
      case _EntryKind.footer:
        return widget.chantSessionFooter!;
      case _EntryKind.item:
        return _buildItem(
          view: views[entry.source],
          item: entry.item!,
          previousItem: entry.previous,
          liveSegmentId: liveSegmentId,
        );
    }
  }

  Widget _buildItem({
    required _SourceView view,
    required FlattenedItem item,
    FlattenedItem? previousItem,
    String? liveSegmentId,
  }) {
    final state = view.state;
    final language = view.language;
    final secondaryState = view.secondaryState;
    final secondarySlot = view.dualSettings.secondary;
    // Set in the collapsed view: the translation's headings per verse id.
    final collapsedHeadings = view.collapsedHeadings;
    // Headings follow the top layer: with only the translation on screen they
    // are the translation's, drawn above the verse they open at. The
    // original's stay in the list as empty items so indices do not move.
    final translationHeadings =
        view.secondaryActive &&
        !view.showOriginal &&
        (secondaryState?.headsTranslationOnly ?? false);
    return item.when(
      header:
          (section, depth) =>
              translationHeadings
                  ? const SizedBox.shrink()
                  : SectionHeader(
                    section: section,
                    depth: depth,
                    language: language,
                    showDivider:
                        depth > 0 && (previousItem?.isSegment ?? false),
                  ),
      segment: (segment, depth, sectionId) {
        final isSelected =
            state.selectedSegment?.segmentId == segment.segmentId;
        final isHighlighted = state.highlightedSegmentId == segment.segmentId;
        final isLive =
            liveSegmentId != null && liveSegmentId == segment.segmentId;

        if (view.secondaryActive) {
          final headings =
              !translationHeadings
                  ? const <SecondaryHeading>[]
                  : collapsedHeadings != null
                  ? collapsedHeadings[segment.segmentId] ??
                      const <SecondaryHeading>[]
                  : secondaryState!.headingsBySegmentNumber[segment
                          .segmentNumber] ??
                      const <SecondaryHeading>[];
          // Translation only: a verse the translation has no line for is
          // left out, unless the reader is being pointed at it.
          final hidden =
              !view.showOriginal &&
              !isLive &&
              !isSelected &&
              !isHighlighted &&
              (secondaryState?.lacks(segment.segmentNumber) ?? false);
          final Widget verse =
              hidden
                  ? const SizedBox.shrink()
                  : InterlinearSegmentItem(
                    segment: segment,
                    depth: depth,
                    primaryLanguage: language,
                    scope: view.params.settingsScope,
                    showPrimary: view.showOriginal,
                    secondarySlot: secondarySlot,
                    secondaryContentBySegmentNumber:
                        secondaryState?.contentBySegmentNumber,
                    secondaryIsLoading:
                        secondaryState?.isPending(segment.segmentNumber) ??
                        false,
                    isSelected: isSelected,
                    isHighlighted: isHighlighted,
                    highlightSource: state.highlightSource,
                    isLive: isLive,
                    onTap: () => _onSegmentTap(view.index, segment),
                  );
          if (headings.isEmpty) return verse;
          final firstVerse =
              previousItem == null ||
              segment.segmentId == state.content?.firstSegmentId;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < headings.length; i++)
                SectionHeader(
                  section: headings[i].section,
                  depth: headings[i].depth,
                  language: secondarySlot.languageCode,
                  // Like the original's: a nested heading after lines.
                  showDivider: i == 0 && headings[i].depth > 0 && !firstVerse,
                ),
              verse,
            ],
          );
        }

        return SegmentItem(
          segment: segment,
          depth: depth,
          language: language,
          scope: view.params.settingsScope,
          isSelected: isSelected,
          isLive: isLive,
          onTap: () {
            HapticFeedback.lightImpact();
            _onSegmentTap(view.index, segment);
          },
        );
      },
    );
  }
}

/// One shown text: its reader and what the list draws for it.
class _SourceView {
  final int index;
  final ReaderParams params;
  final ReaderState state;
  final List<FlattenedItem> items;
  final ReaderDualLayoutSettings dualSettings;
  final bool secondaryActive;
  final bool showOriginal;
  final SecondaryReaderState? secondaryState;
  final Map<String, List<SecondaryHeading>>? collapsedHeadings;

  const _SourceView({
    required this.index,
    required this.params,
    required this.state,
    required this.items,
    required this.dualSettings,
    this.secondaryActive = false,
    this.showOriginal = true,
    this.secondaryState,
    this.collapsedHeadings,
  });

  String get language => state.textDetail?.language ?? 'en';
}

enum _EntryKind { item, title, divider, error, footer }

/// One row of the list.
class _Entry {
  final _EntryKind kind;
  final int source;
  final FlattenedItem? item;

  /// The item before this one in the same source, for heading rules.
  final FlattenedItem? previous;

  const _Entry.item(this.source, this.item, this.previous)
    : kind = _EntryKind.item;
  const _Entry.title(this.source)
    : kind = _EntryKind.title,
      item = null,
      previous = null;
  const _Entry.divider(this.source)
    : kind = _EntryKind.divider,
      item = null,
      previous = null;
  const _Entry.error(this.source)
    : kind = _EntryKind.error,
      item = null,
      previous = null;
  const _Entry.footer()
    : kind = _EntryKind.footer,
      source = 0,
      item = null,
      previous = null;
}

/// Applies a text's first-visit language layout once the text and its
/// translations are known (see [ReaderInitialLayoutApplier]). Draws nothing.
class _ReaderSourceSetup extends ConsumerStatefulWidget {
  final ReaderParams params;

  const _ReaderSourceSetup({super.key, required this.params});

  @override
  ConsumerState<_ReaderSourceSetup> createState() => _ReaderSourceSetupState();
}

class _ReaderSourceSetupState extends ConsumerState<_ReaderSourceSetup> {
  final ReaderInitialLayoutApplier _layoutApplier =
      ReaderInitialLayoutApplier();

  @override
  void initState() {
    super.initState();
    // Both inputs may already be cached from an earlier visit.
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialLayout());
  }

  void _applyInitialLayout() {
    if (!mounted) return;
    unawaited(
      _layoutApplier.maybeApply(
        ref: ref,
        context: context,
        params: widget.params,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The first-visit layout needs the text's language and its list of
    // translations; whichever arrives last applies it. Listening here also
    // keeps the languages request alive for the sheet.
    ref.listen(
      readerNotifierProvider(
        widget.params,
      ).select((s) => s.textDetail?.language),
      (_, __) => _applyInitialLayout(),
    );
    ref.listen(
      readerLanguagesProvider(widget.params.textId),
      (_, __) => _applyInitialLayout(),
    );
    return const SizedBox.shrink();
  }
}

/// The rule between two source texts of a task.
class _SourceDivider extends StatelessWidget {
  const _SourceDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ReaderConstants.segmentHorizontalPadding,
        vertical: 24,
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).dividerColor,
      ),
    );
  }
}

/// A source text's title, styled like a top-level heading, when its own
/// headings carry none.
class _SourceTitle extends ConsumerWidget {
  final String title;
  final String language;

  const _SourceTitle({required this.title, required this.language});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (title.isEmpty) return const SizedBox.shrink();
    final fontSize = ref.watch(fontSizeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ReaderConstants.segmentHorizontalPadding,
        20,
        ReaderConstants.segmentHorizontalPadding,
        12,
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize * 1.2,
          fontWeight: FontWeight.w600,
          fontFamily: getFontFamily(language),
          color: Theme.of(context).textTheme.bodyMedium?.color,
          height: getLineHeight(language),
        ),
      ),
    );
  }
}

/// A source text after the first that failed to load, with a retry.
class _SourceErrorRow extends StatelessWidget {
  final VoidCallback onRetry;

  const _SourceErrorRow({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(l10n.something_went_wrong, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
