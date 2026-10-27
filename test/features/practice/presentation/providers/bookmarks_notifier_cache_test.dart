import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/repositories/bookmark_repository.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FakeRemote extends BookmarkRemoteDatasource {
  _FakeRemote() : super(dio: Dio());

  List<Map<String, dynamic>> rows = const [];
  Exception? error;
  int calls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchBookmarksJson({
    String? language,
  }) async {
    calls++;
    if (error != null) throw error!;
    return rows;
  }
}

Map<String, dynamic> _row(String id, String day) => {
  'id': id,
  'type': 'TEXT',
  'source_id': 'text-$id',
  'created_at': '2026-01-$day' 'T00:00:00Z',
  'updated_at': '2026-01-$day' 'T00:00:00Z',
};

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  late BookmarkRepository repo;
  final key = ScreenCacheKey.user('bookmarks', userId: 'user-1', language: 'en');

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
    repo = BookmarkRepository(remoteDatasource: remote, store: store);
  });

  test('stored bookmarks render first, newest first, then the server list',
      () async {
    store.entries[key] = jsonEncode([_row('a', '01')]);
    remote.rows = [_row('a', '01'), _row('b', '05')];
    final notifier = BookmarksNotifier(repo, 'en', isAuthenticated: true);
    addTearDown(notifier.dispose);
    final seen = <List<String>>[];
    notifier.addListener((s) {
      if (!s.isLoading) seen.add(s.bookmarks.map((b) => b.id).toList());
    });
    await pumpEventQueue();

    expect(seen.first, ['a']);
    expect(seen.last, ['b', 'a']);
  });

  test('a failed refresh keeps the stored bookmarks', () async {
    store.entries[key] = jsonEncode([_row('a', '01')]);
    remote.error = const NetworkException('offline');
    final notifier = BookmarksNotifier(repo, 'en', isAuthenticated: true);
    addTearDown(notifier.dispose);
    await pumpEventQueue();

    expect(notifier.state.bookmarks.map((b) => b.id), ['a']);
    expect(notifier.state.error, isNull);
  });

  test('guests never request', () async {
    final notifier = BookmarksNotifier(repo, 'en', isAuthenticated: false);
    addTearDown(notifier.dispose);
    await pumpEventQueue();
    expect(remote.calls, 0);
    expect(notifier.state.isLoading, isFalse);
  });
}
