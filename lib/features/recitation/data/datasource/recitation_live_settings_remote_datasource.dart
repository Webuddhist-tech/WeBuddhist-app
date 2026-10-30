import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/recitation/data/models/edition_live_settings.dart';

/// An edition's live recitation settings: the parts a live room repeats.
class RecitationLiveSettingsRemoteDatasource {
  RecitationLiveSettingsRemoteDatasource({required this.dio});

  final Dio dio;

  /// Throws on a failed request or a body that is not an object.
  Future<EditionLiveSettings> fetchEditionLiveSettings(String editionId) async {
    final response = await dio.get(
      '/events/recitation/editions/$editionId/settings',
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ServerException('Unexpected edition live settings');
    }
    return EditionLiveSettings.fromJson(data);
  }
}
