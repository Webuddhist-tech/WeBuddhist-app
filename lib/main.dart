import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/analytics/posthog_analytics_service.dart';
import 'package:flutter_pecha/core/cache/cache_service.dart';
import 'package:flutter_pecha/core/config/app_feature_flags.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/deep_linking/app_links_deep_link_service.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/l10n/l10n.dart';
import 'package:flutter_pecha/core/services/airbridge_deep_link_service.dart';
import 'package:flutter_pecha/core/services/service_providers.dart';
import 'package:flutter_pecha/core/theme/theme_notifier.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/models/notification_nav.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_bootstrap.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/push_notifications/application/push_notification_service.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/providers/push_notification_providers.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_local_datasource.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_session_bootstrap.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/more/data/datasource/user_stats_local_datasource.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_local_datasource.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_local_storage.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart';
import 'package:flutter_pecha/features/timer/data/datasource/timers_local_datasource.dart';
import 'package:flutter_pecha/features/timer/presentation/providers/timers_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_localizations_delegate.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_service.dart';
import 'package:fquery/fquery.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/material_localizations_bo.dart';
import 'core/localization/cupertino_localizations_bo.dart';
import 'package:flutter_pecha/core/services/upgrade/force_update_gate.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:airbridge_flutter_sdk/airbridge_flutter_sdk.dart';

