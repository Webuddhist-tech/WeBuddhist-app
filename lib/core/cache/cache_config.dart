/// Cache configuration constants
/// TTL (Time-To-Live) values are based on content update frequency:
/// - Static content (texts, recitations): 24-72 hours
class CacheConfig {
  CacheConfig._();

  // Box names for Hive storage
  /// Text box
  static const String collectionListBox = 'collection_list_cache';
  static const String workListBox = 'work_list_cache';
  static const String textVersionListBox = 'text_version_list_cache';
  static const String textCommentListBox = 'text_comment_list_cache';
  static const String textContentBox = 'text_content_cache';

  /// Recitation box
  static const String recitationContentBox = 'recitation_content_cache';
  static const String recitationListBox = 'recitation_list_cache';
  static const String savedRecitationsBox = 'saved_recitations_cache';

  /// Cache metadata box
  static const String cacheMetadataBox = 'cache_metadata';

  /// Routine data box (persistent local user data — no TTL)
  static const String routineDataBox = 'routine_data';

  // TTL durations for lists (in hours)
  static const Duration collectionListTtl = Duration(hours: 24);
  static const Duration workListTtl = Duration(hours: 24);
  static const Duration textVersionListTtl = Duration(hours: 24);
  static const Duration textCommentListTtl = Duration(hours: 24);
  static const Duration recitationListTtl = Duration(hours: 24);

  /// TTL for text and recitation content - 48 hours (content rarely changes)
  static const Duration textContentTtl = Duration(hours: 48);
  static const Duration recitationContentTtl = Duration(hours: 48);

  /// TTL for saved recitations - 4 hours (user-specific, changes on save/unsave)
  static const Duration savedRecitationsTtl = Duration(hours: 4);

  // Cache size limits
  /// Maximum number of text contents to cache (LRU eviction after this)
  static const int maxTextCacheItems = 50;

  /// Maximum number of recitation contents to cache
  static const int maxRecitationCacheItems = 50;

  // Stale-while-revalidate configuration
  /// Fraction of TTL after which cache is considered stale (0.0 to 1.0).
  /// At this point, cached data is returned but refreshed in background.
  /// Example: 0.5 means cache becomes stale at 50% of TTL.
  static const double staleThresholdFraction = 0.5;

  /// Calculate stale threshold for a given TTL.
  /// Returns the duration after which cache should trigger background refresh.
  static Duration getStaleThreshold(Duration ttl) {
    return Duration(
      milliseconds: (ttl.inMilliseconds * staleThresholdFraction).round(),
    );
  }
}

/// Keys for cache entries
class CacheKeys {
  CacheKeys._();

  /// Generate key for collection list
  static String collectionList(String language) => 'collection_list_$language';

  /// Generate key for work list (texts within a collection/term)
  static String workList({
    required String termId,
    String? language,
    int skip = 0,
    int limit = 20,
  }) => 'work_list_${termId}_${language ?? 'en'}_${skip}_$limit';

  /// Generate key for text version list
  static String textVersionList({required String textId, String? language}) =>
      'text_version_${textId}_${language ?? 'en'}';

  /// Generate key for text comment list (commentary)
  static String textCommentList({required String textId, String? language}) =>
      'text_comment_${textId}_${language ?? 'en'}';

  /// Generate key for text content: text_content_{textId}_{language}
  static String textContent(String textId, String language) =>
      'text_content_${textId}_$language';

  /// Generate key for text reader content with pagination parameters
  static String textReader(
    String textId,
    String language,
    int page,
    int pageSize,
  ) => 'text_reader_${textId}_${language}_${page}_$pageSize';

  /// Generate key for text details (reader view with navigation)
  static String textDetails({
    required String textId,
    String? contentId,
    String? versionId,
    String? segmentId,
    String? direction,
    String? language,
    int? size,
  }) {
    final parts = [
      'text_details',
      textId,
      contentId ?? 'default',
      versionId ?? 'default',
      segmentId ?? 'start',
      direction ?? 'next',
      language ?? 'default',
      if (size != null) 'size$size',
    ];
    return parts.join('_');
  }

  /// Generate key for recitation content: recitation_content_{textId}_{languages}
  static String recitationContent(String textId, List<String> languages) =>
      'recitation_content_${textId}_${languages.join('_')}';

  /// Generate key for recitation list: recitation_list_{language}_{searchQuery}
  static String recitationList(String language, String? searchQuery) =>
      'recitation_list_${language}_${searchQuery ?? 'all'}';

  /// Generate key for saved recitations (user-specific, stored in separate box)
  /// Since saved recitations are user-specific and we only have one logged-in user,
  /// we use a simple constant key. The box itself is user-scoped.
  static const String savedRecitations = 'user_saved_recitations';
}
