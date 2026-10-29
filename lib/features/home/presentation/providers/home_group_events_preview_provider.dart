import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_events_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const homeGroupEventsPreviewLimit = 2;

final homeEventsRemoteDatasourceProvider = Provider<HomeEventsRemoteDatasource>(
  (ref) => HomeEventsRemoteDatasource(dio: ref.watch(dioProvider)),
);

/// Null for guests. Shared by the preview and Home's pull-to-refresh.
final homeGroupEventsPreviewSourceProvider =
    Provider.autoDispose<ScreenCacheSource<List<GroupEvent>>?>((ref) {
      final authState = ref.watch(authProvider);
      if (authState.isGuest || !authState.isLoggedIn) return null;

      final language = ref.watch(contentLanguageProvider);
      final remote = ref.watch(homeEventsRemoteDatasourceProvider);
      final store = ref.watch(screenCacheStoreProvider);
      return ScreenCacheSource<List<GroupEvent>>(
        store: store,
        key: ScreenCacheKey.user(
          'home_events',
          userId: store.currentUserIdSync,
          language: language,
        ),
        fetchJson:
            () => remote.fetchPreviewJson(
              language: language,
              limit: homeGroupEventsPreviewLimit,
            ),
        fromJson:
            (json) =>
                GroupEventsPageModel.fromJson(
                  json as Map<String, dynamic>,
                  language: language,
                ).toEntity().events,
        failureMessage: 'Failed to load events',
      );
    });

/// Stored preview is the first state; guests get an empty list.
final homeGroupEventsPreviewProvider = AsyncNotifierProvider.autoDispose<
  AutoDisposeScreenCacheNotifier<List<GroupEvent>, List<GroupEvent>>,
  List<GroupEvent>
>(() {
  return AutoDisposeScreenCacheNotifier((ref, bind) {
    final source = ref.watch(homeGroupEventsPreviewSourceProvider);
    if (source == null) return const [];
    return bind.source(
      source,
      select:
          (result) =>
              result.fold((_) => const <GroupEvent>[], (events) => events),
    );
  });
});
