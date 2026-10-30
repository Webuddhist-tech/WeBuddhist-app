import 'dart:async';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/realtime/realtime_providers.dart';
import 'package:flutter_pecha/core/realtime/signal_paths.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_post_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_post_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_signal_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/fake_realtime_signals.dart';
import '../../../../helpers/fake_screen_cache_store.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth() : super(const AuthState(isLoggedIn: true, isGuest: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePostRepository extends Fake implements GroupPostRepositoryInterface {
  int fetches = 0;

  /// Newest first, as the group's posts come back.
  List<String> postIds = [];

  /// Holds the next fetch, which has already read [postIds].
  Completer<void>? gate;

  @override
  Future<Either<Failure, ConnectPostsPage>> getGroupPosts(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    fetches++;
    final ids = postIds;
    final held = gate;
    gate = null;
    if (held != null) await held.future;
    return Right(
      ConnectPostsPage(
        posts: [
          for (final id in ids.skip(skip).take(limit))
            ConnectPost(
              id: id,
              groupId: groupId,
              caption: id,
              status: 'published',
              creatorName: 'Tenzin',
            ),
        ],
        skip: skip,
        limit: limit,
        total: ids.length,
      ),
    );
  }

  @override
  ConnectPostsPage? readStoredGroupPosts(String groupId) => null;

  @override
  Future<Either<Failure, void>> deletePost(String groupId, String postId) async =>
      const Right(null);
}

class _FakeProfileRepository extends Fake
    implements GroupProfileRepositoryInterface {
  _FakeProfileRepository(this.store);

  final FakeScreenCacheStore store;
  int eventFetches = 0;
  int refreshes = 0;

  ScreenCacheSource<GroupEventsPage> _source(String groupId) {
    return ScreenCacheSource<GroupEventsPage>(
      store: store,
      key: ScreenCacheKey.user(
        'group_events',
        userId: 'user-1',
        language: 'en',
        params: [groupId],
      ),
      fetchJson: () async {
        eventFetches++;
        return {'events': <Object>[], 'total': 0, 'skip': 0, 'limit': 20};
      },
      fromJson:
          (json) =>
              GroupEventsPageModel.fromJson(
                json as Map<String, dynamic>,
                language: 'en',
              ).toEntity(),
      failureMessage: 'Failed to load events',
    );
  }

  @override
  ScreenCacheSource<GroupEventsPage> groupEventsSource(
    String groupId, {
    required String language,
  }) => _source(groupId);

  @override
  Future<Either<Failure, GroupEventsPage>> refreshGroupEvents(
    String groupId, {
    required String language,
  }) {
    refreshes++;
    return _source(groupId).refresh();
  }
}

