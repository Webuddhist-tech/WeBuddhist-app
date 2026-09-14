/// Application route definitions
/// Contains all route path constants and route names used throughout the app
///
/// Route Categories:
/// - Public Routes: Accessible without authentication
/// - Guest Accessible Routes: Accessible in guest mode
/// - Protected Routes: Require full authentication
class AppRoutes {
  AppRoutes._();

  // ========== CORE ROUTES ==========
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String getApp = '/get-app';
  static const String open = '/open';

  // ========== MAIN ROUTES ==========
  static const String home = '/home';
  static const String texts = "/ai-mode";
  static const String practice = "/practice";
  static const String more = "/more";
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String about = '/about';
  static const String legal = '/legal';
  static const String termsOfService = '/terms-of-service';
  static const String privacyPolicy = '/privacy-policy';
  static const String notifications = '/notifications';
  static const String deleteAccount = '/delete-account';

  // ========== MALA ROUTE ==========
  /// Digital prayer-bead mala. Login-gated (see [_protectedBasePaths]).
  static const String mala = '/mala';

  // ========== GROUP CHAT ==========
  /// Community group chat. Top-level so it is not guest-accessible via `/home`.
  static const String groupChat = '/groups/:groupId/chat';

  static String groupChatPath(String groupId) => '/groups/$groupId/chat';

  /// Every group chat the viewer belongs to. Top-level for the same reason as
  /// [groupChat] — it is not guest-accessible.
  static const String chats = '/chats';

  // ========== PRACTICE SUB ROUTES ==========
  static const String practiceEditRoutine = '/practice/edit-routine';
  static const String practiceMyPractices = '/practice/my-practices';
  static const String practicePlanPreview = '/practice/plans/preview';

  // ========== PLANS SUB ROUTES ==========
  static const String plansInfo = '/plans/info';

  // ========== RECITATIONS SUB ROUTES ==========
  static const String recitationDetail = '/recitations/detail';

  // ========== READER ROUTES ==========
  static const String reader = '/reader';

  // ========== PLAN TEXT ROUTES ==========
  /// Inline plan content screen — renders subtasks where `content_type` is
  /// `TEXT` or `IMAGE`.
  /// Path param is the subtask id; the actual content travels in `extra`
  /// as a [NavigationContext] whose `currentItem` carries inline content.
  static const String planText = '/plan-text';

  // ========== SEARCH ROUTES ==========
  static const String searchResults = '/search-results';

  // ========== CALENDAR ROUTES ==========
  /// Tibetan calendar screen. Nested under /home so the bottom nav persists.
  static const String calendar = '/home/calendar';

  // ========== ROUTE CATEGORIES ==========

  /// Routes that don't require any authentication
  static const Set<String> publicRoutes = {splash, login, getApp, open};

  /// Routes accessible to guest users.
  ///
  /// IMPORTANT — PREFIX MATCHING:
  /// [isGuestAccessible] uses prefix matching, so any sub-route of a listed
  /// path is automatically guest-accessible without being listed here.
  ///
  /// - Sub-routes of listed paths: DO NOT re-list them; they inherit access.
  ///   e.g. `/home` listed → `/home/plans`, `/home/settings` are all guest-accessible.
  /// - New top-level routes guests should access: ADD the prefix here.
  /// - Sub-routes that guests must NOT access under a guest-accessible parent:
  ///   add the base path to [_protectedBasePaths] — it takes priority.
  static const Set<String> guestAccessibleRoutes = {
    open,
    getApp,
    home,
    more,
    settings, // Guests can access settings (theme, language, notifications)
    about, // Linked from Settings; informational, no auth needed
    legal, // Linked from Settings; terms + privacy live as sibling routes
    termsOfService,
    privacyPolicy,
    texts,
    practice, // Guests can see empty practice screen
    practiceMyPractices, // Guests can browse my practices empty state
    practicePlanPreview, // Allow guests to browse/preview plans
    reader,
    notifications, // Local-only — guests can configure routine notifications
    planText, // Guests can see inline TEXT/IMAGE subtasks
  };

  /// Base paths that require full authentication (prefix matching)
  static const Set<String> _protectedBasePaths = {
    practiceEditRoutine, // Building routine requires auth
    profile,
    plansInfo,
    recitationDetail,
    mala, // Mala counting is login-gated (no guest mode)
  };

  // ========== HELPER METHODS ==========

  /// Check if a route is fully public (no auth needed at all)
  static bool isPublicRoute(String path) {
    return publicRoutes.contains(path);
  }

  /// Check if a route is accessible to guest users
  static bool isGuestAccessible(String path) {
    if (isPublicRoute(path)) return true;
    return guestAccessibleRoutes.any((route) => _matchesRoute(path, route));
  }

  /// Check if a route requires full authentication
  static bool requiresAuth(String path) {
    // Public and guest routes don't require auth
    if (isGuestAccessible(path)) return false;

    // Check if path matches any protected base path
    return _protectedBasePaths.any((route) => _matchesRoute(path, route));
  }

  /// Match a path against a route pattern (exact or prefix match)
  static bool _matchesRoute(String path, String route) {
    return path == route || path.startsWith('$route/');
  }
}
