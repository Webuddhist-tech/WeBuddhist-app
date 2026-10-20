import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_request_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const metadata = [
    GroupEventDraftMetadata(language: 'en', name: ' Wednesday practice '),
    GroupEventDraftMetadata(language: 'bo', description: 'only a description'),
    GroupEventDraftMetadata(language: 'zh', name: '周三共修', description: ' 说明 '),
  ];
  final schedule = GroupEventScheduleDraft(
    startDate: DateTime(2026, 10, 7),
    startTime: const GroupEventTime(18, 0),
    endTime: const GroupEventTime(19, 0),
  );

  test('wall-clock times are sent as UTC instants for the timezone', () {
    expect(
      GroupEventRequestBuilder.toBackendIso(
        DateTime(2026, 10, 7),
        const GroupEventTime(18, 0),
        'Asia/Kolkata',
      ),
      '2026-10-07T12:30:00.000Z',
    );
    expect(
      GroupEventRequestBuilder.toBackendIso(
        DateTime(2026, 7, 1),
        const GroupEventTime(9, 0),
        'America/New_York',
      ),
      '2026-07-01T13:00:00.000Z',
    );
  });

  test('one-time event: uppercase codes, nameless languages dropped', () {
    final request = GroupEventRequestBuilder.build(
      GroupEventDraft(
        metadata: metadata,
        schedule: schedule,
        format: GroupEventFormat.offline,
        venue: const GroupEventVenueDraft(
          name: 'Hall',
          latitude: 1,
          longitude: 2,
        ),
      ),
      groupId: 'g1',
      imageUrl: 'uploads/cover.jpg',
      locationId: 'loc1',
    );
    final json = request.toJson();

    expect(json['group_id'], 'g1');
    expect(json['start_date'], '2026-10-07T12:30:00.000Z');
    expect(json['end_date'], '2026-10-07T13:30:00.000Z');
    expect(json['timezone'], 'Asia/Kolkata');
    expect(json['metadata'], [
      {'language': 'EN', 'name': 'Wednesday practice'},
      {'language': 'ZH', 'name': '周三共修', 'description': '说明'},
    ]);
    expect(json['image_url'], 'uploads/cover.jpg');
    expect(json['location_id'], 'loc1');
    expect(json['event_format'], 'offline');
    expect(json['chat_enabled'], isTrue);
    expect(json['notifications_enabled'], isTrue);
    expect(json.containsKey('links'), isFalse);
    expect(json.containsKey('youtube'), isFalse);
    expect(json.containsKey('recurrence'), isFalse);
    expect(json.containsKey('intention_ids'), isFalse);
  });

  test('all day uses the studio fallback times and multi-day end date', () {
    final request = GroupEventRequestBuilder.build(
      GroupEventDraft(
        metadata: metadata,
        schedule: schedule.copyWith(
          allDay: true,
          isMultiDay: true,
          endDate: DateTime(2026, 10, 9),
        ),
      ),
      groupId: 'g1',
    );
    expect(request.startDate, '2026-10-07T00:30:00.000Z');
    expect(request.endDate, '2026-10-09T18:29:00.000Z');
  });

  test('recurring event anchors only the time of day and sends the rule', () {
    final request = GroupEventRequestBuilder.build(
      GroupEventDraft(
        metadata: metadata,
        schedule: schedule.copyWith(
          isRecurring: true,
          recurrence: const GroupEventRecurrenceDraft(
            frequency: GroupEventRecurrenceFrequency.monthly,
            dateSystem: GroupEventDateSystem.tibetanLunar,
            calendarType: 'phugpa',
            day: 15,
            durationDays: 2,
          ),
        ),
      ),
      groupId: 'g1',
      now: DateTime(2026, 10, 20),
    );
    final json = request.toJson();
    expect(json['start_date'], '2026-10-20T12:30:00.000Z');
    expect(json['recurrence'], {
      'frequency': 'MONTHLY',
      'date_system': 'TIBETAN_LUNAR',
      'calendar_type': 'phugpa',
      'month': null,
      'day': 15,
      'day_of_week': null,
      'duration_days': 2,
    });
  });

  test('live link and videos split into youtube and typed links', () {
    final request = GroupEventRequestBuilder.build(
      GroupEventDraft(
        metadata: metadata,
        schedule: schedule,
        format: GroupEventFormat.online,
        liveLink: 'meet.google.com/abc-def',
        videos: const [
          GroupEventVideoDraft(
            url: 'https://youtu.be/8sN0mLpQdT4',
            title: 'Guided sitting',
          ),
        ],
        intentionIds: const ['i1'],
        chatEnabled: false,
      ),
      groupId: 'g1',
    );
    final json = request.toJson();
    expect(json['links'], [
      {
        'type': 'google-meet',
        'url': 'https://meet.google.com/abc-def',
        'language': 'EN',
        'display_order': 1,
      },
      {
        'type': 'video',
        'url': 'https://youtu.be/8sN0mLpQdT4',
        'label': 'Guided sitting',
        'language': 'EN',
        'display_order': 2,
      },
    ]);
    expect(json.containsKey('youtube'), isFalse);
    expect(json['intention_ids'], ['i1']);
    expect(json['chat_enabled'], isFalse);

    final youtube =
        GroupEventRequestBuilder.build(
          GroupEventDraft(
            metadata: metadata,
            schedule: schedule,
            format: GroupEventFormat.hybrid,
            liveLink: 'https://www.youtube.com/@lodhenwarlord/live',
          ),
          groupId: 'g1',
        ).toJson();
    expect(youtube['youtube'], [
      {
        'url': 'https://www.youtube.com/@lodhenwarlord/live',
        'language': 'EN',
        'display_order': 1,
      },
    ]);
    expect(youtube.containsKey('links'), isFalse);
  });

  test('practices fill the plan, collection and accumulation slots', () {
    final request = GroupEventRequestBuilder.build(
      GroupEventDraft(
        metadata: metadata,
        schedule: schedule,
        practices: const [
          GroupEventPracticePick(
            id: 's1',
            kind: GroupEventPracticeKind.series,
            title: 'Series',
          ),
          GroupEventPracticePick(
            id: 'c1',
            kind: GroupEventPracticeKind.collection,
            title: 'Chants',
          ),
          GroupEventPracticePick(
            id: 'a1',
            kind: GroupEventPracticeKind.accumulator,
            title: 'Mantra',
            countMode: GroupEventCountMode.attendees,
          ),
          GroupEventPracticePick(
            id: 'a2',
            kind: GroupEventPracticeKind.accumulator,
            title: 'Praises',
          ),
        ],
      ),
      groupId: 'g1',
    );
    final json = request.toJson();
    expect(json['series_id'], 's1');
    expect(json.containsKey('plan_id'), isFalse);
    expect(json['group_recitation_collection_id'], 'c1');
    expect(json['accumulations'], [
      {
        'group_accumulator_id': 'a1',
        'event_format': 'online',
        'display_order': 1,
        'count_mode': 'offline_participants',
      },
      {
        'group_accumulator_id': 'a2',
        'event_format': 'offline',
        'display_order': 2,
        'count_mode': 'manual_in_person',
      },
    ]);
  });

  test('a draft without a date sends no dates or recurrence', () {
    final json =
        GroupEventRequestBuilder.build(
          const GroupEventDraft(metadata: metadata),
          groupId: 'g1',
        ).toJson();
    expect(json.containsKey('start_date'), isFalse);
    expect(json.containsKey('end_date'), isFalse);
    expect(json.containsKey('recurrence'), isFalse);
    expect(json['status'], 'draft');
    expect(json['timezone'], 'Asia/Kolkata');
  });

  test('link types follow the host', () {
    expect(GroupEventRequestBuilder.linkTypeFor('https://zoom.us/j/1'), 'zoom');
    expect(
      GroupEventRequestBuilder.linkTypeFor('https://us02web.zoom.us/j/1'),
      'zoom',
    );
    expect(
      GroupEventRequestBuilder.linkTypeFor('https://meet.google.com/x'),
      'google-meet',
    );
    expect(GroupEventRequestBuilder.linkTypeFor('https://example.org'), 'web');
  });
}
