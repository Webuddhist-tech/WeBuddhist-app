import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PresetTimer labels', () {
    test('under one minute counts seconds, so it never reads "0 min"', () {
      expect(PresetTimer.labelsInSeconds(20000), isTrue);
      expect(PresetTimer.labelValueFromMs(20000), 20);
      expect(PresetTimer.labelValueFromMs(59000), 59);
    });

    test('one minute and up rounds to the nearest whole minute', () {
      expect(PresetTimer.labelsInSeconds(60000), isFalse);
      expect(PresetTimer.labelValueFromMs(60000), 1);
      expect(PresetTimer.labelValueFromMs(89000), 1);
      expect(PresetTimer.labelValueFromMs(90000), 2);
      expect(PresetTimer.labelValueFromMs(7200000), 120);
    });

    test('instance getters follow durationMs', () {
      const timer = PresetTimer(id: 't', name: '30 seconds', durationMs: 30000);
      expect(timer.displaysSeconds, isTrue);
      expect(timer.displayValue, 30);
    });
  });
}
