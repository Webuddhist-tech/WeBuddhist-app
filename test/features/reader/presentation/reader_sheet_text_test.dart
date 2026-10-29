import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_fonts.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

/// [role]'s sheet text in an interface in [language].
Future<TextStyle> _styleIn(
  WidgetTester tester,
  String language,
  ReaderSheetTextRole role,
) async {
  late TextStyle style;
  await tester.pumpWidget(
    Localizations(
      locale: Locale(language),
      delegates: const [DefaultWidgetsLocalizations.delegate],
      child: Builder(
        builder: (context) {
          style = readerSheetText(context, role, color: Colors.black);
          return const SizedBox();
        },
      ),
    ),
  );
  return style;
}

void main() {
  // The Sheets card: title 17 Semi Bold, group title 15 Semi Bold, row 16,
  // caps label 11 Semi Bold, chips 13; × Tibetan 1.5 and Chinese 1.05.
  const roles = {
    ReaderSheetTextRole.title: (17.0, FontWeight.w600),
    ReaderSheetTextRole.group: (15.0, FontWeight.w600),
    ReaderSheetTextRole.row: (16.0, FontWeight.w400),
    ReaderSheetTextRole.caps: (11.0, FontWeight.w600),
    ReaderSheetTextRole.chip: (13.0, FontWeight.w500),
  };

  testWidgets('English: the card\'s sizes and weights, in Inter', (
    tester,
  ) async {
    for (final MapEntry(key: role, value: (size, weight)) in roles.entries) {
      final style = await _styleIn(tester, 'en', role);
      expect(style.fontSize, size, reason: role.name);
      expect(style.fontWeight, weight, reason: role.name);
      expect(style.fontFamily, ReaderFonts.inter.family(weight: weight));
    }
  });

  testWidgets('Tibetan and Chinese: × their script factor, own fonts', (
    tester,
  ) async {
    final tibetan = [
      for (final role in roles.keys)
        (await _styleIn(tester, 'bo', role)).fontSize,
    ];
    final chinese = [
      for (final role in roles.keys)
        (await _styleIn(tester, 'zh', role)).fontSize,
    ];
    expect(tibetan, [26, 23, 24, 17, 20]);
    expect(chinese, [18, 16, 17, 12, 14]);
    expect(
      (await _styleIn(tester, 'bo', ReaderSheetTextRole.title)).fontFamily,
      isNull,
    );
  });

  testWidgets('Hindi and Mongolian: the Latin sizes', (tester) async {
    for (final language in ['hi', 'mn']) {
      expect(
        (await _styleIn(tester, language, ReaderSheetTextRole.row)).fontSize,
        16,
      );
    }
  });
}
