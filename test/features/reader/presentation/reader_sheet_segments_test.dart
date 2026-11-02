import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';

/// The verse sheet's four tabs across a 390 wide phone, as it lays them out.
Future<void> _pump(WidgetTester tester, {double textScale = 1}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ReaderSheetSegments<String>(
                values: const ['Commentary', 'Versions', 'Videos', 'Root text'],
                selected: 'Commentary',
                labelOf: (value) => value,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets('at ${scale}x text every label fits its tab on one line', (
      tester,
    ) async {
      await _pump(tester, textScale: scale);
      expect(
        tester.getSize(find.byType(ReaderSheetSegments<String>)).height,
        readerSheetTapTarget,
      );
      for (final label in ['Commentary', 'Versions', 'Videos', 'Root text']) {
        // Laid out at its full width on one line: nothing wrapped or cut.
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        expect(
          paragraph.size.width,
          greaterThanOrEqualTo(
            paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5,
          ),
          reason: label,
        );
        // And, scaled to fit, inside its tab.
        final text = tester.getRect(find.text(label));
        final tab = tester.getRect(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(GestureDetector),
          ).first,
        );
        expect(text.left, greaterThanOrEqualTo(tab.left), reason: label);
        expect(text.right, lessThanOrEqualTo(tab.right), reason: label);
        expect(text.top, greaterThanOrEqualTo(tab.top), reason: label);
        expect(text.bottom, lessThanOrEqualTo(tab.bottom), reason: label);
      }
    });
  }
}
