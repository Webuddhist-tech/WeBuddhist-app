import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/calendar/data/datasource/personal_calendar_remote_datasource.dart';
import 'package:flutter_pecha/features/calendar/data/models/personal_calendar_models.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
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
  test('a personal feed row can be tapped and has no source of its own', () {
    final event =
        calendarFeedPageFromJson({
          'items': [
            {
              'kind': 'PERSONAL',
              'id': 'p1',
              'date': '2026-02-03',
              'title': 'Birthday',
              'all_day': true,
            },
          ],
        }).events.single;
    expect(event.kind, CalendarEventKind.personal);
    expect(event.date, DateTime(2026, 2, 3));
    expect(event.allDay, isTrue);
    expect(event.sourceName, isNull);
    expect(event.isTappable, isTrue);
  });

  group('requests', () {
    const eventJson = {'id': 'e1', 'title': 'Puja', 'start_date': '2026-02-20'};

    (PersonalCalendarRemoteDatasource, _Recorder) build(Object? reply) {
      final recorder = _Recorder(reply);
      final dio = Dio()..interceptors.add(recorder);
      return (PersonalCalendarRemoteDatasource(dio: dio), recorder);
    }

    test('an edit sends only the title', () async {
      final (remote, recorder) = build(eventJson);
      final event = await remote.updateEvent('e1', title: 'Puja');
      final request = recorder.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/users/me/calendar-events/e1');
      expect(request.data, {'title': 'Puja'});
      expect(event.startDate, DateTime(2026, 2, 20));
    });

    test('reading and deleting use the event path', () async {
      final (remote, recorder) = build(eventJson);
      final event = await remote.fetchEvent('e1');
      await remote.deleteEvent('e1');
      expect(event.title, 'Puja');
      expect(recorder.requests.map((r) => (r.method, r.path)), [
        ('GET', '/users/me/calendar-events/e1'),
        ('DELETE', '/users/me/calendar-events/e1'),
      ]);
    });
  });
}
