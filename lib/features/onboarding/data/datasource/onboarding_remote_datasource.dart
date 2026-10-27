import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/onboarding/data/models/onboarding_preferences.dart';
import 'package:flutter_pecha/features/onboarding/data/models/onboarding_status_model.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';

final _logger = AppLogger('OnboardingRemoteDatasource');

/// Remote datasource for onboarding preferences.
///
/// Error handling is centralized in ErrorInterceptor, which converts
/// DioExceptions to typed AppExceptions. Exceptions propagate naturally
/// to the repository layer for mapping to Failures.
class OnboardingRemoteDatasource {
  OnboardingRemoteDatasource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Fetch whether the user has seen onboarding.
  ///
  /// Endpoint: GET /users/me/onboarding
  Future<OnboardingStatusModel> fetchOnboardingStatus() async {
    final response = await _dio.get('/users/me/onboarding');

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return OnboardingStatusModel.fromJson(data);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Invalid onboarding status response',
    );
  }

  /// Mark onboarding as seen for the current user.
  ///
  /// Endpoint: PUT /users/me/onboarding
  Future<void> updateOnboardingStatus({required bool hasSeenOnboarding}) async {
    await _dio.put(
      '/users/me/onboarding',
      data: OnboardingStatusModel(
        hasSeenOnboarding: hasSeenOnboarding,
      ).toJson(),
    );
    _logger.info('Onboarding status updated: has_seen_onboarding=$hasSeenOnboarding');
  }

  /// Save onboarding preferences to backend.
  ///
  /// Endpoint: POST /api/v1/users/me/onboarding-preferences
  Future<bool> saveOnboardingPreferences(OnboardingPreferences prefs) async {
    final response = await _dio.post(
      '/users/me/onboarding-preferences',
      data: prefs.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _logger.info('Onboarding preferences saved to backend');
      return true;
    }

    _logger.warning('Unexpected status: ${response.statusCode}');
    return false;
  }

  /// Fetch onboarding preferences from backend.
  ///
  /// Endpoint: GET /api/v1/users/me/onboarding-preferences
  /// Returns: OnboardingPreferences or null if not found
  Future<OnboardingPreferences?> fetchOnboardingPreferences() async {
    final response = await _dio.get('/users/me/onboarding-preferences');

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return OnboardingPreferences.fromJson(data);
      }
    }

    return null;
  }

  /// Fetch tradition path options for onboarding.
  ///
  /// Endpoint: GET /users/me/traditions/onboarding
  Future<List<TraditionPath>> fetchTraditionOnboardingPaths({
    required String language,
  }) async {
    return parseTraditionPaths(
      await fetchTraditionOnboardingPathsJson(language: language),
    );
  }

  static List<TraditionPath> parseTraditionPaths(
    Map<String, dynamic> pathsJson,
  ) {
    return traditionPathOrder
        .where((code) => pathsJson.containsKey(code))
        .map(
          (code) => TraditionPath.fromJson(
            code,
            pathsJson[code] as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// The validated `paths` map as served, for the screen cache.
  Future<Map<String, dynamic>> fetchTraditionOnboardingPathsJson({
    required String language,
  }) async {
    final response = await _dio.get(
      '/users/me/traditions/onboarding',
      queryParameters: {'language': language},
      options: Options(extra: {'no_cache': true}),
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Invalid tradition onboarding response',
      );
    }

    final pathsJson = data['paths'];
    if (pathsJson is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Invalid tradition paths response',
      );
    }

    return pathsJson;
  }

  /// Fetch the user's selected traditions.
  ///
  /// Endpoint: GET /users/me/traditions
  Future<List<UserTradition>> fetchUserTraditions({
    required String language,
  }) async {
    final response = await _dio.get(
      '/users/me/traditions',
      queryParameters: {'language': language},
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Invalid user traditions response',
      );
    }

    final traditionsJson = data['traditions'];
    if (traditionsJson is! List<dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Invalid user traditions list response',
      );
    }

    return traditionsJson
        .whereType<Map<String, dynamic>>()
        .map(UserTradition.fromJson)
        .toList();
  }

  /// Save the user's selected tradition.
  ///
  /// Endpoint: POST /api/v1/users/me/traditions
  Future<void> saveUserTradition(SaveTraditionRequest request) async {
    await _dio.post(
      '/users/me/traditions',
      data: request.toJson(),
    );
    _logger.info('User tradition saved: ${request.traditionCode}');
  }

  /// Remove a user tradition.
  ///
  /// Endpoint: DELETE /users/me/traditions/{user_tradition_id}
  Future<void> deleteUserTradition(String userTraditionId) async {
    await _dio.delete('/users/me/traditions/$userTraditionId');
    _logger.info('User tradition deleted: $userTraditionId');
  }
}
