import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_languages_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activeScriptRow', () {
    test('no pick ticks the "as written" row', () {
      expect(
        activeScriptRow(selectedScriptId: null, sourceScriptId: 'si'),
        isNull,
      );
    });

    test('a pick for another script ticks that script', () {
      expect(
        activeScriptRow(selectedScriptId: 'hi', sourceScriptId: 'si'),
        'hi',
      );
    });

    test('a pick naming the source script ticks "as written"', () {
      // The source script has no row of its own, so passing it through left
      // the whole list with nothing ticked.
      expect(
        activeScriptRow(selectedScriptId: 'si', sourceScriptId: 'si'),
        isNull,
      );
    });

    test('an undetected source still ticks the pick', () {
      expect(
        activeScriptRow(selectedScriptId: 'hi', sourceScriptId: null),
        'hi',
      );
      expect(
        activeScriptRow(selectedScriptId: null, sourceScriptId: null),
        isNull,
      );
    });
  });
}
