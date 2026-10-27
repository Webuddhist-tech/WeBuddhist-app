import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/calendar/data/models/calendar_day_model.dart';
import 'package:flutter_pecha/features/calendar/data/models/calendar_month_model.dart';
import 'package:flutter_pecha/features/calendar/domain/entities/tibetan_calendar_day.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('JSON parsing', () {
    test('formatDesignation hyphenated → title-cased words', () {
      expect(formatDesignation('Fire-male-Horse'), 'Fire Male Horse');
      expect(formatDesignation('Iron-male-Dragon'), 'Iron Male Dragon');
      expect(formatDesignation(null), '');
      expect(formatDesignation(''), '');
    });

    test('CalendarMonthModel parses days incl. the omitted day', () {
      final json = {
        'year': 2026,
        'month': 1,
        'designation': 'Iron-male-Dragon',
        'days': [
          {
            'gregorian_date': '2026-02-18',
            'lunar_day': 1,
            'lunar_month': {'month': 1, 'designation': 'Iron-male-Dragon'},
            'new_year': {'year': '2026', 'designation': 'Fire-male-Horse'},
          },
          {
            'gregorian_date': null,
            'lunar_day': 7,
            'lunar_month': {'month': 1, 'designation': 'Iron-male-Dragon'},
            'new_year': {'year': '2026', 'designation': 'Fire-male-Horse'},
            'day_summary': '7. Omitted: Monkey dwa 4',
          },
        ],
      };

      final entities = CalendarMonthModel.fromJson(json).toEntities();
      expect(entities, hasLength(2));

      final first = entities[0];
      expect(first.gregorianDate, DateTime(2026, 2, 18));
      expect(first.lunarDay, 1);
      expect(first.lunarMonth, 1);
      expect(first.yearDesignation, 'Fire Male Horse');
      expect(first.monthDesignation, 'Iron Male Dragon');
      expect(first.isOmitted, isFalse);

      final omitted = entities[1];
      expect(omitted.gregorianDate, isNull);
      expect(omitted.isOmitted, isTrue);
      expect(omitted.lunarDay, 7);
    });

    test('CalendarDayModel handles missing optional fields', () {
      final entity = CalendarDayModel.fromJson({
        'gregorian_date': '2026-06-15',
        'lunar_day': 30,
        'lunar_month': {'month': 4},
        'new_year': {'year': '2026'},
      }).toEntity();
      expect(entity.lunarDay, 30);
      expect(entity.lunarMonth, 4);
      expect(entity.yearDesignation, '');
    });
  });

  group('hybrid resolution (backend-primary, engine fallback)', () {
    final month = DateTime(2026, 2, 1);
    final losar = DateTime(2026, 2, 18); // lunar 1/1, covered by fake backend

    test('backend value overlays the engine for covered dates', () async {
      final container = ProviderContainer(
        overrides: [
          calendarRepositoryProvider.overrideWithValue(
            _RealisticFakeRepo(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(resolvedMonthDaysProvider(month), (_, __) {});
      await pumpEventQueue();
      final days = container.read(resolvedMonthDaysProvider(month));

      // The backend's sentinel designation wins over the engine's.
      expect(days[dateOnly(losar)]?.yearDesignation, 'BACKEND');
      // A date the backend did not return falls back to the engine.
      final uncovered = days[dateOnly(DateTime(2026, 2, 19))];
      expect(uncovered, isNotNull);
      expect(uncovered!.yearDesignation, isNot('BACKEND'));
    });

    test('offline (repo fails) falls back entirely to the engine', () async {
      final container = ProviderContainer(
        overrides: [
          calendarRepositoryProvider.overrideWithValue(_OfflineRepo()),
        ],
      );
      addTearDown(container.dispose);

      container.listen(resolvedMonthDaysProvider(month), (_, __) {});
      await pumpEventQueue();
      final days = container.read(resolvedMonthDaysProvider(month));

      final day = days[dateOnly(losar)];
      expect(day, isNotNull);
      expect(day!.yearDesignation, isNot('BACKEND'));
      // Engine still gives the correct lunar date for Losar.
      expect(day.lunarDay, 1);
      expect(day.lunarMonth, 1);
    });
  });
}

/// Backend that returns one real day (Losar, 2026-02-18) with a sentinel
/// designation for the Gregorian month February 2026; Left otherwise.
class _RealisticFakeRepo implements CalendarRepository {
  @override
  Future<Either<Failure, List<TibetanCalendarDay>>> getMonth(
    int year,
    int month,
  ) async {
    if (year == 2026 && month == 2) {
      return Right([
        TibetanCalendarDay(
          gregorianDate: DateTime(2026, 2, 18),
          lunarDay: 1,
          lunarMonth: 1,
          yearDesignation: 'BACKEND',
        ),
      ]);
    }
    return const Left(NetworkFailure('no data'));
  }

  @override
  Future<Either<Failure, TibetanCalendarDay>> getToday() async =>
      const Left(NetworkFailure('no data'));

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

class _OfflineRepo implements CalendarRepository {
  @override
  Future<Either<Failure, List<TibetanCalendarDay>>> getMonth(
    int year,
    int month,
  ) async => const Left(NetworkFailure('offline'));

  @override
  Future<Either<Failure, TibetanCalendarDay>> getToday() async =>
      const Left(NetworkFailure('offline'));

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
