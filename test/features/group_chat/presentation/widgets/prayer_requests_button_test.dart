import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_requests_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(
  ProviderContainer container, {
  required int count,
  bool showChip = true,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body:
            showChip
                ? PrayerRequestsButton(
                  eventId: 'e1',
                  count: count,
                  onTap: () {},
                )
                : const SizedBox(),
      ),
    ),
  );
}

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  testWidgets('shows the live count the sheet keeps', (tester) async {
    await tester.pumpWidget(_app(container, count: 3));
    expect(find.text('3 requests'), findsOneWidget);

    container.read(prayerRequestCountProvider('e1').notifier).state = 4;
    await tester.pump();
    expect(find.text('4 requests'), findsOneWidget);
  });

  testWidgets('a newer server count replaces the live count', (tester) async {
    await tester.pumpWidget(_app(container, count: 3));
    container.read(prayerRequestCountProvider('e1').notifier).state = 3;
    await tester.pump();

    // Others posted while the sheet was closed; the event is fetched again.
    await tester.pumpWidget(_app(container, count: 8));
    await tester.pump();
    expect(find.text('8 requests'), findsOneWidget);

    // The sheet keeps counting from the fresh number.
    final live = container.read(prayerRequestCountProvider('e1').notifier);
    live.state = live.state! + 1;
    await tester.pump();
    expect(find.text('9 requests'), findsOneWidget);
  });

  testWidgets('leaving the screen drops the live count', (tester) async {
    await tester.pumpWidget(_app(container, count: 3));
    container.read(prayerRequestCountProvider('e1').notifier).state = 5;
    await tester.pump();

    // Navigating away removes the only chip watching the count.
    await tester.pumpWidget(_app(container, count: 3, showChip: false));
    await tester.pump();
    await tester.pumpWidget(_app(container, count: 3));
    expect(find.text('3 requests'), findsOneWidget);
  });
}
