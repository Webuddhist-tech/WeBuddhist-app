import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_accumulation_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _mantra = Mantra(
  presetId: 'mani',
  mantra: MantraText(
    id: 'mani',
    text: 'ཨོཾ་མ་ཎི་པདྨེ་ཧཱུྃ།',
    title: 'ཨོཾ་མ་ཎི་པདྨེ་ཧཱུྃ། ཨོཾ་མ་ཎི་པདྨེ་ཧཱུྃ། ཨོཾ་མ་ཎི་པདྨེ་ཧཱུྃ།',
  ),
);

/// The grid exactly as the accumulation screens build it.
Widget _grid(String language) => MaterialApp(
  home: Scaffold(
    body: LayoutBuilder(
      builder:
          (context, constraints) => GridView.builder(
            gridDelegate: PracticeAccumulationItem.gridDelegate(
              language,
              constraints.maxWidth,
            ),
            itemCount: 2,
            itemBuilder:
                (_, _) => PracticeAccumulationItem(
                  mantra: _mantra,
                  language: language,
                  onTap: () {},
                ),
          ),
    ),
  ),
);

void main() {
  Future<Size> pumpAt(WidgetTester tester, double width, String language) async {
    tester.view.physicalSize = Size(width, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_grid(language));
    return tester.getSize(find.byType(PracticeAccumulationItem).first);
  }

  testWidgets('narrow screen: tile grows to fit the Tibetan title', (
    tester,
  ) async {
    final size = await pumpAt(tester, 320, AppConfig.tibetanLanguageCode);

    // Margin 8 + padding 16 on each side, 64 image, 8 gap, 14 * 1.5 * 2 title.
    expect(size.height, closeTo(162, 0.01));
    // A column overflow would have failed the pump with a FlutterError.
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow screen: tile grows to fit the English title', (
    tester,
  ) async {
    final size = await pumpAt(tester, 320, 'en');

    expect(size.height, closeTo(155, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide screen keeps the 1.1 aspect ratio', (tester) async {
    final size = await pumpAt(tester, 390, 'en');

    expect(size.width, 195);
    expect(size.height, closeTo(195 / 1.1, 0.01));
    expect(tester.takeException(), isNull);
  });
}
