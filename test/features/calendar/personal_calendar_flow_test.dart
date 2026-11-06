import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/calendar/domain/entities/tibetan_calendar_day.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/personal_calendar_repository.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/calendar_event_sources_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/calendar_events_section.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/personal_event_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineCalendar implements CalendarRepository {
  @override
  Future<Either<Failure, List<TibetanCalendarDay>>> getMonth(
    int y,
    int m,
  ) async => const Left(NetworkFailure('offline'));
  @override
  Future<Either<Failure, TibetanCalendarDay>> getToday() async =>
      const Left(NetworkFailure('offline'));
  @override
  Stream<Either<Failure, List<TibetanCalendarDay>>> watchMonth(int y, int m) =>
      Stream.fromFuture(getMonth(y, m));
  @override
  Future<Either<Failure, List<TibetanCalendarDay>>> refreshMonth(
    int y,
    int m,
  ) => getMonth(y, m);
  @override
  Stream<Either<Failure, TibetanCalendarDay>> watchToday() =>
      Stream.fromFuture(getToday());
  @override
  ScreenCacheSource<List<TibetanCalendarDay>>? monthSource(int y, int m) =>
      null;
  @override
  ScreenCacheSource<TibetanCalendarDay>? todaySource() => null;
}

/// Stands in for the server: a personal event falls on its start date.
class _FakeServer implements PersonalCalendarRepository {
  _FakeServer({
    List<PersonalCalendarEvent> events = const [],
    this.groupRows = const [],
  }) : events = [...events];

  List<PersonalCalendarEvent> events;
  final List<CalendarEvent> groupRows;
  bool failWrites = false;
  int feedReads = 0;

  static const _failure = Left<Failure, Never>(NetworkFailure('offline'));

  @override
  Future<Either<Failure, CalendarFeedPage>> getFeed({
    required DateTime from,
    required DateTime to,
    required String language,
    int skip = 0,
    int limit = 100,
  }) async {
    feedReads++;
    final rows = <CalendarEvent>[
      ...groupRows,
      for (final event in events)
        CalendarEvent(
          date: event.startDate,
          title: event.title,
          kind: CalendarEventKind.personal,
          eventId: event.id,
        ),
    ];
    return Right(
      CalendarFeedPage(events: rows, rowCount: rows.length, hasMore: false),
    );
  }

  @override
  Future<Either<Failure, PersonalCalendarEvent>> getEvent(String id) async =>
      Right(events.firstWhere((event) => event.id == id));

  @override
  Future<Either<Failure, PersonalCalendarEvent>> createEvent({
    required String title,
    required DateTime startDate,
  }) async {
    if (failWrites) return _failure;
    final event = PersonalCalendarEvent(
      id: 'new',
      title: title,
      startDate: startDate,
    );
    events.add(event);
    return Right(event);
  }

  @override
  Future<Either<Failure, PersonalCalendarEvent>> updateEvent(
    String id, {
    required String title,
  }) async {
    if (failWrites) return _failure;
    final old = events.firstWhere((event) => event.id == id);
    final event = PersonalCalendarEvent(
      id: id,
      title: title,
      startDate: old.startDate,
    );
    events = [
      for (final e in events)
        if (e.id == id) event else e,
    ];
    return Right(event);
  }

