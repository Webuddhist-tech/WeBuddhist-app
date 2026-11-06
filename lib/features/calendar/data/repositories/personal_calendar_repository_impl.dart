import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/calendar/data/datasource/personal_calendar_remote_datasource.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/personal_calendar_repository.dart';
import 'package:fpdart/fpdart.dart';

class PersonalCalendarRepositoryImpl implements PersonalCalendarRepository {
  PersonalCalendarRepositoryImpl(this._remote);

  final PersonalCalendarRemoteDatasource _remote;

  @override
  Future<Either<Failure, CalendarFeedPage>> getFeed({
    required DateTime from,
    required DateTime to,
    required String language,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      return Right(
        await _remote.fetchFeed(
          from: from,
          to: to,
          language: language,
          skip: skip,
          limit: limit,
        ),
      );
    } catch (e) {
      return Left(ExceptionMapper.map(e));
    }
  }
}
