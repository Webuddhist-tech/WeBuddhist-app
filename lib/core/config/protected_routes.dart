/// Centralized configuration for protected API routes that require authentication.
class ProtectedRoutes {
  /// List of all protected API paths.
  ///
  /// Paths can contain path parameters in curly braces like {planId}, {taskId}, etc.
  /// These parameters will match any value in that segment position.
  ///
  /// Patterns ending with '/' or '**' will match all sub-paths (prefix match).
  ///
  /// IMPORTANT: These paths should NOT include the /api/v1 prefix as the base URL
  /// is already configured with it. Match the exact paths used in API calls.
  static const List<String> paths = [
    // User profile
    '/users/info',
    '/users/upload',
    '/users/username',

    // User progress - all /users/me routes require auth
    '/users/me',
    '/users/me/', // Catch-all: matches all /users/me/* paths
    '/users/me/push-devices', // Push device token registration

    '/users/me/plans',
    '/users/me/plans/{planId}',
    '/users/me/plans/{planId}/', // Matches sub-paths like /plans/123/tasks
    '/users/me/tasks',
    '/users/me/tasks/{taskId}/complete',
    '/users/me/sub-tasks',
    '/users/me/sub-tasks/{subTaskId}/complete',
    '/users/me/task/{taskId}',
    '/users/me/plan/{planId}/days/{dayNumber}',
    '/users/me/plan/{planId}/days/{dayNumber}/content',

    // Recitations
    '/users/me/recitations',
    '/users/me/recitations/{recitationId}',

    // Community group chat (REST). Distinct from AI `/chats`.
    '/chat/',

    // AI chat
    '/chats',
    '/chats/', // Catch-all for chat sub-paths
    '/threads',
    '/threads/{threadId}',
    '/threads/{threadId}/', // Catch-all for thread sub-paths
    // Timers
    '/timers',
    '/timers/', // Catch-all for timer sub-paths like /timers/user/timer_stop
    // Routines
    '/routines',
    '/routines/{routineId}/time-blocks',
    '/routines/{routineId}/time-blocks/{timeBlockId}',
    '/users/me/routine',

    // Series enrollment
    '/users/me/series',

    // Mala accumulators (user-specific counts). The public preset catalogue
    // (`/accumulators/presets`) is only ever fetched by authenticated users, so
    // a catch-all is safe and also covers detail, create, and update — all of
    // which are user-scoped and 403 without a token.
    '/accumulators/', // Catch-all: detail, create (/user), update (/user/{id})
    // Group accumulator counts (submit requires auth).
    '/group-accumulators/', // Catch-all: POST count, GET detail, etc.
    // Group join / follow
    '/author/groups/{groupId}/join',
    '/author/groups/{groupId}/follow',

    // Event participation (join / leave require auth)
    '/events/{eventId}/participants',
    '/events/{eventId}/participants/me',

    // Post likes (like / unlike require auth)
    '/groups/author/posts/{postId}/likes',

    // Comment delete / like require auth
    '/groups/author/comments/{commentId}',
    '/groups/author/comments/{commentId}/likes',

    // Group accumulators (group prayer accumulations)
    '/group-accumulators/',

    // CMS author routes: group post create + media upload.
    '/cms/',

    // Plans (public endpoints but may need auth for user-specific data)
    '/plans/{planId}',
    '/plans/{planId}/days/{dayNumber}',
  ];

  /// Routes that accept optional authentication.
  ///
  /// The token is sent when the user is authenticated; silently skipped for guests.
  static const List<String> optionalPaths = [
    '/plans/{planId}/days',
    // Verse of the day: public for guests; when logged in, Bearer + existing
    // X-Timezone lets the backend upsert user_metadata.timezone.
    '/verse-of-day/today',
    // Series list/detail: sends auth when logged in so the response includes
    // user-enriched fields like `progress` and `partner`.
    '/series',
    '/series/{id}',
    '/series/featured',
    '/author/groups',
    // Group detail + members: sends auth when logged in so fields like
    // `is_group_enrolled` reflect the current user (anonymous GET → false).
    '/author/groups/',
    // Events list/detail: sends auth when logged in so `is_joined` reflects the
    // current user (anonymous GET → false).
    '/events',
    '/events/{eventId}',
    // Posts feed: sends auth when logged in so `liked_by_me` reflects the
    // current user (anonymous GET → false).
    '/groups/author/posts',
    // A group's own posts list, same `liked_by_me` enrichment.
    '/groups/author/{groupId}/posts',
    // Post comments list: sends auth when logged in so `liked_by_me` reflects
    // the current user on each comment.
    '/groups/author/posts/{postId}/comments',
    // Group feeds: sends auth when logged in for user-specific fields.
    '/author/groups/feeds',
    // Chant catalogue is public; when logged in, Bearer is required for
    // `should_include_collections` / group-collection enrichment to return.
    '/recitations',
  ];

  /// Check if a given path is protected (requires authentication).
  static bool isProtected(String path) {
    return paths.any((route) => _matchesPathPattern(path, route));
  }

  /// Check if a given path accepts optional authentication.
  ///
  /// Token is sent when available (authenticated user), silently skipped for guests.
  static bool isOptional(String path) {
    return optionalPaths.any((route) => _matchesPathPattern(path, route));
  }

  /// Matches a path against a pattern that may contain path parameters like {planId}.
  ///
  /// Examples:
  /// - `_matchesPathPattern('/users/me', '/users/me')` → true
  /// - `_matchesPathPattern('/users/me/plans/123', '/users/me/plans/{planId}')` → true
  /// - `_matchesPathPattern('/users/me/plans/123/tasks', '/users/me/plans/{planId}/')` → true (prefix match)
  /// - `_matchesPathPattern('/users/me/plans/123/tasks', '/users/me/plans/{planId}')` → false (exact segment count)
  static bool _matchesPathPattern(String path, String pattern) {
    // Pattern ending with '/' indicates prefix match for all sub-paths
    final isPrefixMatch = pattern.endsWith('/');
    final cleanPattern =
        isPrefixMatch ? pattern.substring(0, pattern.length - 1) : pattern;

    // Split both path and pattern into segments
    final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();
    final patternSegments =
        cleanPattern.split('/').where((s) => s.isNotEmpty).toList();

    // For prefix match, path must have at least as many segments as pattern
    if (isPrefixMatch) {
      if (pathSegments.length < patternSegments.length) {
        return false;
      }
    } else {
      // For exact match, must have same number of segments
      if (pathSegments.length != patternSegments.length) {
        return false;
      }
    }

    // Compare each segment up to pattern length
    for (var i = 0; i < patternSegments.length; i++) {
      final pathSegment = pathSegments[i];
      final patternSegment = patternSegments[i];

      // If pattern segment is a parameter (e.g., {planId}), it matches any value
      if (patternSegment.startsWith('{') && patternSegment.endsWith('}')) {
        continue;
      }

      // Otherwise, segments must match exactly
      if (pathSegment != patternSegment) {
        return false;
      }
    }

    return true;
  }
}
