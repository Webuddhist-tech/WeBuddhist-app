import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Builds its child but skips laying it out while [skip] is true.
///
/// Reproduces a scroll view that is attached to its controller but has never
/// been laid out, so reading its viewport size or scroll extent throws
/// "Null check operator used on a null value". Flip [skip] to false to let
/// the first layout happen.
class SkipLayout extends SingleChildRenderObjectWidget {
  const SkipLayout({super.key, required this.skip, required super.child});

  final bool skip;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSkipLayout(skip);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSkipLayout renderObject,
  ) {
    renderObject.skip = skip;
  }
}

class RenderSkipLayout extends RenderProxyBox {
  RenderSkipLayout(this._skip);

  bool _skip;
  set skip(bool value) {
    if (value == _skip) return;
    _skip = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  @override
  void performLayout() {
    if (_skip) {
      size = constraints.biggest;
    } else {
      super.performLayout();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_skip) super.paint(context, offset);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (!_skip) super.visitChildrenForSemantics(visitor);
  }
}
