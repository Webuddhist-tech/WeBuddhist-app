import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SegmentHtmlWidget extends ConsumerStatefulWidget {
  final String htmlContent;
  final int segmentIndex;
  final double fontSize;
  final String language;
  final bool isSelected;

  /// Optional override for the body text color. Used to render the secondary
  /// (parallel) version in a muted tone so it reads as supporting text. When
  /// null, the text inherits the default theme color.
  final Color? textColor;

  /// Body style by segment type (italic front matter, bold titles).
  final FontStyle? fontStyle;
  final FontWeight? fontWeight;

  const SegmentHtmlWidget({
    super.key,
    required this.htmlContent,
    required this.segmentIndex,
    required this.fontSize,
    required this.language,
    this.isSelected = false,
    this.textColor,
    this.fontStyle,
    this.fontWeight,
  });

  @override
  ConsumerState<SegmentHtmlWidget> createState() => _SegmentHtmlWidgetState();
}

class _SegmentHtmlWidgetState extends ConsumerState<SegmentHtmlWidget> {
  // Set of visible footnote indices for this segment
  Set<int> visibleFootnotes = {};

  @override
  Widget build(BuildContext context) {
    int footnoteCounter = 0;
    return Html(
      data: widget.htmlContent,
      style: {
        ".footnote-marker": Style(
          color: const Color(0xFF007bff),
          fontWeight: FontWeight.w700,
          verticalAlign: VerticalAlign.top,
        ),
        ".footnote": Style(
          fontStyle: FontStyle.italic,
          color: const Color(0xFF8a8a8a),
          margin: Margins.only(left: 4),
          backgroundColor: const Color(0xFFF0F0F0),
          padding: HtmlPaddings.symmetric(horizontal: 5, vertical: 2),
          fontSize: FontSize(widget.fontSize),
        ),
        "body": Style(
          fontSize: FontSize(widget.fontSize),
          margin: Margins.zero,
          color: widget.textColor,
          fontFamily: getFontFamily(widget.language),
          fontStyle: widget.fontStyle,
          fontWeight: widget.fontWeight,
          padding: HtmlPaddings.zero,
          textDecoration: widget.isSelected ? TextDecoration.underline : null,
          textDecorationStyle:
              widget.isSelected ? TextDecorationStyle.dotted : null,
          textDecorationThickness: widget.isSelected ? 1.5 : null,
        ),
        'p': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
      },
      extensions: [
        TagExtension(
          tagsToExtend: {"sup"},
          builder: (context) {
            final element = context.element;
            if ((element?.classes.contains('footnote-marker')) ?? false) {
              final currentIndex = footnoteCounter++;
              final text = context.element?.text ?? '';
              return InkWell(
                onTap: () {
                  setState(() {
                    if (visibleFootnotes.contains(currentIndex)) {
                      visibleFootnotes.remove(currentIndex);
                    } else {
                      visibleFootnotes.add(currentIndex);
                    }
                  });
                },
                // Increase the tap target size for better UX
                borderRadius: BorderRadius.circular(4),
                child: Transform.translate(
                  offset: const Offset(0, -6),
                  child: Padding(
                    // Increased padding for larger tap target
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          color: const Color(0xFF007bff),
                          fontWeight: FontWeight.w700,
                          fontSize: widget.fontSize * 0.85,
                        ),
                        child: Text(text.isNotEmpty ? text : '*'),
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        TagExtension(
          tagsToExtend: {"i"},
          builder: (context) {
            final element = context.element;
            if ((element?.classes.contains('footnote')) ?? false) {
              final currentIndex = footnoteCounter - 1;
              final isVisible = visibleFootnotes.contains(currentIndex);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child:
                    isVisible
                        ? Container(
                          key: ValueKey('footnote-$currentIndex'),
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: DefaultTextStyle.merge(
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF8a8a8a),
                              fontSize: widget.fontSize,
                            ),
                            child:
                                (context.element?.text ?? '').isNotEmpty
                                    ? Text(context.element?.text ?? '')
                                    : const Text(''),
                          ),
                        )
                        : const SizedBox.shrink(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
