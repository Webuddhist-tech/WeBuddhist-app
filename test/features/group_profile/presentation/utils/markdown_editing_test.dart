import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/markdown_editing.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _value(String text, {int? start, int? end}) {
  if (start == null) return TextEditingValue(text: text);
  return TextEditingValue(
    text: text,
    selection: TextSelection(baseOffset: start, extentOffset: end ?? start),
  );
}

void main() {
  test('bold wraps the selection and keeps it selected', () {
    final result = MarkdownEditing.bold(
      _value('join 21 Taras', start: 5, end: 13),
    );

    expect(result.text, 'join **21 Taras**');
    expect(result.selection.start, 7);
    expect(result.selection.end, 15);
  });

  test('bold with no selection places the cursor between the marks', () {
    final result = MarkdownEditing.bold(_value('abc', start: 3));

    expect(result.text, 'abc****');
    expect(result.selection.isCollapsed, isTrue);
    expect(result.selection.start, 5);
  });

  test('italic appends at the end when the selection is invalid', () {
    final result = MarkdownEditing.italic(_value('abc'));

    expect(result.text, 'abc__');
    expect(result.selection.start, 4);
  });

  test('heading prefixes the current line only', () {
    final result = MarkdownEditing.heading(
      _value('first\nsecond line', start: 9),
    );

    expect(result.text, 'first\n## second line');
  });

  test('bullet list prefixes every selected line', () {
    final result = MarkdownEditing.bulletList(
      _value('one\ntwo\nthree', start: 0, end: 13),
    );

    expect(result.text, '- one\n- two\n- three');
    expect(result.selection.start, 2);
    expect(result.selection.end, result.text.length);
  });

  test('numbered list counts from one', () {
    final result = MarkdownEditing.numberedList(
      _value('a\nb', start: 0, end: 3),
    );

    expect(result.text, '1. a\n2. b');
  });

  test('link replaces the selection and falls back to the url as label', () {
    final labelled = MarkdownEditing.link(
      _value('see here now', start: 4, end: 8),
      label: 'here',
      url: 'https://x.y',
    );
    expect(labelled.text, 'see [here](https://x.y) now');
    expect(labelled.selection.start, 'see [here](https://x.y)'.length);

    final bare = MarkdownEditing.link(
      _value('', start: 0),
      label: '  ',
      url: 'https://x.y',
    );
    expect(bare.text, '[https://x.y](https://x.y)');
  });
}
