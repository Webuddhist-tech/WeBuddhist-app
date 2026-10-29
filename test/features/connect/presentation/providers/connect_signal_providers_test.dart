import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/realtime/realtime_providers.dart';
import 'package:flutter_pecha/core/realtime/signal_paths.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/connect/data/datasource/connect_remote_datasource.dart';
import 'package:flutter_pecha/features/connect/data/repositories/connect_repository_impl.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_post_comments_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_signal_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_unified_feed_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_events_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';
import 'package:flutter_pecha/features/home/presentation/providers/home_group_events_preview_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/fake_realtime_signals.dart';
import '../../../../helpers/fake_screen_cache_store.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth({bool guest = false})
    : super(AuthState(isLoggedIn: true, isGuest: guest));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemote extends ConnectRemoteDatasource {
  _FakeRemote() : super(dio: Dio());

  int commentFetches = 0;
  int feedFetches = 0;
  List<String> groupIds = [];

  /// Oldest first, as the post's comments come back.
  List<String> commentIds = [];

  /// Holds the next comments fetch, which has already read [commentIds].
  Completer<void>? commentGate;

  /// Newest first, as the feed's post cards come back.
  List<String> feedPostIds = [];

  /// Holds the next feed fetch, which has already read [feedPostIds].
  Completer<void>? feedGate;

  @override
  Future<Map<String, dynamic>> fetchPostCommentsJson({
    required String postId,
    int skip = 0,
    int limit = 20,
  }) async {
    commentFetches++;
    final ids = commentIds;
    final held = commentGate;
    commentGate = null;
    if (held != null) await held.future;
    return {
      'comments': [
        for (final id in ids.skip(skip).take(limit))
          {'id': id, 'post_id': postId, 'text': id},
      ],
      'skip': skip,
      'limit': limit,
      'total': ids.length,
    };
  }

  @override
  Future<Map<String, dynamic>> fetchConnectFeedsJson({
    required bool includeUnfollowed,
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    feedFetches++;
    final ids = feedPostIds;
    final held = feedGate;
    feedGate = null;
    if (held != null) await held.future;
    return {
      'items': [
        for (final id in ids.skip(skip).take(limit))
          {
            'type': 'post',
            'group_id': 'g1',
            'group_name': 'Group',
            'post': {
              'id': id,
              'group_id': 'g1',
              'caption': id,
              'status': 'published',
            },
          },
      ],
      'skip': skip,
      'limit': limit,
      'total': ids.length,
    };
  }

  @override
  Future<Map<String, dynamic>> fetchConnectPracticesJson({
    required bool includeUnfollowed,
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    return {'practices': <Object>[], 'skip': skip, 'limit': limit, 'total': 0};
  }

  @override
  Future<Map<String, dynamic>> fetchMyGroupsJson({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    return {
      'groups': [
        for (final id in groupIds)
          {'id': id, 'slug': id, 'group_type': 'COMMUNITY'},
      ],
      'skip': 0,
      'limit': 20,
      'total': groupIds.length,
    };
  }
}

class _FakeHomeEvents extends HomeEventsRemoteDatasource {
  _FakeHomeEvents() : super(dio: Dio());

  int previews = 0;

  @override
  Future<Map<String, dynamic>> fetchPreviewJson({
    required String language,
    required int limit,
  }) async {
    previews++;
    return {'events': <Object>[], 'total': 0, 'skip': 0, 'limit': limit};
  }
}

class _FakeTodayEvents extends Fake implements TodayEventsRepositoryInterface {
  int refreshes = 0;

  @override
  Future<Either<Failure, Unit>> refreshTodayEvents({
    required String language,
  }) async {
    refreshes++;
    return const Right(unit);
  }
}

void main() {
  late FakeRealtimeSignals signals;
  late _FakeRemote remote;
  late _FakeTodayEvents today;
  late _FakeHomeEvents home;
  late ProviderContainer container;

  ProviderContainer build({bool guest = false}) {
    return ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _Auth(guest: guest)),
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        connectRepositoryProvider.overrideWithValue(
          ConnectRepositoryImpl(remote: remote, store: FakeScreenCacheStore()),
        ),
        todayEventsDomainRepositoryProvider.overrideWithValue(today),
        homeEventsRemoteDatasourceProvider.overrideWithValue(home),
        screenCacheStoreProvider.overrideWithValue(FakeScreenCacheStore()),
        realtimeSignalsProvider.overrideWithValue(signals),
        firebaseSignedInProvider.overrideWith((ref) => true),
      ],
    );
  }

  setUp(() {
    signals = FakeRealtimeSignals();
    remote = _FakeRemote();
    today = _FakeTodayEvents();
    home = _FakeHomeEvents();
    container = build();
    addTearDown(container.dispose);
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 600));

  group('postCommentsSignalProvider', () {
    final path = SignalPaths.groupPost('g1', 'p1');

    test('reloads the comments in place while they are shown', () async {
      container.listen(
        postCommentsSignalProvider((groupId: 'g1', postId: 'p1')),
        (_, _) {},
      );
      await pumpEventQueue();
      expect(signals.listeners(path), 1);
      signals.emit(path, {'comments_changed_at': DateTime.utc(2026, 1, 1)});
      await pumpEventQueue();

      // Not shown: nothing to reload.
      signals.emit(path, {'comments_changed_at': DateTime.utc(2026, 1, 2)});
      await pumpEventQueue();
      expect(remote.commentFetches, 0);

      container.listen(connectPostCommentsProvider('p1'), (_, _) {});
      container.read(connectPostCommentsProvider('p1').notifier).loadInitial();
      await pumpEventQueue();
      final before = remote.commentFetches;
      signals.emit(path, {'comments_changed_at': DateTime.utc(2026, 1, 3)});
      await pumpEventQueue();
      expect(remote.commentFetches, before + 1);
      expect(
        container.read(connectPostCommentsProvider('p1')).isLoading,
        isFalse,
      );
    });
  });

  group('postCommentsSignalProvider paging', () {
    final path = SignalPaths.groupPost('g1', 'p1');

    test('a new comment keeps the pages already loaded', () async {
      remote.commentIds = [for (var i = 0; i < 25; i++) 'c$i'];
      container.listen(
        postCommentsSignalProvider((groupId: 'g1', postId: 'p1')),
        (_, _) {},
      );
      container.listen(connectPostCommentsProvider('p1'), (_, _) {});
      final notifier = container.read(
        connectPostCommentsProvider('p1').notifier,
      );
      await pumpEventQueue();
      await notifier.loadMore();
      signals.emit(path, {'comments_changed_at': DateTime.utc(2026, 1, 1)});
      await pumpEventQueue();
      expect(container.read(connectPostCommentsProvider('p1')).comments, hasLength(25));

      remote.commentIds = [...remote.commentIds, 'c25'];
      signals.emit(path, {'comments_changed_at': DateTime.utc(2026, 1, 2)});
      await pumpEventQueue();
      final state = container.read(connectPostCommentsProvider('p1'));
      expect(state.comments, hasLength(25));
      expect(state.total, 26);
      expect(state.hasMore, isTrue);

      await notifier.loadMore();
      expect(
        container.read(connectPostCommentsProvider('p1')).comments.last.id,
        'c25',
      );
    });

    test('a pull-to-refresh is not undone by an older background read', () async {
      remote.commentIds = ['c0'];
      container.listen(connectPostCommentsProvider('p1'), (_, _) {});
      await pumpEventQueue();
      final notifier = container.read(
        connectPostCommentsProvider('p1').notifier,
      );

      final held = Completer<void>();
      remote.commentGate = held;
      final background = notifier.refreshLatest();
      await pumpEventQueue();
      remote.commentIds = ['c0', 'c1'];
      await notifier.refresh();
      held.complete();
      await background;

      expect(
        container
            .read(connectPostCommentsProvider('p1'))
            .comments
            .map((c) => c.id),
        ['c0', 'c1'],
      );
    });

    test('a comment deleted elsewhere leaves the list', () async {
      remote.commentIds = ['c0', 'c1'];
      container.listen(
        postCommentsSignalProvider((groupId: 'g1', postId: 'p1')),
        (_, _) {},
      );
      container.listen(connectPostCommentsProvider('p1'), (_, _) {});
      await pumpEventQueue();
      signals.emit(path, {'comments_changed_at': DateTime.utc(2026, 1, 1)});
      await pumpEventQueue();

      remote.commentIds = [];
      signals.emit(path, {'comments_changed_at': DateTime.utc(2026, 1, 2)});
      await pumpEventQueue();

      final state = container.read(connectPostCommentsProvider('p1'));
      expect(state.comments, isEmpty);
      expect(state.total, 0);
    });

    test('a signal during a load fetches again once it lands', () async {
      remote.commentIds = ['c0'];
      container.listen(
        postCommentsSignalProvider((groupId: 'g1', postId: 'p1')),
        (_, _) {},
      );
      await pumpEventQueue();
      signals.emit(path, {'comments_changed_at': DateTime.utc(2026, 1, 1)});
      await pumpEventQueue();

      final held = Completer<void>();
      remote.commentGate = held;
      container.listen(connectPostCommentsProvider('p1'), (_, _) {});
      await pumpEventQueue();

      // Someone comments after the load read the server.
      remote.commentIds = ['c0', 'c1'];
      signals.emit(path, {'comments_changed_at': DateTime.utc(2026, 1, 2)});
      await pumpEventQueue();
      held.complete();
      await pumpEventQueue();

      expect(
        container
            .read(connectPostCommentsProvider('p1'))
            .comments
            .map((c) => c.id),
        ['c0', 'c1'],
      );
    });
  });

  group('myFeedSignalsProvider', () {
    test('a signal during the first load refreshes once it lands', () async {
      remote.feedPostIds = ['p1'];
      container.listen(myUnifiedConnectFeedProvider, (_, _) {});
      final feed = container.read(myUnifiedConnectFeedProvider.notifier);
      final held = Completer<void>();
      remote.feedGate = held;
      feed.ensureLoaded();
      await pumpEventQueue();

      remote.feedPostIds = ['p2', 'p1'];
      await feed.refreshLatest();
      held.complete();
      await pumpEventQueue();

      expect(
        container
            .read(myUnifiedConnectFeedProvider)
            .feedItems
            .map((item) => item.post?.id),
        ['p2', 'p1'],
      );
    });

    test('a pull-to-refresh is not undone by an older background read', () async {
      remote.feedPostIds = ['p1'];
      container.listen(myUnifiedConnectFeedProvider, (_, _) {});
      final feed = container.read(myUnifiedConnectFeedProvider.notifier);
      feed.ensureLoaded();
      await pumpEventQueue();

      final held = Completer<void>();
      remote.feedGate = held;
      final background = feed.refreshLatest();
      await pumpEventQueue();
      remote.feedPostIds = ['p2', 'p1'];
      await feed.refresh();
      held.complete();
      await background;

      expect(
        container
            .read(myUnifiedConnectFeedProvider)
            .feedItems
            .map((item) => item.post?.id),
        ['p2', 'p1'],
      );
    });

    test('a signal keeps the My feed pages already loaded', () async {
      remote.groupIds = ['g1'];
      remote.feedPostIds = [for (var i = 25; i > 0; i--) 'p$i'];
      container.listen(myFeedSignalsProvider, (_, _) {});
      container.listen(myGroupsProvider, (_, _) {});
      container.listen(myUnifiedConnectFeedProvider, (_, _) {});
      final feed = container.read(myUnifiedConnectFeedProvider.notifier);
      feed.ensureLoaded();
      await pumpEventQueue();
      await pumpEventQueue();
      await feed.loadMore();
      expect(container.read(myUnifiedConnectFeedProvider).feedItems, hasLength(25));

      final path = SignalPaths.group('g1');
      signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 1)});
      await settle();
      remote.feedPostIds = ['p26', ...remote.feedPostIds];
      signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 2)});
      await settle();

      final state = container.read(myUnifiedConnectFeedProvider);
      expect(state.feedItems, hasLength(25));
      expect(state.feedItems.first.post?.id, 'p26');
      expect(state.feedSkip, 25);
      expect(state.feedHasMore, isTrue);
    });

    test('an events signal refreshes the My feed too', () async {
      remote.groupIds = ['g1'];
      container.listen(myFeedSignalsProvider, (_, _) {});
      container.listen(myGroupsProvider, (_, _) {});
      container.listen(myUnifiedConnectFeedProvider, (_, _) {});
      container.read(myUnifiedConnectFeedProvider.notifier).ensureLoaded();
      await pumpEventQueue();
      await pumpEventQueue();
      final path = SignalPaths.group('g1');
      signals.emit(path, {
        'events_changed_at': DateTime.utc(2026, 1, 1),
        'posts_changed_at': DateTime.utc(2026, 1, 1),
      });
      await settle();
      final before = remote.feedFetches;

      signals.emit(path, {
        'events_changed_at': DateTime.utc(2026, 1, 2),
        'posts_changed_at': DateTime.utc(2026, 1, 1),
      });
      await settle();
      expect(remote.feedFetches, before + 1);

      // Both fields in one burst still refresh it once.
      signals.emit(path, {
        'events_changed_at': DateTime.utc(2026, 1, 3),
        'posts_changed_at': DateTime.utc(2026, 1, 3),
      });
      await settle();
      expect(remote.feedFetches, before + 2);
    });

    test('listens to every followed group and follows the list', () async {
      remote.groupIds = ['g2', 'g1'];
      container.listen(myFeedSignalsProvider, (_, _) {});
      container.listen(myGroupsProvider, (_, _) {});
      await pumpEventQueue();
      await pumpEventQueue();

      expect(signals.listeners(SignalPaths.group('g1')), 1);
      expect(signals.listeners(SignalPaths.group('g2')), 1);

      remote.groupIds = ['g3'];
      await container
          .read(connectRepositoryProvider)
          .refreshMyGroups(language: 'en');
      await pumpEventQueue();

      expect(signals.listeners(SignalPaths.group('g1')), 0);
      expect(signals.listeners(SignalPaths.group('g3')), 1);
    });

    test('an events signal refreshes the event lists once per burst', () async {
      remote.groupIds = ['g1'];
      container.listen(myFeedSignalsProvider, (_, _) {});
      container.listen(myGroupsProvider, (_, _) {});
      await pumpEventQueue();
      await pumpEventQueue();
      final path = SignalPaths.group('g1');
      signals.emit(path, {'events_changed_at': DateTime.utc(2026, 1, 1)});
      await settle();
      expect(today.refreshes, 0);

      signals.emit(path, {'events_changed_at': DateTime.utc(2026, 1, 2)});
      signals.emit(path, {'events_changed_at': DateTime.utc(2026, 1, 3)});
      await settle();
      expect(today.refreshes, 1);
      expect(home.previews, 1);
    });
  });

  group('featuredEventsSignalProvider', () {
    test('refreshes the event lists when featuring changes', () async {
      container.listen(featuredEventsSignalProvider, (_, _) {});
      await pumpEventQueue();
      expect(signals.listeners(SignalPaths.featuredEvents), 1);

      signals.emit(SignalPaths.featuredEvents, {
        'featured_changed_at': DateTime.utc(2026, 1, 1),
      });
      await settle();
      expect(today.refreshes, 0);

      signals.emit(SignalPaths.featuredEvents, {
        'featured_changed_at': DateTime.utc(2026, 1, 2),
      });
      await settle();
      expect(today.refreshes, 1);
    });
  });
}
