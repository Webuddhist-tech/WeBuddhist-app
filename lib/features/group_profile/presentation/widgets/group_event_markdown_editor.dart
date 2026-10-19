import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/markdown_editing.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';

/// Markdown text area with a formatting toolbar and a Write/Preview toggle.
class GroupEventMarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;

  const GroupEventMarkdownEditor({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.enabled = true,
  });

  @override
  State<GroupEventMarkdownEditor> createState() =>
      _GroupEventMarkdownEditorState();
}

class _GroupEventMarkdownEditorState extends State<GroupEventMarkdownEditor> {
  final FocusNode _focusNode = FocusNode();
  bool _isPreview = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _apply(TextEditingValue Function(TextEditingValue) edit) {
    widget.controller.value = edit(widget.controller.value);
    _focusNode.requestFocus();
  }

  Future<void> _insertLink() async {
    final selection = widget.controller.selection;
    final text = widget.controller.text;
    final selected =
        selection.isValid && !selection.isCollapsed
            ? text.substring(selection.start, selection.end)
            : '';
    final link = await _MarkdownLinkDialog.show(
      context,
      initialLabel: selected,
    );
    if (link == null || !mounted) return;
    _apply(
      (value) => MarkdownEditing.link(value, label: link.$1, url: link.$2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final fillColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(fontSize: 13, color: secondaryColor),
              ),
            ),
            _WritePreviewToggle(
              isPreview: _isPreview,
              isDark: isDark,
              onChanged: (preview) => setState(() => _isPreview = preview),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child:
              _isPreview
                  ? _buildPreview(
                    l10n.group_event_preview_empty,
                    secondaryColor,
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildToolbar(isDark, borderColor),
                      TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        maxLines: null,
                        minLines: 3,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                        decoration: InputDecoration(
                          hintText: widget.hint,
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: secondaryColor,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.fromLTRB(
                            14,
                            12,
                            14,
                            12,
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isDark, Color borderColor) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          _ToolbarButton(
            icon: AppAssets.textBold,
            tooltip: l10n.group_event_format_bold,
            onTap: () => _apply(MarkdownEditing.bold),
          ),
          _ToolbarButton(
            icon: AppAssets.textItalic,
            tooltip: l10n.group_event_format_italic,
            onTap: () => _apply(MarkdownEditing.italic),
          ),
          _ToolbarButton(
            icon: AppAssets.textHeading,
            tooltip: l10n.group_event_format_heading,
            onTap: () => _apply(MarkdownEditing.heading),
          ),
          _ToolbarButton(
            icon: AppAssets.listBullets,
            tooltip: l10n.group_event_format_bullet_list,
            onTap: () => _apply(MarkdownEditing.bulletList),
          ),
          _ToolbarButton(
            icon: AppAssets.listNumbers,
            tooltip: l10n.group_event_format_numbered_list,
            onTap: () => _apply(MarkdownEditing.numberedList),
          ),
          _ToolbarButton(
            icon: AppAssets.link,
            tooltip: l10n.group_event_format_link,
            onTap: _insertLink,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(String emptyLabel, Color secondaryColor) {
    final content = widget.controller.text.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child:
          content.isEmpty
              ? Text(
                emptyLabel,
                style: TextStyle(fontSize: 15, color: secondaryColor),
              )
              : PlanInlineMarkdownView(content: content, fontSize: 15),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
    );
  }
}

class _WritePreviewToggle extends StatelessWidget {
  const _WritePreviewToggle({
    required this.isPreview,
    required this.isDark,
    required this.onChanged,
  });

  final bool isPreview;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(l10n.group_event_write, !isPreview, () => onChanged(false)),
          _segment(l10n.group_event_preview, isPreview, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    final activeColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final inactiveColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    return Material(
      color:
          selected
              ? (isDark ? AppColors.surfaceDark : AppColors.surfaceWhite)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkdownLinkDialog extends StatefulWidget {
  const _MarkdownLinkDialog({required this.initialLabel});

  final String initialLabel;

  static Future<(String, String)?> show(
    BuildContext context, {
    required String initialLabel,
  }) {
    return showDialog<(String, String)>(
      context: context,
      builder: (_) => _MarkdownLinkDialog(initialLabel: initialLabel),
    );
  }

  @override
  State<_MarkdownLinkDialog> createState() => _MarkdownLinkDialogState();
}

class _MarkdownLinkDialogState extends State<_MarkdownLinkDialog> {
  late final TextEditingController _label = TextEditingController(
    text: widget.initialLabel,
  );
  final TextEditingController _url = TextEditingController();

  bool get _canInsert {
    final uri = Uri.tryParse(_url.text.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _url.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _label.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.group_event_link_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _label,
            autofocus: widget.initialLabel.isEmpty,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.group_event_link_text_hint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            autofocus: widget.initialLabel.isNotEmpty,
            autocorrect: false,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: l10n.group_event_link_url_hint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed:
              _canInsert
                  ? () =>
                      Navigator.of(context).pop((_label.text, _url.text.trim()))
                  : null,
          child: Text(l10n.group_event_link_insert),
        ),
      ],
    );
  }
}
