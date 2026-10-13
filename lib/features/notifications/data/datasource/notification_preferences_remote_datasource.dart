import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/notifications/data/models/notification_preferences_model.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_preferences.dart';

/// Account-wide push preferences. `PUSH` is the backend's default channel, so
/// it is never sent.
///
/// Dio failures are left to propagate: the repository maps the typed
/// exception the error interceptor wraps them in.
class NotificationPreferencesRemoteDatasource {
  NotificationPreferencesRemoteDatasource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const String _path = '/users/me/notification-preferences';

  /// `GET /users/me/notification-preferences`.
  Future<NotificationPreferencesModel> fetch() async {
    final response = await _dio.get(
      _path,
      options: Options(extra: {'no_cache': true}),
    );
    return NotificationPreferencesModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `PATCH /users/me/notification-preferences`. The body is a merge: only
  /// [changes] are written. Returns the full state the backend now holds.
  Future<NotificationPreferencesModel> update(
    Map<ConnectNotificationToggle, bool> changes,
  ) async {
    final response = await _dio.patch(
      _path,
      data: NotificationPreferencesModel.toRequestJson(changes),
    );
    return NotificationPreferencesModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
