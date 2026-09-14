import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/notifications/data/notification_id_scheme.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Pure-compute tests for the engine's `@visibleForTesting` daily-repeat
/// helpers (recitation / mala / timer). Plan and series reminders are delivered
/// via server push (FCM) and are no longer computed locally. These tests avoid
/// the platform plugin and SharedPreferences — only the timezone package needs
/// initialising.
void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  // The engine instance is only used to invoke the pure compute helpers;
  // its plugin/service dependencies are never touched on this path.
  late NotificationSyncEngine engine;
  final l10n = lookupAppLocalizations(const Locale('en'));

  setUp(() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    engine = container.read(notificationSyncEngineProvider);
  });

  // ─── Helpers ───────────────────────────────────────────────────────────────

  RoutineItem recitationItem({String id = 'r-1'}) => RoutineItem(
    id: id,
    title: 'Recitation',
    type: RoutineItemType.recitation,
  );

  // ─── Recitation ────────────────────────────────────────────────────────────

  group('case 4: recitation daily-repeat', () {
    test('emits a single repeating notification when enabled', () {
      final entries = engine.computeForRecitationBlock(
        RoutineBlock(
          id: 'rec-1',
          time: const TimeOfDay(hour: 7, minute: 0),
          notificationEnabled: true,
          items: [recitationItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        recitationOn: true,
        l10n: l10n,
      );
      expect(entries, hasLength(1));
      expect(entries.first.isDailyRepeat, isTrue);
      expect(entries.first.debugCase, contains('4'));
    });

    test('emits nothing when recitation sub-toggle OFF', () {
      final entries = engine.computeForRecitationBlock(
        RoutineBlock(
          id: 'rec-1',
          time: const TimeOfDay(hour: 7, minute: 0),
          notificationEnabled: true,
          items: [recitationItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        recitationOn: false,
        l10n: l10n,
      );
      expect(entries, isEmpty);
    });
  });

  group('case 4: mala (accumulator) daily-repeat', () {
    RoutineItem malaItem({String id = 'm-1', String title = 'Om Mani Padme Hum'}) =>
        RoutineItem(id: id, title: title, type: RoutineItemType.accumulator);

    test('emits a single repeating notification using the mala title', () {
      final entries = engine.computeForAccumulatorBlock(
        RoutineBlock(
          id: 'mala-1',
          time: const TimeOfDay(hour: 8, minute: 30),
          notificationEnabled: true,
          items: [malaItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        practiceOn: true,
      );
      expect(entries, hasLength(1));
      expect(entries.first.isDailyRepeat, isTrue);
      expect(entries.first.title, 'Om Mani Padme Hum');
      expect(entries.first.id, NotificationIdScheme.accumulatorBlockId(5555));
      expect(entries.first.debugCase, contains('4'));
    });

    test('emits nothing when practice sub-toggle OFF', () {
      final entries = engine.computeForAccumulatorBlock(
        RoutineBlock(
          id: 'mala-1',
          time: const TimeOfDay(hour: 8, minute: 30),
          notificationEnabled: true,
          items: [malaItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        practiceOn: false,
      );
      expect(entries, isEmpty);
    });

    test('ignores non-accumulator items in the block', () {
      final entries = engine.computeForAccumulatorBlock(
        RoutineBlock(
          id: 'mala-1',
          time: const TimeOfDay(hour: 8, minute: 30),
          notificationEnabled: true,
          items: [recitationItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        practiceOn: true,
      );
      expect(entries, isEmpty);
    });
  });

  group('case 4: timer daily-repeat (start reminder only)', () {
    RoutineItem timerItem({
      String id = 't-1',
      String title = 'Meditation',
      int? durationMs = 1800000, // 30 min
    }) =>
        RoutineItem(
      id: id,
      title: title,
      type: RoutineItemType.timer,
      durationMs: durationMs,
    );

    RoutineBlock timerBlock({
      List<RoutineItem>? items,
      int hour = 8,
      int minute = 30,
    }) =>
        RoutineBlock(
      id: 'timer-1',
      time: TimeOfDay(hour: hour, minute: minute),
      notificationEnabled: true,
      items: items ?? [timerItem()],
      notificationId: 5555,
    );

    test('emits a single "starting now" start reminder', () {
      final entries = engine.computeForTimerBlock(
        timerBlock(),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        timerOn: true,
      );
      expect(entries, hasLength(1));

      final start = entries.single;
      expect(start.id, NotificationIdScheme.timerStartId(5555));
      expect(start.isDailyRepeat, isTrue);
      expect(start.title, 'Meditation');
      expect(start.body, contains('30 minutes'));
      // Payload embeds the duration so a tap can open the timer without
      // re-resolving the routine item.
      expect(start.payload, contains('durationMs'));
      // Fires at block time.
      expect(start.fireAt!.hour, 8);
      expect(start.fireAt!.minute, 30);
    });

    test('rolls the reminder to next day when block time already passed', () {
      // `now` is UTC so the comparison is deterministic regardless of the host
      // machine's timezone (the engine converts `now` via tz.local, which is
      // UTC in these tests). 10:00 UTC is past the 08:30 block time.
      final entries = engine.computeForTimerBlock(
        timerBlock(),
        DateTime.utc(2026, 6, 5, 10),
        masterOn: true,
        timerOn: true,
      );
      expect(entries, hasLength(1));
      expect(entries[0].fireAt!.day, 6); // start → tomorrow
      expect(entries[0].fireAt!.hour, 8);
    });

    test('emits nothing when master OFF', () {
      final entries = engine.computeForTimerBlock(
        timerBlock(),
        DateTime(2026, 6, 5, 6),
        masterOn: false,
        timerOn: true,
      );
      expect(entries, isEmpty);
    });

    test('emits nothing when timer sub-toggle OFF', () {
      final entries = engine.computeForTimerBlock(
        timerBlock(),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        timerOn: false,
      );
      expect(entries, isEmpty);
    });

    test('emits nothing when duration is null or non-positive', () {
      for (final bad in <int?>[null, 0, -1]) {
        final entries = engine.computeForTimerBlock(
          timerBlock(items: [timerItem(durationMs: bad)]),
          DateTime(2026, 6, 5, 6),
          masterOn: true,
          timerOn: true,
        );
        expect(entries, isEmpty, reason: 'durationMs=$bad');
      }
    });

    test('ignores non-timer items in the block', () {
      final entries = engine.computeForTimerBlock(
        timerBlock(items: [recitationItem()]),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        timerOn: true,
      );
      expect(entries, isEmpty);
    });
  });

  group('case 4: group-recitation-collection daily-repeat', () {
    RoutineItem collectionItem({
      String id = 'c-1',
      String title = 'Morning Chants',
      int? itemCount = 12,
    }) =>
        RoutineItem(
      id: id,
      title: title,
      type: RoutineItemType.groupRecitationCollection,
      itemCount: itemCount,
    );

    test('emits a single repeating notification using the collection title', () {
        final entries = engine.computeForGroupCollectionBlock(
          RoutineBlock(
            id: 'coll-1',
            time: const TimeOfDay(hour: 7, minute: 0),
            notificationEnabled: true,
            items: [collectionItem()],
            notificationId: 5555,
          ),
          DateTime(2026, 6, 5, 6),
          masterOn: true,
          recitationOn: true,
        );
        expect(entries, hasLength(1));
        final entry = entries.single;
        expect(entry.isDailyRepeat, isTrue);
        expect(entry.title, 'Morning Chants');
        expect(entry.body, '12 chants');
        expect(entry.id, NotificationIdScheme.groupCollectionId(5555));
        expect(entry.debugCase, contains('4'));
    });

    test('falls back to a generic body when itemCount is unknown', () {
      final entries = engine.computeForGroupCollectionBlock(
        RoutineBlock(
          id: 'coll-1',
          time: const TimeOfDay(hour: 7, minute: 0),
          notificationEnabled: true,
          items: [collectionItem(itemCount: null)],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        recitationOn: true,
      );
      expect(entries.single.body, 'Time for your chant practice');
    });

    test('emits nothing when recitation sub-toggle OFF', () {
      final entries = engine.computeForGroupCollectionBlock(
        RoutineBlock(
          id: 'coll-1',
          time: const TimeOfDay(hour: 7, minute: 0),
          notificationEnabled: true,
          items: [collectionItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        recitationOn: false,
      );
      expect(entries, isEmpty);
    });

    test('emits nothing when master OFF', () {
      final entries = engine.computeForGroupCollectionBlock(
        RoutineBlock(
          id: 'coll-1',
          time: const TimeOfDay(hour: 7, minute: 0),
          notificationEnabled: true,
          items: [collectionItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: false,
        recitationOn: true,
      );
      expect(entries, isEmpty);
    });

    test('ignores non-collection items in the block', () {
      final entries = engine.computeForGroupCollectionBlock(
        RoutineBlock(
          id: 'coll-1',
          time: const TimeOfDay(hour: 7, minute: 0),
          notificationEnabled: true,
          items: [recitationItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        recitationOn: true,
      );
      expect(entries, isEmpty);
    });

    test('produces an ID distinct from recitation/mala/timer in the same block', () {
        const blockId = 5555;
        final ids = {
          blockId, // recitation
          NotificationIdScheme.accumulatorBlockId(blockId),
          NotificationIdScheme.timerStartId(blockId),
          NotificationIdScheme.groupCollectionId(blockId),
          NotificationIdScheme.groupAccumulatorId(blockId),
        };
        expect(ids, hasLength(5)); // all distinct
      },
    );
  });

  group('case 4: group-accumulator daily-repeat', () {
    RoutineItem groupAccumulatorItem({
      String id = 'ga-1',
      String title = 'Group Mani',
    }) => RoutineItem(
      id: id,
      title: title,
      type: RoutineItemType.groupAccumulator,
    );

    RoutineBlock block(List<RoutineItem> items) => RoutineBlock(
      id: 'ga-block',
      time: const TimeOfDay(hour: 7, minute: 0),
      notificationEnabled: true,
      items: items,
      notificationId: 5555,
    );

    test('emits a single repeating notification using the accumulation title',
        () {
      final entries = engine.computeForGroupAccumulatorBlock(
        block([groupAccumulatorItem()]),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        practiceOn: true,
      );
      expect(entries, hasLength(1));
      final entry = entries.single;
      expect(entry.isDailyRepeat, isTrue);
      expect(entry.title, 'Group Mani');
      expect(entry.body, 'Time for your group accumulation');
      expect(entry.id, NotificationIdScheme.groupAccumulatorId(5555));
      expect(entry.payload, contains('"itemType":"groupAccumulator"'));
    });

    test('counts the other group accumulations in the block', () {
      final entries = engine.computeForGroupAccumulatorBlock(
        block([groupAccumulatorItem(), groupAccumulatorItem(id: 'ga-2')]),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        practiceOn: true,
      );
      expect(entries.single.body, 'Time for your group accumulation and 1 more');
    });

    test('emits nothing when practice sub-toggle OFF', () {
      final entries = engine.computeForGroupAccumulatorBlock(
        block([groupAccumulatorItem()]),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        practiceOn: false,
      );
      expect(entries, isEmpty);
    });

    test('ignores personal mala items in the block', () {
      final entries = engine.computeForGroupAccumulatorBlock(
        block([
          const RoutineItem(
            id: 'preset-1',
            title: 'Om Mani',
            type: RoutineItemType.accumulator,
          ),
        ]),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        practiceOn: true,
      );
      expect(entries, isEmpty);
    });
  });

  group('case 4: personal recitation-collection daily-repeat', () {
    RoutineItem collectionItem({
      String id = 'my-c-1',
      String title = 'My Morning Chants',
      int? itemCount = 7,
    }) => RoutineItem(
      id: id,
      title: title,
      type: RoutineItemType.myRecitationCollection,
      itemCount: itemCount,
    );

    test(
      'emits a single repeating notification using the collection title',
      () {
        final entries = engine.computeForMyCollectionBlock(
          RoutineBlock(
            id: 'my-coll-1',
            time: const TimeOfDay(hour: 7, minute: 0),
            notificationEnabled: true,
            items: [collectionItem()],
            notificationId: 5555,
          ),
          DateTime(2026, 6, 5, 6),
          masterOn: true,
          recitationOn: true,
        );

        expect(entries, hasLength(1));
        final entry = entries.single;
        expect(entry.isDailyRepeat, isTrue);
        expect(entry.title, 'My Morning Chants');
        expect(entry.body, '7 chants');
        expect(entry.id, NotificationIdScheme.myCollectionId(5555));
        expect(entry.debugCase, '4 daily-repeat-my-collection');
      },
    );

    test('ignores group collection items in the block', () {
      final entries = engine.computeForMyCollectionBlock(
        RoutineBlock(
          id: 'my-coll-1',
          time: const TimeOfDay(hour: 7, minute: 0),
          notificationEnabled: true,
          items: const [
            RoutineItem(
              id: 'group-c-1',
              title: 'Group Chants',
              type: RoutineItemType.groupRecitationCollection,
            ),
          ],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        recitationOn: true,
      );

      expect(entries, isEmpty);
    });
  });

  // ─── ID scheme ─────────────────────────────────────────────────────────────

  group('NotificationIdScheme', () {
    test('isOurs covers all owned ranges (incl. legacy plan/series)', () {
      expect(NotificationIdScheme.isOurs(800), isTrue); // legacy special one-shot
      expect(NotificationIdScheme.isOurs(1500), isTrue); // routine block
      expect(NotificationIdScheme.isOurs(9999), isTrue); // diagnostic
      expect(NotificationIdScheme.isOurs(9000000), isTrue); // legacy plan one-shot
      expect(NotificationIdScheme.isOurs(10000000), isTrue); // legacy plan series
      expect(NotificationIdScheme.isOurs(20000000), isTrue); // accumulator block
      expect(NotificationIdScheme.isOurs(21000000), isTrue); // timer start
      expect(NotificationIdScheme.isOurs(23000000), isTrue); // group collection
      expect(NotificationIdScheme.isOurs(24000000), isTrue); // my collection
      expect(NotificationIdScheme.isOurs(25000000), isTrue); // group accumulator
      expect(NotificationIdScheme.isOurs(50), isFalse); // system range
      expect(NotificationIdScheme.isOurs(30000000), isFalse); // outside
    });

    test(
      'isRoutineDailyRepeat covers recitation + mala + timer + collection ranges only',
      () {
        expect(NotificationIdScheme.isRoutineDailyRepeat(5555), isTrue); // recitation block
        expect(
          NotificationIdScheme.isRoutineDailyRepeat(
            NotificationIdScheme.accumulatorBlockId(5555),
          ),
          isTrue, // mala block
        );
        expect(
          NotificationIdScheme.isRoutineDailyRepeat(
            NotificationIdScheme.timerStartId(5555),
          ),
          isTrue, // timer start
        );
        expect(
          NotificationIdScheme.isRoutineDailyRepeat(
            NotificationIdScheme.groupCollectionId(5555),
          ),
          isTrue, // group collection
        );
        expect(
          NotificationIdScheme.isRoutineDailyRepeat(
            NotificationIdScheme.myCollectionId(5555),
          ),
          isTrue, // my collection
        );
        expect(
          NotificationIdScheme.isRoutineDailyRepeat(
            NotificationIdScheme.groupAccumulatorId(5555),
          ),
          isTrue, // group accumulator
        );
        expect(
          NotificationIdScheme.isRoutineDailyRepeat(9000000),
          isFalse,
        ); // legacy plan one-shot
        expect(
          NotificationIdScheme.isRoutineDailyRepeat(10000000),
          isFalse,
        ); // legacy plan series
        expect(
          NotificationIdScheme.isRoutineDailyRepeat(810),
          isFalse,
        ); // legacy special
      },
    );

    test(
      'accumulator + timer + collection block ids are distinct from each other',
      () {
        // A block holding a recitation (notificationId), a mala
        // (accumulatorBlockId), a timer (timerStartId), and a group collection
        // (groupCollectionId/myCollectionId) must produce non-colliding IDs.
        const blockId = 5555;
        final malaId = NotificationIdScheme.accumulatorBlockId(blockId);
        final timerStart = NotificationIdScheme.timerStartId(blockId);
        final groupCollection = NotificationIdScheme.groupCollectionId(blockId);
        final myCollection = NotificationIdScheme.myCollectionId(blockId);
        final ids = {
          blockId,
          malaId,
          timerStart,
          groupCollection,
          myCollection,
        };
        expect(ids, hasLength(5)); // all distinct
        expect(NotificationIdScheme.isOurs(malaId), isTrue);
        expect(NotificationIdScheme.isOurs(timerStart), isTrue);
        expect(NotificationIdScheme.isOurs(groupCollection), isTrue);
        expect(NotificationIdScheme.isOurs(myCollection), isTrue);
      },
    );
  });

  // Silence analyzer warnings for unused imports.
  // Reference the singletons so the static-analysis-only imports are kept.
  test('keeps unused-import warnings down', () {
    expect(RoutineNotificationService(), isNotNull);
    expect(NotificationService(), isNotNull);
  });
}
