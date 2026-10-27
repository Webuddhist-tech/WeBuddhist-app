import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/calendar/data/datasource/calendar_remote_datasource.dart';
import 'package:flutter_pecha/features/calendar/data/models/calendar_day_model.dart';
import 'package:flutter_pecha/features/calendar/data/models/calendar_month_model.dart';
import 'package:flutter_pecha/features/calendar/domain/entities/tibetan_calendar_day.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:fpdart/fpdart.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDatasource _datasource;
  final ScreenCacheStore _store;

  CalendarRepositoryImpl({
    required CalendarRemoteDatasource datasource,
    required ScreenCacheStore store,
  }) : _datasource = datasource,
       _store = store;

  @override
  Stream<Either<Failure, List<TibetanCalendarDay>>> watchMonth(
    int year,
    int month,
  ) => _monthSource(year, month).watch();

  @override
  Future<Either<Failure, List<TibetanCalendarDay>>> refreshMonth(
    int year,
    int month,
  ) => _monthSource(year, month).refresh();

  @override
  Stream<Either<Failure, TibetanCalendarDay>> watchToday() {
    final now = DateTime.now();
    final date = '${now.year}-${now.month}-${now.day}';
    return ScreenCacheSource<TibetanCalendarDay>(
      store: _store,
      key: ScreenCacheKey.public('calendar_today', language: 'all', params: [date]),
      fetchJson: _datasource.fetchTodayJson,
      fromJson:
          (json) =>
              CalendarDayModel.fromJson(json as Map<String, dynamic>).toEntity(),
      failureMessage: 'Calendar',
    ).watch();
  }

  ScreenCacheSource<List<TibetanCalendarDay>> _monthSource(int year, int month) {
    return ScreenCacheSource(
      store: _store,
      key: ScreenCacheKey.public(
        'calendar_month',
        language: 'all',
        params: ['$year', '$month'],
      ),
      fetchJson: () => _datasource.fetchMonthJson(year, month),
      fromJson:
          (json) =>
              CalendarMonthModel.fromJson(
                json as Map<String, dynamic>,
              ).toEntities(),
      failureMessage: 'Calendar',
    );
  }

  @override
  Future<Either<Failure, List<TibetanCalendarDay>>> getMonth(
    int year,
    int month,
  ) async {
    try {
      final model = await _datasource.fetchMonth(year, month);
      return Right(model.toEntities());
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Calendar'));
    }
  }

  @override
  Future<Either<Failure, TibetanCalendarDay>> getToday() async {
    try {
      final model = await _datasource.fetchToday();
      return Right(model.toEntity());
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Calendar'));
    }
  }
}
