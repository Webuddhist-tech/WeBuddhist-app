import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_button.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_embedded_host.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigation_bottom_bar.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_segment_audio_controller.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_subtask_completion.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_bottom_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_button.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight reading screen for inline plan subtasks (`TEXT` or `IMAGE`).
///
/// For `TEXT`, subtask `content` is treated as markdown and rendered via
/// [PlanInlineMarkdownView]. For `IMAGE`, subtask `content` is treated as the
/// image URL and rendered directly.
///
/// Audio behaviour (shared with `ReaderScreen` via
/// [PlanSegmentAudioController]):
/// - A floating play/pause button appears when the task has resolvable audio
///   (its own `audioUrl`, or the day-level track as fallback).
/// - Tapping it plays the task's segment. When the segment ends the screen
///   auto-advances to the next task with auto-play.
/// - Audio stops on any manual navigation or back press — no leaks.
class PlanTextScreen extends ConsumerStatefulWidget {
  final NavigationContext navigationContext;
  const PlanTextScreen({super.key, required this.navigationContext});

  @override
  ConsumerState<PlanTextScreen> createState() => _PlanTextScreenState();
}

class _PlanTextScreenState extends ConsumerState<PlanTextScreen> {
  // ─── Navigation state ──────────────────────────────────────────────────
  bool _isNavigating = false;
  double _dragOffset = 0.0;
  bool _isDragging = false;

  // ─── Audio ─────────────────────────────────────────────────────────────
  PlanSegmentAudioController? _audioController;

  bool get _hasAudio => _audioController?.hasAudio ?? false;

  bool get _isEmbedded => PlanEmbeddedScope.maybeOf(context) != null;

