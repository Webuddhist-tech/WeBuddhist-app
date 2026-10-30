import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../reader/fakes/fake_local_storage.dart';

Future<void> _pump(
  WidgetTester tester,
  List<Widget> verses, {
  double textScale = 1,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
      ],
      child: MaterialApp(
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: verses,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

SegmentHtmlWidget _verse(
  String html, {
  double? lineHeight = 1.8,
  bool isSelected = false,
}) => SegmentHtmlWidget(
  htmlContent: html,
  segmentIndex: 1,
  fontSize: 22,
  lineHeight: lineHeight,
  language: 'bo',
  isSelected: isSelected,
);

// An empty plain span changes nothing drawn but needs flutter_html.
const _forceHtml = '<span></span>';

void main() {
  const samples = [
    'ཕྱག་འཚལ་ཉི་ཤུ་རྩ་གཅིག་གིས་བསྟོད་པ།',
    'མདོར་བསྟན། <span class="yigchung">རྒྱས་བཤད། ཕན་ཡོན།</span> མཇུག་བསྡུ།',
    'line one<br>line two that is long enough to wrap across the width<br>3',
    '  spaced   out \n text <span class="yigchung"> small </span> end  ',
    'Tom &amp; Jerry &lt;3',
    'passage one<br><br>passage two',
  ];

  testWidgets('library verses skip flutter_html', (tester) async {
    await _pump(tester, [for (final s in samples) _verse(s)]);
    expect(find.byType(Html), findsNothing);
  });

  testWidgets('anything else still goes through flutter_html', (tester) async {
    await _pump(tester, [
      _verse('a<sup class="footnote-marker">1</sup><i class="footnote">n</i>'),
      _verse('<p>para</p>'),
      _verse('<span class="other">x</span>'),
    ]);
    expect(find.byType(Html), findsNWidgets(3));
  });

  for (final (lineHeight, selected, scale) in [
    (1.8, false, 1.0),
    (1.8, true, 1.0),
    (null, false, 1.0),
    (1.8, false, 1.3),
  ]) {
    testWidgets('lays out as flutter_html did (line height $lineHeight, '
        'selected $selected, text scale $scale)', (tester) async {
      for (final sample in samples) {
        await _pump(tester, textScale: scale, [
          _verse(sample, lineHeight: lineHeight, isSelected: selected),
          _verse(
            '$sample$_forceHtml',
            lineHeight: lineHeight,
            isSelected: selected,
          ),
        ]);
        final verses = find.byType(SegmentHtmlWidget);
        expect(find.byType(Html), findsOneWidget);
        expect(
          tester.getSize(verses.at(0)),
          tester.getSize(verses.at(1)),
          reason: sample,
        );
      }
    });
  }

  testWidgets('spaces collapse and trim as HTML draws them', (tester) async {
    await _pump(tester, [_verse(samples[3])]);
    final verse = tester.widget<RichText>(find.byType(RichText).last).text;
    expect(verse.toPlainText(), 'spaced out text small end');
  });

  testWidgets('a double line break keeps its blank line', (tester) async {
    await _pump(tester, [_verse('one<br><br>two'), _verse('one<br> <br>two')]);
    final verses = [
      for (final text in tester.widgetList<RichText>(find.byType(RichText)))
        if (text.text.toPlainText().contains('one')) text.text.toPlainText(),
    ];
    expect(verses, ['one\n\ntwo', 'one\n\ntwo']);
  });
}
