import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';

/// Caption cut to [maxLines] with an inline "… more"; when expanded it shows
/// the full text with "less" at the end.
class ConnectExpandableCaption extends StatelessWidget {
  const ConnectExpandableCaption({
    super.key,
    required this.text,
    required this.expanded,
    required this.onToggle,
    this.style,
    this.strutStyle,
    this.maxLines = 2,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final textStyle = DefaultTextStyle.of(context).style.merge(style);
    final linkStyle = textStyle.copyWith(fontWeight: FontWeight.w700);
    final moreLabel = context.l10n.more.toLowerCase();
    final lessLabel = context.l10n.less.toLowerCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        final textScaler = MediaQuery.textScalerOf(context);

        bool fits(InlineSpan span) {
          final painter = TextPainter(
            text: span,
            textDirection: textDirection,
            textScaler: textScaler,
            strutStyle: strutStyle,
            maxLines: maxLines,
          )..layout(maxWidth: constraints.maxWidth);
          final exceeded = painter.didExceedMaxLines;
          painter.dispose();
          return !exceeded;
        }

        if (fits(TextSpan(text: text, style: textStyle))) {
          return Text(text, style: textStyle, strutStyle: strutStyle);
        }

        final Widget caption;
        if (expanded) {
          caption = Text.rich(
            TextSpan(
              style: textStyle,
              children: [
                TextSpan(text: '$text '),
                TextSpan(text: lessLabel, style: linkStyle),
              ],
            ),
            strutStyle: strutStyle,
          );
        } else {
          final characters = text.characters;
          TextSpan collapsed(int length) => TextSpan(
            style: textStyle,
            children: [
              TextSpan(
                text: '${characters.take(length).toString().trimRight()}… ',
              ),
              TextSpan(text: moreLabel, style: linkStyle),
            ],
          );

          // Longest prefix that still leaves room for "… more".
          var low = 0;
          var high = characters.length;
          while (low < high) {
            final mid = (low + high + 1) ~/ 2;
            if (fits(collapsed(mid))) {
              low = mid;
            } else {
              high = mid - 1;
            }
          }
          caption = Text.rich(
            collapsed(low),
            strutStyle: strutStyle,
            maxLines: maxLines,
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: caption,
        );
      },
    );
  }
}
