import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/config/router/page_transitions.dart';
import 'package:flutter_pecha/core/config/router/route_guard.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/presentation/screens/ai_mode_screen.dart';
import 'package:flutter_pecha/features/ai/presentation/screens/search_results_screen.dart';
import 'package:flutter_pecha/core/config/router/pending_route_provider.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/screens/login_page.dart';
import 'package:flutter_pecha/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_pecha/features/calendar/presentation/screens/tibetan_calendar_screen.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/connect_post_detail_screen.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_accumulator_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_event_detail_screen.dart';
import 'package:flutter_pecha/features/group_chat/presentation/screens/chats_screen.dart';
import 'package:flutter_pecha/features/group_chat/presentation/screens/group_chat_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_profile_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_recitation_collection_screen.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/screens/group_events_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/plan_list_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/series_detail_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/series_info_screen.dart';
import 'package:flutter_pecha/features/more/presentation/about_screen.dart';
import 'package:flutter_pecha/features/more/presentation/edit_profile_screen.dart';
import 'package:flutter_pecha/features/more/presentation/more_screen.dart';
import 'package:flutter_pecha/features/more/presentation/legal.dart';
import 'package:flutter_pecha/features/more/presentation/privacy_policy_screen.dart';
import 'package:flutter_pecha/features/more/presentation/delete_account_screen.dart';
import 'package:flutter_pecha/features/more/presentation/terms_of_service_screen.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_wrapper.dart';
import 'package:flutter_pecha/features/poems/presentation/screens/poems_viewer_screen.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/screens/plan_text_screen.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/plan_details.dart';
import 'package:flutter_pecha/features/plans/presentation/plan_info.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_preview/plan_preview_details.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/edit_routine_screen.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/my_recitation_collection_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/bookmarks_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/practice_explore_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/practice_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_plan_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_recitation_screen.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/screens/mala_screen.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/screens/reader_screen.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/texts/presentation/screens/chapters/chapters_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_image/choose_image.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_image/create_image.dart';
import 'package:flutter_pecha/features/texts/presentation/version_selection/language_selection.dart';
import 'package:flutter_pecha/features/texts/presentation/version_selection/version_selection_screen.dart';
import 'package:flutter_pecha/features/timer/presentation/screens/active_timer_screen.dart';
import 'package:flutter_pecha/features/timer/presentation/screens/preset_timers_screen.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _logger = AppLogger('AppRouter');

