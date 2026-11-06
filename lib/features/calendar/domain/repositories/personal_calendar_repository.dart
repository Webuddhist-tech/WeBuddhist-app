import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:fpdart/fpdart.dart';

/// The viewer's calendar on the server.
abstract class PersonalCalendarRepository {
  Future<Either<Failure, CalendarFeedPage>> getFeed({
    required DateTime from,
    required DateTime to,
    required String language,
    int skip = 0,
    int limit = 100,
  });
}
