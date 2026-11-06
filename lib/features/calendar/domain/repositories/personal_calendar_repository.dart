import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';
import 'package:fpdart/fpdart.dart';

/// The viewer's calendar on the server: their personal events and the feed
/// that combines them with events from joined spaces.
abstract class PersonalCalendarRepository {
  Future<Either<Failure, CalendarFeedPage>> getFeed({
    required DateTime from,
    required DateTime to,
    required String language,
    int skip = 0,
    int limit = 100,
  });

  Future<Either<Failure, PersonalCalendarEvent>> getEvent(String id);

  Future<Either<Failure, PersonalCalendarEvent>> createEvent({
    required String title,
    required DateTime startDate,
    required PersonalRepeat repeat,
  });

  /// Changes the title and repeat of every date of the event.
  Future<Either<Failure, PersonalCalendarEvent>> updateEvent(
    String id, {
    required String title,
    required PersonalRepeat repeat,
  });

  /// Removes the event and all of its dates.
  Future<Either<Failure, void>> deleteEvent(String id);

  Future<Either<Failure, List<PersonalRepeatOption>>> getRepeatOptions(
    DateTime date,
  );
}
