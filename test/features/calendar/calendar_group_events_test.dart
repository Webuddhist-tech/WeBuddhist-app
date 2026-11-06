import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/calendar/data/datasource/personal_calendar_remote_datasource.dart';
import 'package:flutter_pecha/features/calendar/data/models/personal_calendar_models.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/calendar_event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

class _Recorder extends Interceptor {
  final requests = <RequestOptions>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {'items': <Object>[]},
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('feed rows', () {
    final page = calendarFeedPageFromJson({
      'has_more': true,
      'items': [
        {'kind': 'LUNAR_DAY', 'date': '2026-02-03', 'all_day': true},
        {
          'kind': 'PERSONAL',
          'id': 'p1',
          'date': '2026-02-03',
          'title': 'Birthday',
          'all_day': true,
        },
        {
          'kind': 'GROUP_EVENT',
          'id': 'g1',
          'date': '2026-02-04',
          'title': 'Puja',
          'all_day': false,
          'starts_at': '2026-02-04T07:00:00Z',
          'end_date': '2026-04-30T08:00:00Z',
          'source': {'id': 's', 'name': 'Tara club', 'avatar_url': 'a.png'},
        },
      ],
    });

    test('leave lunar days to the app but count every row for paging', () {
      expect(page.events.map((e) => e.eventId), ['p1', 'g1']);
      expect(page.rowCount, 3);
      expect(page.hasMore, isTrue);
    });

    test('carry the space and the times', () {
      final event = page.events.last;
      expect(event.kind, CalendarEventKind.group);
      expect(event.date, DateTime(2026, 2, 4));
      expect(event.sourceName, 'Tara club');
      expect(event.sourceAvatarUrl, 'a.png');
      expect(event.allDay, isFalse);
      expect(event.startsAt, DateTime.utc(2026, 2, 4, 7).toLocal());
      expect(event.endDate, DateTime.utc(2026, 4, 30, 8).toLocal());
      expect(event.isTappable, isTrue);
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
          {
            'kind': 'GROUP_EVENT',
            'id': 'h',
            'date': '2026-02-04',
            'all_day': true,
            'repeat': 'WEEKLY',
          },
        ],
      });
      expect(parsed.events.first.repeat, isNull);
      expect(parsed.events.last.repeat, PersonalRepeat.weekly);
    });
  });

  test('the feed asks for its dates as plain days', () async {
    final recorder = _Recorder();
    final dio = Dio()..interceptors.add(recorder);
    await PersonalCalendarRemoteDatasource(dio: dio).fetchFeed(
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

  test('upcoming shows a space event once, on its next date', () {
    CalendarEvent at(int day) => CalendarEvent(
      date: DateTime(2026, 2, day),
      title: 'E',
      kind: CalendarEventKind.group,
      eventId: 'g',
    );
    final upcoming = upcomingEventsFrom([
      at(1),
      at(5),
      at(6),
    ], DateTime(2026, 2, 5));
    expect(upcoming.map((e) => e.date.day), [5]);
  });

  Future<void> pumpCard(
    WidgetTester tester,
    CalendarEvent event,
    void Function(String path) onPush,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) =>
                  Scaffold(body: CalendarEventCard(event: event)),
        ),
        GoRoute(
          path: '/home/events/:id',
          builder: (context, state) {
            onPush(state.uri.path);
            return const Scaffold(body: Text('event page'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a space card opens its event page', (tester) async {
    String? pushed;
    await pumpCard(
      tester,
      CalendarEvent(
        date: DateTime(2026, 2, 20),
        title: 'Morning puja',
        kind: CalendarEventKind.group,
        eventId: 'evt-1',
        sourceName: 'Tara club',
        allDay: false,
        startsAt: DateTime(2026, 2, 20, 7),
      ),
      (path) => pushed = path,
    );

    expect(find.text('Tara club'), findsOneWidget);
    expect(find.text('7 am'), findsOneWidget);
    await tester.tap(find.text('Morning puja'));
    await tester.pumpAndSettle();
    expect(pushed, '/home/events/evt-1');
  });

  testWidgets('a lunar card does not open anything', (tester) async {
    await pumpCard(
      tester,
      CalendarEvent(
        date: DateTime(2026, 2, 18),
        lunarDay: 1,
        title: '',
        kind: CalendarEventKind.lunarPhase,
      ),
      (_) => fail('a lunar card must not open a page'),
    );

    expect(find.text('Lunar calendar'), findsOneWidget);
    await tester.tap(find.text('Lunar calendar'));
    await tester.pumpAndSettle();
    expect(find.text('event page'), findsNothing);
  });
}
