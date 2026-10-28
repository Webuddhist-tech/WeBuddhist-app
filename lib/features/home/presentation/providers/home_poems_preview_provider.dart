import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/poems/data/datasource/poems_remote_datasource.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/features/poems/presentation/providers/poems_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const homePoemsPreviewLimit = 3;

/// Shared by the preview and Home's pull-to-refresh (`refresh()`).
final homePoemsPreviewSourceProvider =
    Provider.autoDispose<ScreenCacheSource<List<Poem>>>((ref) {
      final language = ref.watch(contentLanguageProvider);
      final remote = ref.watch(poemsRemoteDatasourceProvider);
      return ScreenCacheSource<List<Poem>>(
        store: ref.watch(screenCacheStoreProvider),
        key: ScreenCacheKey.public('home_poems', language: language),
        fetchJson:
            () => remote.fetchPoemsJson(
              language: poemsApiLanguageCode(language),
              skip: 0,
              limit: homePoemsPreviewLimit,
              noCache: true,
            ),
        fromJson:
            (json) =>
                PoemsRemoteDatasource.parsePage(
                  json,
                  skip: 0,
                  limit: homePoemsPreviewLimit,
                ).poems.map((poem) => poem.toEntity()).toList(),
        failureMessage: 'Failed to load poems',
      );
    });

/// Poems are fully public, so — unlike [homeGroupEventsPreviewProvider] —
/// this fetches for guests too. Stored page is the first state.
final homePoemsPreviewProvider = AsyncNotifierProvider.autoDispose<
  AutoDisposeScreenCacheNotifier<List<Poem>, List<Poem>>,
  List<Poem>
>(() {
  return AutoDisposeScreenCacheNotifier((ref, bind) {
    return bind.source(
      ref.watch(homePoemsPreviewSourceProvider),
      select: (result) => result.fold((_) => const <Poem>[], (poems) => poems),
    );
  });
});

