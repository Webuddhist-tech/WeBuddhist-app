import 'dart:async';

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/realtime/realtime_providers.dart';
import 'package:flutter_pecha/core/realtime/signal_listener.dart';
import 'package:flutter_pecha/core/realtime/signal_paths.dart';
import 'package:flutter_pecha/core/realtime/signal_set.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_events_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_post_comments_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_unified_feed_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/home/presentation/providers/home_group_events_preview_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Merges a post's new comments in when someone comments, keeping the pages
/// already loaded. Watched by the post detail while it knows the post's group.
final postCommentsSignalProvider = Provider.autoDispose
    .family<void, ({String groupId, String postId})>((ref, key) {
      listenSignal(
        ref,
        path: SignalPaths.groupPost(key.groupId, key.postId),
        fields: const {SignalFields.commentsChangedAt},
        onChange: (_) {
          if (!ref.exists(connectPostCommentsProvider(key.postId))) return;
          ref
              .read(connectPostCommentsProvider(key.postId).notifier)
              .refreshLatest();
        },
      );
    });

/// How many followed groups the feed listens to at once.
const int maxWatchedFeedGroups = 50;

/// Refreshes the "My" feed and the event lists when a followed group posts
/// or changes an event. One listener per followed group; the discover feed
/// spans every group and keeps pull-to-refresh.
final myFeedSignalsProvider = Provider.autoDispose<void>((ref) {
  final signals = ref.watch(liveSignalsProvider);
  if (signals == null) return;

  final pending = <String>{};
  Timer? coalesce;
  final groups = SignalSet(
    signals: signals,
    fields: const {SignalFields.postsChangedAt, SignalFields.eventsChangedAt},
    maxDocuments: maxWatchedFeedGroups,
    onChange: (change) {
      pending.add(change.field);
      coalesce ??= Timer(const Duration(milliseconds: 500), () {
        coalesce = null;
        final posts = pending.remove(SignalFields.postsChangedAt);
        final events = pending.remove(SignalFields.eventsChangedAt);
        pending.clear();
        // The My feed shows event cards too, so either field refreshes it once.
        if ((posts || events) && ref.exists(myUnifiedConnectFeedProvider)) {
          ref.read(myUnifiedConnectFeedProvider.notifier).refreshLatest();
        }
        if (events) refreshEventListsIfShown(ref);
      });
    },
  );

  ref.listen<AsyncValue<DiscoverGroupsPage>>(myGroupsProvider, (_, next) {
    final page = next.valueOrNull;
    if (page == null) return;
    final ids = [for (final group in page.groups) group.id]..sort();
    groups.sync(ids.map(SignalPaths.group));
  }, fireImmediately: true);

  ref.onDispose(() {
    coalesce?.cancel();
    groups.dispose();
  });
});

/// Refreshes every event list on screen when an event is featured or
/// unfeatured. Watched by Home's events section and the events screen.
final featuredEventsSignalProvider = Provider.autoDispose<void>((ref) {
  listenSignal(
    ref,
    path: SignalPaths.featuredEvents,
    fields: const {SignalFields.featuredChangedAt},
    coalesce: const Duration(milliseconds: 300),
    onChange: (_) => refreshEventListsIfShown(ref),
  );
});

/// Home's preview and today's events revalidate through their sources; the
/// paged lists refresh only while they are alive.
void refreshEventListsIfShown(Ref ref) {
  final language = ref.read(contentLanguageProvider);
  ref.read(homeGroupEventsPreviewSourceProvider)?.refresh();
  ref
      .read(todayEventsDomainRepositoryProvider)
      .refreshTodayEvents(language: language);
  for (final filter in ConnectEventFormatFilter.values) {
    if (!ref.exists(myConnectEventsProvider(filter))) continue;
    ref.read(myConnectEventsProvider(filter).notifier).refresh();
  }
  if (ref.exists(discoverConnectEventsProvider)) {
    ref.read(discoverConnectEventsProvider.notifier).refresh();
  }
}
