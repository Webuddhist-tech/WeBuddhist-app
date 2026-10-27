import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/calendar/data/kharag_tibetan_calendar_service.dart';
import 'package:flutter_pecha/features/calendar/domain/entities/tibetan_calendar_day.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/screens/tibetan_calendar_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Fails every request so the screen falls back to the local engine — makes the
/// widget assertions deterministic and network-free (also exercises the
/// silent-offline path).
class _OfflineCalendarRepository implements CalendarRepository {
  @override
  Future<Either<Failure, List<TibetanCalendarDay>>> getMonth(
    int year,
    int month,
  ) async => const Left(NetworkFailure('offline test'));

  @override
  Future<Either<Failure, TibetanCalendarDay>> getToday() async =>
      const Left(NetworkFailure('offline test'));

  @override
  Stream<Either<Failure, List<TibetanCalendarDay>>> watchMonth(
    int year,
    int month,
  ) => Stream.fromFuture(getMonth(year, month));

  @override
  Future<Either<Failure, List<TibetanCalendarDay>>> refreshMonth(
    int year,
    int month,
  ) => getMonth(year, month);

  @override
  Stream<Either<Failure, TibetanCalendarDay>> watchToday() =>
      Stream.fromFuture(getToday());
}

void main() {
  const service = KharagTibetanCalendarService();

  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        calendarRepositoryProvider.overrideWithValue(
          _OfflineCalendarRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TibetanCalendarScreen(),
        ),
      ),
    );
    // Let the post-frame today-sync run and the overlay future resolve.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    return container;
  }

  testWidgets('opens on today: header + month reflect the current date', (
    tester,
  ) async {
    final today = DateTime.now();
    final tib = service.fromWestern(today);

    final container = await pumpScreen(tester);

    // The screen snapped selection/focus to today.
    expect(
      container.read(selectedCalendarDayProvider),
      DateTime(today.year, today.month, today.day),
    );

    expect(find.text('Day ${tib.day}'), findsOneWidget);
    expect(find.text(DateFormat.yMMMM('en').format(today)), findsWidgets);
  });

  testWidgets('current month exposes moon-phase events', (tester) async {
    final container = await pumpScreen(tester);
    final month = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final events = container.read(monthEventsProvider(month));
    expect(events, isNotEmpty); // every month has at least one phase day
  });

  testWidgets('tap-to-select still updates the header (no re-sync)', (
    tester,
  ) async {
    final container = await pumpScreen(tester);

    // 2025-02-28 is Losar → lunar day 1. Distinct from today's lunar day.
    final picked = DateTime(2025, 2, 28);
    final expected = service.fromWestern(picked);
    container.read(selectedCalendarDayProvider.notifier).state = picked;
    await tester.pump();

    expect(find.text('Day ${expected.day}'), findsOneWidget);
  });

  testWidgets('changing the focused month updates the grid header', (
    tester,
  ) async {
    final container = await pumpScreen(tester);

    container.read(focusedCalendarMonthProvider.notifier).state = DateTime(
      2025,
      3,
      1,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('March 2025'), findsOneWidget);
  });
}
