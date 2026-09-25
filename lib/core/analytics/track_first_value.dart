import 'package:flutter/widgets.dart';

/// Calls [onFirstValue] once, the first time [value] is non-null, so a
/// stateless screen can report a view as soon as its async data lands.
class TrackFirstValue<T extends Object> extends StatefulWidget {
  const TrackFirstValue({
    super.key,
    required this.value,
    required this.onFirstValue,
    required this.child,
  });

  final T? value;
  final void Function(T value) onFirstValue;
  final Widget child;

  @override
  State<TrackFirstValue<T>> createState() => _TrackFirstValueState<T>();
}

class _TrackFirstValueState<T extends Object>
    extends State<TrackFirstValue<T>> {
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _fireIfReady();
  }

  @override
  void didUpdateWidget(covariant TrackFirstValue<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fireIfReady();
  }

  void _fireIfReady() {
    final T? value = widget.value;
    if (_fired || value == null) return;
    _fired = true;
    widget.onFirstValue(value);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
