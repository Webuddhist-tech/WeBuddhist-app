import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// Configuration for segment highlighting based on navigation source
class HighlightConfig {
  final Duration duration;
  final Color Function(BuildContext context) colorBuilder;

  const HighlightConfig({required this.duration, required this.colorBuilder});

  /// Get highlight configuration for a navigation source
  factory HighlightConfig.forSource(NavigationSource source) {
    switch (source) {
      case NavigationSource.plan:
        return HighlightConfig(
          duration: ReaderConstants.planHighlightDuration,
          colorBuilder:
              (context) =>
                  Theme.of(context).colorScheme.primaryContainer.withAlpha(128),
        );
      case NavigationSource.search:
        return HighlightConfig(
          duration: ReaderConstants.searchHighlightDuration,
          colorBuilder:
              (context) =>
                  Theme.of(context).colorScheme.tertiaryContainer.withAlpha(77),
        );
      case NavigationSource.deepLink:
        return HighlightConfig(
          duration: ReaderConstants.deepLinkHighlightDuration,
          colorBuilder:
              (context) => Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withAlpha(128),
        );
      case NavigationSource.normal:
      case NavigationSource.recitationList:
      case NavigationSource.routine:
      case NavigationSource.groupAccumulatorChant:
      case NavigationSource.groupRecitationCollection:
      case NavigationSource.myRecitationCollection:
        return HighlightConfig(
          duration: Duration.zero,
          colorBuilder: (context) => Colors.transparent,
        );
    }
  }

  /// Get the highlight color for a given context
  Color getColor(BuildContext context) => colorBuilder(context);
}
