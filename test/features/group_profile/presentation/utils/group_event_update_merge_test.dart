import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_draft_mapper.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_request_builder.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_update_merge.dart';
import 'package:flutter_test/flutter_test.dart';

/// An event made in the studio, with more link data than the draft models.
final _json = <String, dynamic>{
  'id': 'ev-1',
  'group_id': 'g1',
  'status': 'published',
  'timezone': 'Asia/Kolkata',
  'start_date': '2026-10-07T12:30:00Z',
  'end_date': '2026-10-07T13:30:00Z',
  'is_recurring': false,
  'event_format': 'hybrid',
  'metadata': [
    {'language': 'EN', 'name': 'Practice'},
  ],
  'youtube': [
    {
      'url': 'https://www.youtube.com/@x/live',
      'label': 'Main stream',
      'language': 'BO',
      'display_order': 1,
    },
    {
      'url': 'https://www.youtube.com/@x/live-zh',
      'language': 'ZH',
      'display_order': 2,
    },
  ],
  'links': [
    {
      'type': 'zoom',
      'url': 'https://zoom.us/j/1',
      'label': 'Zoom',
      'language': 'EN',
      'display_order': 1,
    },
    {
      'type': 'video',
      'url': 'https://youtu.be/a',
      'label': 'Teaching',
      'language': 'BO',
      'display_order': 2,
    },
  ],
  'accumulations': [
    {
      'group_accumulator_id': 'a1',
      'event_format': 'offline',
      'count_mode': 'offline_participants',
      'display_order': 1,
    },
  ],
};

void main() {
  final now = DateTime.utc(2026, 10, 1);
  final source = GroupEventDraftMapper.fromJson(_json);

  Map<String, dynamic> updateBody(GroupEventDraft edited) {
    final original = GroupEventRequestBuilder.build(
      source.draft,
      groupId: 'g1',
      status: 'published',
      now: now,
    );
    final next = GroupEventRequestBuilder.build(
      edited,
      groupId: 'g1',
      status: 'published',
      now: now,
    );
    return GroupEventUpdateMerge.apply(
      next,
      original: original,
      source: source,
    ).toUpdateJson(original);
  }

  test('an untouched event sends no links or accumulations', () {
    final body = updateBody(source.draft);
    expect(body.containsKey('links'), isFalse);
    expect(body.containsKey('youtube'), isFalse);
    expect(body.containsKey('accumulations'), isFalse);
  });

  test('adding a video keeps every saved link and its details', () {
    final body = updateBody(
      source.draft.copyWith(
        videos: [
          ...source.draft.videos,
          const GroupEventVideoDraft(url: 'https://youtu.be/b', title: 'New'),
        ],
      ),
    );
    expect(body.containsKey('youtube'), isFalse);
    expect(body['links'], [
      {
        'type': 'zoom',
        'url': 'https://zoom.us/j/1',
        'label': 'Zoom',
        'language': 'EN',
        'display_order': 1,
      },
      {
        'type': 'video',
        'url': 'https://youtu.be/a',
        'label': 'Teaching',
        'language': 'BO',
        'display_order': 2,
      },
      {
        'type': 'video',
        'url': 'https://youtu.be/b',
        'label': 'New',
        'language': 'EN',
        'display_order': 3,
      },
    ]);
  });

  test('removing a video removes only that link', () {
    final body = updateBody(source.draft.copyWith(videos: const []));
    expect(body['links'], [
      {
        'type': 'zoom',
        'url': 'https://zoom.us/j/1',
        'label': 'Zoom',
        'language': 'EN',
        'display_order': 1,
      },
    ]);
  });

  test('changing the live link replaces only the first stream', () {
    final body = updateBody(
      source.draft.copyWith(liveLink: 'https://www.youtube.com/@y/live'),
    );
    expect(body.containsKey('links'), isFalse);
    expect(body['youtube'], [
      {
        'url': 'https://www.youtube.com/@y/live',
        'language': 'BO',
        'display_order': 1,
      },
      {
        'url': 'https://www.youtube.com/@x/live-zh',
        'language': 'ZH',
        'display_order': 2,
      },
    ]);
  });

  test('an untouched accumulation keeps its saved format and mode', () {
    final body = updateBody(
      source.draft.copyWith(
        practices: [
          ...source.draft.practices,
          const GroupEventPracticePick(
            id: 'a2',
            kind: GroupEventPracticeKind.accumulator,
            title: 'Tara',
          ),
        ],
      ),
    );
    expect(body['accumulations'], [
      {
        'group_accumulator_id': 'a1',
        'event_format': 'offline',
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

  test('a changed count mode takes the draft values', () {
    final body = updateBody(
      source.draft.copyWith(
        practices: [
          source.draft.practices.single.copyWith(
            countMode: GroupEventCountMode.admin,
          ),
        ],
      ),
    );
    expect(body['accumulations'], [
      {
        'group_accumulator_id': 'a1',
        'event_format': 'offline',
        'display_order': 1,
        'count_mode': 'manual_in_person',
      },
    ]);
  });
}
