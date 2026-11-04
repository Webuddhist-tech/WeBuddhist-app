import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_space_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/your_spaces_screen.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Shaped like the joined-spaces API: counts in joiner_count and
// follower_count, member_count left out.
const _spaces = [
  GroupProfile(id: 'a', title: 'WeBuddhist', joinerCount: 1200),
  GroupProfile(id: 'b', title: 'Light of Buddhadharma', joinerCount: 2),
  GroupProfile(
    id: 'c',
    title: 'Dharma Voices',
    groupType: GroupType.page,
    followerCount: 1,
  ),
];

Future<ProviderContainer> _open(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      joinedSpacesProvider.overrideWithValue(
        const JoinedSpaces(spaces: _spaces, isLoading: false),
      ),
      unreadSpaceIdsProvider.overrideWithValue(const {'b'}),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed:
                      () => YourSpacesScreen.show(context, currentSpaceId: 'a'),
                  child: const Text('open'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('lists the spaces with a dot only on the unread one', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Your spaces'), findsOneWidget);
    expect(find.text('1.2k members'), findsOneWidget);
    expect(find.text('2 members'), findsOneWidget);
    expect(find.text('1 follower'), findsOneWidget);
    expect(find.text('0 members'), findsNothing);
    expect(find.text('Find a space'), findsOneWidget);
    expect(find.byType(ConnectUnreadDot), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Light of Buddhadharma'),
          matching: find.byType(Row),
        ),
        matching: find.byType(ConnectUnreadDot),
      ),
      findsOneWidget,
    );
  });

  testWidgets('choosing a space remembers it and closes the panel', (
    tester,
  ) async {
    final container = await _open(tester);

    await tester.tap(find.text('Light of Buddhadharma'));
    await tester.pumpAndSettle();

    expect(find.byType(YourSpacesScreen), findsNothing);
    expect(container.read(connectLastSpaceProvider).spaceId, 'b');
  });
}
