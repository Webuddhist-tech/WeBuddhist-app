import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/texts/constants/text_details_constants.dart';

/// Constants for reader feature
class ReaderConstants {
  ReaderConstants._(); // Private constructor to prevent instantiation

  // Pagination
  /// Segments per page. Must match what the API returns when no explicit
  /// `size` is sent, so the plan-window threshold compares like with like.
  static const int pageSize = TextDetailsConstants.defaultPageSize;
  static const int previousLoadThreshold = 5;
  static const int nextLoadThreshold = 3;

  // Commentary split view
  static const double defaultSplitRatio = 0.5;
  static const double minSplitRatio = 0.0;
  static const double maxSplitRatio = 0.8;
  static const double commentaryDividerHeight = 8.0;

  /// Minimum visible panel height (logical px) before the panel auto-dismisses
  /// when the user drags the handle downwards.
  static const double minPanelHeightBeforeDismiss = 120.0;

  // Scroll behavior
  static const Duration scrollDebounce = Duration(milliseconds: 100);
  static const Duration scrollAnimationDuration = Duration(milliseconds: 500);
  static const Duration instantScrollDuration = Duration(milliseconds: 1);
  static const double scrollToSegmentAlignment = 0.0; // 30% from top

  // Highlight durations by source
  static const Duration planHighlightDuration = Duration(seconds: 3);
  static const Duration searchHighlightDuration = Duration(seconds: 2);
  static const Duration deepLinkHighlightDuration = Duration(seconds: 2);

  // Swipe navigation
  static const double swipeVelocityThreshold = 300.0;
  static const Duration swipeAnimationDuration = Duration(milliseconds: 300);

  // Skeleton loading
  static const int skeletonLineCount = 5;
  static const int skeletonLineCountShort = 3;

  // Loading thresholds
  static const double loadingThresholdPercentage = 0.8;

  // App bar
  static const double appBarElevation = 0.0;
  static const double appBarToolbarHeight = 50.0;
  static const double appBarBottomHeight = 3.0;
  static const bool enableAppBarAutoHide = true; // Set to true to re-enable

  // Segment item
  static const double segmentHorizontalPadding = 12.0;
  static const double segmentVerticalPadding = 6.0;
  static const double contentTopPadding = 12.0;
  static const double segmentNumberWidth = 28.0;
  static const double segmentBorderRadius = 16.0;

  /// Segment numbers render at a fraction of the segment's content font size.
  static const double segmentNumberFontScale = 0.6;

  // Font sizes
  static const double tibetanBaseFontSize = AppFontConfig.contentFontSize;
  static const double defaultBaseFontSize = AppFontConfig.contentFontSize;
  static const double sectionTitleFontSizeTibetan =
      AppFontConfig.tibetanDisplayFontSize;
  static const double sectionTitleFontSizeDefault =
      AppFontConfig.displayFontSize;
}
