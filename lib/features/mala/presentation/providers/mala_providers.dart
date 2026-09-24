import 'dart:async';

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_remote_datasource.dart';
import 'package:flutter_pecha/features/mala/data/repositories/mala_repository_impl.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/repositories/mala_repository.dart';
import 'package:flutter_pecha/features/mala/domain/usecases/mala_usecases.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulation_search_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_counter_notifier.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/features/mala/presentation/services/mala_sound_player.dart';
import 'package:flutter_pecha/features/mala/presentation/utils/mala_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

// ============ Data sources ============

final malaRemoteDataSourceProvider = Provider<MalaRemoteDataSource>((ref) {
  return MalaRemoteDataSource(dio: ref.watch(dioProvider));
});

/// Local store is a singleton; the Hive box is opened in app bootstrap.
final malaLocalDataSourceProvider = Provider<MalaLocalDataSource>((ref) {
  return MalaLocalDataSource();
});

// ============ Repository ============

final malaRepositoryProvider = Provider<MalaRepository>((ref) {
  return MalaRepositoryImpl(
    remote: ref.watch(malaRemoteDataSourceProvider),
    local: ref.watch(malaLocalDataSourceProvider),
  );
});

// ============ Use cases ============

final getCatalogueUseCaseProvider = Provider<GetCatalogueUseCase>((ref) {
  return GetCatalogueUseCase(ref.watch(malaRepositoryProvider));
});

final getAccumulatorDetailUseCaseProvider =
    Provider<GetAccumulatorDetailUseCase>((ref) {
      return GetAccumulatorDetailUseCase(ref.watch(malaRepositoryProvider));
    });

final createUserAccumulatorUseCaseProvider =
    Provider<CreateUserAccumulatorUseCase>((ref) {
      return CreateUserAccumulatorUseCase(ref.watch(malaRepositoryProvider));
    });

final updateUserAccumulatorUseCaseProvider =
    Provider<UpdateUserAccumulatorUseCase>((ref) {
      return UpdateUserAccumulatorUseCase(ref.watch(malaRepositoryProvider));
    });

final deleteUserAccumulatorUseCaseProvider =
    Provider<DeleteUserAccumulatorUseCase>((ref) {
      return DeleteUserAccumulatorUseCase(ref.watch(malaRepositoryProvider));
    });

final submitGroupAccumulatorCountUseCaseProvider =
    Provider<SubmitGroupAccumulatorCountUseCase>((ref) {
      return SubmitGroupAccumulatorCountUseCase(
        ref.watch(malaRepositoryProvider),
      );
    });

final deleteGroupAccumulatorUseCaseProvider =
    Provider<DeleteGroupAccumulatorUseCase>((ref) {
      return DeleteGroupAccumulatorUseCase(ref.watch(malaRepositoryProvider));
    });

// ============ Auth helpers ============

bool _isAuthenticated(Ref ref) {
  final auth = ref.read(authProvider);
  return auth.isLoggedIn && !auth.isGuest;
}

/// Resolves the current user id for mala storage/sync.
///
/// Prefers the id persisted at login ([StorageKeys.currentUserId]) — it is
/// written before auth state flips to logged-in and does not depend on the
/// async (and possibly failing) user-profile fetch, so it's available the
/// moment the login-gated mala route is reachable. Falls back to the profile.
Future<String?> resolveMalaUserId(Ref ref) async {
  final stored = await ref
      .read(localStorageServiceProvider)
      .get<String>(StorageKeys.currentUserId);
  if (stored != null && stored.isNotEmpty) return stored;
  return ref.read(userProvider).user?.id;
}

// ============ Sync manager (app-scoped, kept alive) ============

/// Read this early (app shell) so [MalaSyncManager.start] runs and the manager
/// observes lifecycle + connectivity for the whole app lifetime.
final malaSyncManagerProvider = Provider<MalaSyncManager>((ref) {
  final manager = MalaSyncManager(
    local: ref.watch(malaLocalDataSourceProvider),
    createAccumulator: ref.watch(createUserAccumulatorUseCaseProvider),
    updateAccumulator: ref.watch(updateUserAccumulatorUseCaseProvider),
    submitGroupCount: ref.watch(submitGroupAccumulatorCountUseCaseProvider),
    isLoggedIn: () => _isAuthenticated(ref),
    currentUserId: () => resolveMalaUserId(ref),
    connectivityStream:
        ref.watch(connectivityServiceProvider).onConnectivityChanged,
    analytics: ref.watch(malaAnalyticsProvider),
  )..start();
  ref.onDispose(manager.dispose);
  return manager;
});

// ============ Catalogue ============

final malaCatalogueProvider = FutureProvider<Either<Failure, List<Mantra>>>((
  ref,
) async {
  if (!_isAuthenticated(ref)) {
    return const Left(AuthenticationFailure('Not authenticated'));
  }
  // Re-fetches when the app language changes so mantra content is localized.
  final language = ref.watch(localeProvider).languageCode;
  return ref.watch(getCatalogueUseCaseProvider)(language);
});

// ============ Catalogue search (debounced, server-side) ============

final accumulationSearchProvider =
    StateNotifierProvider<AccumulationSearchNotifier, AccumulationSearchState>((
      ref,
    ) {
      return AccumulationSearchNotifier(
        repository: ref.watch(malaRepositoryProvider),
        languageCode: ref.watch(localeProvider).languageCode,
      );
    });

// ============ Bead-tap sound ============

/// Short click played on each bead count. Loaded once; lives as long as a mala
/// counter is active and is disposed with the screen.
final malaSoundPlayerProvider = Provider.autoDispose<MalaSoundPlayer>((ref) {
  final player = MalaSoundPlayer();
  unawaited(player.init());
  ref.onDispose(player.dispose);
  return player;
});

// ============ Per-mantra counter ============

final malaCounterProvider = StateNotifierProvider.autoDispose
    .family<MalaCounterNotifier, MalaCounterState, Mantra>((ref, mantra) {
      final sync = ref.watch(malaSyncManagerProvider);
      final notifier = MalaCounterNotifier(
        mantra: mantra,
        local: ref.watch(malaLocalDataSourceProvider),
        getAccumulatorDetail: ref.watch(getAccumulatorDetailUseCaseProvider),
        deleteUserAccumulator: ref.watch(deleteUserAccumulatorUseCaseProvider),
        downloadImageBytes:
            ref.watch(malaRemoteDataSourceProvider).fetchImageBytes,
        sync: sync,
        currentUserId: () => resolveMalaUserId(ref),
        sound: ref.watch(malaSoundPlayerProvider),
      );
      void onPersonalCountSynced(String presetId) {
        notifier.handlePersonalCountSynced(presetId);
      }
      sync.onPersonalCountSynced = onPersonalCountSynced;
      ref.onDispose(() {
        if (sync.onPersonalCountSynced == onPersonalCountSynced) {
          sync.onPersonalCountSynced = null;
        }
      });
      return notifier;
    });
