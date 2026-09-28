import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Padding above and below the label of a row in a Languages sheet list.
const double readerOptionRowPadding = 14;

/// Rows a list shows before the rest scroll inside it. The half row is the
/// hint that there is more.
const double _visibleRows = 3.5;

/// Room kept clear on the right for the scrollbar, so it never sits on a
/// row's tick or caret.
const double _scrollbarGutter = 8;

const Duration _revealDuration = Duration(milliseconds: 250);

/// Height of a one-line row whose label is in [style]: the label line at
/// [textScaler], the padding above and below it, and the divider under it.
@visibleForTesting
double readerOptionRowHeight(TextStyle? style, TextScaler textScaler) {
  final painter = TextPainter(
    text: TextSpan(text: 'Ag', style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final lineHeight = painter.height;
  painter.dispose();
  return lineHeight + readerOptionRowPadding * 2 + 1;
}

/// Where to scroll a list so a block is in view, or null to stay put.
/// [top] and [bottom] are the offsets that put the block's top at the top of
/// the list, or its bottom at the bottom.
///
/// A block that fits moves as little as possible. A taller one shows its
/// top, unless the list is already somewhere inside it.
@visibleForTesting
double? readerOptionRevealOffset({
  required double current,
  required double top,
  required double bottom,
  required double min,
  required double max,
}) {
  final double target;
  if (bottom <= top) {
    target = clampDouble(current, bottom, top);
  } else if (current >= top && current <= bottom) {
    target = current;
  } else {
    target = top;
  }
  final clamped = clampDouble(target, min, max);
  return clamped == current ? null : clamped;
}

/// A dropdown's rows in the Languages sheet: about three and a half show and
/// the rest scroll inside the list, with a scrollbar while it overflows.
///
/// The child at [revealIndex] is kept in view. The list scrolls to it when it
/// first lays out, when [revealIndex] changes, and when the rows change height
/// (a language opening, its versions arriving). Only this list scrolls, never
/// the sheet around it.
///
/// A row inside that child can carry [revealKey] (the checked version under
/// an open language). The list then shows the child's top through that row
/// when the two fit together, and the row alone when they do not, so the
/// pick is never left below the fold.
class ReaderOptionList extends StatefulWidget {
  const ReaderOptionList({
    super.key,
    required this.children,
    this.revealIndex,
    this.revealKey,
  });

  final List<Widget> children;
  final int? revealIndex;
  final GlobalKey? revealKey;

  @override
  State<ReaderOptionList> createState() => _ReaderOptionListState();
}

class _ReaderOptionListState extends State<ReaderOptionList> {
  final _controller = ScrollController();
  final _keys = <GlobalKey>[];
  bool _revealScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleReveal(animate: false);
  }

  @override
  void didUpdateWidget(ReaderOptionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revealIndex != widget.revealIndex) _scheduleReveal();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  GlobalKey _keyAt(int index) {
    while (_keys.length <= index) {
      _keys.add(GlobalKey());
    }
    return _keys[index];
  }

  void _scheduleReveal({bool animate = true}) {
    if (_revealScheduled) return;
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      if (mounted) _reveal(animate: animate);
    });
  }

  void _reveal({required bool animate}) {
    final index = widget.revealIndex;
    if (index == null || index >= _keys.length || !_controller.hasClients) {
      return;
    }
    final block = _keys[index].currentContext?.findRenderObject();
    final viewport = RenderAbstractViewport.maybeOf(block);
    if (block == null || viewport == null) return;
    var top = viewport.getOffsetToReveal(block, 0).offset;
    var bottom = viewport.getOffsetToReveal(block, 1).offset;
    final row = widget.revealKey?.currentContext?.findRenderObject();
    if (row != null && RenderAbstractViewport.maybeOf(row) == viewport) {
      final rowBottom = viewport.getOffsetToReveal(row, 1).offset;
      if (rowBottom <= top) {
        // The block's top through the row fits: show both.
        bottom = rowBottom;
      } else {
        // Too tall together: the row is what matters.
        top = viewport.getOffsetToReveal(row, 0).offset;
        bottom = rowBottom;
      }
    }
    final position = _controller.position;
    final offset = readerOptionRevealOffset(
      current: position.pixels,
      top: top,
      bottom: bottom,
      min: position.minScrollExtent,
      max: position.maxScrollExtent,
    );
    if (offset == null) return;
    if (animate) {
      position.animateTo(
        offset,
        duration: _revealDuration,
        curve: Curves.easeOutCubic,
      );
    } else {
      position.jumpTo(offset);
    }
  }

  bool _onSizeChanged(SizeChangedLayoutNotification notification) {
    _scheduleReveal();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final rowHeight = readerOptionRowHeight(
      Theme.of(context).textTheme.bodyLarge,
      MediaQuery.textScalerOf(context),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: rowHeight * _visibleRows),
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _controller,
          padding: const EdgeInsets.only(right: _scrollbarGutter),
          child: NotificationListener<SizeChangedLayoutNotification>(
            onNotification: _onSizeChanged,
            child: SizeChangedLayoutNotifier(
              child: Column(
                children: [
                  for (var i = 0; i < widget.children.length; i++)
                    KeyedSubtree(key: _keyAt(i), child: widget.children[i]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
