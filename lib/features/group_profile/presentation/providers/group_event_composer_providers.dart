import 'package:dio/dio.dart';
import 'package:flutter_pecha/env.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/place_search_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Null when no LocationIQ token is configured; the venue sheet then offers
/// the map pin only.
final placeSearchDatasourceProvider = Provider<PlaceSearchRemoteDatasource?>((
  ref,
) {
  final token = Env.locationIqToken;
  if (token == null) return null;
  // A plain client: the app's Dio adds auth headers meant for our API.
  return PlaceSearchRemoteDatasource(
    dio: Dio(BaseOptions(receiveTimeout: const Duration(seconds: 10))),
    token: token,
  );
});
