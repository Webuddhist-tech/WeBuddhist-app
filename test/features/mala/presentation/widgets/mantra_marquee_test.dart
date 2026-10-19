import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mantra_marquee.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(String text, {bool reduceMotion = false}) {
  return MaterialApp(
    home: Builder(
      builder:
          (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  child: MantraMarquee(
                    text: text,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
    ),
  );
}

const _long =
    'Om Mani Padme Hum Om Mani Padme Hum Om Mani Padme Hum Om Mani Padme Hum';

void main() {
  testWidgets('text that fits stays still', (tester) async {
    await tester.pumpWidget(_host('Om'));
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('text that overflows keeps scrolling', (tester) async {
    await tester.pumpWidget(_host(_long));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('reduced motion stops overflowing text from scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_long, reduceMotion: true));
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
