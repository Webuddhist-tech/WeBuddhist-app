import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitations_page_response.dart';
import 'package:flutter_pecha/features/recitation/data/repositories/recitations_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FakeRemote extends RecitationsRemoteDatasource {
  final List<RecitationsQueryParams> calls = [];
  List<RecitationModel> recitations = const [];
  Exception? error;

  @override
  Future<RecitationsPageResponse> fetchRecitationsPage({
    RecitationsQueryParams? queryParams,
  }) async {
    calls.add(queryParams!);
    if (error != null) throw error!;
    return RecitationsPageResponse(
      recitations: recitations,
      skip: 0,
      limit: 20,
      total: recitations.length,
    );
  }
}

RecitationModel _chant(String id, String title) =>
    RecitationModel(textId: id, title: title, language: 'en');

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  late RecitationsRepository repo;
  final key = ScreenCacheKey.public('recitations', language: 'en');

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
    repo = RecitationsRepository(recitationsRemoteDatasource: remote, store: store);
  });

  List<String> titles(Either<Failure, List<RecitationModel>> e) =>
      e.fold((_) => const [], (list) => list.map((r) => r.title).toList());

  test('watch yields the stored list, then the changed server list', () async {
    store.entries[key] = '[{"text_id":"1","title":"Old","language":"en"}]';
    remote.recitations = [_chant('1', 'Old'), _chant('2', 'New')];

    final events = <Either<Failure, List<RecitationModel>>>[];
    final sub = repo.watchRecitations(language: 'en').listen(events.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    expect(events.map(titles), [
      ['Old'],
      ['Old', 'New'],
    ]);
    expect(remote.calls.single.noCache, isTrue);
    expect(remote.calls.single.language, 'en');
  });

  test('refresh writes the store and an open stream picks it up', () async {
    remote.recitations = [_chant('1', 'A')];
    final events = <Either<Failure, List<RecitationModel>>>[];
    final sub = repo.watchRecitations(language: 'en').listen(events.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    remote.recitations = [_chant('1', 'A'), _chant('2', 'B')];
    final result = await repo.refreshRecitations(language: 'en');
    await pumpEventQueue();

    expect(titles(result), ['A', 'B']);
    expect(titles(events.last), ['A', 'B']);
  });

  test('a first load with no network is a NetworkFailure', () async {
    remote.error = const NetworkException('offline');
    final events = await repo.watchRecitations(language: 'en').first;
    expect(events.getLeft().toNullable(), isA<NetworkFailure>());
  });

  test('getRecitations is network only and keeps the search query', () async {
    remote.recitations = [_chant('1', 'Tara')];
    final result = await repo.getRecitations(language: 'en', searchQuery: 'Ta');
    expect(titles(result), ['Tara']);
    expect(remote.calls.single.search, 'Ta');
    expect(remote.calls.single.noCache, isFalse);
    expect(store.entries, isEmpty);
  });
}
