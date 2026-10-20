import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_draft_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

final _json = <String, dynamic>{
  'id': 'ev-1',
  'group_id': 'g1',
  'status': 'draft',
  'timezone': 'Asia/Kolkata',
  'start_date': '2026-10-07T12:30:00Z',
  'end_date': '2026-10-09T13:30:00Z',
  'is_one_day': false,
  'is_recurring': false,
  'event_format': 'hybrid',
  'chat_enabled': false,
  'notifications_enabled': true,
  'metadata': [
    {
      'id': 'm1',
      'language': 'EN',
      'name': 'Wednesday practice',
      'description': 'Join',
    },
    {'id': 'm2', 'language': 'BO', 'name': 'ལྷག་པ།'},
  ],
  'image': {'original': 'https://cdn/x.jpg', 'medium': 'https://cdn/x-m.jpg'},
  'location_id': 'loc-1',
  'location': {
    'id': 'loc-1',
    'group_id': 'g1',
    'name': 'Hall',
    'latitude': 27.3,
    'longitude': 88.6,
  },
  'youtube': [
    {
      'id': 'y1',
      'url': 'https://www.youtube.com/@x/live',
      'language': 'EN',
      'display_order': 1,
    },
  ],
  'links': [
    {
      'id': 'l2',
      'type': 'video',
      'url': 'https://youtu.be/b',
      'label': 'Second',
      'display_order': 2,
    },
    {
      'id': 'l1',
      'type': 'video',
      'url': 'https://youtu.be/a',
      'label': 'First',
      'display_order': 1,
    },
  ],
  'plan_id': 'p1',
  'plan': {'id': 'p1', 'name': '21 Taras', 'image_url': 'https://cdn/p.jpg'},
  'group_recitation_collection_id': 'c1',
  'group_recitation_collection': {'id': 'c1', 'name': 'Praises'},
  'accumulations': [
    {
      'id': 'x2',
      'group_accumulator_id': 'a2',
      'event_format': 'online',
      'display_order': 2,
      'count_mode': 'offline_participants',
      'group_accumulator': {'id': 'a2', 'name': 'Green Tara'},
    },
    {
      'id': 'x1',
      'group_accumulator_id': 'a1',
      'event_format': 'offline',
      'display_order': 1,
      'count_mode': 'manual_in_person',
      'group_accumulator': {'id': 'a1', 'name': 'Mani'},
    },
  ],
  'intentions': [
    {'slug': 'peace', 'label': 'Peace'},
  ],
};

void main() {
  test('reads a CMS event back into the draft', () {
    final source = GroupEventDraftMapper.fromJson(_json);
    final draft = source.draft;

    expect(source.eventId, 'ev-1');
    expect(source.locationId, 'loc-1');
    expect(source.imageUrl, 'https://cdn/x.jpg');
    expect(source.intentionSlugs, ['peace']);

    expect(draft.languages, ['en', 'bo']);
    expect(draft.metadataFor('en')?.name, 'Wednesday practice');
    expect(draft.metadataFor('en')?.description, 'Join');
    expect(draft.cover, isA<GroupEventCoverUrl>());

    final schedule = draft.schedule;
    expect(schedule.timezone, 'Asia/Kolkata');
    expect(schedule.startDate, DateTime(2026, 10, 7));
    expect(schedule.endDate, DateTime(2026, 10, 9));
    expect(schedule.isMultiDay, isTrue);
    expect(schedule.allDay, isFalse);
    expect(schedule.startTime, const GroupEventTime(18, 0));
    expect(schedule.endTime, const GroupEventTime(19, 0));
    expect(schedule.isRecurring, isFalse);

    expect(draft.format, GroupEventFormat.hybrid);
    expect(draft.venue?.name, 'Hall');
    expect(source.sameVenue(draft.venue), isTrue);
    expect(draft.liveLink, 'https://www.youtube.com/@x/live');
    expect(draft.videos.map((v) => v.title), ['First', 'Second']);

    expect(draft.practices.map((p) => p.id), ['p1', 'c1', 'a1', 'a2']);
    expect(draft.practices[0].kind, GroupEventPracticeKind.plan);
    expect(draft.practices[0].title, '21 Taras');
    expect(draft.practices[2].countMode, GroupEventCountMode.admin);
    expect(draft.practices[3].countMode, GroupEventCountMode.attendees);

    expect(draft.chatEnabled, isFalse);
    expect(draft.notificationsEnabled, isTrue);
  });

  test('all-day and recurring events come back as such', () {
    final source = GroupEventDraftMapper.fromJson({
      ..._json,
      'start_date': '2026-10-07T00:30:00Z',
      'end_date': '2026-10-07T18:29:00Z',
      'is_recurring': true,
      'recurrence': {
        'frequency': 'WEEKLY',
        'date_system': 'GREGORIAN',
        'day_of_week': 2,
        'duration_days': 1,
      },
    });
    final schedule = source.draft.schedule;

    expect(schedule.allDay, isTrue);
    expect(schedule.startTime, isNull);
    expect(schedule.isRecurring, isTrue);
    expect(schedule.isMultiDay, isFalse);
    expect(
      schedule.recurrence?.frequency,
      GroupEventRecurrenceFrequency.weekly,
    );
    expect(schedule.recurrence?.dayOfWeek, 2);
  });

  test('a bare event with no timezone or location still maps', () {
    final source = GroupEventDraftMapper.fromJson({
      'id': 'ev-2',
      'metadata': {'language': 'EN', 'name': 'Solo'},
      'start_date': '2026-10-07T12:30:00Z',
      'end_date': '2026-10-07T13:30:00Z',
    });
    expect(source.draft.schedule.timezone, 'Asia/Kolkata');
    expect(source.draft.languages, ['en']);
    expect(source.venue, isNull);
    expect(source.draft.cover, isNull);
    expect(source.draft.format, GroupEventFormat.hybrid);
  });
}
