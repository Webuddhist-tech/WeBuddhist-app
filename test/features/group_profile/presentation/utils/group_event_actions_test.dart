import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_actions.dart';
import 'package:flutter_test/flutter_test.dart';

const _series = GroupEventPracticeRef(id: 's1', name: '21 Taras');

GroupEvent _event(String format, {bool hasPuja = true}) => GroupEvent(
  id: 'e1',
  groupId: 'g1',
  eventFormat: format,
  series: hasPuja ? _series : null,
);

void main() {
  group('groupEventActionsFor, not joined', () {
    test('offers both views and Join on an upcoming hybrid event', () {
      expect(
        groupEventActionsFor(
          _event('hybrid'),
          isAttending: false,
          isPast: false,
        ),
        [
          GroupEventAction.viewInPerson,
          GroupEventAction.viewOnline,
          GroupEventAction.join,
        ],
      );
    });

    test('offers only the event format view on a single-format event', () {
      expect(
        groupEventActionsFor(
          _event('online'),
          isAttending: false,
          isPast: false,
        ),
        [GroupEventAction.viewOnline, GroupEventAction.join],
      );
      expect(
        groupEventActionsFor(
          _event('offline'),
          isAttending: false,
          isPast: false,
        ),
        [GroupEventAction.viewInPerson, GroupEventAction.join],
      );
    });

    test('offers only Join when there is no plan to explore', () {
      expect(
        groupEventActionsFor(
          _event('hybrid', hasPuja: false),
          isAttending: false,
          isPast: false,
        ),
        [GroupEventAction.join],
      );
    });

    test('keeps the views but drops Join once the event is over', () {
      expect(
        groupEventActionsFor(
          _event('hybrid'),
          isAttending: false,
          isPast: true,
        ),
        [GroupEventAction.viewInPerson, GroupEventAction.viewOnline],
      );
      expect(
        groupEventActionsFor(
          _event('online', hasPuja: false),
          isAttending: false,
          isPast: true,
        ),
        isEmpty,
      );
    });
  });

  group('groupEventActionsFor, joined', () {
    test('offers both practice buttons on an upcoming hybrid event', () {
      expect(
        groupEventActionsFor(
          _event('hybrid'),
          isAttending: true,
          isPast: false,
        ),
        [GroupEventAction.practiceInPerson, GroupEventAction.practiceOnline],
      );
    });

    test('offers only the event format on a single-format event', () {
      expect(
        groupEventActionsFor(
          _event('online'),
          isAttending: true,
          isPast: false,
        ),
        [GroupEventAction.practiceOnline],
      );
      expect(
        groupEventActionsFor(
          _event('offline'),
          isAttending: true,
          isPast: false,
        ),
        [GroupEventAction.practiceInPerson],
      );
    });

    test('shows no buttons when there is no plan', () {
      expect(
        groupEventActionsFor(
          _event('hybrid', hasPuja: false),
          isAttending: true,
          isPast: false,
        ),
        isEmpty,
      );
    });

    test('falls back to one Practice now button after the event', () {
      expect(
        groupEventActionsFor(
          _event('hybrid'),
          isAttending: true,
          isPast: true,
        ),
        [GroupEventAction.practiceNow],
      );
    });
  });

  test('an event without a format but with a location runs in person', () {
    const event = GroupEvent(
      id: 'e1',
      groupId: 'g1',
      locationId: 'l1',
      series: _series,
    );
    expect(
      groupEventActionsFor(
        event,
        isAttending: false,
        isPast: false,
      ),
      [GroupEventAction.viewInPerson, GroupEventAction.join],
    );
  });

  group('showsGroupEventMenu', () {
    test('only for an attendee of an event that is not over', () {
      expect(showsGroupEventMenu(isAttending: true, isPast: false), isTrue);
      expect(showsGroupEventMenu(isAttending: true, isPast: true), isFalse);
      expect(showsGroupEventMenu(isAttending: false, isPast: false), isFalse);
      expect(showsGroupEventMenu(isAttending: false, isPast: true), isFalse);
    });
  });
}
