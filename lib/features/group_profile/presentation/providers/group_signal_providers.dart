import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/realtime/signal_listener.dart';
import 'package:flutter_pecha/core/realtime/signal_paths.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_composer_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_post_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Refetches a group's posts and events when its signal moves. Watched by
/// the group profile; a group that cannot be read keeps fetching on open.
final groupSignalsProvider = Provider.autoDispose.family<void, String>((
  ref,
  groupId,
) {
  listenSignal(
    ref,
    path: SignalPaths.group(groupId),
    fields: const {SignalFields.postsChangedAt, SignalFields.eventsChangedAt},
    coalesce: const Duration(milliseconds: 300),
    onChange: (change) {
      if (change.field == SignalFields.postsChangedAt) {
        refreshGroupPostsIfShown(ref, groupId);
      } else {
        refreshGroupEventsIfShown(ref, groupId);
      }
    },
  );
});

/// Reloads the posts list in place when it is on screen.
void refreshGroupPostsIfShown(Ref ref, String groupId) {
  if (!ref.exists(groupPostsProvider(groupId))) return;
  ref.read(groupPostsProvider(groupId).notifier).loadInitial();
}

/// Revalidates the events source (its stream updates the bound provider)
/// and the publisher's CMS list when either is on screen.
void refreshGroupEventsIfShown(Ref ref, String groupId) {
  if (ref.exists(groupEventsProvider(groupId))) {
    ref
        .read(groupProfileRepositoryProvider)
        .refreshGroupEvents(
          groupId,
          language: ref.read(contentLanguageProvider),
        );
  }
  if (ref.exists(groupCmsEventsProvider(groupId))) {
    ref.invalidate(groupCmsEventsProvider(groupId));
  }
}
