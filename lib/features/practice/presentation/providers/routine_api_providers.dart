import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/repositories/routine_repository.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/routine_api_repository.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/routine_api_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Infrastructure providers ───

final routineRemoteDatasourceProvider = Provider<RoutineRemoteDatasource>((ref) {
  return RoutineRemoteDatasource(dio: ref.watch(dioProvider));
});

final routineApiRepositoryProvider = Provider<RoutineApiRepository>((ref) {
  return RoutineApiRepositoryImpl(
    datasource: ref.watch(routineRemoteDatasourceProvider),
    store: ref.watch(screenCacheStoreProvider),
  );
});

// ─── Use case providers ───

final getUserRoutineUseCaseProvider = Provider<GetUserRoutineUseCase>((ref) {
  return GetUserRoutineUseCase(ref.watch(routineApiRepositoryProvider));
});

final createRoutineWithTimeBlockUseCaseProvider =
    Provider<CreateRoutineWithTimeBlockUseCase>((ref) {
  return CreateRoutineWithTimeBlockUseCase(
    ref.watch(routineApiRepositoryProvider),
  );
});

final createTimeBlockUseCaseProvider = Provider<CreateTimeBlockUseCase>((ref) {
  return CreateTimeBlockUseCase(ref.watch(routineApiRepositoryProvider));
});

final updateTimeBlockUseCaseProvider = Provider<UpdateTimeBlockUseCase>((ref) {
  return UpdateTimeBlockUseCase(ref.watch(routineApiRepositoryProvider));
});

final deleteTimeBlockUseCaseProvider = Provider<DeleteTimeBlockUseCase>((ref) {
  return DeleteTimeBlockUseCase(ref.watch(routineApiRepositoryProvider));
});

// ─── Data providers ───

/// The user's routine: stored copy first, refreshed in the background; null
/// for guests. Pull-to-refresh calls `refreshUserRoutine`; `ref.invalidate`
/// after a mutation still works (stored → fresh).
final userRoutineProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<RoutineData, RoutineData?>,
  RoutineData?
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final auth = ref.watch(authProvider);
    if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) return null;

    final language = ref.watch(contentLanguageProvider);
    final source = ref
        .watch(routineApiRepositoryProvider)
        .userRoutineSource(language: language);
    if (source == null) return null;
    return bind.source(
      source,
      select:
          (result) => result.fold(
            (failure) => throw Exception(failure.message),
            (data) => data,
          ),
    );
  });
});
