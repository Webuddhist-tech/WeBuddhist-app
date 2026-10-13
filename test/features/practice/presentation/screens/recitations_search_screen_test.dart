import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/recitations_search_screen.dart';
import 'package:flutter_pecha/features/recitation/data/repositories/recitations_repository.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRecitationsRepository extends Fake
    implements RecitationsRepository {}

void main() {
  // Crashlytics 4836da56 (variant 3dbf1723): dispose() read a provider
  // through `ref`, which Riverpod forbids once the widget is unmounted, so
  // the screen threw every time it closed.
  testWidgets('closing the search screen does not throw', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recitationsRepositoryProvider.overrideWithValue(
            _FakeRecitationsRepository(),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(),
        ),
      ),
    );

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const RecitationsSearchScreen(languageCode: 'en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RecitationsSearchScreen), findsOneWidget);

    // A system back, which skips the screen's own back button.
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.byType(RecitationsSearchScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
