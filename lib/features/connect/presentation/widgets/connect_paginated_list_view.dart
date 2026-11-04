import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';

/// Builds a scrollable list with standard loading, error, empty, and
/// paginated footer states for Connect My/Discover tabs.
class ConnectPaginatedListView<T> extends StatelessWidget {
  const ConnectPaginatedListView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
    required this.hasMore,
    required this.onRetry,
    required this.itemBuilder,
    this.scrollController,
    this.scrollViewKey,
    this.header,
    this.separatorHeight = 0,
    this.useHairlineDividers = true,
    this.padding = const EdgeInsets.fromLTRB(0, 0, 0, 24),
    this.emptyDiscoverMessage,
    this.myEmptyState,
    this.leadingItemCount = 0,
    this.leadingItemBuilder,
    this.hasLoaded = true,
  });

  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final ScrollController? scrollController;
  final Key? scrollViewKey;
  final Widget? header;
  final VoidCallback onRetry;
  final IndexedWidgetBuilder itemBuilder;
  final double separatorHeight;
  final bool useHairlineDividers;
  final EdgeInsets padding;
  final String? emptyDiscoverMessage;
  final Widget? myEmptyState;
  final int leadingItemCount;
  final WidgetBuilder? leadingItemBuilder;

  /// Whether the first fetch has settled. While false the loader is shown
  /// instead of an empty state, so switching tabs never flashes "no content"
  /// before the request that was scheduled for the next frame starts.
  final bool hasLoaded;

  @override
  Widget build(BuildContext context) {
    if ((isLoading || !hasLoaded) && items.isEmpty) {
      return _scrollableState(const Center(child: CircularProgressIndicator()));
    }

    if (error != null && items.isEmpty) {
      return _scrollableState(
        ErrorStateWidget(error: error!, onRetry: onRetry),
      );
    }

    if (items.isEmpty) {
      if (myEmptyState != null) {
        return _scrollableState(myEmptyState!, hasScrollBody: false);
      }

      if (emptyDiscoverMessage != null) {
        return _scrollableState(
          Center(
            child: Text(
              emptyDiscoverMessage!,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }

      return _scrollableState(const SizedBox.shrink());
    }

    final itemCount = leadingItemCount + items.length + (hasMore ? 1 : 0);

    return CustomScrollView(
      key: scrollViewKey,
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (header != null) SliverToBoxAdapter(child: header!),
        SliverPadding(
          padding: padding,
          sliver: SliverList.separated(
            itemCount: itemCount,
            separatorBuilder: (context, _) {
              if (useHairlineDividers) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
                );
              }
              if (separatorHeight <= 0) {
                return const SizedBox.shrink();
              }
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return ColoredBox(
                color:
                    isDark
                        ? AppColors.scaffoldBackgroundDark
                        : AppColors.scaffoldBackgroundLight,
                child: SizedBox(height: separatorHeight),
              );
            },
            itemBuilder: (context, index) {
              if (index < leadingItemCount) {
                return leadingItemBuilder!(context);
              }

              final dataIndex = index - leadingItemCount;
              if (dataIndex == items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child:
                        isLoadingMore
                            ? const CircularProgressIndicator()
                            : const SizedBox.shrink(),
                  ),
                );
              }

              return itemBuilder(context, dataIndex);
            },
          ),
        ),
      ],
    );
  }

  Widget _scrollableState(Widget child, {bool hasScrollBody = true}) {
    return CustomScrollView(
      key: scrollViewKey,
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (header != null) SliverToBoxAdapter(child: header!),
        SliverFillRemaining(hasScrollBody: hasScrollBody, child: child),
      ],
    );
  }
}
