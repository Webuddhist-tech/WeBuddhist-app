import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/calendar/data/datasource/personal_calendar_remote_datasource.dart';
import 'package:flutter_pecha/features/calendar/data/models/personal_calendar_models.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records each request and answers with [reply].
class _Recorder extends Interceptor {
  _Recorder(this.reply);

  final Object? reply;
  final requests = <RequestOptions>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    handler.resolve(
      Response(requestOptions: options, statusCode: 200, data: reply),
    );
  }
}

void main() {
  group('feed rows', () {
    final page = calendarFeedPageFromJson({
      'has_more': true,
      'items': [
        {
          'kind': 'LUNAR_DAY',
          'date': '2026-02-03',
          'all_day': true,
          'lunar_label': 'FULL_MOON',
        },
        {
          'kind': 'PERSONAL',
          'id': 'p1',
          'date': '2026-02-03',
          'title': 'Birthday',
          'all_day': true,
          'repeat': 'MONTHLY_LUNAR',
          'repeat_day': 15,
          'lunar_day': 15,
        },
        {
          'kind': 'GROUP_EVENT',
          'id': 'g1',
          'date': '2026-02-04',
          'title': 'Puja',
          'all_day': false,
          'starts_at': '2026-02-04T07:00:00Z',
          'start_date': '2026-02-01T07:00:00Z',
          'end_date': '2026-04-30T08:00:00Z',
          'source': {'id': 's', 'name': 'Tara club', 'avatar_url': 'a.png'},
        },
      ],
    });

    test('leave lunar days to the app but count them for paging', () {
      expect(page.events.map((e) => e.eventId), ['p1', 'g1']);
      expect(page.rowCount, 3);
      expect(page.hasMore, isTrue);
    });

    test('carry a personal event\'s repeat', () {
      final event = page.events.first;
      expect(event.kind, CalendarEventKind.personal);
      expect(event.date, DateTime(2026, 2, 3));
      expect(event.repeat, PersonalRepeat.monthlyLunar);
      expect(event.repeatDay, 15);
      expect(event.isTappable, isTrue);
    });

    test('carry a space event\'s source and times', () {
      final event = page.events.last;
      expect(event.kind, CalendarEventKind.group);
      expect(event.sourceName, 'Tara club');
      expect(event.sourceAvatarUrl, 'a.png');
      expect(event.allDay, isFalse);
      expect(event.startsAt, DateTime.utc(2026, 2, 4, 7).toLocal());
      expect(event.endDate, DateTime.utc(2026, 4, 30, 8).toLocal());
    });

    test('with an unknown repeat still parse', () {
      final parsed = calendarFeedPageFromJson({
        'items': [
          {
            'kind': 'GROUP_EVENT',
            'id': 'g',
            'date': '2026-02-04',
            'all_day': true,
            'repeat': 'SOMETHING_NEW',
          },
        ],
      });
      expect(parsed.events.single.repeat, isNull);
      expect(parsed.hasMore, isFalse);
    });
  });

  test('repeat options keep known rows and their next dates', () {
    final options = repeatOptionsFromJson({
      'options': [
        {
          'repeat': 'WEEKLY',
          'day_of_week': 4,
          'next_dates': ['2026-02-27', '2026-03-06'],
        },
        {'repeat': 'SOMETHING_NEW', 'next_dates': <String>[]},
      ],
    });
    expect(options.single.repeat, PersonalRepeat.weekly);
    expect(options.single.dayOfWeek, 4);
    expect(options.single.nextDates, [
      DateTime(2026, 2, 27),
      DateTime(2026, 3, 6),
    ]);
  });

  group('requests', () {
    const eventJson = {
      'id': 'e1',
      'title': 'Puja',
      'start_date': '2026-02-20',
      'repeat': 'WEEKLY',
    };

    (PersonalCalendarRemoteDatasource, _Recorder) build(Object? reply) {
      final recorder = _Recorder(reply);
      final dio = Dio()..interceptors.add(recorder);
      return (PersonalCalendarRemoteDatasource(dio: dio), recorder);
    }

    test('the feed asks for its dates as plain days', () async {
      final (remote, recorder) = build({'items': <Object>[]});
      await remote.fetchFeed(
        from: DateTime(2026, 2, 1),
        to: DateTime(2026, 2, 28),
        language: 'bo',
        skip: 100,
        limit: 100,
      );
      final request = recorder.requests.single;
      expect(request.path, '/users/me/calendar');
      expect(request.queryParameters, {
        'from_date': '2026-02-01',
        'to_date': '2026-02-28',
        'language': 'bo',
        'skip': 100,
        'limit': 100,
      });
    });

    test('an edit sends only the title and repeat', () async {
      final (remote, recorder) = build(eventJson);
      final event = await remote.updateEvent(
        'e1',
        title: 'Puja',
        repeat: PersonalRepeat.yearlyLunar,
      );
      final request = recorder.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/users/me/calendar-events/e1');
      expect(request.data, {'title': 'Puja', 'repeat': 'YEARLY_LUNAR'});
      expect(event.startDate, DateTime(2026, 2, 20));
    });

    test('reading and deleting use the event path', () async {
      final (remote, recorder) = build(eventJson);
      final event = await remote.fetchEvent('e1');
      await remote.deleteEvent('e1');
      expect(event.repeat, PersonalRepeat.weekly);
      expect(event.isRepeating, isTrue);
      expect(recorder.requests.map((r) => (r.method, r.path)), [
        ('GET', '/users/me/calendar-events/e1'),
        ('DELETE', '/users/me/calendar-events/e1'),
      ]);
    });
  });

  test('upcoming shows a space event once and personal dates each time', () {
    CalendarEvent at(int day, CalendarEventKind kind) => CalendarEvent(
      date: DateTime(2026, 2, day),
      title: 'E',
      kind: kind,
      eventId: kind.name,
    );
    final upcoming = upcomingEventsFrom([
      at(1, CalendarEventKind.group),
      at(5, CalendarEventKind.group),
      at(6, CalendarEventKind.group),
      at(5, CalendarEventKind.personal),
      at(6, CalendarEventKind.personal),
    ], DateTime(2026, 2, 5));
    expect(upcoming.map((e) => (e.date.day, e.kind)), [
      (5, CalendarEventKind.group),
      (5, CalendarEventKind.personal),
      (6, CalendarEventKind.personal),
    ]);
  });
}
