import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/home/presentation/utils/home_live_event_navigation.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_live_position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveHomeLiveEventKind', () {
    test('stays on the event page when the user has not joined', () {
      expect(
        resolveHomeLiveEventKind(
          isJoined: false,
          participationType: GroupEventParticipationType.offline,
          isHybrid: false,
          isOnlineFormat: false,
          liveSessionStarted: true,
        ),
        HomeLiveEventKind.eventPage,
      );
    });

    test('stays on the event page when a hybrid attendee has not chosen', () {
      expect(
        resolveHomeLiveEventKind(
          isJoined: true,
          participationType: null,
          isHybrid: true,
          isOnlineFormat: false,
          liveSessionStarted: true,
        ),
        HomeLiveEventKind.eventPage,
      );
    });

    test('stays on the event page when the live session has not started', () {
      expect(
        resolveHomeLiveEventKind(
          isJoined: true,
          participationType: GroupEventParticipationType.offline,
          isHybrid: true,
          isOnlineFormat: false,
          liveSessionStarted: false,
        ),
        HomeLiveEventKind.eventPage,
      );
      expect(
        resolveHomeLiveEventKind(
          isJoined: true,
          participationType: GroupEventParticipationType.online,
          isHybrid: true,
          isOnlineFormat: false,
          liveSessionStarted: false,
        ),
        HomeLiveEventKind.eventPage,
      );
    });

    test('opens the live text for an in-person attendee', () {
      expect(
        resolveHomeLiveEventKind(
          isJoined: true,
          participationType: GroupEventParticipationType.offline,
          isHybrid: true,
          isOnlineFormat: false,
          liveSessionStarted: true,
        ),
        HomeLiveEventKind.inPerson,
      );
    });

    test('opens the join-online screen for an online attendee', () {
      expect(
        resolveHomeLiveEventKind(
          isJoined: true,
          participationType: GroupEventParticipationType.online,
          isHybrid: true,
          isOnlineFormat: false,
          liveSessionStarted: true,
        ),
        HomeLiveEventKind.online,
      );
    });

    test('infers a single-format event once the user has joined', () {
      expect(
        resolveHomeLiveEventKind(
          isJoined: true,
          participationType: null,
          isHybrid: false,
          isOnlineFormat: true,
          liveSessionStarted: true,
        ),
        HomeLiveEventKind.online,
      );
      expect(
        resolveHomeLiveEventKind(
          isJoined: true,
          participationType: null,
          isHybrid: false,
          isOnlineFormat: false,
          liveSessionStarted: true,
        ),
        HomeLiveEventKind.inPerson,
      );
    });
  });

  group('readerContextForLivePosition', () {
    const position = RecitationLivePosition(
      eventId: 'ev1',
      textId: 'text-b',
      segmentId: 'seg-9',
      revision: 4,
    );

    test('opens the live text on its own when it is not in the day', () {
      final context = readerContextForLivePosition(
        eventId: 'ev1',
        position: position,
        items: [
          PlanTextItem.sourceReference(textId: 'text-a', title: 'A'),
        ],
      );

      expect(context.source, NavigationSource.normal);
      expect(context.eventId, 'ev1');
      expect(context.isOnlineAttendee, isFalse);
      expect(context.isLiveRecitation, isTrue);
      expect(context.targetSegmentId, 'seg-9');
      expect(context.planTextItems, isNull);
    });

    test('attaches the day sequence when the live text is in it', () {
      final items = [
        PlanTextItem.sourceReference(textId: 'text-a', title: 'A'),
        PlanTextItem.sourceReference(textId: 'text-b', title: 'B'),
      ];
      final context = readerContextForLivePosition(
        eventId: 'ev1',
        position: position,
        planId: 'plan-1',
        dayNumber: 2,
        dayAudioUrl: 'https://audio.example/day.mp3',
        items: items,
      );

      expect(context.source, NavigationSource.plan);
      expect(context.planId, 'plan-1');
      expect(context.dayNumber, 2);
      expect(context.currentTextIndex, 1);
      expect(context.planTextItems, items);
      expect(context.targetSegmentId, 'seg-9');
      expect(context.dayAudioUrl, 'https://audio.example/day.mp3');
      expect(context.isLiveRecitation, isTrue);
    });
  });
}
