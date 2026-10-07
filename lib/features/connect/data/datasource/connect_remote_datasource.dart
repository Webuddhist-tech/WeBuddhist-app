import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/connect/data/models/connect_feed_model.dart';
import 'package:flutter_pecha/features/connect/data/models/connect_post_comment_model.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post_comment.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_profile_model.dart';

class ConnectRemoteDatasource {
  ConnectRemoteDatasource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('ConnectRemoteDatasource');

  Future<DiscoverGroupsPage> fetchDiscoverGroups({
    required String language,
    int skip = 0,
    int limit = 20,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'language': language,
        'group_type': 'COMMUNITY',
        'skip': skip,
        'limit': limit,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      final response = await dio.get(
        '/author/groups',
        queryParameters: queryParameters,
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode != 200) {
        _logger.error('Failed to load discover groups: ${response.statusCode}');
        throw _statusToException(
          response.statusCode,
          'Failed to load discover groups',
        );
      }

      return _parseGroupsPage(
        response.data as Map<String, dynamic>,
        skip: skip,
        limit: limit,
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchDiscoverGroups', e);
      throw _dioToException(e, 'Failed to load discover groups');
    }
  }

  Future<DiscoverGroupsPage> fetchMyGroups({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/users/me/joined/author/groups',
        queryParameters: {'language': language, 'skip': skip, 'limit': limit},
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode != 200) {
        _logger.error('Failed to load my groups: ${response.statusCode}');
        throw _statusToException(
          response.statusCode,
          'Failed to load my groups',
        );
      }

      return _parseGroupsPage(
        response.data as Map<String, dynamic>,
        skip: skip,
        limit: limit,
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchMyGroups', e);
      throw _dioToException(e, 'Failed to load my groups');
    }
  }

  Future<ConnectFeedPage> fetchConnectFeeds({
    required bool includeUnfollowed,
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'skip': skip,
        'limit': limit,
        'language': language,
      };
      if (includeUnfollowed) {
        queryParameters['include_unfollowed'] = true;
      }

      final response = await dio.get(
        '/author/groups/feeds',
        queryParameters: queryParameters,
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode != 200) {
        _logger.error('Failed to load connect feeds: ${response.statusCode}');
        throw _statusToException(response.statusCode, 'Failed to load feed');
      }

      return ConnectFeedPageModel.fromJson(
        response.data as Map<String, dynamic>,
        language: language,
      ).toEntity();
    } on DioException catch (e) {
      _logger.error('Dio error in fetchConnectFeeds', e);
      throw _dioToException(e, 'Failed to load feed');
    }
  }

  Future<void> likePost(String postId) async {
    try {
      final response = await dio.post('/groups/author/posts/$postId/likes');
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw _statusToException(response.statusCode, 'Failed to like post');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in likePost', e);
      throw _dioToException(e, 'Failed to like post');
    }
  }

  Future<void> unlikePost(String postId) async {
    try {
      final response = await dio.delete('/groups/author/posts/$postId/likes');
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw _statusToException(response.statusCode, 'Failed to unlike post');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in unlikePost', e);
      throw _dioToException(e, 'Failed to unlike post');
    }
  }

  Future<ConnectPostCommentsPage> fetchPostComments({
    required String postId,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/groups/author/posts/$postId/comments',
        queryParameters: {'skip': skip, 'limit': limit},
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode != 200) {
        _logger.error('Failed to load post comments: ${response.statusCode}');
        throw _statusToException(
          response.statusCode,
          'Failed to load comments',
        );
      }

      return ConnectPostCommentsPageModel.fromJson(
        response.data as Map<String, dynamic>,
      ).toEntity();
    } on DioException catch (e) {
      _logger.error('Dio error in fetchPostComments', e);
      throw _dioToException(e, 'Failed to load comments');
    }
  }

  Future<ConnectPostComment> createPostComment({
    required String postId,
    required String text,
    String? parentCommentId,
  }) async {
    try {
      final payload = <String, dynamic>{'text': text};
      if (parentCommentId != null && parentCommentId.trim().isNotEmpty) {
        payload['parent_comment_id'] = parentCommentId;
      }

      final response = await dio.post(
        '/groups/author/posts/$postId/comments',
        data: payload,
      );

      if (response.statusCode != 201) {
        throw _statusToException(response.statusCode, 'Failed to post comment');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ServerException('Failed to parse created comment');
      }

      final commentJson =
          data['comment'] is Map<String, dynamic>
              ? data['comment'] as Map<String, dynamic>
              : data;
      return ConnectPostCommentModel.fromJson(commentJson).toEntity();
    } on DioException catch (e) {
      _logger.error('Dio error in createPostComment', e);
      throw _dioToException(e, 'Failed to post comment');
    }
  }

  Future<void> deletePostComment(String commentId) async {
    try {
      final response = await dio.delete('/groups/author/comments/$commentId');
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw _statusToException(
          response.statusCode,
          'Failed to delete comment',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in deletePostComment', e);
      throw _dioToException(e, 'Failed to delete comment');
    }
  }

  Future<void> likeComment(String commentId) async {
    try {
      final response = await dio.post(
        '/groups/author/comments/$commentId/likes',
      );
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw _statusToException(response.statusCode, 'Failed to like comment');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in likeComment', e);
      throw _dioToException(e, 'Failed to like comment');
    }
  }

  Future<void> unlikeComment(String commentId) async {
    try {
      final response = await dio.delete(
        '/groups/author/comments/$commentId/likes',
      );
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw _statusToException(
          response.statusCode,
          'Failed to unlike comment',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in unlikeComment', e);
      throw _dioToException(e, 'Failed to unlike comment');
    }
  }

  DiscoverGroupsPage _parseGroupsPage(
    Map<String, dynamic> data, {
    required int skip,
    required int limit,
  }) {
    final groupsJson = data['groups'] as List<dynamic>? ?? const [];
    final groups =
        groupsJson
            .whereType<Map<String, dynamic>>()
            .map(GroupProfileModel.fromJson)
            .map((model) => model.toEntity())
            .toList();

    return DiscoverGroupsPage(
      groups: groups,
      skip: (data['skip'] as num?)?.toInt() ?? skip,
      limit: (data['limit'] as num?)?.toInt() ?? limit,
      total: (data['total'] as num?)?.toInt() ?? groups.length,
    );
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Groups not found');
    } else if (statusCode == 429) {
      return const RateLimitException('Too many requests');
    } else {
      return ServerException('$label: $statusCode');
    }
  }

  Exception _dioToException(DioException e, String label) {
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
