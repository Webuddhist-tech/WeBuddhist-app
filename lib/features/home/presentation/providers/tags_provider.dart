import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

// Stored tags are the first state; refreshes when the language changes.
final tagsFutureProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<List<String>, Either<Failure, List<String>>>,
  Either<Failure, List<String>>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final language = ref.watch(contentLanguageProvider);
    final repository = ref.watch(tagsDomainRepositoryProvider);
    final stored = ref.watch(homeLocalDatasourceProvider).readTags(language);
    return bind.stream(
      stored == null ? null : Right(stored),
      repository.watchTags(language: language),
    );
  });
});
