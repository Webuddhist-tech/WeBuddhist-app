import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onboarding tradition paths for the current content language: the stored
/// list is the first state, so the picker sheet opens without a flash.
final traditionOnboardingPathsProvider = AsyncNotifierProvider.autoDispose<
  AutoDisposeScreenCacheNotifier<List<TraditionPath>, List<TraditionPath>>,
  List<TraditionPath>
>(() {
  return AutoDisposeScreenCacheNotifier((ref, bind) {
    ref.watch(authProvider);
    final language = ref.watch(contentLanguageProvider);
    final remote = ref.watch(onboardingRemoteDatasourceProvider);
    final store = ref.watch(screenCacheStoreProvider);
    final source = ScreenCacheSource<List<TraditionPath>>(
      store: store,
      key: ScreenCacheKey.user(
        'tradition_paths',
        userId: store.currentUserIdSync,
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
    return bind.source(
      source,
      select:
          (result) => result.fold(
            (failure) => throw Exception(failure.message),
            (paths) => paths,
          ),
    );
  });
});
