import 'package:flutter/widgets.dart';

/// Markdown edits applied to a text field's current selection.
class MarkdownEditing {
  MarkdownEditing._();

  static TextEditingValue bold(TextEditingValue value) =>
      wrap(value, '**', '**');

  static TextEditingValue italic(TextEditingValue value) =>
      wrap(value, '_', '_');

  static TextEditingValue heading(TextEditingValue value) =>
      prefixLines(value, (_) => '## ');

  static TextEditingValue bulletList(TextEditingValue value) =>
      prefixLines(value, (_) => '- ');

  static TextEditingValue numberedList(TextEditingValue value) =>
      prefixLines(value, (index) => '${index + 1}. ');

  static TextEditingValue link(
    TextEditingValue value, {
    required String label,
    required String url,
  }) {
    final (start, end) = _range(value);
    final text = label.trim().isNotEmpty ? label.trim() : url;
    return insert(value, start, end, '[$text]($url)');
  }

  /// Wraps the selection; with no selection the cursor lands between the marks.
  static TextEditingValue wrap(
    TextEditingValue value,
    String prefix,
    String suffix,
  ) {
    final (start, end) = _range(value);
    final selected = value.text.substring(start, end);
    final next = value.text.replaceRange(start, end, '$prefix$selected$suffix');
    return TextEditingValue(
      text: next,
      selection: TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selected.length,
      ),
    );
  }

  /// Prefixes every line touched by the selection and keeps them selected.
  static TextEditingValue prefixLines(
    TextEditingValue value,
    String Function(int index) prefixFor,
  ) {
    final (start, end) = _range(value);
    final text = value.text;
    final lineStart = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
    final block = text.substring(lineStart, end);
    final lines = block.split('\n');
    final prefixed = [
      for (final (index, line) in lines.indexed) '${prefixFor(index)}$line',
    ].join('\n');
    final next = text.replaceRange(lineStart, end, prefixed);
    final firstPrefix = prefixFor(0).length;
    return TextEditingValue(
      text: next,
      selection: TextSelection(
        baseOffset: start + firstPrefix,
        extentOffset: lineStart + prefixed.length,
      ),
    );
  }

  static TextEditingValue insert(
    TextEditingValue value,
    int start,
    int end,
    String snippet,
  ) {
    final next = value.text.replaceRange(start, end, snippet);
    return TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + snippet.length),
    );
  }

  static (int, int) _range(TextEditingValue value) {
    final selection = value.selection;
    final length = value.text.length;
    if (!selection.isValid) return (length, length);
    return (selection.start.clamp(0, length), selection.end.clamp(0, length));
  }
}
