import 'package:flutter/widgets.dart';

extension ScrollControllerLayoutX on ScrollController {
  /// Whether the single attached scroll view has been laid out, so its
  /// viewport size and scroll extents can be read.
  ///
  /// [ScrollController.hasClients] is not enough. A scroll view attaches when
  /// it is built, but its sizes only exist after its first layout. Reading
  /// them earlier throws "Null check operator used on a null value".
  bool get hasLaidOutPosition {
    if (positions.length != 1) return false;
    final position = positions.single;
    return position.hasViewportDimension && position.hasContentDimensions;
  }
}
