import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/calendar/data/datasource/personal_calendar_remote_datasource.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/personal_calendar_repository.dart';
import 'package:fpdart/fpdart.dart';

class PersonalCalendarRepositoryImpl implements PersonalCalendarRepository {
  PersonalCalendarRepositoryImpl(this._remote);

  final PersonalCalendarRemoteDatasource _remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } catch (e) {
      return Left(ExceptionMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, CalendarFeedPage>> getFeed({
    required DateTime from,
    required DateTime to,
    required String language,
    int skip = 0,
    int limit = 100,
  }) => _guard(
    () => _remote.fetchFeed(
      from: from,
      to: to,
      language: language,
      skip: skip,
      limit: limit,
    ),
  );

  @override
  Future<Either<Failure, PersonalCalendarEvent>> getEvent(String id) =>
      _guard(() => _remote.fetchEvent(id));

  @override
  Future<Either<Failure, PersonalCalendarEvent>> createEvent({
    required String title,
    required DateTime startDate,
  }) => _guard(() => _remote.createEvent(title: title, startDate: startDate));

  @override
  Future<Either<Failure, PersonalCalendarEvent>> updateEvent(
    String id, {
    required String title,
  }) => _guard(() => _remote.updateEvent(id, title: title));

  @override
  Future<Either<Failure, void>> deleteEvent(String id) =>
      _guard(() => _remote.deleteEvent(id));
}
