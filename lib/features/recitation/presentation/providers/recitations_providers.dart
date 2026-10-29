import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/recitations_repository.dart';
import '../../data/models/recitation_model.dart';
import 'recitations_datasource_provider.dart';

// Repository provider
final recitationsRepositoryProvider = Provider<RecitationsRepository>((ref) {
  return RecitationsRepository(
    recitationsRemoteDatasource: ref.watch(recitationsRemoteDatasourceProvider),
    store: ref.watch(screenCacheStoreProvider),
  );
});

// Stored list is the first state, refreshed in the background (name kept).
final recitationsFutureProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<List<RecitationModel>, Either<Failure, List<RecitationModel>>>,
  Either<Failure, List<RecitationModel>>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final languageCode = ref.watch(contentLanguageProvider);
    return bind.source(
      ref
          .watch(recitationsRepositoryProvider)
          .recitationsSource(language: languageCode),
    );
  });
});
