import 'package:flutter_pecha/features/calendar/data/kharag_tibetan_calendar_service.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_schedule_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calendar = KharagTibetanCalendarService();
  final monday = DateTime(2026, 10, 26);

  group('rulesForDate', () {
    test('derives weekly, monthly, lunar and yearly rules from the date', () {
      final rules = GroupEventScheduleUtils.rulesForDate(monday, calendar);
      final lunar = calendar.fromWestern(monday);

      expect(rules, hasLength(5));
      expect(rules[0].frequency, GroupEventRecurrenceFrequency.weekly);
      expect(rules[0].dayOfWeek, 0);
      expect(rules[1].frequency, GroupEventRecurrenceFrequency.monthly);
      expect(rules[1].day, 26);
      expect(rules[2].isLunar, isTrue);
      expect(rules[2].day, lunar.day);
      expect(rules[2].calendarType, 'phugpa');
      expect(rules[3].month, 10);
      expect(rules[3].day, 26);
      expect(rules[4].isLunar, isTrue);
      expect(rules[4].month, lunar.month);
      expect(rules[4].day, lunar.day);
    });
  });

  group('nextOccurrences', () {
    test('lunar dates are whole calendar days, without repeats', () {
      final rules = GroupEventScheduleUtils.rulesForDate(monday, calendar);
      final next = GroupEventScheduleUtils.nextOccurrences(
        rules[2],
        monday,
        calendar,
        count: 6,
      );
      expect(next, hasLength(6));
      expect(next.toSet(), hasLength(6));
      for (final date in next) {
        expect(date, DateTime(date.year, date.month, date.day));
        expect(calendar.fromWestern(date).day, rules[2].day);
      }
    });

    test('weekly steps seven days', () {
      final rules = GroupEventScheduleUtils.rulesForDate(monday, calendar);
      final next = GroupEventScheduleUtils.nextOccurrences(
        rules[0],
        monday,
        calendar,
      );
      expect(next, [
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 16),
      ]);
    });

    test('monthly skips months without the day', () {
      const rule = GroupEventRecurrenceDraft(
        frequency: GroupEventRecurrenceFrequency.monthly,
        dateSystem: GroupEventDateSystem.gregorian,
        day: 31,
      );
      final next = GroupEventScheduleUtils.nextOccurrences(
        rule,
        DateTime(2026, 10, 31),
        calendar,
      );
      expect(next, [
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 31),
        DateTime(2027, 3, 31),
      ]);
    });

    test('lunar monthly lands on the same lunar day each time', () {
      final rules = GroupEventScheduleUtils.rulesForDate(monday, calendar);
      final rule = rules[2];
      final next = GroupEventScheduleUtils.nextOccurrences(
        rule,
        monday,
        calendar,
      );
      expect(next, hasLength(3));
      for (final date in next) {
        expect(date.isAfter(monday), isTrue);
        expect(calendar.fromWestern(date).day, rule.day);
      }
    });
  });

  group('validateSchedule', () {
    test('needs a date, then a rule when recurring', () {
      expect(
        GroupEventScheduleUtils.validateSchedule(
          const GroupEventScheduleDraft(),
        ),
        GroupEventScheduleIssue.missingDate,
      );
      expect(
        GroupEventScheduleUtils.validateSchedule(
          GroupEventScheduleDraft(isRecurring: true, startDate: monday),
        ),
        GroupEventScheduleIssue.missingRecurrence,
      );
    });

    test('same-day end time must follow the start time', () {
      final schedule = GroupEventScheduleDraft(
        startDate: monday,
        startTime: const GroupEventTime(19, 0),
        endTime: const GroupEventTime(18, 0),
      );
      expect(
        GroupEventScheduleUtils.validateSchedule(schedule),
        GroupEventScheduleIssue.endTimeBeforeStart,
      );
      expect(
        GroupEventScheduleUtils.validateSchedule(
          schedule.copyWith(allDay: true),
        ),
        isNull,
      );
      expect(
        GroupEventScheduleUtils.validateSchedule(
          schedule.copyWith(
            isMultiDay: true,
            endDate: monday.add(const Duration(days: 1)),
          ),
        ),
        isNull,
      );
    });

    test('multi-day needs an end date on or after the start', () {
      final schedule = GroupEventScheduleDraft(
        startDate: monday,
        isMultiDay: true,
        endDate: monday.subtract(const Duration(days: 1)),
      );
      expect(
        GroupEventScheduleUtils.validateSchedule(schedule),
        GroupEventScheduleIssue.endDateBeforeStart,
      );
    });
  });

  group('validateWhere', () {
    test('in person needs a venue, live needs a valid link', () {
      const venue = GroupEventVenueDraft(
        name: 'Hall',
        latitude: 1,
        longitude: 2,
      );
      expect(
        GroupEventScheduleUtils.validateWhere(const GroupEventDraft()),
        GroupEventWhereIssue.missingVenue,
      );
      expect(
        GroupEventScheduleUtils.validateWhere(
          const GroupEventDraft(format: GroupEventFormat.online),
        ),
        GroupEventWhereIssue.missingLink,
      );
      expect(
        GroupEventScheduleUtils.validateWhere(
          const GroupEventDraft(
            format: GroupEventFormat.online,
            liveLink: 'meet google abc',
          ),
        ),
        GroupEventWhereIssue.invalidLink,
      );
      expect(
        GroupEventScheduleUtils.validateWhere(
          const GroupEventDraft(
            format: GroupEventFormat.hybrid,
            venue: venue,
            liveLink: 'meet.google.com/abc-def',
          ),
        ),
        isNull,
      );
    });
  });

  group('channelLiveUrl', () {
    test('turns the group youtube channel into a live url', () {
      const links = [
        GroupProfileSocialLink(
          id: '1',
          platform: 'instagram',
          url: 'https://instagram.com/x',
        ),
        GroupProfileSocialLink(
          id: '2',
          platform: 'YouTube',
          url: 'youtube.com/@lodhenwarlord',
        ),
      ];
      expect(
        GroupEventScheduleUtils.channelLiveUrl(links),
        'https://www.youtube.com/@lodhenwarlord/live',
      );
      expect(
        GroupEventScheduleUtils.channelLiveUrl(const [
          GroupProfileSocialLink(
            id: '3',
            platform: 'youtube',
            url: 'https://www.youtube.com/channel/UC123',
          ),
        ]),
        'https://www.youtube.com/channel/UC123/live',
      );
      expect(
        GroupEventScheduleUtils.channelLiveUrl(const [
          GroupProfileSocialLink(
            id: '4',
            platform: 'youtube',
            url: 'https://youtube.com/watch?v=abc',
          ),
        ]),
        isNull,
      );
    });

    test('recognises youtube links', () {
      expect(
        GroupEventScheduleUtils.isYoutubeLink('https://youtu.be/abc'),
        isTrue,
      );
      expect(
        GroupEventScheduleUtils.isYoutubeLink('https://meet.google.com/x'),
        isFalse,
      );
    });
  });
}
