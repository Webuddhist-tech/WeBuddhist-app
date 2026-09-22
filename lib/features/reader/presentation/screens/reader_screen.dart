import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/widgets/slide_away_header.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/add_offline_chants_dialog.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_chant_bar.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_chant_footer.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/group_accumulation_counts_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_accumulation_selection_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_settings_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_button.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_embedded_host.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_segment_audio_controller.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_subtask_completion.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/domain/services/live_position_resolver.dart';
import 'package:flutter_pecha/features/reader/domain/services/navigation_service.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_actions/segement_action_bar.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_app_bar.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_bottom_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_button.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_languages_button.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_more_bottom_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/reader_commentary_split_view.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_translation/reader_translation_split_view.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_content_part.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_gestures/swipe_navigation_wrapper.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_search/reader_search_delegate.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_languages_sheet.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_live_position.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_live_notifier.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_live_sync_toggle.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Main reader screen - thin orchestrator that composes child widgets
class ReaderScreen extends ConsumerStatefulWidget {
  final String textId;
  final String? segmentId;
  final NavigationContext? navigationContext;
  final int? colorIndex;

  const ReaderScreen({
    super.key,
    required this.textId,
    this.segmentId,
    this.navigationContext,
    this.colorIndex,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with SingleTickerProviderStateMixin {
  late ReaderParams _params;

  /// Gap kept below the floating audio button when it sits over the bare
  /// reader content (no action bar). Matches the original floating offset.
  static const double _audioBottomGap = 76;

  /// Tighter gap used when the audio button sits directly above the segment
  /// action bar, so the button hugs the bar instead of leaving a large empty
  /// band of background between them.
  static const double _audioActionBarGap = 16;

  /// Lets the audio button keep its state when it is reparented between the
  /// behind-panel slot and the bottom overlay.
  final GlobalKey _audioButtonKey = GlobalKey();
  static const double _defaultContentBottomPadding = 60;
  static const double _selectedSegmentOverlayFallbackHeight = 360;

  // App bar visibility state
  bool _isAppBarVisible = true;
  double _bottomOverlayHeight = 0;
  // Scroll controller callback
  void Function(String segmentId, {double? alignment})? _scrollToSegment;
  VoidCallback? _scrollToTop;

  // Group accumulation chant session
  bool _hasSeededInitialChantCount = false;
  bool _chantSessionFinished = false;

  /// Absolute count already synced before this reader visit; UI shows the delta.
  int _chantSessionBaseline = 0;

  NavigationContext? get _chantContext {
    final ctx = widget.navigationContext;
    if (ctx == null || !ctx.isGroupAccumulatorChant) return null;
    return ctx;
  }

  bool get _isGroupAccumulatorChant => _chantContext != null;

  /// Set when the reader follows a group event's live recitation.
  String? get _liveEventId {
    final ctx = widget.navigationContext;
    return ctx != null && ctx.isLiveRecitation ? ctx.eventId : null;
  }

  bool get _isEmbedded => PlanEmbeddedScope.maybeOf(context) != null;

  // ─── Audio ─────────────────────────────────────────────────────────────
  // Plays the current SOURCE_REFERENCE subtask's audio when the reader is
  // opened from a plan. Shares the engine with PlanTextScreen.
  PlanSegmentAudioController? _audioController;
  bool _isAdvancing = false;

  bool get _hasAudio => _audioController?.hasAudio ?? false;

  @override
  void initState() {
    super.initState();
    _params = ReaderParams(
      textId: widget.textId,
      segmentId: widget.segmentId,
      navigationContext: widget.navigationContext,
    );
    _initAudio();
    _initGroupAccumulatorChantSession();
  }

  void _initGroupAccumulatorChantSession() {
    final ctx = _chantContext;
    if (ctx == null) return;

    final presetId = ctx.presetAccumulatorId!;
    final groupAccumulatorId = ctx.groupAccumulatorId!;
    final sessionCount = ctx.groupAccumulatorSessionCount ?? 0;

    Future.microtask(() async {
      if (!mounted) return;
      await ref
          .read(malaAccumulationSelectionProvider(presetId).notifier)
          .applyNavigationIntent(groupAccumulatorId);
      if (!mounted) return;
      final countsNotifier = ref.read(
        groupAccumulationCountsProvider(presetId).notifier,
      );
      await countsNotifier.mergeFromServerCounts({
        groupAccumulatorId: sessionCount,
      });
      if (!mounted) return;
      _chantSessionBaseline = countsNotifier.countFor(groupAccumulatorId);
      _seedInitialChantCountIfNeeded();
    });
  }

  void _seedInitialChantCountIfNeeded() {
    if (_hasSeededInitialChantCount) return;
    _hasSeededInitialChantCount = true;

    final ctx = _chantContext;
    if (ctx == null) return;

    _incrementGroupChantCount();
  }

  void _incrementGroupChantCount() {
    final ctx = _chantContext;
    if (ctx == null) return;

    final presetId = ctx.presetAccumulatorId!;
    final groupAccumulatorId = ctx.groupAccumulatorId!;
    final settings = ref.read(malaSettingsProvider);
    ref
        .read(groupAccumulationCountsProvider(presetId).notifier)
        .increment(
          groupAccumulatorId: groupAccumulatorId,
          groups: const [],
          soundEnabled: settings.soundEnabled,
          vibrationEnabled: settings.vibrationEnabled,
          beadsPerRound: kBeadsPerRound,
        );
  }

  void _onChantAgain() {
    _scrollToTop?.call();
    _incrementGroupChantCount();
  }

  Future<void> _addOfflineChantCount() async {
    final count = await showAddOfflineChantsDialog(context);
    if (count == null || count <= 0 || !mounted) return;

    final ctx = _chantContext;
    if (ctx == null) return;

    ref
        .read(
          groupAccumulationCountsProvider(ctx.presetAccumulatorId!).notifier,
        )
        .addCount(
          groupAccumulatorId: ctx.groupAccumulatorId!,
          groups: const [],
          count: count,
        );
  }

  Future<void> _finishChantSession() async {
    final ctx = _chantContext;
    int? finishedSessionCount;
    if (ctx != null) {
      final sessionCount = _groupChantSessionCount();
      final success = await finishGroupAccumulatorSession(
        ref: ref,
        groupAccumulatorId: ctx.groupAccumulatorId!,
        presetId: ctx.presetAccumulatorId!,
        groupId: ctx.groupId,
      );
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.something_went_wrong)),
        );
        return;
      }
      _chantSessionFinished = true;
      finishedSessionCount = sessionCount;
    }
    if (mounted && (_isEmbedded || context.canPop())) {
      PlanNavigator.pop(context, finishedSessionCount);
    }
  }

  int _groupChantSessionCount([Map<String, int>? counts]) {
    final ctx = _chantContext;
    if (ctx == null) return 0;
    final presetId = ctx.presetAccumulatorId!;
    final groupAccumulatorId = ctx.groupAccumulatorId!;
    final notifier = ref.read(
      groupAccumulationCountsProvider(presetId).notifier,
    );
    final absolute =
        counts != null
            ? counts[groupAccumulatorId] ??
                notifier.countFor(groupAccumulatorId)
            : notifier.countFor(groupAccumulatorId);
    return (absolute - _chantSessionBaseline).clamp(0, absolute);
  }

  /// Create the audio controller when the reader was opened from a plan and the
  /// current item has resolvable audio (its own `audioUrl` wins over the
  /// day-level track). Auto-plays when the navigation requested it.
  void _initAudio() {
    final ctx = widget.navigationContext;
    if (ctx == null || ctx.source != NavigationSource.plan) return;
    final item = ctx.currentItem;
    if (item == null) return;
    final url = ctx.effectiveAudioUrlFor(item);
    if (url == null) return;

    _audioController = PlanSegmentAudioController(
      url: url,
      startMs: item.startMs,
      endMs: item.endMs,
      onSegmentComplete: _onAudioSegmentComplete,
    );

    if (ctx.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _audioController?.maybeAutoPlay(),
      );
    }
  }

  @override
  void dispose() {
    _audioController?.dispose();
    super.dispose();
  }

  /// Called when the current item's audio finishes. Mirrors
  /// [SwipeNavigationWrapper]'s forward navigation: mark the subtask complete,
  /// clear transient reader UI, then advance to the next task with auto-play.
  /// Pops the sequence when there is no next task.
  void _onAudioSegmentComplete() {
    if (!mounted || _isAdvancing) return;
    final navContext = widget.navigationContext;
    if (navContext == null) return;

    _audioController?.cancel();
    ref.read(planSubtaskCompletionProvider).completeCurrent(navContext);

    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    notifier.selectSegment(null);
    notifier.closeCommentary();
    notifier.closeTranslation();

    final didNavigate = PlanNavigator.navigateAdjacent(
      context,
      navContext,
      SwipeDirection.next,
      autoPlay: true,
    );

    if (didNavigate) {
      _isAdvancing = true;
    } else if (_isEmbedded || context.canPop()) {
      // Last task in the day — close the sequence.
      PlanNavigator.pop(context);
    }
  }

  // ─── Live recitation ─────────────────────────────────────────────────────

  void _onLiveStateChanged(
    RecitationLiveState? previous,
    RecitationLiveState next,
  ) {
    if (!mounted) return;
    if (next.isEnded && !(previous?.isEnded ?? false)) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.recitation_live_session_ended)),
        );
    }
    final position = next.position;
    if (position == null || !next.isFollowing) return;
    // Where the room already was is not the operator moving on: leave the
    // user on the text they opened. The content part pauses following for
    // them instead.
    if (next.positionIsSnapshot) return;
    final positionChanged = previous?.position != position;
    final followRequested = previous?.followRequest != next.followRequest;
    if (positionChanged || followRequested) _maybeSwitchLiveText(position);
  }

  /// The operator moved to another text of this sequence: go there. Texts
  /// outside the sequence are left alone (the content reports out of sync),
  /// so a stray id can never pull the user off their reading list.
  void _maybeSwitchLiveText(RecitationLivePosition position) {
    final navContext = widget.navigationContext;
    if (navContext == null || _isAdvancing) return;
    final state = ref.read(readerNotifierProvider(_params));
    final primaryVersionId =
        ref.read(readerDualSettingsProvider(widget.textId)).primary.versionId;
    final onThisText = LivePositionResolver.textMatches(
      position,
      loadedTextIds: [widget.textId, state.textDetail?.id, primaryVersionId],
      content: state.content,
    );
    if (onThisText) return;

    final items = navContext.planTextItems;
    if (items == null) return;
    final index = items.indexWhere(
      (item) => item.isSourceReference && item.textId == position.textId,
    );
    if (index < 0) return;
    final newContext = const NavigationService()
        .createNavigationContextForIndex(navContext, index);
    if (newContext == null) return;

    _isAdvancing = true;
    _audioController?.cancel();
    if (navContext.source == NavigationSource.plan &&
        index > (navContext.currentTextIndex ?? -1)) {
      // Moving on with the group finishes this text, as a swipe would.
      ref.read(planSubtaskCompletionProvider).completeCurrent(navContext);
    }
    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    notifier.selectSegment(null);
    notifier.closeCommentary();
    notifier.closeTranslation();
    PlanNavigator.replace(context, items[index], newContext);
  }

  void _onScrollDirectionChanged(bool isScrollingDown) {
    if (!ReaderConstants.enableAppBarAutoHide) return;
    final host = PlanEmbeddedScope.maybeOf(context);
    host?.setContentScrollingDown(isScrollingDown);
    if (isScrollingDown && _isAppBarVisible) {
      setState(() {
        _isAppBarVisible = false;
      });
    } else if (!isScrollingDown && !_isAppBarVisible) {
      setState(() {
        _isAppBarVisible = true;
      });
    }
  }

  void _invalidatePlanProviders() {
    final navContext = widget.navigationContext;
    if (navContext == null || navContext.source != NavigationSource.plan) {
      return;
    }

    final planId = navContext.planId;
    final dayNumber = navContext.dayNumber;
    if (planId == null || dayNumber == null) return;

    ref.invalidate(
      userPlanDayContentFutureProvider(
        PlanDaysParams(planId: planId, dayNumber: dayNumber),
      ),
    );
    ref.invalidate(userPlanDaysCompletionStatusProvider(planId));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
      prefetchBookmarkExistsProvider(
        BookmarkTarget(type: BookmarkType.text, sourceId: widget.textId),
      ),
    );

    final state = ref.watch(readerNotifierProvider(_params));
    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    final readerTheme = _readerTheme(context);
    // The embedded host drops its video to audio while a panel is open.
    ref.listen(
      readerNotifierProvider(
        _params,
      ).select((s) => s.isCommentaryOpen || s.isTranslationOpen),
      (_, isPanelOpen) =>
          PlanEmbeddedScope.maybeOf(context)?.setPanelOpen(isPanelOpen),
    );

    final liveEventId = _liveEventId;
    if (liveEventId != null) {
      // Holds the event socket open for as long as this reader is on screen.
      ref.watch(recitationLiveProvider(liveEventId).select((s) => s.isVisible));
      ref.listen<RecitationLiveState>(
        recitationLiveProvider(liveEventId),
        _onLiveStateChanged,
      );
    }

    if (_isGroupAccumulatorChant) {
      final presetId = _chantContext!.presetAccumulatorId!;
      ref.watch(joinedAccumulatorGroupsProvider(presetId));
      ref.listen(joinedGroupUserCountsProvider(presetId), (_, next) {
        next.whenData((counts) {
          ref
              .read(groupAccumulationCountsProvider(presetId).notifier)
              .mergeFromServerCounts(counts);
        });
      });
    }

    final scaffold = Scaffold(
      backgroundColor: readerTheme.scaffoldBackgroundColor,
      body: _buildBody(context, state, notifier),
    );
    // Embedded, the host owns leaving; there is no route of our own to pop.
    if (_isEmbedded) return Theme(data: readerTheme, child: scaffold);

    return Theme(
      data: readerTheme,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) return;
          // Stop audio immediately so nothing plays during the exit animation.
          _audioController?.cancel();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            // Clear transient reader state after navigation finishes so this
            // cannot mutate Riverpod state while GoRouter rebuilds the tree.
            notifier.selectSegment(null);
            notifier.closeCommentary();
            notifier.closeTranslation();
            _invalidatePlanProviders();
            if (_isGroupAccumulatorChant && !_chantSessionFinished) {
              unawaited(
                ref.read(malaSyncManagerProvider).flush(SyncReason.screenLeave),
              );
            }
          });
        },
        child: scaffold,
      ),
    );
  }

  ThemeData _readerTheme(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness != Brightness.light) return theme;

    return theme.copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: theme.appBarTheme.copyWith(backgroundColor: Colors.white),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReaderState state,
    ReaderNotifier notifier,
  ) {
    final localizations = context.l10n;
    final textDetail = state.textDetail;
    // Loading state; also the first frame, before the initial fetch starts.
    if (state.isLoading || state.status == ReaderStatus.initial) {
      return _buildStatusView(
        context,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(localizations.loading),
            ],
          ),
        ),
      );
    }

    // Error / empty content state — always reachable back navigation so the
    // user is never trapped on a dead-end screen. Technical exception text is
    // never surfaced; we show a friendly, localized message instead.
    if (state.isError || state.textDetail == null) {
      return _buildStatusView(
        context,
        child: _ReaderErrorView(
          title: localizations.no_content,
          message: localizations.noContentAvailable,
          retryLabel: localizations.retry,
          backLabel: localizations.back,
          onRetry: () => notifier.reload(),
          onBack: () => _navigateBack(context),
        ),
      );
    }

    final isPanelOpen = state.isCommentaryOpen || state.isTranslationOpen;
    final isActionBarVisible = state.hasSelection && !isPanelOpen;
    final isBottomOverlayVisible =
        !isPanelOpen && (_hasAudio || isActionBarVisible);
    final chantBarHeight =
        _isGroupAccumulatorChant ? GroupAccumulatorChantBar.barHeight : 0.0;
    final chantSessionCount =
        _isGroupAccumulatorChant
            ? _groupChantSessionCount(
              ref.watch(
                groupAccumulationCountsProvider(
                  _chantContext!.presetAccumulatorId!,
                ),
              ),
            )
            : 0;
    final contentBottomPadding =
        (isBottomOverlayVisible
            ? (_bottomOverlayHeight > 0
                ? _bottomOverlayHeight + 16
                : _selectedSegmentOverlayFallbackHeight)
            : _defaultContentBottomPadding) +
        chantBarHeight;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final chantFooter =
        _isGroupAccumulatorChant && !isPanelOpen
            ? GroupAccumulatorChantFooter(
              onChantAgain: _onChantAgain,
              onFinishSession: _finishChantSession,
            )
            : null;

    return Stack(
      children: [
        // Audio in the background of an open panel: keep the button alive
        // (playing or paused) but paint it *under* the content so the opaque
        // panel covers it. Rendered first so it sits behind everything.
        if (_hasAudio && isPanelOpen)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + _audioBottomGap,
            child: Center(child: _buildAudioButton()),
          ),
        // Main content area
        SafeArea(
          child: Column(
            children: [
              // App bar slides up out of view on scroll-down.
              SlideAwayHeader(
                visible: _isAppBarVisible,
                child: _buildAppBar(context, state, textDetail),
              ),
              // Main scrollable content
              Expanded(
                child: SwipeNavigationWrapper(
                  params: _params,
                  textDetail: state.textDetail!,
                  isAppBarVisible: _isAppBarVisible,
                  child: ReaderTranslationSplitView(
                    params: _params,
                    // Reader content with scroll detection. The segment
                    // action bar is hosted in the screen-level bottom
                    // overlay so it can share a fixed gap with the
                    // floating audio button.
                    mainContent: ReaderCommentarySplitView(
                      params: _params,
                      mainContent: ReaderContentPart(
                        params: _params,
                        language: state.textDetail!.language,
                        initialSegmentId: widget.segmentId,
                        visibleSegmentIds:
                            widget.navigationContext?.currentSegmentIds,
                        bottomPadding: contentBottomPadding,
                        chantSessionFooter: chantFooter,
                        onScrollDirectionChanged: _onScrollDirectionChanged,
                        onScrollControllerReady: (scrollFn) {
                          _scrollToSegment = scrollFn;
                        },
                        onScrollToTopReady: (scrollFn) {
                          _scrollToTop = scrollFn;
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (_isGroupAccumulatorChant)
                GroupAccumulatorChantBar(
                  presetId: _chantContext!.presetAccumulatorId!,
                  groupAccumulatorId: _chantContext!.groupAccumulatorId!,
                  sessionCount: chantSessionCount,
                  chantTitle: textDetail!.title,
                  chantTitleFontFamily: getFontFamily(textDetail.language),
                ),
            ],
          ),
        ),
        // Bottom overlay (only when no panel is open): the floating audio
        // button sits above the segment action bar, sharing a fixed gap so
        // the two never overlap. When neither is present this branch is
        // skipped entirely.
        if (isBottomOverlayVisible)
          Positioned(
            left: 0,
            right: 0,
            bottom: isActionBarVisible ? 0 : chantBarHeight,
            child: _MeasuredSize(
              onChange: (size) {
                if ((_bottomOverlayHeight - size.height).abs() < 1) return;
                setState(() => _bottomOverlayHeight = size.height);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // Stretch so the action bar spans full width; the audio button
                // is centered explicitly.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_hasAudio)
                    Padding(
                      // Hug the action bar with a tight gap when it is open;
                      // otherwise keep the original floating offset above bottom.
                      padding: EdgeInsets.only(
                        bottom:
                            isActionBarVisible
                                ? _audioActionBarGap
                                : bottomInset + _audioBottomGap,
                      ),
                      child: Center(child: _buildAudioButton()),
                    ),
                  if (isActionBarVisible)
                    _buildSegmentActionBar(state, notifier),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Embedded: a close bar with font size and languages instead of the app bar.
  /// Either bar carries the live sync button when following an event.
  Widget _buildAppBar(
    BuildContext context,
    ReaderState state,
    TextDetail? textDetail,
  ) {
    final liveEventId = _liveEventId;
    final liveSyncToggle =
        liveEventId == null
            ? null
            : RecitationLiveSyncToggle(eventId: liveEventId);
    if (_isEmbedded) {
      return PlanEmbeddedHeader(
        onClose: _closeEmbedded,
        actions: [
          if (liveSyncToggle != null) liveSyncToggle,
          ReaderFontSizeButton(
            onPressed: () => showFontSizeBottomSheet(context),
          ),
          ReaderLanguagesButton(
            params: _params,
            onPressed: () => _openLanguagesSheet(context, textDetail),
          ),
        ],
      );
    }
    return ReaderAppBarOverlay(
      params: _params,
      colorIndex: widget.colorIndex,
      liveSyncToggle: liveSyncToggle,
      onSearchPressed: () => _handleSearch(context, state),
      onLanguagesPressed: () => _openLanguagesSheet(context, textDetail),
      // The event page already offers share and offline recitations.
      onMorePressed:
          liveEventId == null
              ? () => _openMoreBottomSheet(context, textDetail)
              : null,
    );
  }

  /// The embedded host has no route of its own, so the leave work that the
  /// route's PopScope would do (see [build]) runs here instead.
  void _closeEmbedded() {
    _audioController?.cancel();
    _invalidatePlanProviders();
    if (_isGroupAccumulatorChant && !_chantSessionFinished) {
      unawaited(
        ref.read(malaSyncManagerProvider).flush(SyncReason.screenLeave),
      );
    }
    PlanNavigator.pop(context);
  }

  /// The floating plan audio play/pause control. Keyed so its animation state
  /// survives reparenting between the behind-panel slot and the bottom overlay.
  Widget _buildAudioButton() {
    return PlanAudioButton(key: _audioButtonKey, controller: _audioController!);
  }

  /// Segment action bar wired to the reader notifier. Scrolls the selected
  /// segment to the top when a commentary/translation panel is opened.
  Widget _buildSegmentActionBar(ReaderState state, ReaderNotifier notifier) {
    return SegmentActionBar(
      segment: state.selectedSegment!,
      params: _params,
      onClose: () => notifier.selectSegment(null),
      onOpenCommentary: () {
        if (_scrollToSegment != null && state.selectedSegment != null) {
          _scrollToSegment!(state.selectedSegment!.segmentId, alignment: 0.0);
        }
      },
      onOpenTranslation: () {
        if (_scrollToSegment != null && state.selectedSegment != null) {
          _scrollToSegment!(state.selectedSegment!.segmentId, alignment: 0.0);
        }
      },
    );
  }

  /// Wraps a status view (loading / error / empty) in a [SafeArea] with a
  /// minimal app bar that always exposes a back button. This guarantees the
  /// user can leave the screen even when content fails to load.
  Widget _buildStatusView(BuildContext context, {required Widget child}) {
    if (_isEmbedded) {
      return Column(
        children: [
          PlanEmbeddedHeader(onClose: () => _navigateBack(context)),
          Expanded(child: child),
        ],
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                tooltip: context.l10n.back,
                onPressed: () => _navigateBack(context),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  /// Pops back if possible, otherwise falls back to the home route so the user
  /// is never stranded (e.g. when arriving via a deep link with no history).
  void _navigateBack(BuildContext context) {
    if (_isEmbedded || context.canPop()) {
      PlanNavigator.pop(context);
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleSearch(BuildContext context, ReaderState state) async {
    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    final router = ref.read(appRouterProvider);

    // Close selection before search
    notifier.selectSegment(null);
    notifier.closeCommentary();
    notifier.closeTranslation();

    final result = await showSearch<Map<String, String>?>(
      context: context,
      delegate: ReaderSearchDelegate(
        ref: ref,
        textId: widget.textId,
        language: state.textDetail?.language,
      ),
    );

    if (result != null && mounted) {
      final selectedTextId = result['textId']!;
      final selectedSegmentId = result['segmentId']!;

      if (selectedTextId == widget.textId) {
        router.pushReplacement(
          '/reader/$selectedTextId',
          extra: NavigationContext(
            source: NavigationSource.search,
            targetSegmentId: selectedSegmentId,
          ),
        );
      }
    }
  }

  Future<void> _openLanguagesSheet(
    BuildContext context,
    TextDetail? textDetail,
  ) async {
    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    notifier.selectSegment(null);
    notifier.closeCommentary();
    notifier.closeTranslation();

    // Snapshot of the loaded text so the drawer can show it as "Original".
    final languageCode = textDetail?.language ?? 'en';
    final primaryDisplay = ReaderSlotConfig(
      languageCode: languageCode,
      languageLabel: getLanguageName(languageCode, context),
      versionId: textDetail?.id,
      versionLabel: textDetail?.title,
    );

    await showReaderLanguagesSheet(
      context,
      textId: widget.textId,
      primaryDisplay: primaryDisplay,
    );
  }

  void _openMoreBottomSheet(BuildContext context, TextDetail? textDetail) {
    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    notifier.selectSegment(null);
    notifier.closeCommentary();
    notifier.closeTranslation();

    final showAddToPractices =
        (widget.navigationContext?.source == NavigationSource.recitationList ||
            widget.navigationContext?.source == NavigationSource.routine) &&
        textDetail != null;

    showReaderMoreBottomSheet(
      context,
      textId: widget.textId,
      showAddToPractices: showAddToPractices,
      showOfflineRecitation: _isGroupAccumulatorChant,
      onAddToPractices:
          showAddToPractices
              ? () => _openRoutineWithRecitation(context, textDetail)
              : null,
      onAddOfflineRecitation:
          _isGroupAccumulatorChant ? _addOfflineChantCount : null,
    );
  }

  void _openRoutineWithRecitation(BuildContext context, TextDetail textDetail) {
    context.push(
      AppRoutes.practiceEditRoutine,
      extra: {
        'initialRecitation': RecitationModel(
          textId: widget.textId,
          title: textDetail.title,
          language: textDetail.language,
        ),
      },
    );
  }
}

/// Friendly, centered error/empty state for the reader with retry and back
/// actions. Intentionally hides raw exception details from the user.
class _ReaderErrorView extends StatelessWidget {
  final String title;
  final String message;
  final String retryLabel;
  final String backLabel;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ReaderErrorView({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.backLabel,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(backLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasuredSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const _MeasuredSize({required this.child, required this.onChange});

  @override
  State<_MeasuredSize> createState() => _MeasuredSizeState();
}

class _MeasuredSizeState extends State<_MeasuredSize> {
  Size? _oldSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
  }

  @override
  void didUpdateWidget(covariant _MeasuredSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
  }

  void _notifySize() {
    if (!mounted) return;
    final size = context.size;
    if (size == null || size == _oldSize) return;
    _oldSize = size;
    widget.onChange(size);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
