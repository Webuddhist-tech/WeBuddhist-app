import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextDetailsParams', () {
    test('equal params with the same size are equal and share a hash', () {
      const a = TextDetailsParams(
        textId: 't1',
        versionId: 'v1',
        segmentId: 's1',
        direction: 'next',
        size: 45,
      );
      const b = TextDetailsParams(
        textId: 't1',
        versionId: 'v1',
        segmentId: 's1',
        direction: 'next',
        size: 45,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('size is part of identity so a plan window gets its own provider', () {
      const page = TextDetailsParams(textId: 't1', segmentId: 's1');
      const window = TextDetailsParams(textId: 't1', segmentId: 's1', size: 45);
      expect(page, isNot(equals(window)));
      expect(page.key, isNot(window.key));
    });

    test('null size and explicit size differ in the key', () {
      const a = TextDetailsParams(textId: 't1');
      const b = TextDetailsParams(textId: 't1', size: 20);
      expect(a.key, isNot(b.key));
    });
  });
}