  @override
  Future<Either<Failure, void>> deleteEvent(String id) async {
    if (failWrites) return _failure;
    events = events.where((event) => event.id != id).toList();
    return const Right(null);
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // 20 Feb 2026 is lunar day 3, so the day holds only what a test adds.
  final day = DateTime(2026, 2, 20);
  final month = DateTime(2026, 2, 1);

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    _FakeServer? server,
    void Function(String path)? onPush,
  }) async {
    final container = ProviderContainer(
      overrides: [
        calendarRepositoryProvider.overrideWithValue(_OfflineCalendar()),
        calendarViewerProvider.overrideWithValue((
          id: 'me',
          name: 'Tenzin',
          avatarUrl: null,
        )),
        personalCalendarRepositoryProvider.overrideWithValue(
          server ?? _FakeServer(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(focusedCalendarMonthProvider.notifier).state = month;
    container.read(selectedCalendarDayProvider.notifier).state = day;
    container.read(hasPickedCalendarDayProvider.notifier).state = true;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) => const Scaffold(
                body: SingleChildScrollView(child: CalendarEventsSection()),
              ),
        ),
        GoRoute(
          path: '/home/events/:id',
          builder: (context, state) {
            onPush?.call(state.uri.path);
            return const Scaffold(body: Text('event page'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('an empty day says so, and Today goes back to upcoming', (
    tester,
  ) async {
    final container = await pump(tester);
    expect(find.text('Fri 20 Feb'), findsOneWidget);
    expect(find.text('No events'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(container.read(hasPickedCalendarDayProvider), isFalse);
    expect(find.text('No events'), findsNothing);
  });

  testWidgets('adding an event needs a name, saves it and re-reads the feed', (
    tester,
  ) async {
    final server = _FakeServer();
    final container = await pump(tester, server: server);
    final context = tester.element(find.byType(CalendarEventsSection));
    final readsBefore = server.feedReads;

    PersonalEventSheet.show(context, date: day);
    await tester.pumpAndSettle();

    final save = find.widgetWithText(ElevatedButton, 'Save');
    expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
    expect(find.text('Delete event'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Rinpoche birthday');
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Rinpoche birthday'), findsOneWidget);
    expect(find.text('Tenzin'), findsOneWidget);
    expect(find.text('All day'), findsOneWidget);
    expect(server.events.single.startDate, day);
    expect(server.feedReads, greaterThan(readsBefore));
    expect(
      container.read(monthEventsProvider(month)).map((e) => e.date),
      contains(day),
    );
  });

  testWidgets('a failed save keeps the sheet open with a message', (
    tester,
  ) async {
    final server = _FakeServer()..failWrites = true;
    await pump(tester, server: server);
    final context = tester.element(find.byType(CalendarEventsSection));

    PersonalEventSheet.show(context, date: day);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Puja');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonalEventSheet), findsOneWidget);
    expect(find.text('Something went wrong. Please try again'), findsOneWidget);
    expect(server.events, isEmpty);
  });

  testWidgets('deleting a one-off confirms, can cancel, and shows a toast', (
    tester,
  ) async {
    final server = _FakeServer(
      events: [
        PersonalCalendarEvent(id: 'a', title: 'Birthday', startDate: day),
      ],
    );
    await pump(tester, server: server);

    await tester.tap(find.text('Birthday'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete event'));
    await tester.pumpAndSettle();
    expect(find.text('Delete event?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete event?'), findsNothing);
    expect(server.events, isNotEmpty);

    await tester.tap(find.text('Delete event'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(server.events, isEmpty);
    expect(find.text('Event deleted'), findsOneWidget);
    expect(find.text('No events'), findsOneWidget);
  });

  testWidgets('a space card opens its event page', (tester) async {
    String? pushed;
    await pump(
      tester,
      onPush: (path) => pushed = path,
      server: _FakeServer(
        groupRows: [
          CalendarEvent(
            date: day,
            title: 'Morning puja',
            kind: CalendarEventKind.group,
            eventId: 'evt-1',
            sourceName: 'Tara club',
            allDay: false,
            startsAt: DateTime(2026, 2, 20, 7),
          ),
        ],
      ),
    );

    expect(find.text('Tara club'), findsOneWidget);
    expect(find.text('7 am'), findsOneWidget);
    await tester.tap(find.text('Morning puja'));
    await tester.pumpAndSettle();
    expect(pushed, '/home/events/evt-1');
  });

  testWidgets('a lunar card does not open anything', (tester) async {
    final container = await pump(tester);
    // Losar 2026 is lunar day 1: a new moon.
    container.read(selectedCalendarDayProvider.notifier).state = DateTime(
      2026,
      2,
      18,
    );
    await tester.pumpAndSettle();

    expect(find.text('Lunar calendar'), findsOneWidget);
    await tester.tap(find.text('Lunar calendar'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalEventSheet), findsNothing);
    expect(find.text('event page'), findsNothing);
  });
}