/// Root navigator key for the GoRouter instance.
///
/// Exposed so widgets above the navigator tree (e.g. ForceUpdateGate)
/// can call showDialog on a context that is actually inside the navigator.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Shell navigator key for routes that share the persistent bottom nav bar.
/// Public so [HomeShellScaffold] can pop imperatively-pushed screens on tab switch.
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Provider for the application router with authentication and route protection
///
/// This provider creates a GoRouter instance that:
/// - Protects routes based on authentication state
/// - Handles guest mode access restrictions
/// - Manages onboarding flow
/// - Preserves deep links for post-login redirection
/// - Automatically refreshes when auth state changes
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    // App links are consumed explicitly by AppLinksDeepLinkService. If
    // go_router also uses the platform launch URL during cold start, the same
    // deep link can be inserted twice and leave a stale page under Back.
    overridePlatformDefaultLocation: true,
    debugLogDiagnostics: true,
    observers: [ref.read(analyticsServiceProvider).routeObserver],

    // Re-evaluate redirect whenever auth state changes.
    refreshListenable: GoRouterRefreshStream(
      ref.read(authProvider.notifier).stream,
    ),

    // Route guard for authentication and authorization.
    // Always reads the latest auth state — do NOT capture it in the closure.
    // RouteGuard.redirect is synchronous: onboarding status lives on AuthState
    // and is prefetched during login/auth-restore. When still unknown, a
    // debounced background retry is kicked off here (never awaited).
    redirect: (context, state) {
      ref.read(authProvider.notifier).refreshOnboardingStatusIfNeeded();
      return RouteGuard.redirect(
        context,
        state,
        ref.read(authProvider),
        getPendingRoute: () => ref.read(pendingRouteProvider),
        setPendingRoute:
            (route) => ref.read(pendingRouteProvider.notifier).state = route,
      );
    },

    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Defensive fallback for the Airbridge tracking URL if it is ever handed
      // to go_router after native Airbridge handling.
      GoRoute(
        path: AppRoutes.getApp,
        name: 'get-app',
        redirect: (_, __) => AppRoutes.home,
      ),

      // Compatibility fallback for series deep links delivered directly to
      // go_router instead of through AppLinksDeepLinkService.
      GoRoute(
        path: '/open/series/:seriesId',
        name: 'open-series',
        redirect: (_, state) {
          final seriesId = state.pathParameters['seriesId'] ?? '';
          return '/home/series/$seriesId';
        },
      ),
      GoRoute(
        path: '/open/poem/:poemId',
        name: 'open-poem',
        redirect: (_, state) {
          final poemId = state.pathParameters['poemId'] ?? '';
          return Uri(
            path: '/home/poems',
            queryParameters: {'poemId': poemId},
          ).toString();
        },
      ),
      // Compatibility fallback in case a platform sends the first-party app
      // link directly to go_router instead of through AppLinksDeepLinkService.
      GoRoute(
        path: '/open/reader/:textId',
        name: 'open-reader',
        redirect: (_, state) {
          final textId = state.pathParameters['textId'] ?? '';
          final segmentId =
              state.uri.queryParameters['segment'] ??
              state.uri.queryParameters['segmentId'];
          final language = state.uri.queryParameters['lang'];
          return Uri(
            pathSegments: ['reader', textId],
            queryParameters: {
              if (segmentId != null && segmentId.isNotEmpty)
                'segment': segmentId,
              if (language != null && language.isNotEmpty) 'lang': language,
            },
          ).toString();
        },
      ),
      // First-party app entry point shared from the home screen.
      // AppLinksDeepLinkService handles normal delivery; this is the home
      // fallback in case go_router receives only /open directly.
      GoRoute(path: '/open', name: 'open', redirect: (_, __) => AppRoutes.home),
      GoRoute(
        path: "/login",
        name: "login",
        builder: (context, state) => const LoginPage(),
      ),
      // onboarding route
      GoRoute(
        path: "/onboarding",
        name: "onboarding",
        builder: (context, state) => const OnboardingWrapper(),
      ),
      GoRoute(
        path: AppRoutes.chats,
        name: 'chats',
        builder: (context, state) => const ChatsScreen(),
      ),
      GoRoute(
        path: AppRoutes.groupChat,
        name: 'group-chat',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId'] ?? '';
          return GroupChatScreen(groupId: groupId);
        },
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return HomeShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: "/home",
            name: "home",
            builder: (context, state) => const MainNavigationScreen(),
            routes: [
              GoRoute(
                path: "plans/:tag",
                name: "home-plans",
                builder: (context, state) {
                  final tag = state.pathParameters['tag'] ?? '';
                  return PlanListScreen(tag: tag);
                },
                routes: [
                  GoRoute(
                    path: "preview",
                    name: "home-plan-preview",
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final plan = extra?['plan'] as Plan?;
                      final seriesId = extra?['seriesId'] as String?;
                      if (plan == null) {
                        throw Exception('Missing required parameters');
                      }
                      return PlanPreviewDetails(plan: plan, seriesId: seriesId);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: "series/:id",
                name: "home-series-detail",
                // Root navigator so this full-screen detail can be pushed from
                // root-level routes (e.g. /practice/bookmarks) without
                // go_router inserting a second /home shell page and hitting a
                // duplicate page key. Mirrors home-timer-active.
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  final extra = state.extra as Map<String, dynamic>?;
                  final groupId = extra?['groupId'] as String?;
                  final groupType = extra?['groupType'] as GroupType?;
                  final isGroupEnrolled =
                      extra?['isGroupEnrolled'] as bool? ?? false;
                  final series = extra?['series'] as Series?;
                  return SeriesDetailScreen(
                    seriesId: id,
                    initialSeries: series,
                    groupId: groupId,
                    groupType: groupType,
                    isGroupEnrolled: isGroupEnrolled,
                  );
                },
                routes: [
                  GoRoute(
                    path: "info",
                    name: "home-series-info",
                    // Must share the parent's (root) navigator so detail → info
                    // stays on one navigator.
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return SeriesInfoScreen(seriesId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: "group/:groupId/recitation-collections/:collectionId",
                name: "home-group-recitation-collection",
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId'] ?? '';
                  final collectionId =
                      state.pathParameters['collectionId'] ?? '';
                  final extra = state.extra as Map<String, dynamic>?;
                  return GroupRecitationCollectionScreen(
                    groupId: groupId,
                    collectionId: collectionId,
                    initialTitle: extra?['title'] as String?,
                  );
                },
              ),
              GoRoute(
                path: "recitation-collection/:collectionId",
                name: "recitation-collection",
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final collectionId =
                      state.pathParameters['collectionId'] ?? '';
                  final extra = state.extra as Map<String, dynamic>?;
                  return GroupRecitationCollectionScreen(
                    groupId: '',
                    collectionId: collectionId,
                    initialTitle: extra?['title'] as String?,
                  );
                },
              ),
              GoRoute(
                path: "my-recitation-collection/:collectionId",
                name: "my-recitation-collection",
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final collectionId =
                      state.pathParameters['collectionId'] ?? '';
                  final extra = state.extra as Map<String, dynamic>?;
                  return MyRecitationCollectionScreen(
                    collectionId: collectionId,
                    initialTitle: extra?['title'] as String?,
                  );
                },
              ),
              GoRoute(
                path: "group/:groupId",
                name: "home-group-profile",
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId'] ?? '';
                  return GroupProfileScreen(groupId: groupId);
                },
              ),
              GoRoute(
                path: "group-accumulator/:accumulatorId",
                name: "home-group-accumulator",
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final accumulatorId =
                      state.pathParameters['accumulatorId'] ?? '';
                  final extra = state.extra as Map<String, dynamic>?;
                  final groupTitle = extra?['groupTitle'] as String?;
                  return GroupAccumulatorScreen(
                    accumulatorId: accumulatorId,
                    groupTitle: groupTitle,
                  );
                },
              ),
              GoRoute(
                path: "group-events",
                name: "home-group-events",
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const GroupEventsScreen(),
              ),
              GoRoute(
                path: "events/:eventId",
                name: "home-group-event",
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final eventId = state.pathParameters['eventId'] ?? '';
                  return GroupEventDetailScreen(eventId: eventId);
                },
              ),
              GoRoute(
                path: "poems",
                name: "home-poems",
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final initialPoemId =
                      extra?['initialPoemId'] as String? ??
                      state.uri.queryParameters['poemId'];
                  return PoemsViewerScreen(initialPoemId: initialPoemId);
                },
              ),
              GoRoute(
                path: "posts/:postId",
                name: "home-connect-post",
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final postId = state.pathParameters['postId'] ?? '';
                  final extra = state.extra as Map<String, dynamic>?;
                  final post = extra?['post'] as ConnectPost?;
                  final includeUnfollowed =
                      extra?['includeUnfollowed'] as bool? ?? false;
                  return ConnectPostDetailScreen(
                    postId: postId,
                    initialPost: post,
                    includeUnfollowed: includeUnfollowed,
                  );
                },
              ),
              GoRoute(
                path: "timers",
                name: "home-timers",
                builder: (context, state) => const PresetTimersScreen(),
                routes: [
                  GoRoute(
                    path: "active",
                    name: "home-timer-active",
                    // Root navigator so this works when my-practices (or any
                    // root-pushed route) is already on the stack above /home.
                    // Without this, go_router inserts a second /home shell page
                    // and hits duplicate page keys.
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final timer = state.extra as PresetTimer?;
                      if (timer == null) {
                        throw Exception('Missing preset timer');
                      }
                      return ActiveTimerScreen(presetTimer: timer);
                    },
                  ),
                ],
              ),
              // settings route
              GoRoute(
                path: "settings",
                name: "home-settings",
                builder: (context, state) => const MoreScreen(),
              ),
              // calendar route
              GoRoute(
                path: "calendar",
                name: "home-calendar",
                builder: (context, state) => const TibetanCalendarScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: "notifications",
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: "profile",
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.about,
            name: "about",
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: AppRoutes.legal,
            name: "legal",
            builder: (context, state) => const LegalScreen(),
          ),
          GoRoute(
            path: AppRoutes.termsOfService,
            name: "terms-of-service",
            builder: (context, state) => const TermsOfServiceScreen(),
          ),
          GoRoute(
            path: AppRoutes.privacyPolicy,
            name: "privacy-policy",
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),
          GoRoute(
            path: AppRoutes.deleteAccount,
            name: "delete-account",
            builder: (context, state) => const DeleteAccountScreen(),
          ),
        ],
      ),

      // ai mode route
      GoRoute(
        path: "/ai-mode",
        name: "ai-mode",
        builder: (context, state) => const AiModeScreen(),
        routes: [
          // route - /ai-mode/search-results
          GoRoute(
            path: "search-results", // route - /ai-mode/search-results
            name: "search-results",
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final query = extra?['query'] as String? ?? '';
              return SearchResultsScreen(initialQuery: query);
            },
            routes: [
              GoRoute(
                path: "text-chapters", // /ai-mode/search-results/text-chapters
                name: "text-chapters",
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final textId = extra?['textId'] as String? ?? '';
                  final segmentId = extra?['segmentId'] as String?;
                  return ChaptersScreen(textId: textId, segmentId: segmentId);
                },
              ),
            ],
          ),
        ],
      ),

      // mala route (login-gated digital prayer beads)
      GoRoute(
        path: AppRoutes.mala,
        name: "mala",
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MalaScreen(
            initialPresetId: extra?['presetId'] as String?,
            initialGroupAccumulatorId: extra?['groupAccumulatorId'] as String?,
          );
        },
      ),

      // Practice routes are flat top-level siblings (not nested under /practice)
      // so child navigations do not also push a parent /practice page onto the
      // root navigator — that duplicate page key caused crashes when returning
      // from edit-routine to my-practices (RoutineFilledState transition).
      GoRoute(
        path: "/practice",
        name: "practice",
        builder: (context, state) => const PracticeExploreScreen(),
      ),
      GoRoute(
        path: "/practice/my-practices",
        name: "my-practices",
        builder: (context, state) => const PracticeScreen(showAppBar: true),
      ),
      GoRoute(
        path: "/practice/edit-routine",
        name: "edit-routine",
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final plan = extra?['initialPlan'] as Plan?;
          final recitation = extra?['initialRecitation'] as RecitationModel?;
          final series = extra?['initialSeries'] as Series?;
          final mantra = extra?['initialMantra'] as Mantra?;
          final enrollSeriesId = extra?['enrollSeriesId'] as String?;
          final timer = extra?['initialTimer'] as PresetTimer?;
          final groupCollection =
              extra?['initialGroupCollection'] as GroupRecitationCollection?;
          final myCollection =
              extra?['initialMyCollection']
                  as MyRecitationCollectionDetailModel?;
          final groupAccumulator =
              extra?['initialGroupAccumulator'] as GroupAccumulator?;
          return EditRoutineScreen(
            initialPlan: plan,
            initialRecitation: recitation,
            initialTimer: timer,
            initialSeries: series,
            initialMantra: mantra,
            enrollSeriesId: enrollSeriesId,
            initialGroupCollection: groupCollection,
            initialMyCollection: myCollection,
            initialGroupAccumulator: groupAccumulator,
          );
        },
        routes: [
          GoRoute(
            path: "select-plan",
            name: "select-plan",
            builder: (context, state) => const SelectPlanScreen(),
          ),
          GoRoute(
            path: "select-recitation",
            name: "select-recitation",
            builder: (context, state) => const SelectRecitationScreen(),
          ),
        ],
      ),
      GoRoute(
        path: "/practice/bookmarks",
        name: "bookmarks",
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: "/practice/details",
        name: "practice-plan-details",
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final plan = extra?['plan'] as UserPlansModel?;
          final selectedDay = extra?['selectedDay'] as int?;
          final startDate = extra?['startDate'] as DateTime?;
          final seriesId = extra?['seriesId'] as String?;
          final eventId = extra?['eventId'] as String?;
          if (plan == null) {
            throw Exception('Missing required parameters');
          }
          return PlanDetails(
            plan: plan,
            selectedDay: selectedDay ?? 1,
            startDate: startDate ?? DateTime.now(),
            seriesId: seriesId,
            eventId: eventId,
          );
        },
      ),
      GoRoute(
        path: "/practice/plans/preview",
        name: "practice-plan-preview",
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final plan = extra?['plan'] as Plan?;
          final seriesId = extra?['seriesId'] as String?;
          final selectedDay = extra?['selectedDay'] as int?;
          if (plan == null) {
            throw Exception('Missing required parameters');
          }
          return PlanPreviewDetails(
            plan: plan,
            seriesId: seriesId,
            initialDay: selectedDay,
          );
        },
      ),
      GoRoute(
        path: "/practice/plans/info",
        name: "practice-plan-info",
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final plan = extra?['plan'] as Plan?;
          if (plan == null) {
            throw Exception('Missing required parameters');
          }
          return PlanInfo(plan: plan);
        },
        routes: [
          GoRoute(
            path: "details",
            name: "practice-plan-info-details",
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final plan = extra?['plan'] as UserPlansModel?;
              final selectedDay = extra?['selectedDay'] as int?;
              final startDate = extra?['startDate'] as DateTime?;
              final seriesId = extra?['seriesId'] as String?;
              final eventId = extra?['eventId'] as String?;
              if (plan == null) {
                throw Exception('Missing required parameters');
              }
              return PlanDetails(
                plan: plan,
                selectedDay: selectedDay ?? 1,
                startDate: startDate ?? DateTime.now(),
                seriesId: seriesId,
                eventId: eventId,
              );
            },
          ),
        ],
      ),

      // route - /choose-image (choose image)
      GoRoute(
        path: "/choose-image",
        name: "choose-image",
        builder: (context, state) {
          final extra = state.extra as String?;
          if (extra == null) {
            throw Exception('Missing required parameters');
          }
          return ChooseImage(text: extra);
        },
      ),
      // route - /create-image (create image)
      GoRoute(
        path: "/create-image",
        name: "create-image",
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CreateImage(
            text: extra?['text'] as String,
            imagePath: extra?['imagePath'] as String,
          );
        },
      ),

      // plan content route - inline TEXT/IMAGE subtasks (sibling to /reader)
      GoRoute(
        path: "/plan-text/:subtaskId",
        name: "plan-text",
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is! NavigationContext) {
            _logger.warning(
              'plan-text route called without NavigationContext extra',
            );
            return const MaterialPage(child: MainNavigationScreen());
          }

          return CustomTransitionPage(
            key: state.pageKey,
            child: PlanTextScreen(navigationContext: extra),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return buildPlanNavigationTransition(
                context,
                animation,
                secondaryAnimation,
                child,
                extra.navigationDirection,
              );
            },
          );
        },
      ),

      // reader route - new refactored text reader
      GoRoute(
        path: "/reader/:textId",
        name: "reader",
        pageBuilder: (context, state) {
          final textId = state.pathParameters['textId'] ?? '';
          final extra = state.extra;
          String? segmentId =
              state.uri.queryParameters['segment'] ??
              state.uri.queryParameters['segmentId'];

          // Extract navigation context if provided
          NavigationContext? navigationContext;
          if (extra is NavigationContext) {
            navigationContext = extra;
            segmentId = extra.targetSegmentId;
          } else if (extra is Map<String, dynamic>) {
            // Support passing as map for flexibility
            segmentId = extra['segmentId'] as String?;
            final sourceStr = extra['source'] as String?;
            final planTextItems = extra['planTextItems'] as List<PlanTextItem>?;
            final currentTextIndex = extra['currentTextIndex'] as int?;

            NavigationSource source = NavigationSource.normal;
            if (sourceStr == 'plan') {
              source = NavigationSource.plan;
            } else if (sourceStr == 'search') {
              source = NavigationSource.search;
            } else if (sourceStr == 'deepLink') {
              source = NavigationSource.deepLink;
            } else if (sourceStr == 'recitationList') {
              source = NavigationSource.recitationList;
            } else if (sourceStr == 'routine') {
              source = NavigationSource.routine;
            } else if (sourceStr == 'groupAccumulatorChant') {
              source = NavigationSource.groupAccumulatorChant;
            } else if (sourceStr == 'groupRecitationCollection') {
              source = NavigationSource.groupRecitationCollection;
            } else if (sourceStr == 'myRecitationCollection') {
              source = NavigationSource.myRecitationCollection;
            }

            navigationContext = NavigationContext(
              source: source,
              targetSegmentId: segmentId,
              planTextItems: planTextItems,
              currentTextIndex: currentTextIndex ?? 0,
              groupAccumulatorId: extra['groupAccumulatorId'] as String?,
              presetAccumulatorId: extra['presetAccumulatorId'] as String?,
              groupId: extra['groupId'] as String?,
              groupTitle: extra['groupTitle'] as String?,
              groupAccumulatorSessionCount:
                  extra['groupAccumulatorSessionCount'] as int?,
              language: extra['language'] as String?,
              collectionId: extra['collectionId'] as String?,
            );
          } else if (segmentId != null && segmentId.isNotEmpty) {
            navigationContext = NavigationContext(
              source: NavigationSource.deepLink,
              targetSegmentId: segmentId,
            );
          }

          final screen = ReaderScreen(
            textId: textId,
            navigationContext: navigationContext,
            segmentId: segmentId,
          );

          // Use directional transition for plan navigation
          if (navigationContext != null &&
              (navigationContext.source == NavigationSource.plan ||
                  navigationContext.source ==
                      NavigationSource.groupRecitationCollection ||
                  navigationContext.source ==
                      NavigationSource.myRecitationCollection)) {
            final direction = navigationContext.navigationDirection;
            return CustomTransitionPage(
              key: state.pageKey,
              child: screen,
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return buildPlanNavigationTransition(
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                  direction,
                );
              },
            );
          }

          // Default MaterialPage for non-plan navigation
          return MaterialPage(key: state.pageKey, child: screen);
        },
        routes: [
          // route - /reader/:textId/versions (version selection)
          GoRoute(
            path: "versions",
            name: "reader-versions",
            builder: (context, state) {
              final textId = state.pathParameters['textId'] ?? '';
              return VersionSelectionScreen(textId: textId);
            },
            routes: [
              // route - /reader/:textId/versions/language (language selection)
              GoRoute(
                path: "language",
                name: "reader-versions-language",
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final uniqueLanguages =
                      extra?['uniqueLanguages'] as List<String>?;
                  return LanguageSelectionScreen(
                    uniqueLanguages: uniqueLanguages ?? [],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],

    // Error handling for invalid routes
    errorBuilder: (context, state) {
      _logger.warning('Route error: ${state.error}');
      return const MainNavigationScreen();
    },
  );
});

/// This allows the router to automatically refresh when auth state changes,
/// triggering redirect logic to re-evaluate route access permissions.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListener = () => notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListener());
  }

  late final void Function() notifyListener;
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
