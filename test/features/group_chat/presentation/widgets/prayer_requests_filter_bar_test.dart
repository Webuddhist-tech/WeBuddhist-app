import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_requests_filter.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_requests_filter_bar.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onFindPrayer,
  PrayerRequestsFilter filter = const PrayerRequestsFilter(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 328,
            child: PrayerRequestsFilterBar(
              filter: filter,
              total: 8,
              onOpenSort: () {},
              onClearIntention: () {},
              onFindPrayer: onFindPrayer,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the random pill sits against the sort control', (tester) async {
    var taps = 0;
    await _pump(tester, onFindPrayer: () => taps++);

    final bar = tester.getRect(find.byType(PrayerRequestsFilterBar));
    final pill = tester.getRect(find.text('Random'));
    final sort = tester.getRect(find.text('Newest'));
    expect(sort.left - pill.right, lessThan(24));
    expect(bar.right - sort.right, lessThan(24));

    await tester.tap(find.text('Random'));
    expect(taps, 1);
  });

  testWidgets('a long sort label gives way before the count does', (
    tester,
  ) async {
    await _pump(
      tester,
      onFindPrayer: () {},
      filter: const PrayerRequestsFilter(sort: PrayerSort.needsPrayers),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('8 requests'), findsOneWidget);
    expect(find.text('Needs prayers'), findsOneWidget);
  });

  testWidgets('no callback hides the pill', (tester) async {
    await _pump(tester);
    expect(find.text('Random'), findsNothing);
  });
}
