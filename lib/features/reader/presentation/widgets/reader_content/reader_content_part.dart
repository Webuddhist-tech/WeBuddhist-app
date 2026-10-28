import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/widgets/slide_away_header.dart';
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
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/collapsed_reader_items.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_initial_layout_applier.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_toc_titles.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/interlinear_segment_item.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_live_follow.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_page_toc.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_scroll_chrome.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_sections_pill.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_sections_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/section_header.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_item.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_skeleton.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_live_position.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_live_notifier.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_info.dart';
import 'package:flutter_pecha/features/texts/data/models/text/text_outline.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/segment_provider.dart';
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
  /// Focus mode: true when the header and bottom bar should slide away, false
  /// when they should come back (see [ReaderFocusMode]).
  final void Function(bool isScrollingDown)? onScrollDirectionChanged;
  final void Function(void Function(String segmentId, {double? alignment}))?
  onScrollControllerReady;
  final void Function(VoidCallback scrollToTop)? onScrollToTopReady;
  final Widget? chantSessionFooter;

  /// Gets how far through the page the reader is, 0 to 1, for the progress
  /// line under the header.
  final ValueNotifier<double>? progress;

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
    this.progress,
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

  // Focus mode, from the list's scroll updates in pixels.
  final ReaderFocusMode _focusMode = ReaderFocusMode();

  // User gesture tracking, for telling the person's scrolls from the app's.
  bool _isUserScrolling = false;
  bool _isProgrammaticScroll = false;

  /// Collapsed view: a plan task's verses of each source, read in turn and
  /// loaded forward from the first; never the text around them.
  bool get _isCollapsed =>
      widget.sources.length > 1 || widget.sources.first.isCollapsed;

  /// The list as last built, with the page's table of contents.
  _PageLayout? _layout;

  /// The table of contents for the sections sheet, refreshed after each build.
  final ValueNotifier<ReaderSectionsSnapshot> _sections = ValueNotifier(
    const ReaderSectionsSnapshot.empty(),
  );

  /// Key of the section at the top of the viewport.
  final ValueNotifier<String?> _currentSectionKey = ValueNotifier(null);

  /// The sections pill slides away on a scroll down and back on a scroll up.
  bool _pillVisible = true;

  /// Section id of a text's own title, for verses under no heading.
  static const _textSectionId = 'text';

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

  /// The section and round the live verse was last in, to tell a controller
  /// jump to a new section or round from the next verse.
  String? _lastLiveSection;
  int? _lastLiveRound;

  /// A controller jump put a section heading at the top and the live verse
  /// has not reached its place below it yet.
  bool _liveAfterSectionJump = false;

  /// Counts the live scrolls, so only the latest one hands the page back.
  int _liveScroll = 0;
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
    _sections.dispose();
    _currentSectionKey.dispose();
    super.dispose();
  }

  void _onScrollPositionChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(ReaderConstants.scrollDebounce, () {
      _checkPaginationThresholds();
      _reportFurthestSegment();
    });

    _updateCurrentSection();
    _updateProgress();
  }

  /// The section of the entry at the top of the viewport, for the pill.
  void _updateCurrentSection() {
    final layout = _layout;
    if (layout == null) return;
    int? top;
    for (final position in _itemPositionsListener.itemPositions.value) {
      if (position.itemTrailingEdge <= 0) continue;
      if (top == null || position.index < top) top = position.index;
    }
    if (top == null || top >= layout.sectionOfEntry.length) return;
    final section = layout.sectionOfEntry[top];
    if (section < 0) return;
    _currentSectionKey.value = layout.sections[section].key;
  }

  /// Focus mode. The person's scrolls count both ways. The app's own count
  /// only while following a live recitation, and only downwards, so a jump
  /// back up the page does not bring hidden bars back.
  void _onScrollOffset(double delta) {
    if (!mounted) return;
    // A finger on the list makes the scroll the person's, even one that
    // interrupts the app's own.
    final byApp =
        !_isUserScrolling && (_isProgrammaticScroll || !_recentUserGesture);
    // Any scroll by the person leaves the live recitation.
    if (!byApp && delta != 0 && _isLiveRecitation) _pauseLiveFollow();
    if (byApp && !_isLiveRecitation) return;
    if (!_focusMode.scrolled(delta, countUp: !byApp)) return;
    final hide = !_focusMode.barsVisible;
    widget.onScrollDirectionChanged?.call(hide);
    setState(() => _pillVisible = !hide);
  }

  /// The progress line: the last verse on screen out of the text's verses,
  /// or, on a plan task's page, the last row on screen out of its rows.
  void _updateProgress() {
    final progress = widget.progress;
    final layout = _layout;
    if (progress == null || layout == null || layout.entries.isEmpty) return;
    int? last;
    for (final position in _itemPositionsListener.itemPositions.value) {
      if (position.itemLeadingEdge >= 1) continue;
      if (last == null || position.index > last) last = position.index;
    }
    if (last == null) return;
    if (last >= layout.entries.length) last = layout.entries.length - 1;

    int? verse;
    var totalVerses = 0;
    if (!_isCollapsed) {
      totalVerses =
          ref.read(readerNotifierProvider(widget.sources.first)).totalSegments;
      for (var i = last; i >= 0 && verse == null; i--) {
        verse = layout.entries[i].item?.segment?.segmentNumber;
      }
    }
    progress.value = readerProgress(
      lastVerseNumber: verse,
      totalVerses: totalVerses,
      lastVisibleRow: last,
      rowCount: layout.entries.length,
    );
  }

  // ─── Sources and the rendered list ───────────────────────────────────────

  /// Source [index] as the list draws it, read outside build. Built like
  /// [_watchView], so indices into it match the rendered list's.
  _SourceView _readView(int index) => _viewOf(index, watch: false);

  /// The items of source [index] from [state]: its task verses under the
  /// headings that enclose them, or the whole loaded text.
  List<FlattenedItem> _itemsOf(int index, ReaderState state) {
    final content = state.content;
    if (content == null) return const [];
    final active = _activeSegmentIdsOf(index, state);
    if (active.isEmpty) return content.items;
    return collapsedReaderItems(content, active.toSet());
  }

  List<_Entry> _currentEntries() =>
      _layoutFor([
        for (var i = 0; i < _startedCount; i++) _readView(i),
      ]).entries;

  /// The list, source after source, with the page's table of contents.
  ///
  /// A rule goes before each source after the first, then its title when its
  /// headings carry none, its items, or its retry row when it failed. The
  /// translation's headings go above the verse they open at. A source still
  /// loading its first page adds nothing; the tail skeleton stands in for it.
  ///
  /// The navigator lists each source as a text, titled by its first heading
  /// or its own title, with its sections nested: each verse belongs to the
  /// innermost titled heading over it, or to the text.
  _PageLayout _layoutFor(List<_SourceView> views) {
    final entries = <_Entry>[];
    final sectionOfEntry = <int>[];
    final sections = <ReaderPageSection>[];
    final texts = <ReaderPageText>[];
    final sectionIndexByKey = <String, int>{};
    // Headings drawn so far, by the source and entry they were drawn at.
    final drawn = <String, (int, int)>{};
    // The original's heading in effect at each depth.
    final open = <FlattenedItem>[];
    String? previousTextId;

    int sectionAt(
      int source,
      String id,
      String title,
      String language,
      int entry, {
      String? segmentId,
    }) => sectionIndexByKey.putIfAbsent('$source:$id', () {
      sections.add(
        ReaderPageSection(
          source: source,
          id: id,
          title: title,
          language: language,
          entryIndex: entry,
          segmentId: segmentId,
        ),
      );
      return sections.length - 1;
    });

    void add(_Entry entry, int section) {
      entries.add(entry);
      sectionOfEntry.add(section);
    }

    for (final view in views) {
      final items = view.items;
      if (view.index > 0) {
        if (items.isEmpty && !view.state.isError) continue;
        add(_Entry.divider(view.index), -1);
      }
      if (view.state.isError) {
        add(_Entry.error(view.index), -1);
        continue;
      }
      if (view.params.textId != previousTextId) open.clear();
      previousTextId = view.params.textId;
      final (textTitle, textLanguage) = _titleOf(view);
      // The whole table of contents, its titled headings: those verses sit
      // directly under are the text's sections, not loaded yet included.
      final outline = view.outline;
      final titled = <TextOutlineSection>[
        if (outline != null)
          for (final section in outline.sections)
            if (section.titleFor(outline.language) != null) section,
      ];
      final outlined = readerPageSections(titled);
      final opening = titled.firstOrNull;
      // The text is named by its first heading when it has one.
      final String titleSectionId;
      final String title;
      final String titleLanguage;
      if (outline != null) {
        final opens = opening != null && opening.opensText && opening.depth == 0;
        titleSectionId = opens ? opening.id : _textSectionId;
        (title, titleLanguage) =
            opens && !view.translationHeadings
                ? _outlineTitle(view, opening)
                : (textTitle, textLanguage);
      } else {
        final heading = items.isEmpty ? null : items.first.section;
        final titled = heading != null && (heading.title?.isNotEmpty ?? false);
        titleSectionId = titled ? heading.id : _textSectionId;
        (title, titleLanguage) =
            titled && !view.translationHeadings
                ? _headingText(view, heading)
                : (textTitle, textLanguage);
      }
      final startUnloaded = !_isCollapsed && view.state.hasPreviousPage;
      final opensFromHeading =
          startUnloaded && opening != null && opening.opensText;
      final text = ReaderPageText(
        source: view.index,
        title: title,
        language: titleLanguage,
        entryIndex: entries.length,
        titleSectionId: titleSectionId,
        // Loaded from further in: the opening verse is not on the page. A
        // heading that opens the text names it; otherwise the text's first
        // page is loaded. A collapsed page always holds its own start.
        startSegmentId: opensFromHeading ? opening.segmentId : null,
        startsBeforePage: startUnloaded && !opensFromHeading,
      );
      texts.add(text);
      int textSection() => sectionAt(
        view.index,
        _textSectionId,
        textTitle,
        textLanguage,
        entries.length,
      );
      // Verses before the first heading belong to the text itself, ahead of
      // its headings.
      if (opening != null && !opening.opensText) textSection();
      final outlineSection = <String, int>{};
      for (final section in outlined) {
        final (sectionTitle, sectionLanguage) = _outlineTitle(view, section);
        outlineSection[section.id] = sectionAt(
          view.index,
          section.id,
          sectionTitle,
          sectionLanguage,
          -1,
          segmentId: section.segmentId,
        );
      }
      // Where each heading and verse of this source sits in the list.
      final headerEntry = <String, int>{};
      final verseEntry = <int, int>{};
      if (views.length > 1 &&
          items.isNotEmpty &&
          !view.translationHeadings &&
          !_startsWithTitle(items)) {
        add(_Entry.title(view.index), textSection());
      }
      FlattenedItem? previous;
      for (final item in items) {
        if (item.isHeader) {
          final section = item.section!;
          if (open.length > item.depth) {
            open.removeRange(item.depth, open.length);
          }
          while (open.length < item.depth) {
            open.add(item);
          }
          open.add(item);
          if (!view.translationHeadings) {
            drawn[section.id] = (view.index, entries.length);
          }
          headerEntry[section.id] = entries.length;
          // A heading the translation's stand in for stays in the list, as
          // an empty item, so indices do not move.
          add(_Entry.item(view.index, item, previous), -1);
          previous = item;
          continue;
        }

        final segment = item.segment!;
        verseEntry.putIfAbsent(segment.segmentNumber, () => entries.length);
        var headings = const <SecondaryHeading>[];
        if (view.translationHeadings) {
          headings =
              view.collapsedHeadings?[segment.segmentId] ??
              view.secondaryState!.headingsBySegmentNumber[segment
                  .segmentNumber] ??
              const <SecondaryHeading>[];
        }
        final int sectionIndex;
        if (outline != null) {
          final holding = innermostSectionHolding(
            outlined,
            segment.segmentNumber,
          );
          sectionIndex =
              holding == null ? textSection() : outlineSection[holding.id]!;
        } else if (view.translationHeadings) {
          final secondary = view.secondaryState!;
          final enclosing = secondary.headingsEnclosing(segment.segmentNumber);
          sectionIndex =
              enclosing.isEmpty
                  ? textSection()
                  : sectionAt(
                    view.index,
                    enclosing.last.section.id,
                    enclosing.last.section.title ?? '',
                    view.dualSettings.secondary.languageCode,
                    entries.length,
                  );
        } else {
          Section? heading;
          for (var depth = open.length - 1; depth >= 0; depth--) {
            final candidate = open[depth].section!;
            if (candidate.title?.isNotEmpty ?? false) {
              heading = candidate;
              break;
            }
          }
          if (heading == null) {
            sectionIndex = textSection();
          } else {
            final (title, language) = _headingText(view, heading);
            final at = drawn[heading.id];
            sectionIndex = sectionAt(
              view.index,
              heading.id,
              title,
              language,
              at != null && at.$1 == view.index ? at.$2 : entries.length,
            );
          }
        }
        add(
          _Entry.item(view.index, item, previous, headings: headings),
          sectionIndex,
        );
        previous = item;
      }
      // A section is on the page once the verse it opens at is: it goes
      // where its heading is drawn, else to that verse. A page that starts
      // partway into a section repeats its heading over the later verses,
      // so a heading alone does not count; such a section waits to be
      // loaded from its start.
      for (final section in outlined) {
        final opensAt = verseEntry[section.number];
        if (opensAt == null) continue;
        final at = headerEntry[section.id] ?? opensAt;
        final index = outlineSection[section.id]!;
        final placed = sections[index];
        sections[index] = ReaderPageSection(
          source: placed.source,
          id: placed.id,
          title: placed.title,
          language: placed.language,
          entryIndex: at,
          segmentId: placed.segmentId,
        );
      }
    }
    if (!_isCollapsed && widget.chantSessionFooter != null) {
      add(const _Entry.footer(), -1);
    }
    // Headings and rules go with the section that follows them.
    var next = -1;
    for (var i = sectionOfEntry.length - 1; i >= 0; i--) {
      if (sectionOfEntry[i] < 0) {
        sectionOfEntry[i] = next;
      } else {
        next = sectionOfEntry[i];
      }
    }
    // A text's sections nest under it; the one it is named after is the text.
    for (final section in sections) {
      final text = texts.firstWhere((t) => t.source == section.source);
      if (section.id != text.titleSectionId) text.sections.add(section);
    }
    return _PageLayout(
      entries: entries,
      sections: sections,
      texts: texts,
      sectionOfEntry: sectionOfEntry,
    );
  }

  static bool _startsWithTitle(List<FlattenedItem> items) {
    final first = items.first;
    return first.isHeader && (first.section?.title?.isNotEmpty ?? false);
  }

  /// A heading's title as the page reads it: the translation's for it when
  /// one shows, else the text's (see [readerSectionTitle]).
  (String, String) _headingText(_SourceView view, Section section) {
    final title = readerSectionTitle(
      titles: section.titles,
      originalLanguage: view.language,
      translationTitle: view.translationTitles[section.id],
      translationLanguage:
          view.secondaryActive
              ? view.dualSettings.secondary.languageCode
              : null,
      textTitle: section.title ?? '',
      textLanguage: view.language,
    );
    return (title.title, title.language);
  }

  /// A section of the whole table of contents as the navigator lists it.
  (String, String) _outlineTitle(
    _SourceView view,
    TextOutlineSection section,
  ) {
    final (textTitle, textLanguage) = _titleOf(view);
    final title = readerSectionTitle(
      titles: section.titles,
      originalLanguage: view.outline?.language ?? view.language,
      translationTitle: view.translationTitles[section.id],
      translationLanguage:
          view.secondaryActive
              ? view.dualSettings.secondary.languageCode
              : null,
      textTitle: textTitle,
      textLanguage: textLanguage,
    );
    return (title.title, title.language);
  }

  /// The sections the pill counts, text by text: a text's sections, or the
  /// text itself while none of its verses are in.
  static List<ReaderPageSection> _pillSections(_PageLayout layout) => [
    for (final text in layout.texts)
      if (layout.sections.any((s) => s.source == text.source))
        ...layout.sections.where((s) => s.source == text.source)
      else
        ReaderPageSection(
          source: text.source,
          id: text.titleSectionId,
          title: text.title,
          language: text.language,
          entryIndex: text.entryIndex,
        ),
  ];

  /// What the sections are of: the plan task on a page of several texts,
  /// else the text.
  String _pageTitle(_SourceView first) {
    final task = widget.sources.first.navigationContext?.currentItem?.title;
    if (widget.sources.length > 1 && task != null && task.trim().isNotEmpty) {
      return task;
    }
    return first.state.openedText?.title ?? '';
  }

  // ─── Sections navigator ──────────────────────────────────────────────────

  Future<void> _openSectionsSheet() async {
    HapticFeedback.lightImpact();
    // Every text takes part in the navigator: start those not loaded yet.
    if (_startedCount < widget.sources.length) {
      setState(() => _startedCount = widget.sources.length);
    }
    final picked = await showModalBottomSheet<ReaderPageSection>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ReaderPanelConstants.topRadius),
        ),
      ),
      isScrollControlled: true,
      builder:
          (_) =>
              ReaderSectionsSheet(snapshot: _sections, current: _currentSectionKey),
    );
    if (picked == null || !mounted) return;
    await _goToSection(picked);
  }

  /// Brings [section] to the top, loading the verse it opens at first when
  /// it is not on the page; a text's own row whose start is not known by a
  /// verse loads the text's first page.
  Future<void> _goToSection(ReaderPageSection section) async {
    if (section.isOnPage) {
      _scrollToEntry(section.entryIndex);
      return;
    }
    final segmentId = section.segmentId;
    final notifier = ref.read(
      readerNotifierProvider(widget.sources[section.source]).notifier,
    );
    final bool loaded;
    if (segmentId == null) {
      final textStart =
          _layout?.texts.any(
            (text) =>
                text.source == section.source &&
                text.titleSectionId == section.id &&
                text.startsBeforePage,
          ) ??
          false;
      if (!textStart) return;
      loaded = await notifier.jumpToStart();
    } else if (_isCollapsed) {
      loaded = await _loadForwardTo(section.source, segmentId);
    } else {
      loaded = await notifier.jumpToSegment(segmentId) != null;
    }
    if (!loaded || !mounted) return;
    // Let the list take the new verses, then find the section in it, or the
    // text it names.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final layout = _layout;
    if (layout == null) return;
    var entry = -1;
    for (final placed in layout.sections) {
      if (placed.key == section.key) entry = placed.entryIndex;
    }
    for (final text in layout.texts) {
      if (entry < 0 &&
          text.source == section.source &&
          text.titleSectionId == section.id) {
        entry = text.entryIndex;
      }
    }
    if (entry >= 0) _scrollToEntry(entry);
  }

  /// Brings the entry at [index] to the top.
  void _scrollToEntry(int index) {
    final count = _layout?.entries.length ?? 0;
    if (index < 0 || index >= count || !_itemScrollController.isAttached) {
      return;
    }
    _isProgrammaticScroll = true;
    _itemScrollController.scrollTo(
      index: index,
      duration: ReaderConstants.scrollAnimationDuration,
      curve: Curves.easeInOutCubic,
      alignment: 0,
    );
    Future.delayed(
      ReaderConstants.scrollAnimationDuration +
          const Duration(milliseconds: 100),
      () {
        _isProgrammaticScroll = false;
        if (mounted) _checkPaginationThresholds();
      },
    );
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
      notifier.loadPreviousPage().then((addedCount) {
        _hasTriggeredPrevious = false;
        _adjustScrollAfterPreviousLoad(addedCount);
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

  /// Near the end of a started source's verses, it fetches its next ones.
  /// Every started source is checked, not only the last: a jump (the
  /// sections sheet, live) starts later sources before an earlier one has
  /// all its verses. Once the last started source has them all, or failed,
  /// the next source starts.
  void _loadForward(int lastVisibleIndex, int totalItems) {
    final entries = _currentEntries();
    var lastIsDone = false;
    for (var index = 0; index < _startedCount; index++) {
      final state = ref.read(readerNotifierProvider(widget.sources[index]));
      final isLast = index == _startedCount - 1;
      if (state.isError) {
        if (isLast) lastIsDone = true;
        continue;
      }
      final content = state.content;
      if (state.status != ReaderStatus.loaded || content == null) continue;

      final active = _activeSegmentIdsOf(index, state);
      final missing = nextSegmentToLoad(
        content,
        active,
        skipped: _skippedSegmentIds[index] ?? const {},
      );
      final wantsMore =
          state.hasNextPage && (active.isEmpty || missing != null);
      if (!wantsMore) {
        if (isLast) lastIsDone = true;
        continue;
      }
      if (state.isLoadingNext || _nextTriggered.contains(index)) continue;

      final end = entries.lastIndexWhere((e) => e.source == index);
      if (end >= 0 &&
          lastVisibleIndex < end - ReaderConstants.nextLoadThreshold) {
        continue;
      }
      _logger.debug('Loading source $index forward from ${missing ?? 'end'}');
      _loadNext(index, fromSegmentId: missing);
    }
    if (lastIsDone &&
        _startedCount < widget.sources.length &&
        lastVisibleIndex >= totalItems - ReaderConstants.nextLoadThreshold) {
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

  /// Keeps the reader's place after [addedCount] items were added at the top.
  void _adjustScrollAfterPreviousLoad(int addedCount) {
    // Runs after an earlier page loads, which can finish after the reader
    // was closed. There is nothing left to scroll, and `ref` is unusable.
    if (!mounted || _positionBeforePreviousLoad == null) return;

    // Nothing was added (the load failed or the page was empty): the list
    // did not shift, so moving it would push the reader away from the top.
    if (addedCount <= 0) {
      _positionBeforePreviousLoad = null;
      return;
    }

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

        final targetIndex = _positionBeforePreviousLoad! + addedCount;
        if (targetIndex >= 0 && targetIndex < content.itemCount) {
          _itemScrollController.jumpTo(index: targetIndex);
          _logger.debug(
            'Adjusted scroll after prepend: $targetIndex (added $addedCount items)',
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
    // Opening a verse's resources leaves the live recitation.
    if (_isLiveRecitation) _pauseLiveFollow();
    final params = widget.sources[index];
    for (var i = 0; i < _startedCount; i++) {
      if (i == index) continue;
      final other = ref.read(
        readerNotifierProvider(widget.sources[i]).notifier,
      );
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
    if (followRequested) {
      // Rejoining goes to the live verse itself, not to the heading of a
      // section the room moved to meanwhile.
      _lastLiveSection = null;
      _lastLiveRound = null;
      // The verse opened before leaving would cover the live one.
      for (var i = 0; i < _startedCount; i++) {
        ref
            .read(readerNotifierProvider(widget.sources[i]).notifier)
            .selectSegment(null);
      }
    }
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

  /// Source [index]'s local id for the live segment when it shows it: a
  /// collapsed source fetches whole pages but shows only its own verses, so
  /// a later source of the same text may be the one showing it.
  String? _shownLocalIdFor(int index, ReaderState state, String segmentId) {
    final content = state.content;
    if (content == null) return null;
    final local = _localSegmentIdFor(content, segmentId);
    if (local == null) return null;
    final active = _activeSegmentIdsOf(index, state);
    return active.isEmpty || active.contains(local) ? local : null;
  }

  /// The started source showing [position] and its local id, if loaded.
  (int, String)? _locateLive(RecitationLivePosition position) {
    for (var i = 0; i < _startedCount; i++) {
      final state = ref.read(readerNotifierProvider(widget.sources[i]));
      final local = _shownLocalIdFor(i, state, position.segmentId);
      if (local != null) return (i, local);
    }
    return null;
  }

  /// Local id of the line to show on the live card, or null when no source
  /// shows it or the person is not following: paused, the page reads like
  /// the normal reader.
  String? _resolveLiveHighlight(
    List<_SourceView> views,
    RecitationLivePosition? position,
    RecitationLiveFollowMode mode,
  ) {
    if (position == null || mode != RecitationLiveFollowMode.following) {
      return null;
    }
    for (final view in views) {
      final localId = _shownLocalIdFor(
        view.index,
        view.state,
        position.segmentId,
      );
      if (localId != null) return localId;
    }
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
    liveNotifier.setOutOfSync(
      !_scrollToLiveSegment(located.$1, located.$2, position.roundNumber),
    );
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
        if (!await _loadForwardTo(i, local)) continue;
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

  /// Loads source [index] forward until it holds [segmentId], page after
  /// page from where reading would load next. A page fetched at [segmentId]
  /// itself would be appended after the loaded ones and skip every verse in
  /// between. False when the verse never arrives: the source ran out, a
  /// fetch failed, or a page brought nothing new.
  Future<bool> _loadForwardTo(int index, String segmentId) async {
    final params = widget.sources[index];
    final notifier = ref.read(readerNotifierProvider(params).notifier);
    while (mounted) {
      final state = ref.read(readerNotifierProvider(params));
      if (state.isLoadingNext) {
        // A page reading asked for is on its way; it may bring the verse.
        try {
          await notifier.stream
              .firstWhere((s) => !s.isLoadingNext)
              .timeout(const Duration(seconds: 30));
        } catch (e) {
          _logger.debug('Page for live verse $segmentId did not settle: $e');
          return false;
        }
        continue;
      }
      final content = state.content;
      if (content == null) return false;
      if (_localSegmentIdFor(content, segmentId) != null) return true;
      if (!state.hasNextPage) return false;

      final active = _activeSegmentIdsOf(index, state);
      final from =
          active.isEmpty
              ? null
              : nextSegmentToLoad(
                content,
                active,
                skipped: _skippedSegmentIds[index] ?? const {},
              );
      if (active.isNotEmpty && from == null) return false;

      final before = content.segmentIndexMap.length;
      _nextTriggered.add(index);
      final merged = await notifier
          .loadNextPage(fromSegmentId: from)
          .whenComplete(() => _nextTriggered.remove(index));
      if (!mounted || !merged) return false;
      final after = ref.read(readerNotifierProvider(params)).content;
      if (after == null) return false;
      if (from != null && !after.containsSegment(from)) {
        // The edition lacks that verse, as in [_loadNext].
        (_skippedSegmentIds[index] ??= {}).add(from);
      } else if (after.segmentIndexMap.length <= before) {
        return false;
      }
    }
    return false;
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

  /// Scrolls to the rendered line [segmentId] of [source], read in [round];
  /// false when it is not on this page (a verse outside the task's).
  ///
  /// The verse is held ⅔ down the text area (see [liveScrollTarget]). When
  /// the room moved to another section or round, that section's heading
  /// goes to the top instead.
  bool _scrollToLiveSegment(
    int source,
    String segmentId,
    int? round, {
    bool settling = false,
  }) {
    final layout = _layoutFor([
      for (var i = 0; i < _startedCount; i++) _readView(i),
    ]);
    final index = _entryIndexForSegment(
      layout.entries,
      segmentId,
      source: source,
    );
    if (index == null) return false;

    final sectionIndex =
        index < layout.sectionOfEntry.length
            ? layout.sectionOfEntry[index]
            : -1;
    final section = sectionIndex < 0 ? null : layout.sections[sectionIndex];
    final jump = isLiveSectionJump(
      previousSection: _lastLiveSection,
      section: section?.key,
      previousRound: _lastLiveRound,
      round: round,
    );
    if (jump || section?.key != _lastLiveSection) _liveAfterSectionJump = jump;
    _lastLiveSection = section?.key;
    _lastLiveRound = round;
    if (!_itemScrollController.isAttached) return true;

    final LiveScrollTarget? target;
    // A verse not laid out yet is placed by its top; once the scroll lands
    // it is measured and placed again by its middle.
    var measured = true;
    if (jump && section != null && section.isOnPage) {
      target = (index: section.entryIndex, alignment: 0);
    } else {
      final positions = _itemPositionsListener.itemPositions.value;
      ItemPosition? at(int row) =>
          positions.where((p) => p.index == row).firstOrNull;
      final verse = at(index);
      final start = at(0);
      measured = verse != null;
      target = liveScrollTarget(
        index: index,
        heightFraction:
            verse == null ? null : verse.itemTrailingEdge - verse.itemLeadingEdge,
        distanceFromStart:
            verse == null || start == null
                ? null
                : verse.itemLeadingEdge - start.itemLeadingEdge,
        currentTop: verse?.itemLeadingEdge,
        afterSectionJump: _liveAfterSectionJump,
      );
      // Once the verse has reached its place, the page holds it there.
      if (target != null) _liveAfterSectionJump = false;
    }
    if (target == null) return true;

    final generation = _liveGeneration;
    final scroll = ++_liveScroll;
    _isProgrammaticScroll = true;
    // A jump far down the page runs past its duration, so this waits for
    // the scroll itself rather than a timer: until it lands, its steps are
    // the app's, not the person's.
    _itemScrollController
        .scrollTo(
          index: target.index,
          duration: ReaderConstants.scrollAnimationDuration,
          curve: Curves.easeInOutCubic,
          alignment: target.alignment,
        )
        .whenComplete(() async {
          if (!mounted || scroll != _liveScroll) return;
          _isProgrammaticScroll = false;
          // Pull the next page in at the operator's pace, not the user's.
          _checkPaginationThresholds();
          if (measured || settling) return;
          // The list reports where the verse landed a frame later.
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted ||
              scroll != _liveScroll ||
              _isUserScrolling ||
              generation != _liveGeneration ||
              !ref.read(recitationLiveProvider(_liveEventId!)).isFollowing) {
            return;
          }
          _scrollToLiveSegment(source, segmentId, round, settling: true);
        });
    return true;
  }

  /// Leaves the live recitation: the Live pill turns to Paused, the page stops
  /// following and reads like the normal reader until the person rejoins.
  void _pauseLiveFollow() {
    final eventId = _liveEventId;
    if (eventId == null) return;
    if (!ref.read(recitationLiveProvider(eventId)).isFollowing) return;
    ref.read(recitationLiveProvider(eventId).notifier).pauseFollowing();
    // Bring the bars back, so the Paused pill is there to tap.
    if (_focusMode.show()) {
      widget.onScrollDirectionChanged?.call(false);
      setState(() => _pillVisible = true);
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
  _SourceView _watchView(int index) => _viewOf(index, watch: true);

  /// Source [index] as the list draws it: watched in build, read outside it.
  /// A read takes the translation only once build has subscribed to it.
  _SourceView _viewOf(int index, {required bool watch}) {
    T get<T>(ProviderListenable<T> provider) =>
        watch ? ref.watch(provider) : ref.read(provider);
    final params = widget.sources[index];
    final state = get(readerNotifierProvider(params));
    final dualSettings = get(readerDualSettingsProvider(params.settingsScope));

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
    SecondaryReaderState? secondaryState;
    if (secondaryActive) {
      // The key's identity ignores the anchor; a read leaves it uncomputed.
      final secondary = secondaryReaderProvider(
        SecondaryReaderKey(
          textId: effectivePrimaryTextId,
          versionId: secondaryVersionId,
          initialSegmentId:
              watch
                  ? _resolveSecondaryInitialSegmentId(index)
                  : _secondaryInitialSegmentId[index],
        ),
      );
      if (watch || ref.exists(secondary)) secondaryState = get(secondary);
    }
    if (watch) _scheduleSecondarySync(index, secondaryState);

    final items = _itemsOf(index, state);
    final collapsed = _activeSegmentIdsOf(index, state).isNotEmpty;
    // Headings follow the translation when one shows: its own table of
    // contents where it has one. A page showing only the translation waits
    // for its first page, so the original's never flash in; one showing the
    // original too keeps the original's headings until then.
    final translationHeadings =
        secondaryActive &&
        secondaryState != null &&
        (showOriginal
            ? secondaryState.headingsBySegmentNumber.isNotEmpty
            : secondaryState.headsTranslationOnly);

    // The whole table of contents, for a source showing its whole text, by
    // the edition its pages came from; with a translation, its titles too.
    TextOutline? outline;
    var translationTitles = const <String, String>{};
    final editionId = state.textDetail?.id;
    if (editionId != null && !collapsed) {
      final outlineProvider = readerOutlineProvider(editionId);
      if (watch || ref.exists(outlineProvider)) {
        final loaded = get(outlineProvider).valueOrNull;
        if (loaded != null && !loaded.isEmpty) outline = loaded;
      }
      if (outline != null && secondaryActive) {
        final titlesProvider = readerTranslationTitlesProvider((
          textId: editionId,
          versionId: secondaryVersionId,
        ));
        if (watch || ref.exists(titlesProvider)) {
          translationTitles = get(titlesProvider).valueOrNull ?? const {};
        }
      }
    }
    return _SourceView(
      index: index,
      params: params,
      state: state,
      items: items,
      dualSettings: dualSettings,
      secondaryActive: secondaryActive,
      showOriginal: showOriginal,
      secondaryState: secondaryState,
      translationHeadings: translationHeadings,
      collapsedHeadings:
          collapsed && secondaryState != null
              ? collapsedTranslationHeadings(items, secondaryState)
              : null,
      outline: outline,
      translationTitles: translationTitles,
    );
  }

  /// A text's title as the page reads it: its translation's when one shows.
  (String, String) _titleOf(_SourceView view) {
    final translation = view.dualSettings.secondary;
    final translated = translation.versionLabel;
    if (view.secondaryActive && translated != null && translated.isNotEmpty) {
      return (translated, translation.languageCode);
    }
    return (view.state.openedText?.title ?? '', view.language);
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

    final layout = _layoutFor(views);
    _layout = layout;
    final entries = layout.entries;
    final liveSegmentId = _resolveLiveHighlight(views, livePosition, liveMode);
    final tail = views.last.state;
    final isLoadingTail =
        tail.isLoadingNext ||
        (views.length > 1 && !tail.hasContent && !tail.isError);

    // Texts not started yet are listed as loading until they are.
    final pending = widget.sources.length - _startedCount;
    final snapshot = ReaderSectionsSnapshot(
      title: _pageTitle(first),
      texts: layout.texts,
      pendingSources: pending,
    );
    if (snapshot != _sections.value) {
      // The sheet, in its own route, listens: not during this build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sections.value = snapshot;
      });
    }
    // Something to move between: more than one section on the page.
    final pillSections = _pillSections(layout);
    final sectionCount = pillSections.length + pending;
    final showPill = pillSections.isNotEmpty && sectionCount > 1;

    return Column(
      children: [
        if (showPill)
          SlideAwayHeader(
            visible: _pillVisible,
            duration: ReaderConstants.focusModeDuration,
            curve: ReaderConstants.focusModeCurve,
            child: ValueListenableBuilder<String?>(
              valueListenable: _currentSectionKey,
              builder: (context, key, _) {
                // The section at the top of the page, counted among the
                // page's sections.
                final at = pillSections.indexWhere((s) => s.key == key);
                final index = at < 0 ? 0 : at;
                final section = pillSections[index];
                return ReaderSectionsPill(
                  title: section.title,
                  language: section.language,
                  position: index + 1,
                  total: sectionCount,
                  onTap: _openSectionsSheet,
                );
              },
            ),
          ),
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
            // The list's own ScrollOffsetListener stops hearing the person
            // once a long scrollTo swaps its inner lists; the updates they
            // bubble up come from whichever list is showing.
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) {
                if (notification.depth == 0 &&
                    notification.metrics.axis == Axis.vertical) {
                  _onScrollOffset(notification.scrollDelta ?? 0);
                }
                return false;
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
        final (title, language) = _titleOf(views[entry.source]);
        return _SourceTitle(title: title, language: language);
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
          headings: entry.headings,
          liveSegmentId: liveSegmentId,
        );
    }
  }

  Widget _buildItem({
    required _SourceView view,
    required FlattenedItem item,
    FlattenedItem? previousItem,
    // The translation's headings to draw above this verse, when its own
    // headings stand in for the original's (then empty items in the list).
    List<SecondaryHeading> headings = const [],
    String? liveSegmentId,
  }) {
    final state = view.state;
    final language = view.language;
    final secondaryState = view.secondaryState;
    final secondarySlot = view.dualSettings.secondary;
    return item.when(
      header: (section, depth) {
        if (view.translationHeadings) return const SizedBox.shrink();
        final (title, headingLanguage) = _headingText(view, section);
        return SectionHeader(
          section:
              title == section.title ? section : section.copyWith(title: title),
          depth: depth,
          language: headingLanguage,
          showDivider: depth > 0 && (previousItem?.isSegment ?? false),
        );
      },
      segment: (segment, depth, sectionId) {
        final isSelected =
            state.selectedSegment?.segmentId == segment.segmentId;
        final isHighlighted = state.highlightedSegmentId == segment.segmentId;
        final isLive =
            liveSegmentId != null && liveSegmentId == segment.segmentId;

        if (view.secondaryActive) {
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

  /// The translation's own headings stand in for the original's.
  final bool translationHeadings;
  final Map<String, List<SecondaryHeading>>? collapsedHeadings;

  /// The text's whole table of contents, for a source showing all of it;
  /// null while it loads or when it has none.
  final TextOutline? outline;

  /// The translation's title for each section, by the original's id.
  final Map<String, String> translationTitles;

  const _SourceView({
    required this.index,
    required this.params,
    required this.state,
    required this.items,
    required this.dualSettings,
    this.secondaryActive = false,
    this.showOriginal = true,
    this.secondaryState,
    this.translationHeadings = false,
    this.collapsedHeadings,
    this.outline,
    this.translationTitles = const {},
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

  /// The translation's headings drawn above this verse.
  final List<SecondaryHeading> headings;

  const _Entry.item(
    this.source,
    this.item,
    this.previous, {
    this.headings = const [],
  }) : kind = _EntryKind.item;
  const _Entry.title(this.source)
    : kind = _EntryKind.title,
      item = null,
      previous = null,
      headings = const [];
  const _Entry.divider(this.source)
    : kind = _EntryKind.divider,
      item = null,
      previous = null,
      headings = const [];
  const _Entry.error(this.source)
    : kind = _EntryKind.error,
      item = null,
      previous = null,
      headings = const [];
  const _Entry.footer()
    : kind = _EntryKind.footer,
      source = 0,
      item = null,
      previous = null,
      headings = const [];
}

/// The list and its table of contents, as built from the started sources.
class _PageLayout {
  final List<_Entry> entries;
  final List<ReaderPageSection> sections;
  final List<ReaderPageText> texts;

  /// Each entry's section, -1 for one past the last section.
  final List<int> sectionOfEntry;

  const _PageLayout({
    required this.entries,
    required this.sections,
    required this.texts,
    required this.sectionOfEntry,
  });
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
class _SourceDivider extends ConsumerWidget {
  const _SourceDivider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ReaderConstants.segmentHorizontalPadding,
        vertical: 24,
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color: ReaderStyle.of(context, ref).palette.divider,
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
    final style = ReaderStyle.of(context, ref);
    // A top-level heading's size.
    final metrics = style.type.heading(
      0,
      ReaderScript.of(title, language: language),
    );
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
          fontSize: metrics.fontSize,
          fontWeight: metrics.fontWeight,
          fontFamily: style.type.family(language),
          color: style.palette.heading,
          height: metrics.height,
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