  // ─── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initAudio();
    if (widget.navigationContext.autoPlay && _hasAudio) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _audioController?.maybeAutoPlay(),
      );
    }
  }

  /// Resolve the audio for the current item (subtask audio wins over the
  /// day-level track) and create the controller if any audio is available.
  void _initAudio() {
    final ctx = widget.navigationContext;
    final item = ctx.currentItem;
    if (item == null) return;
    final url = ctx.effectiveAudioUrlFor(item);
    if (url == null) return;
    _audioController = PlanSegmentAudioController(
      url: url,
      startMs: item.startMs,
      endMs: item.endMs,
      onSegmentComplete: _autoAdvance,
    );
  }

  @override
  void dispose() {
    _audioController?.dispose();
    super.dispose();
  }

  /// Called by the audio controller when the segment finishes. Marks the
  /// current subtask complete and navigates to the next task with auto-play.
  /// Falls through to [_finish] on the last task.
  void _autoAdvance() {
    if (!mounted || _isNavigating) return;

    _audioController?.cancel();
    ref
        .read(planSubtaskCompletionProvider)
        .completeCurrent(widget.navigationContext);

    final didNavigate = PlanNavigator.navigateAdjacent(
      context,
      widget.navigationContext,
      SwipeDirection.next,
      autoPlay: true,
    );

    if (didNavigate) {
      setState(() => _isNavigating = true);
    } else {
      _finish(); // no next task — close the sequence
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  ThemeData _readerTheme(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness != Brightness.light) return theme;

    return theme.copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: theme.appBarTheme.copyWith(backgroundColor: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.navigationContext.currentItem;
    final fontSize = ref.watch(fontSizeProvider);
    final readerTheme = _readerTheme(context);

    if (currentItem == null || !_hasRenderableContent(currentItem)) {
      return Theme(
        data: readerTheme,
        child: _buildMissingContentScaffold(context),
      );
    }

    final canSwipe = widget.navigationContext.canSwipe;

    return Theme(
      data: readerTheme,
      child: Scaffold(
        backgroundColor: readerTheme.scaffoldBackgroundColor,
        appBar:
            _isEmbedded
                ? _buildEmbeddedHeader(
                  context,
                  showFontControls: currentItem.isInlineText,
                )
                : _buildAppBar(
                  context,
                  currentItem.title,
                  showFontControls: currentItem.isInlineText,
                ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: canSwipe ? _onDragStart : null,
          onHorizontalDragUpdate: canSwipe ? _onDragUpdate : null,
          onHorizontalDragEnd: canSwipe ? _onDragEnd : null,
          onHorizontalDragCancel: canSwipe ? _onDragCancel : null,
          child: SafeArea(
            child: AnimatedContainer(
              duration: Duration(milliseconds: _isDragging ? 0 : 250),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_dragOffset * 0.25, 0, 0),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        if (currentItem.isInlineImage)
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: _hasAudio ? 72 : 0,
                              ),
                              child: _buildInlineImage(item: currentItem),
                            ),
                          )
                        else
                          SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              16,
                              20,
                              _hasAudio ? 88 : 16,
                            ),
                            child: _buildInlineText(
                              content: currentItem.inlineContent!,
                              fontSize: fontSize,
                            ),
                          ),
                        // Floating play/pause — overlaid, zero layout footprint.
                        if (_hasAudio)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 8,
                            child: Center(
                              child: PlanAudioButton(
                                controller: _audioController!,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PlanNavigationBottomBar(
                    navigationContext: widget.navigationContext,
                    fallbackTitle: currentItem.title,
                    onPreviousTap: () => _navigate(SwipeDirection.previous),
                    onNextTap: () => _navigate(SwipeDirection.next),
                    onFinishedTap: _finish,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasRenderableContent(PlanTextItem item) {
    switch (item.contentType) {
      case PlanItemContentType.inlineText:
        return item.inlineContent?.trim().isNotEmpty == true;
      case PlanItemContentType.inlineImage:
        return item.imageUrl?.trim().isNotEmpty == true;
      case PlanItemContentType.sourceReference:
        return false;
    }
  }

  Widget _buildInlineText({
    required String content,
    required double fontSize,
  }) {
    return PlanInlineMarkdownView(content: content, fontSize: fontSize);
  }

  /// Scales the image to fill the available viewport while preserving aspect
  /// ratio (no cropping). Uses both width and height so tall/portrait images
  /// also expand to use the full screen area.
  Widget _buildInlineImage({required PlanTextItem item}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : null;
        final height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : null;

        return CachedNetworkImageWidget(
          imageUrl: item.imageUrl,
          width: width,
          height: height,
          fit: BoxFit.contain,
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    String title, {
    required bool showFontControls,
  }) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(AppAssets.arrowLeft),
        onPressed: _close,
      ),
      centerTitle: true,
      actions:
          showFontControls
              ? [
                ReaderFontSizeButton(
                  onPressed: () => showFontSizeBottomSheet(context),
                ),
                const SizedBox(width: 12),
              ]
              : null,
    );
  }

  PreferredSizeWidget _buildEmbeddedHeader(
    BuildContext context, {
    required bool showFontControls,
  }) {
    return PlanEmbeddedHeader(
      onClose: _close,
      actions: [
        if (showFontControls)
          ReaderFontSizeButton(
            onPressed: () => showFontSizeBottomSheet(context),
          ),
      ],
    );
  }

  Widget _buildMissingContentScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar:
          _isEmbedded
              ? PlanEmbeddedHeader(onClose: _close)
              : AppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: IconButton(
                  icon: const Icon(AppAssets.arrowLeft),
                  onPressed: _close,
                ),
              ),
      body: Center(child: Text(context.l10n.no_content)),
    );
  }

  void _close() {
    _audioController?.cancel();
    PlanNavigator.pop(context);
  }

  // ─── Drag / swipe ──────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    if (_isNavigating) return;
    setState(() {
      _isDragging = true;
      _dragOffset = 0.0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isNavigating) return;
    setState(() => _dragOffset += details.primaryDelta ?? 0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isNavigating) {
      _resetDrag();
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isHighVelocity =
        velocity.abs() >= ReaderConstants.swipeVelocityThreshold;
    final isFarDrag = _dragOffset.abs() > screenWidth * 0.2;

    if (isHighVelocity || isFarDrag) {
      final goNext = velocity < 0 || (velocity == 0 && _dragOffset < 0);
      _navigate(goNext ? SwipeDirection.next : SwipeDirection.previous);
    }
    _resetDrag();
  }

  void _onDragCancel() => _resetDrag();

  void _resetDrag() {
    setState(() {
      _isDragging = false;
      _dragOffset = 0.0;
    });
  }

  // ─── Navigation ────────────────────────────────────────────────────────

  void _navigate(SwipeDirection direction) {
    if (_isNavigating) return;
    if (direction == SwipeDirection.next) {
      ref
          .read(planSubtaskCompletionProvider)
          .completeCurrent(widget.navigationContext);
    }
    _audioController?.cancel();
    final didNavigate = PlanNavigator.navigateAdjacent(
      context,
      widget.navigationContext,
      direction,
    );
    if (!didNavigate && direction == SwipeDirection.next) {
      _finish();
      return;
    }
    if (didNavigate) setState(() => _isNavigating = true);
  }

  void _finish() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    _audioController?.cancel();
    await ref
        .read(planSubtaskCompletionProvider)
        .completeCurrent(widget.navigationContext);
    if (!mounted) return;
    PlanNavigator.pop(context);
  }
}
