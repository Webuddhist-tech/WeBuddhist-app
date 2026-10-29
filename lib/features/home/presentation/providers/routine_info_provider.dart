import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/home/domain/entities/routine_info.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

// Stored routine info is the first state for the signed-in user.
final routineInfoFutureProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<RoutineInfo, Either<Failure, RoutineInfo>>,
  Either<Failure, RoutineInfo>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final auth = ref.watch(authProvider);
    if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final local = ref.watch(homeLocalDatasourceProvider);
    final userId = local.currentUserIdSync;
    final stored =
        userId == null ? null : local.readRoutineInfo(userId)?.toEntity();
    return bind.stream(
      stored == null ? null : Right(stored),
      ref.watch(routineInfoDomainRepositoryProvider).watchRoutineInfo(),
    );
  });
});
