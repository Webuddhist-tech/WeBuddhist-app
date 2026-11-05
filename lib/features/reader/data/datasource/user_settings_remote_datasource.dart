import 'package:dio/dio.dart';

/// What `/users/me/settings` holds, as far as the reader sync needs it.
class UserSettingsResponse {
  const UserSettingsResponse({
    required this.contentLanguage,
    required this.preferences,
  });

  /// Uppercase API code, e.g. `BO`; null when the response has none.
  final String? contentLanguage;
  final Map<String, dynamic> preferences;

  factory UserSettingsResponse.fromJson(Map<String, dynamic> json) {
    final preferences = json['preferences'];
    final language = json['content_language'];
    return UserSettingsResponse(
      contentLanguage: language is String ? language : null,
      preferences:
          preferences is Map
              ? Map<String, dynamic>.from(preferences)
              : const {},
    );
  }
}

/// The signed-in user's settings on the server.
///
/// PATCH merges `preferences` by top-level key: a key sent replaces the stored
/// value whole, a key sent as null is deleted, and a key not sent is kept.
class UserSettingsRemoteDatasource {
  UserSettingsRemoteDatasource({required Dio dio}) : _dio = dio;

  static const String _path = '/users/me/settings';

  final Dio _dio;

  Future<UserSettingsResponse> fetch() async {
    final response = await _dio.get<Object?>(
      _path,
      options: Options(extra: const {'no_cache': true}),
    );
    return _parse(response.data);
  }

  Future<UserSettingsResponse> patchPreferences(
    Map<String, dynamic> preferences,
  ) async {
    final response = await _dio.patch<Object?>(
      _path,
      data: {'preferences': preferences},
    );
    return _parse(response.data);
  }

  UserSettingsResponse _parse(Object? data) {
    if (data is! Map) {
      throw const FormatException('Unexpected user settings response');
    }
    return UserSettingsResponse.fromJson(Map<String, dynamic>.from(data));
  }
}
