import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/services/service_providers.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/featured_series_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/home_group_events_preview_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/routine_info_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/streak_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/today_events_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/verse_of_day_provider.dart';
import 'package:flutter_pecha/features/home/presentation/home_screen_constants.dart';
import 'package:flutter_pecha/features/home/presentation/utils/home_analytics.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/featured_plan_section.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/group_events_section.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/home_header.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/home_share_prompt.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/home_shortcuts_row.dart';
import 'package:flutter_pecha/features/home/presentation/providers/home_poems_preview_provider.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/poems_section.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/my_practices_stats_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/my_practices_stats_card_skeleton.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_of_day_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_of_day_skeleton.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('HomeScreen');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasRequestedPermissions = false;

  // For proper keyboard dismissal with SearchAnchor
  final FocusScopeNode _searchFocusScopeNode = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    _trackHomeViewed();
    // Request notification permissions when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermissionsIfNeeded();
    });
  }

  /// Once per mount of the Home tab, with what the providers already hold.
  void _trackHomeViewed() {
    final streak = ref.read(streakFutureProvider).valueOrNull;
    ref
        .read(homeAnalyticsProvider)
        .homeViewed(
          hasRoutine: ref.read(routineProvider).hasItems,
          streakCurrent: streak?.fold<int?>((_) => null, (days) => days),
          isGuest: ref.read(authProvider).isGuest,
        );
  }

  @override
  void dispose() {
    _searchFocusScopeNode.dispose();
    super.dispose();
  }

  Future<void> _requestNotificationPermissionsIfNeeded() async {
    _log.info(
      '[HOME-SCREEN] _requestNotificationPermissionsIfNeeded ENTER '
      'hasRequested=$_hasRequestedPermissions',
    );
    if (_hasRequestedPermissions) return;
    _hasRequestedPermissions = true;

    // Capture the root ProviderContainer BEFORE any await. The OS permission
    // dialog backgrounds the app and may dispose this State by the time we
    // resume — `ref` becomes unusable but the container lives for the whole
    // app, so post-permission scheduling still fires either way.
    final container = ProviderScope.containerOf(context, listen: false);

    final notificationService = container.read(notificationServiceProvider);
    if (notificationService == null) {
      _log.warning(
        '[HOME-SCREEN] NotificationService not initialized, skipping permission request',
      );
      if (mounted) _navigateToPendingPlanIfNeeded();
      return;
    }

    try {
      // Check if permissions are already granted
      final alreadyEnabled =
          await notificationService.areNotificationsEnabled();
      _log.info('[HOME-SCREEN] alreadyEnabled=$alreadyEnabled');
      if (!alreadyEnabled) {
        _log.info('[HOME-SCREEN] requesting notification permissions...');
        final granted = await notificationService.requestPermission();
        _log.info('[HOME-SCREEN] permission request result granted=$granted');
      }
    } catch (e) {
      _log.warning(
        '[HOME-SCREEN] error requesting notification permissions: $e',
      );
    }

    // Permission flow has run — fire any pending special-plan Day 1
    // notifications now (e.g. user just enrolled in ITCC during onboarding
    // after 09:00). Without permission, `_plugin.show()` silently no-ops, so
    // this MUST run after the permission request above.
    await _firePendingSpecialPlanDay1IfNeeded(container);

    if (!mounted) return;

    // After the permission flow (dialog shown or already granted), check
    // whether onboarding left a plan waiting to be opened in Practice.
    _navigateToPendingPlanIfNeeded();
  }

  Future<void> _firePendingSpecialPlanDay1IfNeeded(
    ProviderContainer container,
  ) async {
    // Use [container], NOT `this.ref` — see the comment in the caller.
    // Invalidate first — the provider may have been evaluated pre-login
    // (no auth header) and cached a Forbidden failure. We need a fresh read.
    _log.info('invalidating userPlansFutureProvider for fresh fetch');
    container.invalidate(userPlansFutureProvider);

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      _log.info('fetch attempt $attempt/$maxAttempts');
      try {
        final userPlansAsync = await container.read(
          userPlansFutureProvider.future,
        );
        final isFailure = userPlansAsync.isLeft();
        _log.info('attempt $attempt resolved isFailure=$isFailure');
        if (isFailure && attempt < maxAttempts) {
          _log.warning(
            'attempt $attempt failed — invalidating and retrying: '
            '${userPlansAsync.fold((f) => f, (_) => "")}',
          );
          container.invalidate(userPlansFutureProvider);
          await Future.delayed(const Duration(milliseconds: 400));
          continue;
        }
        await userPlansAsync.fold(
          (failure) async {
            _log.warning(
              'giving up after $attempt attempts — fetch failed: $failure',
            );
          },
          (response) async {
            _log.info(
              'user plans loaded count=${response.userPlans.length} '
              'on attempt=$attempt — triggering engine sync (appLaunch)',
            );
            // Permission may have just been granted; trigger a sync so
            // catch-up immediates fire now that `plugin.show()` works.
            await container
                .read(notificationSyncEngineProvider)
                .sync(trigger: SyncTrigger.appLaunch);
          },
        );
        break;
      } catch (e, st) {
        _log.warning('attempt $attempt threw: $e\n$st');
        if (attempt < maxAttempts) {
          container.invalidate(userPlansFutureProvider);
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    }
    _log.info('_firePendingSpecialPlanDay1IfNeeded EXIT');
  }

  /// Consumes [pendingOnboardingPlanProvider] and navigates to the Practice
  /// tab + plan detail screen. Called once, right after notification setup.
  void _navigateToPendingPlanIfNeeded() {
    if (!mounted) return;
    final plan = ref.read(pendingOnboardingPlanProvider);
    if (plan == null) return;

    // Clear immediately so back-navigation never re-triggers this.
    ref.read(pendingOnboardingPlanProvider.notifier).state = null;

    // Push plan details FIRST while HomeScreen is still mounted.
    // Switching the tab index BEFORE the push would unmount HomeScreen,
    // making the subsequent context.push a no-op.
    final anchor = plan.effectiveStartDate;
    final selectedDay = PlanUtils.dayNumberFor(
      anchor,
      DateTime.now(),
      plan.totalDays,
    ).clamp(1, plan.totalDays);
    _log.info(
      '[ENROLL-NAV] onboarding open ${plan.id} '
      'anchor=${anchor.toIso8601String()} '
      'startDate=${plan.startDate?.toIso8601String()} '
      'startedAt=${plan.startedAt.toIso8601String()} '
      'selectedDay=$selectedDay/${plan.totalDays}',
    );
    context.push(
      '/practice/details',
      extra: {'plan': plan, 'selectedDay': selectedDay, 'startDate': anchor},
    );

    // Switch bottom-nav to Practice so popping back from plan details
    // lands on the Practice tab rather than Home.
    ref.read(mainNavigationIndexProvider.notifier).state =
        MainTab.practice.index;
  }

  /// Pull-to-refresh handler. Invalidates the series list and verse of day,
  /// then awaits the refreshed results so the spinner stays until data lands.
  Future<void> _onRefresh() async {
    ref.invalidate(seriesListFutureProvider);
    ref.invalidate(featuredSeriesFutureProvider);
    ref.invalidate(homeGroupEventsPreviewProvider);
    ref.invalidate(homePoemsPreviewProvider);
    ref.invalidate(verseOfDayFutureProvider);
    ref.invalidate(todayEventsFutureProvider);
    ref.invalidate(routineInfoFutureProvider);
    ref.invalidate(streakFutureProvider);
    await Future.wait([
      ref.read(seriesListFutureProvider.future),
      ref.read(featuredSeriesFutureProvider.future),
      ref.read(homeGroupEventsPreviewProvider.future),
      ref.read(homePoemsPreviewProvider.future),
      ref.read(verseOfDayFutureProvider.future),
      ref.read(todayEventsFutureProvider.future),
      ref.read(routineInfoFutureProvider.future),
    ]);
  }

  /// Opens a login-only feature shortcut (Mala, Timer). Guests are prompted to
  /// sign in via the login drawer instead of navigating, since these features
  /// need an authenticated account to persist progress.
  void _openGatedFeature(String route) {
    if (ref.read(authProvider).isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }
    context.push(route);
  }

  void _navigateToSeries(Series series) {
    context.pushNamed(
      'home-series-detail',
      pathParameters: {'id': series.id},
      extra: {'series': series},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(userProvider).user;
    final firstName = user?.firstName ?? user?.username;
    final hasName = firstName?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: HomeTabAppBar(
        toolbarHeight: HomeTabAppBar.toolbarHeightFor(
          context: context,
          hasName: hasName,
        ),
        firstName: firstName,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [const HomeEventBanner(), _buildBody(context, l10n)],
      ),
    );
  }

  Widget _buildMyPracticesSection() {
    final routineInfoAsync = ref.watch(routineInfoFutureProvider);

    return routineInfoAsync.when(
      data: (infoEither) {
        return infoEither.fold((_) => const SizedBox.shrink(), (info) {
          if (info.seriesCount == 0 && info.recitationCount == 0) {
            return const SizedBox.shrink();
          }
          return MyPracticesStatsCard(
            routineInfo: info,
            onTap: () => context.pushNamed('my-practices'),
          );
        });
      },
      loading: () => const MyPracticesStatsCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildVerseOfDaySection() {
    final verseAsync = ref.watch(verseOfDayFutureProvider);

    return verseAsync.when(
      data: (verseEither) {
        return verseEither.fold(
          (_) => const SizedBox.shrink(),
          (verse) => VerseOfDayCard(verseOfDay: verse),
        );
      },
      loading: () => const VerseOfDaySkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations localizations) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildVerseOfDaySection(),
                  const SizedBox(height: HomeScreenConstants.cardSpacing),
                  HomeShortcutsRow(
                    onTimerTap: () => _openGatedFeature('/home/timers'),
                    onMalaTap: () => _openGatedFeature('/mala'),
                  ),
                  const SizedBox(height: HomeScreenConstants.cardSpacing),
                  _buildMyPracticesSection(),
                  const SizedBox(height: HomeScreenConstants.cardSpacing),
                  FeaturedPlanSection(
                    onSeriesTap: (series) {
                      _log.info('Featured series tapped: ${series.id}');
                      _navigateToSeries(series);
                    },
                  ),
                  const SizedBox(height: HomeScreenConstants.cardSpacing),
                  const GroupEventsSection(),
                  const SizedBox(height: HomeScreenConstants.cardSpacing),
                  const PoemsSection(),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: HomeSharePrompt()),
          ],
        ),
      ),
    );
  }
}
