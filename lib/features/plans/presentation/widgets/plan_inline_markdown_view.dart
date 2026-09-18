import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_drawer.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/segment_drawer.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_pecha/core/utils/url_opener.dart';

/// Renders markdown content for plan TEXT subtasks.
///
/// - Selectable text (matches the previous `SelectableText` behaviour).
/// - Locale-aware system (sans-serif) font and line height for Tibetan / EN / ZH.
/// - Headings, lists, emphasis and blockquotes scale off [fontSize] so the
///   reader font-size bottom sheet still drives the whole document.
/// - `[label](url)` opens in the in-app browser.
/// - Images are intentionally disabled — plan markdown is not expected to
///   include them and disabling avoids accidental network fetches.
class PlanInlineMarkdownView extends StatelessWidget {
  final String content;
  final double fontSize;

  const PlanInlineMarkdownView({
    super.key,
    required this.content,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return MarkdownBody(
      data: content,
      selectable: true,
      shrinkWrap: true,
      softLineBreak: true,
      imageBuilder: (_, __, ___) => const SizedBox.shrink(),
      onTapLink: (_, href, __) => _openExternalLink(context, href),
      styleSheet: _buildStyleSheet(context, language),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context, String language) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final fontFamily = getSystemFontFamily(language);
    final lineHeight = getLineHeight(language) ?? 1.6;

    TextStyle text(double size, {FontWeight? weight}) {
      return TextStyle(
        fontSize: size,
        height: lineHeight,
        fontFamily: fontFamily,
        fontWeight: weight,
        color: onSurface,
      );
    }

    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: text(fontSize),
      strong: text(fontSize, weight: FontWeight.bold),
      em: text(fontSize).copyWith(fontStyle: FontStyle.italic),
      h1: text(fontSize * 1.6, weight: FontWeight.bold),
      h2: text(fontSize * 1.4, weight: FontWeight.bold),
      h3: text(fontSize * 1.2, weight: FontWeight.bold),
      h4: text(fontSize * 1.1, weight: FontWeight.w600),
      h5: text(fontSize, weight: FontWeight.w600),
      h6: text(fontSize, weight: FontWeight.w600),
      listBullet: text(fontSize),
      blockquote: text(fontSize).copyWith(
        fontStyle: FontStyle.italic,
        color: onSurface.withValues(alpha: 0.75),
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      code: TextStyle(
        fontSize: fontSize * 0.95,
        fontFamily: 'monospace',
        color: onSurface,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      a: text(fontSize).copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      blockSpacing: fontSize * 0.75,
    );
  }

  Future<void> _openExternalLink(BuildContext context, String? href) async {
    if (href == null || href.isEmpty) return;
    try {
      final uri = Uri.parse(href);

      if (uri.scheme == 'drawer') {
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        if (id != null && id.isNotEmpty && context.mounted) {
          switch (uri.host) {
            case 'group':
              GroupProfileDrawer.show(context, id);
            case 'segment':
              SegmentDrawer.show(context, id);
          }
        }
        return;
      }

      if (await openUrl(uri.toString())) return;
      if (context.mounted) context.showSnackBar(context.l10n.link_cannot_open);
    } catch (_) {
      if (context.mounted) context.showSnackBar(context.l10n.link_invalid);
    }
  }
}
