import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/today_event.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Stored events are the first state; re-fetches when the language changes.
final todayEventsFutureProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<List<TodayEvent>, Either<Failure, List<TodayEvent>>>,
  Either<Failure, List<TodayEvent>>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final language = ref.watch(contentLanguageProvider);
    final repository = ref.watch(todayEventsDomainRepositoryProvider);
    final stored = ref
        .watch(homeLocalDatasourceProvider)
        .readTodayEvents(language)
        ?.map((m) => m.toEntity())
        .toList();
    return bind.stream(
      stored == null ? null : Right(stored),
      repository.watchTodayEvents(language: language),
    );
  });
});
