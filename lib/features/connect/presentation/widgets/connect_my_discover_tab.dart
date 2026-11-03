import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_segmented_control.dart';

typedef ConnectSegmentChildBuilder =
    Widget Function(
      BuildContext context,
      VoidCallback switchToDiscover,
      Widget scrollHeader,
    );

/// Shared My / Discover segmented tab scaffold with threshold-based pagination.
class ConnectMyDiscoverTab extends StatefulWidget {
  const ConnectMyDiscoverTab({
    super.key,
    this.initialSegment = 0,
    required this.myBuilder,
    required this.discoverBuilder,
    this.onMyRefresh,
    this.onDiscoverRefresh,
    this.onMyLoadMore,
    this.onDiscoverLoadMore,
    this.onSegmentChanged,
  });

  final int initialSegment;
  final ConnectSegmentChildBuilder myBuilder;
  final ConnectSegmentChildBuilder discoverBuilder;
  final Future<void> Function()? onMyRefresh;
  final Future<void> Function()? onDiscoverRefresh;
  final VoidCallback? onMyLoadMore;
  final VoidCallback? onDiscoverLoadMore;
  final ValueChanged<int>? onSegmentChanged;

  @override
  State<ConnectMyDiscoverTab> createState() => _ConnectMyDiscoverTabState();
}

class _ConnectMyDiscoverTabState extends State<ConnectMyDiscoverTab> {
  static const _paginationThreshold = 200.0;

  late int _selectedSegment;

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialSegment.clamp(0, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onSegmentChanged?.call(_selectedSegment);
    });
  }

  bool _handleScrollNotification(
    ScrollNotification notification,
    VoidCallback? loadMore,
  ) {
    if (loadMore == null) return false;
    if (notification.metrics.pixels <
        notification.metrics.maxScrollExtent - _paginationThreshold) {
      return false;
    }
    loadMore();
    return false;
  }

  void _switchToDiscover() => _selectSegment(1);

  void _selectSegment(int index) {
    if (_selectedSegment == index) return;
    setState(() => _selectedSegment = index);
    widget.onSegmentChanged?.call(index);
  }

  Widget _buildScrollHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: ConnectSegmentedControl(
        segments: [
          context.l10n.connect_segment_my,
          context.l10n.connect_segment_discover,
        ],
        selectedIndex: _selectedSegment,
        onChanged: _selectSegment,
      ),
    );
  }

  Widget _buildSegment({
    required ConnectSegmentChildBuilder builder,
    required Future<void> Function()? onRefresh,
    required VoidCallback? onLoadMore,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: NotificationListener<ScrollNotification>(
        onNotification:
            (notification) =>
                _handleScrollNotification(notification, onLoadMore),
        child: builder(context, _switchToDiscover, _buildScrollHeader()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _selectedSegment,
      children: [
        _buildSegment(
          builder: widget.myBuilder,
          onRefresh: widget.onMyRefresh,
          onLoadMore: widget.onMyLoadMore,
        ),
        _buildSegment(
          builder: widget.discoverBuilder,
          onRefresh: widget.onDiscoverRefresh,
          onLoadMore: widget.onDiscoverLoadMore,
        ),
      ],
    );
  }
}
