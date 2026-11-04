import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_filled_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

RoutineItem _item(String title) =>
    RoutineItem(id: title, title: title, type: RoutineItemType.series);

Widget _app(RoutineData data) => ProviderScope(
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: RoutineFilledState(routineData: data, onEdit: () {})),
  ),
);

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  final untitled = RoutineBlock(
    time: const TimeOfDay(hour: 7, minute: 0),
    items: [_item('Morning chants'), _item('Heart Sutra'), _item('Tara')],
  );
  final titled = RoutineBlock(
    time: const TimeOfDay(hour: 19, minute: 0),
    title: 'Evening practice',
    items: [_item('Mani')],
  );
  final data = RoutineData(blocks: [untitled, titled]);

  testWidgets('collapsed untitled block shows the default title', (
    tester,
  ) async {
    await tester.pumpWidget(_app(data));
    await tester.pumpAndSettle();

    expect(find.text('Morning chants +2 more'), findsOneWidget);
    expect(find.text('Evening practice'), findsOneWidget);
  });

  testWidgets('expand all hides the default title but keeps real titles', (
    tester,
  ) async {
    await tester.pumpWidget(_app(data));
    await tester.pumpAndSettle();

    await tester.tap(find.text(en.routine_expand_all));
    await tester.pumpAndSettle();

    expect(find.text('Morning chants +2 more'), findsNothing);
    expect(find.text('Evening practice'), findsOneWidget);
    // The items themselves are listed instead.
    expect(find.text('Morning chants'), findsOneWidget);
  });

  testWidgets('expanding one block hides only its default title', (
    tester,
  ) async {
    final other = RoutineBlock(
      time: const TimeOfDay(hour: 12, minute: 0),
      items: [_item('Bodhisattva Challenge'), _item('Mani')],
    );
    await tester.pumpWidget(_app(RoutineData(blocks: [untitled, other])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning chants +2 more'));
    await tester.pumpAndSettle();

    expect(find.text('Morning chants +2 more'), findsNothing);
    expect(find.text('Bodhisattva Challenge +1 more'), findsOneWidget);
  });
}
