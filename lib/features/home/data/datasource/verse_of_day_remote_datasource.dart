import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/home/data/models/verse_of_day_engagement_model.dart';
import 'package:flutter_pecha/features/home/data/models/verse_of_day_model.dart';

/// Remote source for [GET /verse-of-day/today](https://api.webuddhist.com/api/v1/doc#/Verse%20of%20Day/get_verse_of_day_today_endpoint_verse_of_day_today_get).
///
/// Uses the shared [Dio] client so auth, logging, retry, and [X-Timezone]
/// (for the user's local calendar date) are applied automatically.
class VerseOfDayRemoteDatasource {
  VerseOfDayRemoteDatasource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('VerseOfDayRemoteDatasource');

  Future<VerseOfDayModel> fetchVerseOfDay({required String language}) async {
    try {
      final response = await dio.get(
        '/verse-of-day/today',
        queryParameters: {'lang': language},
      );

      if (response.statusCode == 200) {
        return VerseOfDayModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        _logger.error('Failed to load verse of day: ${response.statusCode}');
        throw _statusToException(
          response.statusCode,
          'Failed to load verse of day',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchVerseOfDay', e);
      throw _dioToException(e, 'Failed to load verse of day');
    }
  }

  Future<VerseOfDayLikesModel> fetchLikes(String verseId) async {
    try {
      final response = await dio.get(
        '/verse-of-day/$verseId/likes',
        options: Options(extra: {'no_cache': true}),
      );
      if (response.statusCode != 200) {
        throw _statusToException(response.statusCode, 'Failed to load likes');
      }
      return VerseOfDayLikesModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.error('Dio error in fetchLikes', e);
      throw _dioToException(e, 'Failed to load likes');
    }
  }

  Future<void> likeVerse(String verseId) async {
    try {
      final response = await dio.post('/verse-of-day/$verseId/likes');
      if (!_isSuccess(response.statusCode)) {
        throw _statusToException(response.statusCode, 'Failed to like verse');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in likeVerse', e);
      throw _dioToException(e, 'Failed to like verse');
    }
  }

  Future<void> unlikeVerse(String verseId) async {
    try {
      final response = await dio.delete('/verse-of-day/$verseId/likes');
      if (!_isSuccess(response.statusCode)) {
        throw _statusToException(response.statusCode, 'Failed to unlike verse');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in unlikeVerse', e);
      throw _dioToException(e, 'Failed to unlike verse');
    }
  }

  Future<VerseOfDayCommentsPageModel> fetchComments({
    required String verseId,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/verse-of-day/$verseId/comments',
        queryParameters: {'skip': skip, 'limit': limit},
        options: Options(extra: {'no_cache': true}),
      );
      if (response.statusCode != 200) {
        throw _statusToException(
          response.statusCode,
          'Failed to load comments',
        );
      }
      return VerseOfDayCommentsPageModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchComments', e);
      throw _dioToException(e, 'Failed to load comments');
    }
  }

  Future<VerseOfDayCommentModel> createComment({
    required String verseId,
    required String text,
  }) async {
    try {
      final response = await dio.post(
        '/verse-of-day/$verseId/comments',
        data: {'text': text},
      );
      if (!_isSuccess(response.statusCode)) {
        throw _statusToException(response.statusCode, 'Failed to post comment');
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ServerException('Failed to parse created comment');
      }
      return VerseOfDayCommentModel.fromJson(data);
    } on DioException catch (e) {
      _logger.error('Dio error in createComment', e);
      throw _dioToException(e, 'Failed to post comment');
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      final response = await dio.delete('/verse-of-day/comments/$commentId');
      if (!_isSuccess(response.statusCode)) {
        throw _statusToException(
          response.statusCode,
          'Failed to delete comment',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in deleteComment', e);
      throw _dioToException(e, 'Failed to delete comment');
    }
  }

  bool _isSuccess(int? statusCode) =>
      statusCode == 200 || statusCode == 201 || statusCode == 204;

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Verse of day not found');
    } else if (statusCode == 429) {
      return const RateLimitException('Too many requests');
    } else {
      return ServerException('$label: $statusCode');
    }
  }

  Exception _dioToException(DioException e, String label) {
    if (e.error is Exception) return e.error as Exception;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Connection timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      return const NetworkException('No internet connection');
    } else if (e.response?.statusCode != null) {
      return _statusToException(e.response!.statusCode, label);
    } else {
      return const NetworkException('Network error');
    }
  }
}
