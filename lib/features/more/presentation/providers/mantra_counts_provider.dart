import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/more/domain/entities/mantra_count.dart';
import 'package:flutter_pecha/features/more/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

// Stored counts are the first state, refreshed in the background.
final mantraCountsProvider = AsyncNotifierProvider.autoDispose<
  AutoDisposeScreenCacheNotifier<MantraCountPage, Either<Failure, MantraCountPage>>,
  Either<Failure, MantraCountPage>
>(() {
  return AutoDisposeScreenCacheNotifier((ref, bind) {
    final auth = ref.watch(authProvider);
    if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final language = ref.watch(contentLanguageProvider);
    return bind.source(
      ref.watch(userStatsRepositoryProvider).mantraCountsSource(language: language),
    );
  });
});
