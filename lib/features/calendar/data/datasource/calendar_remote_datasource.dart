import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/calendar/data/models/calendar_day_model.dart';
import 'package:flutter_pecha/features/calendar/data/models/calendar_month_model.dart';

class CalendarRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('CalendarRemoteDatasource');

  CalendarRemoteDatasource({required this.dio});

  /// Endpoint: GET /calendar/{year}/{month}
  ///
  /// [year]/[month] are the Gregorian year and month (1–12). Returns every day
  /// of that Gregorian month, each carrying its Tibetan lunar data (omitted
  /// lunar days appear with a null gregorian_date).
  Future<CalendarMonthModel> fetchMonth(int year, int month) async {
    return CalendarMonthModel.fromJson(await fetchMonthJson(year, month));
  }

  /// Raw month as served, so the screen cache stores exactly what the API sent.
  Future<Map<String, dynamic>> fetchMonthJson(int year, int month) async {
    try {
      final response = await dio.get(
        '/calendar/$year/$month',
        options: Options(extra: {'no_cache': true}),
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      _logger.error('Failed to load calendar month: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to load calendar');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchMonth', e);
      throw _dioToException(e, 'Failed to load calendar');
    }
  }

  /// Endpoint: GET /calendar/today
  Future<CalendarDayModel> fetchToday() async {
    return CalendarDayModel.fromJson(await fetchTodayJson());
  }

  Future<Map<String, dynamic>> fetchTodayJson() async {
    try {
      final response = await dio.get(
        '/calendar/today',
        options: Options(extra: {'no_cache': true}),
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['day'] as Map<String, dynamic>;
      }
      _logger.error('Failed to load today: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to load today');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchToday', e);
      throw _dioToException(e, 'Failed to load today');
    }
  }

  AppException _statusToException(int? status, String message) {
    return switch (status) {
      401 => AuthenticationException(message),
      403 => AuthorizationException(message),
      404 => NotFoundException(message),
      _ => ServerException(message),
    };
  }

  AppException _dioToException(DioException e, String message) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException(message);
    }
    final status = e.response?.statusCode;
    if (status != null) return _statusToException(status, message);
    return ServerException(message);
  }
}
