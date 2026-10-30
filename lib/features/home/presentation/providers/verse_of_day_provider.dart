import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Stored verse is the first state; re-fetches when the app language changes.
final verseOfDayFutureProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<VerseOfDay, Either<Failure, VerseOfDay>>,
  Either<Failure, VerseOfDay>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final language = ref.watch(contentLanguageProvider);
    final repository = ref.watch(verseOfDayDomainRepositoryProvider);
    final stored =
        ref.watch(homeLocalDatasourceProvider).readVerseOfDay(language)?.toEntity();
    return bind.stream(
      stored == null ? null : Right(stored),
      repository.watchVerseOfDay(language: language),
    );
  });
});
