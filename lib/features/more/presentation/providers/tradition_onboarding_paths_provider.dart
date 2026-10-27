import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onboarding tradition paths for the current content language: stored list
/// first, refreshed in the background, so the picker sheet opens without a flash.
final traditionOnboardingPathsProvider =
    StreamProvider.autoDispose<List<TraditionPath>>((ref) async* {
      ref.watch(authProvider);
      final language = ref.watch(contentLanguageProvider);
      final remote = ref.watch(onboardingRemoteDatasourceProvider);
      final store = ref.watch(screenCacheStoreProvider);
      final userId = await store.currentUserId();
      final source = ScreenCacheSource<List<TraditionPath>>(
        store: store,
        key: ScreenCacheKey.user(
          'tradition_paths',
          userId: userId,
          language: language,
        ),
        fetchJson:
            () => remote.fetchTraditionOnboardingPathsJson(language: language),
        fromJson:
            (json) => OnboardingRemoteDatasource.parseTraditionPaths(
              json as Map<String, dynamic>,
            ),
        failureMessage: 'Failed to load tradition paths',
      );
      yield* source.watch().map(
        (result) => result.fold(
          (failure) => throw Exception(failure.message),
          (paths) => paths,
        ),
      );
    });
