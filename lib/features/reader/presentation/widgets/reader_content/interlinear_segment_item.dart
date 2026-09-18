import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_transliteration.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_number.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InterlinearSegmentItem extends ConsumerWidget {
  const InterlinearSegmentItem({
    super.key,
    required this.segment,
    required this.depth,
    required this.primaryLanguage,
    this.showPrimary = true,
    required this.secondarySlot,
    this.secondaryContentBySegmentNumber,
    this.secondaryIsLoading = false,
    this.isSelected = false,
    this.isHighlighted = false,
    this.highlightSource = NavigationSource.normal,
    this.isGreyedOut = false,
    this.onTap,
  });

  final Segment segment;
  final int depth;
  final String primaryLanguage;

  /// False for "translation only": the primary line is left out and the
  /// translation is drawn as the main text rather than in the muted tone.
  final bool showPrimary;
  final ReaderSlotConfig secondarySlot;

  /// Lookup map of secondary version content keyed by segment_number.
  /// Falls back to a placeholder when the key is missing or while loading.
  final Map<int, String>? secondaryContentBySegmentNumber;
  final bool secondaryIsLoading;
  final bool isSelected;
  // Received from caller but visual highlight not yet applied in interlinear mode.
  final bool isHighlighted;
  final NavigationSource highlightSource;
  final bool isGreyedOut;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final primary = primarySegmentHtml(
      ref,
      content: segment.content,
      language: primaryLanguage,
    );
    final secondary = _resolveSecondaryContent(context);

    // Per Figma: the secondary (parallel) version uses a fixed muted tone that
    // differs per theme so it reads as supporting text beneath the primary.
    // Without a primary it is the text, so it takes the default colour.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color? secondaryColor =
        !showPrimary
            ? null
            : isDark
            ? const Color(0xFFE0E0E0)
            : const Color(0xFF707070);

    return AnimatedOpacity(
      opacity: isGreyedOut ? 0.3 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ReaderConstants.segmentBorderRadius,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: ReaderConstants.segmentHorizontalPadding + (depth * 8),
              right: ReaderConstants.segmentHorizontalPadding,
              top: ReaderConstants.segmentVerticalPadding,
              bottom: ReaderConstants.segmentVerticalPadding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentNumber(
                  segmentNumber: segment.segmentNumber,
                  fontSize: fontSize,
                  language: primaryLanguage,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showPrimary) ...[
                        SegmentHtmlWidget(
                          htmlContent: primary.html,
                          segmentIndex: segment.segmentNumber,
                          fontSize: fontSize,
                          language: primary.fontLanguage,
                          isSelected: isSelected,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (secondary.isPlaceholder)
                        _SecondaryPlaceholder(
                          text: secondary.text,
                          language: secondarySlot.languageCode,
                          fontSize: fontSize,
                          color: secondaryColor,
                        )
                      else
                        SegmentHtmlWidget(
                          htmlContent: secondary.text,
                          segmentIndex: segment.segmentNumber,
                          fontSize: fontSize,
                          language: secondarySlot.languageCode,
                          isSelected: isSelected,
                          textColor: secondaryColor,
                        ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _SecondaryResolved _resolveSecondaryContent(BuildContext context) {
    final fromMap = secondaryContentBySegmentNumber?[segment.segmentNumber];
    if (fromMap != null && fromMap.trim().isNotEmpty) {
      return _SecondaryResolved(
        text: normalizeSegmentHtml(fromMap),
        isPlaceholder: false,
      );
    }
    if (secondaryIsLoading) {
      return _SecondaryResolved(
        text: context.l10n.loading,
        isPlaceholder: true,
      );
    }
    // A version is selected but this particular segment has no translation.
    // Show a quiet centered em-dash rather than a verbose error line.
    return const _SecondaryResolved(text: '—', isPlaceholder: true);
  }
}

class _SecondaryResolved {
  final String text;
  final bool isPlaceholder;
  const _SecondaryResolved({required this.text, required this.isPlaceholder});
}

class _SecondaryPlaceholder extends StatelessWidget {
  const _SecondaryPlaceholder({
    required this.text,
    required this.language,
    required this.fontSize,
    required this.color,
  });

  final String text;
  final String language;
  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: getFontFamily(language),
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          color: color,
          height: 1.4,
        ),
      ),
    );
  }
}
