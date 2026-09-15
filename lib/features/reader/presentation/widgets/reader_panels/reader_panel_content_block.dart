import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Body text for a panel item with an inline "MORE/ LESS" toggle.
///
/// [content] is HTML (same format as main reader segments). The full content is
/// rendered with [SegmentHtmlWidget] when [isExpanded] is true; otherwise the
/// plain-text preview is truncated at [ReaderPanelConstants.previewMaxLength]
/// characters and an inline `... MORE` affordance is appended. When the
/// content exceeds the preview length, the entire block is tappable to expand
/// or collapse.
class ReaderPanelContentBlock extends StatelessWidget {
  const ReaderPanelContentBlock({
    super.key,
    required this.content,
    required this.language,
    required this.segmentIndex,
    required this.isExpanded,
    required this.onToggle,
  });

  final String content;
  final String language;
  final int segmentIndex;
  final bool isExpanded;
  final VoidCallback onToggle;

  String _plainTextFromHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  void _handleToggle() {
    HapticFeedback.selectionClick();
    onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = context.l10n;
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    final fontSize = getLocalizedFontSize(AppTextSize.body);

    final plainText = _plainTextFromHtml(content);
    final isToggleable =
        plainText.length > ReaderPanelConstants.previewMaxLength;
    final isTruncated = !isExpanded && isToggleable;
    final displayContent =
        isTruncated
            ? plainText.substring(0, ReaderPanelConstants.previewMaxLength)
            : plainText;

    final bodyStyle = AppFontConfig.applyTibetanMetrics(
      language,
      TextStyle(
        fontFamily: fontFamily,
        height: lineHeight,
        fontSize: fontSize,
        color: theme.colorScheme.onSurface,
      ),
    );
    final actionStyle = bodyStyle?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      fontWeight: FontWeight.w600,
      fontSize: fontSize * 0.85,
    );
    final strutStyle = AppFontConfig.tibetanStrutStyle(language, fontSize);
    final htmlWidget = SegmentHtmlWidget(
      htmlContent: content,
      segmentIndex: segmentIndex,
      fontSize: fontSize,
      language: language,
    );

    final Widget contentWidget;
    if (isTruncated) {
      contentWidget = Text.rich(
        TextSpan(
          style: bodyStyle,
          children: [
            TextSpan(text: displayContent),
            TextSpan(
              text: ' ...${localizations.more.toUpperCase()}',
              style: actionStyle,
            ),
          ],
        ),
        strutStyle: strutStyle,
      );
    } else if (isExpanded && isToggleable) {
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          htmlWidget,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(localizations.less.toUpperCase(), style: actionStyle),
          ),
        ],
      );
    } else {
      contentWidget = htmlWidget;
    }

    if (!isToggleable) {
      return contentWidget;
    }

    return GestureDetector(
      onTap: _handleToggle,
      behavior: HitTestBehavior.opaque,
      child: contentWidget,
    );
  }
}
