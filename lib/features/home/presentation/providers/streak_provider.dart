import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

// Stored streak is the first state for the signed-in user.
final streakFutureProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<int, Either<Failure, int>>,
  Either<Failure, int>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final auth = ref.watch(authProvider);
    if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final local = ref.watch(homeLocalDatasourceProvider);
    final userId = local.currentUserIdSync;
    final stored = userId == null ? null : local.readStreak(userId);
    return bind.stream(
      stored == null ? null : Right(stored),
      ref.watch(streakDomainRepositoryProvider).watchStreak(),
    );
  });
});
