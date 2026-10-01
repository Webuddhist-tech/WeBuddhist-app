import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/home/presentation/utils/home_live_event_navigation.dart';
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
}