final _logger = AppLogger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait only; the live player switches to landscape for fullscreen.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await PostHogAnalyticsService.create().initialize();
    _logger.info('Analytics initialized');
  } catch (e) {
    _logger.warning('Error initializing analytics: $e');
  }

  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Register the FCM background/terminated-state handler. Must be done before
  // runApp and references a top-level function so it survives AOT and runs in
  // its own isolate.
  FirebaseMessaging.onBackgroundMessage(pushNotificationBackgroundHandler);

  // Setup environment-aware logging
  AppLogger.init();

  // Enable Google Fonts runtime fetching for automatic font management
  // Fonts are downloaded once and cached locally for offline use
  GoogleFonts.config.allowRuntimeFetching = true;

  // Note: .env files are loaded by flavor-specific entry points (main_dev.dart, main_staging.dart, main_prod.dart)

  // Initialize cache service for offline-first data
  try {
    await CacheService.instance.initialize();
    _logger.info('Cache service initialized');
  } catch (e) {
    _logger.warning('Error initializing cache service: $e');
    // Continue app initialization even if cache fails
  }

  // Initialize connectivity service for offline detection
  try {
    await ConnectivityService.instance.initialize();
    _logger.info('Connectivity service initialized');
  } catch (e) {
    _logger.warning('Error initializing connectivity service: $e');
    // Continue app initialization even if connectivity check fails
  }

  // Cancel any previously scheduled notifications in Coming Soon mode
  if (AppFeatureFlags.kComingSoonMode) {
    try {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      await notificationsPlugin.cancelAll();
      _logger.info(
        'Cancelled all scheduled notifications for Coming Soon mode',
      );
    } catch (e) {
      _logger.warning('Error cancelling notifications: $e');
    }
  }

  // Initialize notification service early so scheduled notifications can fire
  // even when the app is in the background or was just launched from a tap.
  try {
    await NotificationService().initializeWithoutPermissions();
    _logger.info('Notification service initialized');
  } catch (e) {
    _logger.warning('Error initializing notification service: $e');
  }

  // Initialize routine local storage (persistent user data, not cache)
  final routineStorage = RoutineLocalStorage();
  try {
    await routineStorage.initialize();
    _logger.info('Routine local storage initialized');
  } catch (e) {
    _logger.warning('Error initializing routine local storage: $e');
  }

  // Initialize mala counts local storage (per-user namespaced, not cache)
  try {
    await MalaLocalDataSource.init();
    _logger.info('Mala local storage initialized');
  } catch (e) {
    _logger.warning('Error initializing mala local storage: $e');
  }

  // Initialize Home local storage (source of truth for local-first Home).
  try {
    await HomeLocalDatasource.init();
    _logger.info('Home local storage initialized');
  } catch (e) {
    _logger.warning('Error initializing home local storage: $e');
  }

  // Initialize Me stats local storage (source of truth for local-first stats).
  try {
    await UserStatsLocalDatasource.init();
    _logger.info('Me stats local storage initialized');
  } catch (e) {
    _logger.warning('Error initializing me stats local storage: $e');
  }

  // Initialize Timer local storage (source of truth for local-first timers).
  try {
    await TimersLocalDatasource.init();
    _logger.info('Timer local storage initialized');
  } catch (e) {
    _logger.warning('Error initializing timer local storage: $e');
  }

  // Initialize Plans local storage (source of truth for local-first plans).
  try {
    await PlansLocalDatasource.init();
    _logger.info('Plans local storage initialized');
  } catch (e) {
    _logger.warning('Error initializing plans local storage: $e');
  }

  // Create provider container for routine storage
  final container = ProviderContainer(
    overrides: [routineLocalStorageProvider.overrideWithValue(routineStorage)],
  );

  // Set container reference for notification navigation
  NotificationService.setContainer(container);

  // Initialize Airbridge deep link handler
  try {
    Airbridge.setOnDeeplinkReceived((url) {
      _logger.info('Airbridge deep link received: $url');
      AirbridgeDeepLinkService.storePendingDeepLink(url);
    });
    _logger.info('Airbridge deep link handler initialized');
  } catch (e) {
    _logger.warning('Error initializing Airbridge deep link handler: $e');
  }

  try {
    await AppLinksDeepLinkService.instance.initialize();
  } catch (e) {
    _logger.warning('Error initializing app links handler: $e');
  }

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool _hasRegisteredDeepLinkRouters = false;
  bool _hasDrainedInitialAppLink = false;
  bool _hasConsumedLaunchNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Deliberately not awaited in main(): the first frame renders with the
    // bundled ARB strings and swaps to the Tolgee versions once they arrive,
    // so a slow or unreachable CDN can never delay app startup.
    unawaited(_bootstrapTolgee());
  }

  Future<void> _bootstrapTolgee() async {
    // localeProvider starts on the default language and only reaches the stored
    // one after a storage read, so fetching before that would pull the wrong
    // language. This also covers a restore that lands before build() registers
    // the localeProvider listener, which nothing downstream could recover from.
    await ref.read(localeProvider.notifier).ensureInitialized();
    if (!mounted) return;
    final bool ready = await TolgeeService.initialize(
      locale: ref.read(localeProvider),
    );
    if (!ready || !mounted) return;
    ref.read(tolgeeRevisionProvider.notifier).state++;
  }

  Future<void> _applyTolgeeLocale(Locale locale) async {
    final bool changed = await TolgeeService.setLocale(locale);
    if (!changed || !mounted) return;
    ref.read(tolgeeRevisionProvider.notifier).state++;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reconcile on every foreground return, wherever the user is in the
      // app: picks up OS permission changes, timezone moves, and day
      // rollovers. The engine is idempotent and serialises concurrent
      // triggers, so overlapping with screen-level resume syncs is safe.
      ref
          .read(notificationSyncEngineProvider)
          .sync(trigger: SyncTrigger.appResume);
      unawaited(
        ref.read(timersDomainRepositoryProvider).flushPendingTimerStops(),
      );
      unawaited(
        ref.read(userPlansDomainRepositoryProvider).flushPendingPlanActions(),
      );
      // Retry FCM initialization if a previous attempt failed (e.g. transient
      // Firebase error on cold start). No-op once _initialized is true.
      unawaited(ref.read(pushNotificationServiceProvider).initialize());
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);
    final tolgeeRevision = ref.watch(tolgeeRevisionProvider);

    // Tolgee holds one language in memory at a time, so a UI language change
    // has to trigger a fetch for the newly selected one.
    ref.listen<Locale>(localeProvider, (previous, next) {
      if (previous == next) return;
      unawaited(_applyTolgeeLocale(next));
    });

    // Get the singleton router instance - same instance is reused across rebuilds
    // final router = AppRouter().router;
    final router = ref.watch(appRouterProvider);

    // Register the router once so both deep-link sources can drain links that
    // arrived during cold start and dispatch warm links immediately afterward.
    if (!_hasRegisteredDeepLinkRouters) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AirbridgeDeepLinkService.setRouter(router);
        AppLinksDeepLinkService.instance.setRouter(router);
        AppLinksDeepLinkService.instance.setTabSetter((int tabIndex) {
          ref.read(mainNavigationIndexProvider.notifier).state = tabIndex;
        });
        // Plan deep links resolve the specific plan the same way a PLAN push
        // does: seed the pending nav, switch to the Practice tab, then open My
        // Practices where RoutineFilledState resolves the plan + current day
        // and pushes /practice/details.
        AppLinksDeepLinkService.instance.setPlanNavigator(
          (String planId, int? dayNumber, String? planLanguage) {
            ref.read(pendingNotificationNavProvider.notifier).state =
                NotificationNav(
                  itemId: planId,
                  itemType: RoutineItemType.plan.name,
                  planId: planId,
                  dayNumber: dayNumber,
                  planLanguage: planLanguage,
                );
            ref.read(mainNavigationIndexProvider.notifier).state =
                MainTab.practice.index;
            router.go(AppRoutes.home);
            router.push(AppRoutes.practiceMyPractices);
          },
        );
      });
      _hasRegisteredDeepLinkRouters = true;
    }

    if (!authState.isLoading && !_hasDrainedInitialAppLink) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppLinksDeepLinkService.instance.drainPendingLink();
        _hasDrainedInitialAppLink = true;
      });
    }

    // Initialize services in background via providers
    ref.watch(audioHandlerProvider);
    ref.watch(notificationServiceProvider);
    // Bootstrap listener — kept alive for the app lifetime. Hydrates the
    // server routine into local Hive on login, then delegates to
    // NotificationSyncEngine to reconcile local recitation/mala/timer
    // reminders. Plan/series reminders are delivered via FCM push.
    ref.watch(notificationSyncBootstrapProvider);
    // Bootstrap FCM: capture/refresh token, register handlers, and register the
    // device token with the backend once the user signs in.
    ref.watch(pushNotificationBootstrapProvider);
    // Mala background sync — kept alive for the app lifetime so offline counts
    // flush on lifecycle/connectivity triggers even off the mala screen.
    ref.watch(malaSyncManagerProvider);
    // Clears user-scoped HTTP cache and invalidates profile/plan providers
    // when auth transitions between accounts.
    ref.watch(userSessionBootstrapProvider);
    // Home background sync — flushes pending local-first writes when
    // connectivity returns.
    ref.watch(homeSyncBootstrapProvider);
    // Timer background sync — flushes pending local-first writes when
    // connectivity returns.
    ref.watch(timerSyncBootstrapProvider);
    // Plans background sync — flushes pending local-first writes when
    // connectivity returns.
    ref.watch(plansSyncBootstrapProvider);
    NotificationService.setRouter(router);
    // Consume a terminated-state launch tap only after auth has settled and a
    // frame has rendered. Firing it during build (or before the async auth
    // redirect resolves) races the router's initial redirect and strands the
    // app on a shell-less /home (no bottom nav). One-shot; mirrors the
    // deep-link drain above. consumeLaunchNotification is itself idempotent.
    if (!authState.isLoading && !_hasConsumedLaunchNotification) {
      _hasConsumedLaunchNotification = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        NotificationService().consumeLaunchNotification();
      });
    }

    // Add QueryClient provider wrapper
    return QueryClientProvider(
      queryClient: QueryClient(
        defaultQueryOptions: DefaultQueryOptions(
          staleDuration: const Duration(
            minutes: 5,
          ), // Data stays fresh for 5 minutes
          cacheDuration: const Duration(
            minutes: 10,
          ), // Cache persists for 10 minutes
          retryCount: 3, // Retry failed queries 3 times
        ),
      ),
      child: MaterialApp.router(
        title: 'WeBuddhist',
        theme: AppTheme.lightTheme(locale),
        darkTheme: AppTheme.darkTheme(locale),
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: [
          MaterialLocalizationsBo.delegate,
          CupertinoLocalizationsBo.delegate,
          // Replaces AppLocalizations.delegate so every `context.l10n` lookup
          // can be overridden from Tolgee at runtime.
          TolgeeAppLocalizationsDelegate(revision: tolgeeRevision),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.all,
        debugShowCheckedModeBanner: false,
        // routerConfig: router,
        routerConfig: router,
        builder:
            (context, child) =>
                ForceUpdateGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
