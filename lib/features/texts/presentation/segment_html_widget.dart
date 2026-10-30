import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:flutter_pecha/features/library/domain/library_content_slicer.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_palette.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yigchung text size relative to the verse.
const double _yigchungScale = 0.85;

class SegmentHtmlWidget extends ConsumerStatefulWidget {
  final String htmlContent;
  final int segmentIndex;
  final double fontSize;

  /// Line height of the text, as a multiple of [fontSize]; null leaves the
  /// font's own.
  final double? lineHeight;
  final String language;
  final bool isSelected;

  /// Optional override for the body text color. Used to render the secondary
  /// (parallel) version in a muted tone so it reads as supporting text. When
  /// null, the text inherits the default theme color.
  final Color? textColor;

  /// Body style by segment type (italic front matter, bold titles).
  final FontStyle? fontStyle;
  final FontWeight? fontWeight;

  /// The font family; null uses [language]'s content font.
  final String? fontFamily;

  const SegmentHtmlWidget({
    super.key,
    required this.htmlContent,
    required this.segmentIndex,
    required this.fontSize,
    this.lineHeight,
    required this.language,
    this.isSelected = false,
    this.textColor,
    this.fontStyle,
    this.fontWeight,
    this.fontFamily,
  });

  @override
  ConsumerState<SegmentHtmlWidget> createState() => _SegmentHtmlWidgetState();
}

class _SegmentHtmlWidgetState extends ConsumerState<SegmentHtmlWidget> {
  // Set of visible footnote indices for this segment
  Set<int> visibleFootnotes = {};

  /// The verse as plain runs when it needs nothing flutter_html does.
  late List<_Run>? _runs = _plainRuns(widget.htmlContent);

  @override
  void didUpdateWidget(SegmentHtmlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      _runs = _plainRuns(widget.htmlContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = ReaderPalette.resolve(theme, ref);
    final runs = _runs;
    if (runs != null) return _buildPlain(theme, palette, runs);
    return _buildHtml(palette);
  }

  /// Drawn as flutter_html would, without its style tree: text over the
  /// theme's body text, the verse's style, yigchung runs smaller.
  Widget _buildPlain(ThemeData theme, ReaderPalette palette, List<_Run> runs) {
    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    final style = base
        .copyWith(height: base.height ?? 1.2)
        .merge(
          TextStyle(
            fontSize: widget.fontSize,
            height: widget.lineHeight,
            color: widget.textColor,
            fontFamily: widget.fontFamily ?? getFontFamily(widget.language),
            fontStyle: widget.fontStyle,
            fontWeight: widget.fontWeight,
            decoration: widget.isSelected ? TextDecoration.underline : null,
            decorationStyle:
                widget.isSelected ? TextDecorationStyle.dotted : null,
            decorationThickness: widget.isSelected ? 1.5 : null,
          ),
        );
    final yigchung = TextStyle(
      color: palette.yigchung,
      fontStyle: FontStyle.italic,
      fontSize: widget.fontSize * _yigchungScale,
    );
    final verse = SizedBox(
      width: double.infinity,
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            for (final run in runs)
              TextSpan(text: run.text, style: run.yigchung ? yigchung : null),
          ],
        ),
      ),
    );
    // flutter_html's root line around its body block: the same spacing, and
    // text scaling applied once to the whole verse.
    final root = DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(
        style: root.copyWith(height: root.height ?? 1.2),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.bottom,
            baseline: TextBaseline.alphabetic,
            child: MediaQuery.withNoTextScaling(child: verse),
          ),
        ],
      ),
    );
  }

  Widget _buildHtml(ReaderPalette palette) {
    int footnoteCounter = 0;
    final lineHeight = widget.lineHeight;
    return Html(
      data: widget.htmlContent,
      style: {
        ".$libraryYigchungClass": Style(
          color: palette.yigchung,
          fontStyle: FontStyle.italic,
          fontSize: FontSize(widget.fontSize * _yigchungScale),
        ),
        ".footnote-marker": Style(
          color: palette.footnoteMarker,
          fontWeight: FontWeight.w700,
          verticalAlign: VerticalAlign.top,
        ),
        ".footnote": Style(
          fontStyle: FontStyle.italic,
          color: palette.footnoteText,
          margin: Margins.only(left: 4),
          backgroundColor: palette.footnoteBackground,
          padding: HtmlPaddings.symmetric(horizontal: 5, vertical: 2),
          fontSize: FontSize(widget.fontSize),
        ),
        "body": Style(
          fontSize: FontSize(widget.fontSize),
          lineHeight: lineHeight == null ? null : LineHeight(lineHeight),
          margin: Margins.zero,
          color: widget.textColor,
          fontFamily: widget.fontFamily ?? getFontFamily(widget.language),
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
                          color: palette.footnoteMarker,
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
                            color: palette.footnoteBackground,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: DefaultTextStyle.merge(
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: palette.footnoteText,
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

/// A stretch of a verse: plain, or yigchung (small text).
class _Run {
  final String text;
  final bool yigchung;

  const _Run(this.text, {this.yigchung = false});
}

final RegExp _htmlSpace = RegExp(r'[ \t\n\r\f]+');

/// [html] as runs when it holds only text, `<br>` and yigchung spans, as
/// library verses do; null for anything else. Spaces collapse as in HTML.
List<_Run>? _plainRuns(String html) {
  final runs = <_Run>[];
  void add(String text, {bool yigchung = false}) {
    var collapsed = text.replaceAll(_htmlSpace, ' ');
    // A space ending the run before swallows one starting this run.
    if (runs.isNotEmpty && runs.last.text.endsWith(' ')) {
      collapsed = collapsed.trimLeft();
    }
    if (collapsed.isNotEmpty) runs.add(_Run(collapsed, yigchung: yigchung));
  }

  for (final node in html_parser.parseFragment(html).nodes) {
    if (node is dom.Text) {
      add(node.data);
    } else if (node is dom.Element && node.localName == 'br') {
      runs.add(const _Run('\n'));
    } else if (node is dom.Element &&
        node.localName == 'span' &&
        node.classes.length == 1 &&
        node.classes.contains(libraryYigchungClass) &&
        node.nodes.every((child) => child is dom.Text)) {
      add(node.text, yigchung: true);
    } else {
      return null;
    }
  }
  return _trimLines(runs);
}

/// Drops the spaces HTML would not draw: at the start and end of each line.
List<_Run> _trimLines(List<_Run> runs) {
  final result = <_Run>[];
  for (var i = 0; i < runs.length; i++) {
    var text = runs[i].text;
    final lineStart = result.isEmpty || result.last.text.endsWith('\n');
    // A line break is never trimmed away: `<br><br>` keeps its blank line.
    if (lineStart && text != '\n') text = text.trimLeft();
    final lineEnd = i == runs.length - 1 || runs[i + 1].text == '\n';
    if (lineEnd && text != '\n') text = text.trimRight();
    if (text.isEmpty) continue;
    result.add(_Run(text, yigchung: runs[i].yigchung));
  }
  return result;
}
