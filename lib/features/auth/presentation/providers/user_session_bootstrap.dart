import 'package:flutter_pecha/core/network/interceptors/cache_interceptor.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/home/presentation/providers/routine_info_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/streak_provider.dart';
import 'package:flutter_pecha/features/more/presentation/providers/user_stats_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void _invalidateUserScopedProviders(Ref ref) {
  ref.invalidate(userRoutineProvider);
  ref.invalidate(userPlansFutureProvider);
  ref.invalidate(myPlansPaginatedProvider);
  ref.invalidate(bookmarkExistsCacheProvider);
  ref.invalidate(streakFutureProvider);
  ref.invalidate(userStatsFutureProvider);
  ref.invalidate(routineInfoFutureProvider);
}

/// Keeps user-scoped HTTP cache and Riverpod providers in sync with auth
/// transitions so a different account never inherits the prior user's data.
final userSessionBootstrapProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authProvider, (previous, next) {
    final wasAuthenticated =
        previous?.isLoggedIn == true && previous?.isGuest != true;
    final isAuthenticated = next.isLoggedIn && !next.isGuest;

    if (wasAuthenticated == isAuthenticated) return;

    ref.read(cacheInterceptorProvider).clearUserScoped();
    _invalidateUserScopedProviders(ref);

    // In-app login (e.g. from the Me tab) keeps the current shell route (/home)
    // but should land on Home, not stay on the tab where sign-in was triggered.
    if (!wasAuthenticated && isAuthenticated) {
      ref.read(mainNavigationIndexProvider.notifier).state =
          MainTab.home.index;
    }
  });
});
