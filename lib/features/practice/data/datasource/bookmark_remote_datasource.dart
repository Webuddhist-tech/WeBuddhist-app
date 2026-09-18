import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';

/// Bookmark types supported by the API.
enum BookmarkType {
  text,
  verse,
  timer,
  accumulator,
  series,
  groupRecitationCollection,
  recitationCollection,
  groupAccumulator,
}

extension BookmarkTypeExt on BookmarkType {
  String get value {
    switch (this) {
      case BookmarkType.text:
        return 'TEXT';
      case BookmarkType.verse:
        return 'VERSE';
      case BookmarkType.timer:
        return 'TIMER';
      case BookmarkType.accumulator:
        return 'ACCUMULATOR';
      case BookmarkType.series:
        return 'SERIES';
      case BookmarkType.groupRecitationCollection:
        return 'GROUP_RECITATION_COLLECTION';
      case BookmarkType.recitationCollection:
        return 'RECITATION_COLLECTION';
      case BookmarkType.groupAccumulator:
        return 'GROUP_ACCUMULATOR';
    }
  }
}

/// Remote datasource for the bookmark endpoints.
///
/// Error handling is centralised in ErrorInterceptor, which converts
/// DioExceptions to typed AppExceptions that propagate to the repository layer.
class BookmarkRemoteDatasource {
  final Dio dio;

  BookmarkRemoteDatasource({required this.dio});

  /// POST /users/me/bookmarks
  ///
  /// [type]     – the bookmark kind (TEXT, VERSE, TIMER, ACCUMULATOR, …)
  /// [sourceId] – text ID (TEXT), segment ID (VERSE), timer ID (TIMER), or
  ///              preset-accumulator ID (ACCUMULATOR)
  /// [name]     – optional display label stored alongside the bookmark so the
  ///              list can show a meaningful title without a follow-up lookup.
  ///
  /// A 409 response means the item is already bookmarked, which is treated as
  /// success so callers see "Bookmark saved" regardless of duplication.
  Future<bool> createBookmark({
    required BookmarkType type,
    required String sourceId,
    String? name,
  }) async {
    try {
      final response = await dio.post(
        '/users/me/bookmarks',
        data: {
          'type': type.value,
          'source_id': sourceId,
          if (name != null && name.isNotEmpty) 'name': name,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) return true;
      rethrow;
    }
  }

  /// GET /users/me/bookmarks
  ///
  /// Returns every bookmark across all types, localized to [language] (the
  /// selected content language). The endpoint paginates (default limit 20), so
  /// we page through to the reported `total` — the bookmarks screen filters per
  /// tab client-side, so a single combined list backs every tab and a removal
  /// reflects everywhere at once.
  Future<List<BookmarkDTO>> fetchBookmarks({String? language}) async {
    const pageSize = 50;
    final all = <BookmarkDTO>[];
    var skip = 0;

    while (true) {
      final response = await dio.get(
        '/users/me/bookmarks',
        queryParameters: {
          'skip': skip,
          'limit': pageSize,
          if (language != null && language.isNotEmpty) 'language': language,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException(
          'Unexpected /users/me/bookmarks payload type',
        );
      }

      final page = BookmarksResponse.fromJson(data);
      all.addAll(page.bookmarks);
      skip += pageSize;

      // Stop on an empty/short page or once we've collected the reported total.
      if (page.bookmarks.isEmpty ||
          page.bookmarks.length < pageSize ||
          all.length >= page.total) {
        break;
      }
    }

    return all;
  }

  /// GET /users/me/bookmarks/exists
  ///
  /// [sourceId] – entity id (text, segment, timer, accumulator, series, …)
  /// [type]     – bookmark kind; pass when known so the check is unambiguous
  Future<BookmarkExistsResult> checkBookmarkExists({
    required String sourceId,
    BookmarkType? type,
  }) async {
    final response = await dio.get(
      '/users/me/bookmarks/exists',
      queryParameters: {
        'source_id': sourceId,
        if (type != null) 'type': type.value,
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Unexpected /users/me/bookmarks/exists payload type',
      );
    }
    return BookmarkExistsResult.fromJson(data);
  }

  /// DELETE /users/me/bookmarks/{bookmarkId}
  Future<void> deleteBookmark(String bookmarkId) async {
    await dio.delete('/users/me/bookmarks/$bookmarkId');
  }
}
