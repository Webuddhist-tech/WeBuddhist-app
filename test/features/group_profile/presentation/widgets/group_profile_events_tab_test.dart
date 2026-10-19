import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_events_tab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

Future<int> _pump(
  WidgetTester tester, {
  required List<GroupEvent> events,
  required bool canCreate,
}) async {
  var taps = 0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        groupEventsProvider.overrideWith(
          (ref, groupId) async => Right<Failure, GroupEventsPage>(
            GroupEventsPage(events: events, total: events.length),
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder:
                (context, _) => [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                    sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
                ],
            body: GroupProfileEventsTab(
              groupId: 'g1',
              isDark: false,
              pageStorageKey: 'events',
              canCreate: canCreate,
              onCreateEvent: () => taps++,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return taps;
}

void main() {
  testWidgets('empty tab offers Create event only to publishers', (
    tester,
  ) async {
    await _pump(tester, events: const [], canCreate: false);

    expect(find.text('No events yet'), findsOneWidget);
    expect(find.text('Create event'), findsNothing);
    expect(find.byTooltip('New event'), findsNothing);

    await _pump(tester, events: const [], canCreate: true);

    expect(find.text('No events yet'), findsOneWidget);
    expect(
      find.text('Create your first gathering — members will be notified.'),
      findsOneWidget,
    );
    expect(find.text('Create event'), findsOneWidget);
    expect(find.byTooltip('New event'), findsNothing);
  });

  testWidgets('list shows the plus button only to publishers', (tester) async {
    const event = GroupEvent(id: 'e1', groupId: 'g1', title: 'Wednesday');

    await _pump(tester, events: const [event], canCreate: false);
    expect(find.text('Wednesday'), findsOneWidget);
    expect(find.byTooltip('New event'), findsNothing);

    await _pump(tester, events: const [event], canCreate: true);
    expect(find.text('Wednesday'), findsOneWidget);
    expect(find.byTooltip('New event'), findsOneWidget);
  });
}
