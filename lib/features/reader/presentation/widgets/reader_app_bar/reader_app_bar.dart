import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_button.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_languages_button.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_search_button.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// App bar overlay for the reader screen - animates in/out based on scroll.
///
/// Live reader: back · Live · prayer requests · Aa · globe. Normal reader:
/// back · search · Aa · globe · ⋮. A thin reading-progress line runs under
/// it and slides away with it.
class ReaderAppBarOverlay extends ConsumerWidget {
  final ReaderParams params;

  /// Opens in-text search. The button is hidden when null.
  final VoidCallback? onSearchPressed;

  /// Opens the Languages drawer (original + translation).
  final VoidCallback onLanguagesPressed;

  /// Opens the "more" bottom sheet (add-to-practices, bookmark…). The menu
  /// button is hidden when null.
  final VoidCallback? onMorePressed;

  /// Opens the font size sheet. The Aa button is hidden when null.
  final VoidCallback? onFontSizePressed;

  /// Live recitation sync button, shown before search.
  final Widget? liveSyncToggle;

  /// Event prayer requests, shown after the sync button.
  final Widget? prayerRequestsButton;

  /// How far through the page the reader is, 0 to 1. No line when null.
  final ValueListenable<double>? progress;

  const ReaderAppBarOverlay({
    super.key,
    required this.params,
    this.onSearchPressed,
    required this.onLanguagesPressed,
    this.onMorePressed,
    this.onFontSizePressed,
    this.liveSyncToggle,
    this.prayerRequestsButton,
    this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ReaderStyle.of(context, ref).palette;

    // The event layout (live pill + extra buttons) overflows a 320px toolbar
    // at the default 48px per icon button, so tighten it to 40px.
    final theme = Theme.of(context);
    final isCrowded = liveSyncToggle != null || prayerRequestsButton != null;
    final appBar = AppBar(
      elevation: ReaderConstants.appBarElevation,
      scrolledUnderElevation: ReaderConstants.appBarElevation,
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(AppAssets.arrowLeft),
        onPressed: () {
          // Read on tap: the bar rebuilds as the reader's settings load, and
          // a read in build would recreate the reader each time.
          final notifier = ref.read(readerNotifierProvider(params).notifier);
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
        if (prayerRequestsButton != null) prayerRequestsButton!,
        if (onSearchPressed != null)
          ReaderSearchButton(onPressed: onSearchPressed!),
        if (onFontSizePressed != null)
          ReaderFontSizeButton(onPressed: onFontSizePressed!),
        ReaderLanguagesButton(onPressed: onLanguagesPressed),
        const SizedBox(width: 4),
        if (onMorePressed != null) ...[
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: onMorePressed,
          ),
          const SizedBox(width: 4),
        ],
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCrowded)
          IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ).merge(theme.iconButtonTheme.style),
            ),
            child: appBar,
          )
        else
          appBar,
        if (progress case final progress?)
          ValueListenableBuilder<double>(
            valueListenable: progress,
            builder:
                (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: ReaderConstants.progressLineHeight,
                  backgroundColor: palette.divider,
                  color: palette.pastVerse,
                ),
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
        ReaderLanguagesButton(onPressed: onLanguagesPressed ?? () {}),
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
