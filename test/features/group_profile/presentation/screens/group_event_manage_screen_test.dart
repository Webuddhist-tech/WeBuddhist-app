import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_in_person_count.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_event_composer_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_composer_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_event_manage_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Only the in-person list is read; everything else stays unimplemented.
class _FakeComposerRepository implements GroupEventComposerRepositoryInterface {
  @override
  Future<Either<Failure, GroupEventInPersonCountList>> getInPersonCounts(
    String eventId, {
    required String eventAccumulationId,
    int skip = 0,
    int limit = 20,
  }) async => const Right(
    GroupEventInPersonCountList(
      items: [],
      total: 0,
      skip: 0,
      limit: 20,
      totalCount: 1000,
      groupAccumulatorId: 'ga1',
      timezone: 'UTC',
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _goodDeeds = GroupEventPracticeRef(id: 'ga1', name: 'Good deeds');
const _health = GroupEventPracticeRef(id: 'ga2', name: 'Health');

const _event = GroupEvent(
  id: 'e1',
  groupId: 'g1',
  title: 'test 1',
  isRecurring: true,
  accumulations: [
    GroupEventAccumulation(
      id: 'ea1',
      groupAccumulatorId: 'ga1',
      format: GroupEventParticipationType.offline,
      countMode: 'manual_in_person',
      displayOrder: 1,
      groupAccumulator: _goodDeeds,
    ),
    GroupEventAccumulation(
      id: 'ea2',
      groupAccumulatorId: 'ga2',
      format: GroupEventParticipationType.online,
      countMode: 'offline_participants',
      displayOrder: 2,
      groupAccumulator: _health,
    ),
  ],
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        groupEventDetailProvider.overrideWith(
          (ref, eventId) => Stream.value(const Right<Failure, GroupEvent>(_event)),
        ),
        groupCmsEventsProvider.overrideWith(
          (ref, groupId) => Stream.value(const []),
        ),
        groupEventComposerRepositoryProvider.overrideWithValue(
          _FakeComposerRepository(),
        ),
        groupAccumulatorDetailProvider.overrideWith(
          (ref, id) => Stream.value(
            Right<Failure, GroupAccumulatorDetail>(
            GroupAccumulatorDetail(
              id: id,
              presetAccumulatorId: 'p-$id',
              groupId: 'g1',
              title: 'Health',
              targetCount: 10000,
              totalCount: 1840,
              memberCount: 9,
            ),
          ),
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GroupEventManageScreen(event: _event),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('counts tab offers add count on the admin row only', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Counts'));
    await tester.pumpAndSettle();

    expect(find.text('Good deeds'), findsOneWidget);
    expect(find.text('Admin adds · 1,000 so far'), findsOneWidget);
    expect(find.text('Add count'), findsOneWidget);

    expect(find.text('Health'), findsOneWidget);
    expect(
      find.text('Attendees add in app · 1,840 from 9 people'),
      findsOneWidget,
    );

    expect(find.textContaining('recurring events'), findsOneWidget);
  });
}
