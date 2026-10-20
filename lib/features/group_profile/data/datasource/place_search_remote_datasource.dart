import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

/// One hit from LocationIQ autocomplete or reverse lookup.
class PlaceSearchResult {
  final String id;
  final String label;
  final String primary;
  final String secondary;
  final double latitude;
  final double longitude;

  const PlaceSearchResult({
    required this.id,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.latitude,
    required this.longitude,
  });

  static PlaceSearchResult? fromJson(Map<String, dynamic> json) {
    final latitude = double.tryParse('${json['lat'] ?? ''}');
    final longitude = double.tryParse('${json['lon'] ?? ''}');
    final displayName = (json['display_name'] as String? ?? '').trim();
    if (latitude == null || longitude == null || displayName.isEmpty) {
      return null;
    }
    final parts = displayName.split(',');
    final primary =
        (json['display_place'] as String?)?.trim().isNotEmpty == true
            ? (json['display_place'] as String).trim()
            : parts.first.trim();
    final secondary =
        (json['display_address'] as String?)?.trim().isNotEmpty == true
            ? (json['display_address'] as String).trim()
            : parts.skip(1).join(',').trim();
    if (primary.isEmpty) return null;
    return PlaceSearchResult(
      id: '${json['place_id'] ?? displayName}',
      label: displayName,
      primary: primary,
      secondary: secondary,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

/// LocationIQ, called directly like the studio does.
class PlaceSearchRemoteDatasource {
  final Dio dio;
  final String token;
  final _logger = AppLogger('PlaceSearchRemoteDatasource');

  static const minQueryLength = 4;

  PlaceSearchRemoteDatasource({required this.dio, required this.token});

  Future<List<PlaceSearchResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength) return const [];
    try {
      final response = await dio.get(
        'https://api.locationiq.com/v1/autocomplete',
        queryParameters: {'key': token, 'q': trimmed, 'limit': 8, 'dedupe': 1},
      );
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(PlaceSearchResult.fromJson)
          .whereType<PlaceSearchResult>()
          .toList();
    } on DioException catch (e) {
      // No match is a 404 here, not an error.
      if (e.response?.statusCode == 404) return const [];
      _logger.error('Dio error in search', e);
      throw const NetworkException('Place search failed');
    }
  }

  Future<PlaceSearchResult?> reverse(double latitude, double longitude) async {
    try {
      final response = await dio.get(
        'https://api.locationiq.com/v1/reverse',
        queryParameters: {
          'key': token,
          'lat': latitude,
          'lon': longitude,
          'format': 'json',
          'zoom': 18,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      return PlaceSearchResult.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _logger.error('Dio error in reverse', e);
      return null;
    }
  }
}
