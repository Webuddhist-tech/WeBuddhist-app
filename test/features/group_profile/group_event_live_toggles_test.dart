import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_live_toggles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('language toggle reports the tapped language code', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupEventLanguageToggle(
            language: 'en',
            onChanged: (code) => selected = code,
          ),
        ),
      ),
    );

    expect(find.text('En'), findsOneWidget);
    expect(find.text('中文'), findsOneWidget);

    await tester.tap(find.text('བོད'));
    expect(selected, 'bo');

    await tester.tap(find.text('中文'));
    expect(selected, 'zh');
  });
}
