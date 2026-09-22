import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_languages_button.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_search_button.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// App bar overlay for the reader screen - animates in/out based on scroll
class ReaderAppBarOverlay extends ConsumerWidget {
  final ReaderParams params;
  final int? colorIndex;
  final VoidCallback onSearchPressed;

  /// Opens the Languages drawer (original + translation).
  final VoidCallback onLanguagesPressed;

  /// Opens the "more" bottom sheet (font size, add-to-practices, bookmark…).
  /// The menu button is hidden when null.
  final VoidCallback? onMorePressed;

  /// Live recitation sync button, shown before search.
  final Widget? liveSyncToggle;

  const ReaderAppBarOverlay({
    super.key,
    required this.params,
    this.colorIndex,
    required this.onSearchPressed,
    required this.onLanguagesPressed,
    this.onMorePressed,
    this.liveSyncToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    // Get the border color from the color index
    final borderColor =
        colorIndex != null
            ? TextScreenConstants.collectionCyclingColors[colorIndex! % 9]
            : TextScreenConstants.primaryBorderColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          elevation: ReaderConstants.appBarElevation,
          scrolledUnderElevation: ReaderConstants.appBarElevation,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () {
              // Clear selection states before navigating back
              notifier.selectSegment(null);
              notifier.closeCommentary();
              notifier.closeTranslation();
              _navigateBack(context);
            },
          ),
          toolbarHeight: ReaderConstants.appBarToolbarHeight,
          actions: [
            if (liveSyncToggle != null) liveSyncToggle!,
            ReaderSearchButton(onPressed: onSearchPressed),
            ReaderLanguagesButton(
              params: params,
              onPressed: onLanguagesPressed,
            ),
            const SizedBox(width: 4),
            if (onMorePressed != null) ...[
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onMorePressed,
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
        // Bottom border
        Container(
          height: ReaderConstants.appBarBottomHeight,
          color: borderColor,
        ),
      ],
    );
  }
}

/// SliverAppBar version for use with CustomScrollView (kept for reference)
class ReaderAppBar extends ConsumerWidget {
  final ReaderParams params;
  final int? colorIndex;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onLanguagesPressed;
  final VoidCallback? onMorePressed;

  const ReaderAppBar({
    super.key,
    required this.params,
    this.colorIndex,
    this.onSearchPressed,
    this.onLanguagesPressed,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    // Get the border color from the color index
    final borderColor =
        colorIndex != null
            ? TextScreenConstants.collectionCyclingColors[colorIndex! % 9]
            : TextScreenConstants.primaryBorderColor;

    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: ReaderConstants.appBarElevation,
      scrolledUnderElevation: ReaderConstants.appBarElevation,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          // Clear selection states before navigating back
          notifier.selectSegment(null);
          notifier.closeCommentary();
          notifier.closeTranslation();
          _navigateBack(context);
        },
      ),
      toolbarHeight: ReaderConstants.appBarToolbarHeight,
      actions: [
        ReaderSearchButton(
          onPressed: onSearchPressed ?? () => _handleSearch(context, ref),
        ),
        ReaderLanguagesButton(
          params: params,
          onPressed: onLanguagesPressed ?? () {},
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onMorePressed ?? () {},
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(
          ReaderConstants.appBarBottomHeight,
        ),
        child: Container(
          height: ReaderConstants.appBarBottomHeight,
          color: borderColor,
        ),
      ),
    );
  }

  void _handleSearch(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(readerNotifierProvider(params).notifier);
    notifier.closeCommentary();
    notifier.closeTranslation();
    notifier.selectSegment(null);
  }
}

void _navigateBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.home);
  }
}