void main() {
  late FakeRealtimeSignals signals;
  late _FakePostRepository posts;
  late _FakeProfileRepository profile;
  late ProviderContainer container;
  final path = SignalPaths.group('g1');

  setUp(() {
    signals = FakeRealtimeSignals();
    posts = _FakePostRepository();
    profile = _FakeProfileRepository(FakeScreenCacheStore());
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _Auth()),
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        groupPostRepositoryProvider.overrideWithValue(posts),
        groupProfileRepositoryProvider.overrideWithValue(profile),
        realtimeSignalsProvider.overrideWithValue(signals),
        firebaseSignedInProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);
    container.listen(groupSignalsProvider('g1'), (_, _) {});
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 350));

  test('listens to the group and ignores the first snapshot', () async {
    await pumpEventQueue();
    expect(signals.listeners(path), 1);

    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 1)});
    await settle();
    expect(posts.fetches, 0);
    expect(profile.refreshes, 0);
  });

  test('a posts signal reloads the posts list while it is shown', () async {
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 1)});
    await pumpEventQueue();

    // Not on screen: nothing to reload.
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 2)});
    await settle();
    expect(posts.fetches, 0);

    container.listen(groupPostsProvider('g1'), (_, _) {});
    await pumpEventQueue();
    final before = posts.fetches;
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 3)});
    await settle();
    expect(posts.fetches, before + 1);
    expect(profile.refreshes, 0);
  });

  test('a new post keeps the pages already loaded', () async {
    posts.postIds = [for (var i = 25; i > 0; i--) 'p$i'];
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 1)});
    container.listen(groupPostsProvider('g1'), (_, _) {});
    await pumpEventQueue();
    await container.read(groupPostsProvider('g1').notifier).loadMore();
    expect(container.read(groupPostsProvider('g1')).posts, hasLength(25));

    posts.postIds = ['p26', ...posts.postIds];
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 2)});
    await settle();

    final state = container.read(groupPostsProvider('g1'));
    expect(state.posts, hasLength(25));
    expect(state.posts.first.id, 'p26');
    expect(state.hasMore, isTrue);

    // The post the new one pushed past the window comes back with paging.
    await container.read(groupPostsProvider('g1').notifier).loadMore();
    expect(container.read(groupPostsProvider('g1')).posts.last.id, 'p1');
  });

  test('a signal during the first load refreshes once it lands', () async {
    posts.postIds = ['p1'];
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 1)});
    await pumpEventQueue();
    final held = Completer<void>();
    posts.gate = held;
    container.listen(groupPostsProvider('g1'), (_, _) {});
    await pumpEventQueue();

    // Someone posts after the load read the server.
    posts.postIds = ['p2', 'p1'];
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 2)});
    await settle();
    held.complete();
    await pumpEventQueue();

    expect(
      container.read(groupPostsProvider('g1')).posts.map((p) => p.id),
      ['p2', 'p1'],
    );
  });

  test('a post deleted elsewhere leaves the list', () async {
    posts.postIds = ['p2', 'p1'];
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 1)});
    container.listen(groupPostsProvider('g1'), (_, _) {});
    await pumpEventQueue();

    posts.postIds = [];
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 2)});
    await settle();

    final state = container.read(groupPostsProvider('g1'));
    expect(state.posts, isEmpty);
    expect(state.total, 0);
  });

  test('a burst larger than a page leaves no gap behind it', () async {
    final old = [for (var i = 20; i > 0; i--) 'old$i'];
    posts.postIds = old;
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 1)});
    container.listen(groupPostsProvider('g1'), (_, _) {});
    await pumpEventQueue();

    posts.postIds = [for (var i = 25; i > 0; i--) 'new$i', ...old];
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 2)});
    await settle();
    final notifier = container.read(groupPostsProvider('g1').notifier);
    while (container.read(groupPostsProvider('g1')).hasMore) {
      await notifier.loadMore();
    }

    expect(
      container.read(groupPostsProvider('g1')).posts.map((p) => p.id),
      posts.postIds,
    );
  });

  test('a page loaded during a refresh is not overwritten', () async {
    posts.postIds = [for (var i = 45; i > 0; i--) 'p$i'];
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 1)});
    container.listen(groupPostsProvider('g1'), (_, _) {});
    await pumpEventQueue();
    final notifier = container.read(groupPostsProvider('g1').notifier);

    final held = Completer<void>();
    posts.gate = held;
    final refresh = notifier.refreshLatest();
    await pumpEventQueue();
    await notifier.loadMore();
    expect(container.read(groupPostsProvider('g1')).posts, hasLength(40));

    held.complete();
    await refresh;
    final state = container.read(groupPostsProvider('g1'));
    expect(state.posts, hasLength(40));
    expect(state.skip, 40);
  });

  test('a post deleted here during a refresh stays gone', () async {
    posts.postIds = ['p2', 'p1'];
    signals.emit(path, {'posts_changed_at': DateTime.utc(2026, 1, 1)});
    container.listen(groupPostsProvider('g1'), (_, _) {});
    await pumpEventQueue();
    final notifier = container.read(groupPostsProvider('g1').notifier);

    final held = Completer<void>();
    posts.gate = held;
    final refresh = notifier.refreshLatest();
    await pumpEventQueue();
    expect(await notifier.deletePost('p2'), isTrue);
    // The read still carries it: the server answered before the delete.
    held.complete();
    await refresh;

    final state = container.read(groupPostsProvider('g1'));
    expect(state.posts.map((p) => p.id), ['p1']);
    expect(state.total, 1);
  });

  test('an events signal revalidates the events source while shown', () async {
    signals.emit(path, {'events_changed_at': DateTime.utc(2026, 1, 1)});
    await pumpEventQueue();

    signals.emit(path, {'events_changed_at': DateTime.utc(2026, 1, 2)});
    await settle();
    expect(profile.refreshes, 0);

    container.listen(groupEventsProvider('g1'), (_, _) {});
    await pumpEventQueue();
    signals.emit(path, {'events_changed_at': DateTime.utc(2026, 1, 3)});
    await settle();
    expect(profile.refreshes, 1);
    expect(posts.fetches, 0);
  });

  test('a refused group keeps fetching on open, quietly', () async {
    final refused =
        FakeRealtimeSignals()
          ..permissionDeniedUntil(SignalPaths.group('g2'), 1);
    final other = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _Auth()),
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        groupPostRepositoryProvider.overrideWithValue(posts),
        groupProfileRepositoryProvider.overrideWithValue(profile),
        realtimeSignalsProvider.overrideWithValue(refused),
        firebaseSignedInProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(other.dispose);
    other.listen(groupSignalsProvider('g2'), (_, _) {});
    await pumpEventQueue();

    expect(refused.listeners(SignalPaths.group('g2')), 0);
  });
}
