import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_cms_item.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_composer_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_events_tab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

Future<void> _pump(
  WidgetTester tester, {
  required List<GroupEvent> events,
  required bool canCreate,
  List<GroupEventCmsItem> cmsItems = const [],
  VoidCallback? onCreateEvent,
  ValueChanged<GroupEventCmsItem>? onEditDraft,
  ValueChanged<GroupEventCmsItem>? onDeleteDraft,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        groupEventsProvider.overrideWith(
          (ref, groupId) => Stream.value(
            Right<Failure, GroupEventsPage>(
              GroupEventsPage(events: events, total: events.length),
            ),
          ),
        ),
        groupCmsEventsProvider.overrideWith(
          (ref, groupId) => Stream.value(cmsItems),
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
              onCreateEvent: onCreateEvent ?? () {},
              onEditDraft: onEditDraft ?? (_) {},
              onDeleteDraft: onDeleteDraft ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty tab offers Create event only to publishers', (
    tester,
  ) async {
    await _pump(tester, events: const [], canCreate: false);

    expect(find.text('No events yet'), findsOneWidget);
    expect(find.text('Create event'), findsNothing);
    expect(find.byTooltip('New event'), findsNothing);

    var taps = 0;
    await _pump(
      tester,
      events: const [],
      canCreate: true,
      onCreateEvent: () => taps++,
    );

    expect(find.text('No events yet'), findsOneWidget);
    expect(
      find.text('Create your first gathering — members will be notified.'),
      findsOneWidget,
    );
    expect(find.text('Create event'), findsOneWidget);
    expect(find.byTooltip('New event'), findsNothing);

    await tester.tap(find.text('Create event'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('list shows the plus button only to publishers', (tester) async {
    const event = GroupEvent(id: 'e1', groupId: 'g1', title: 'Wednesday');
    const cms = GroupEventCmsItem(event: event, status: 'published', raw: {});

    await _pump(tester, events: const [event], canCreate: false);
    expect(find.text('Wednesday'), findsOneWidget);
    expect(find.byTooltip('New event'), findsNothing);

    var taps = 0;
    await _pump(
      tester,
      events: const [],
      canCreate: true,
      cmsItems: const [cms],
      onCreateEvent: () => taps++,
    );
    expect(find.text('Wednesday'), findsOneWidget);
    expect(find.byTooltip('New event'), findsOneWidget);
    expect(find.text('DRAFTS'), findsNothing);

    await tester.tap(find.byTooltip('New event'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('publishers see drafts first with a menu', (tester) async {
    const live = GroupEvent(id: 'e1', groupId: 'g1', title: 'Wednesday');
    const draft = GroupEvent(id: 'e2', groupId: 'g1', title: 'Half done');
    const items = [
      GroupEventCmsItem(event: live, status: 'published', raw: {}),
      GroupEventCmsItem(event: draft, status: 'draft', raw: {'id': 'e2'}),
    ];
    GroupEventCmsItem? edited;
    GroupEventCmsItem? deleted;

    await _pump(
      tester,
      events: const [],
      canCreate: true,
      cmsItems: items,
      onEditDraft: (item) => edited = item,
      onDeleteDraft: (item) => deleted = item,
    );

    expect(find.text('DRAFTS'), findsOneWidget);
    expect(find.text('Half done'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Wednesday'), findsOneWidget);

    await tester.tap(find.byTooltip('Draft'));
    await tester.pumpAndSettle();
    expect(find.text('Continue editing'), findsOneWidget);
    await tester.tap(find.text('Delete draft'));
    await tester.pumpAndSettle();
    expect(deleted?.event.id, 'e2');

    await tester.tap(find.text('Half done'));
    await tester.pumpAndSettle();
    expect(edited?.event.id, 'e2');
  });
}
