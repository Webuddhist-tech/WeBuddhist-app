import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/calendar/data/models/personal_calendar_models.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';

/// The Personal Calendar API. Failures reach the repository as exceptions.
class PersonalCalendarRemoteDatasource {
  PersonalCalendarRemoteDatasource({required this.dio});

  final Dio dio;

  static final _noCache = Options(extra: {'no_cache': true});

  Future<CalendarFeedPage> fetchFeed({
    required DateTime from,
    required DateTime to,
    required String language,
    required int skip,
    required int limit,
  }) async {
    final response = await dio.get(
      '/users/me/calendar',
      queryParameters: {
        'from_date': formatApiDate(from),
        'to_date': formatApiDate(to),
        'language': language,
        'skip': skip,
        'limit': limit,
      },
      options: _noCache,
    );
    return calendarFeedPageFromJson(response.data as Map<String, dynamic>);
  }
}
