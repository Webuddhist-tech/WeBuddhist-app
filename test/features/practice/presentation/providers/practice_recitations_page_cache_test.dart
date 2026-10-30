import 'dart:convert';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_recitations_paginated_provider.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitations_page_response.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FakeRemote extends RecitationsRemoteDatasource {
  List<RecitationModel> recitations = const [];
  Exception? error;
  final List<RecitationsQueryParams> calls = [];

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

RecitationModel _chant(String id) =>
    RecitationModel(textId: id, title: 'Chant $id', language: 'en');

String _stored(List<String> ids) => jsonEncode(
  RecitationsPageResponse(
    recitations: ids.map(_chant).toList(),
    skip: 0,
    limit: 20,
    total: ids.length,
  ).toJson(),
);

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  final key = ScreenCacheKey.public('chants_page1', language: 'en');

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
  });

  List<List<String>> ids(List<PracticeRecitationsState> states) => [
    for (final s in states)
      if (!s.isLoading) s.recitations.map((r) => r.textId).toList(),
  ];

  test('the stored page renders first, then the server page', () async {
    store.entries[key] = _stored(['1']);
    remote.recitations = [_chant('1'), _chant('2')];
    final notifier = PracticeRecitationsNotifier(
      datasource: remote,
      store: store,
      languageCode: 'en',
      includeCollections: false,
    );
    addTearDown(notifier.dispose);
    final states = <PracticeRecitationsState>[];
    notifier.addListener(states.add);
    await pumpEventQueue();

    final rendered = ids(states).where((l) => l.isNotEmpty).toList();
    expect(rendered.first, ['1']);
    expect(rendered.last, ['1', '2']);
    expect(remote.calls.single.noCache, isTrue);
    expect(store.entries[key], _stored(['1', '2']));
  });

  test('a failed refresh keeps the stored page without an error', () async {
    store.entries[key] = _stored(['1']);
    remote.error = const NetworkException('offline');
    final notifier = PracticeRecitationsNotifier(
      datasource: remote,
      store: store,
      languageCode: 'en',
      includeCollections: false,
    );
    addTearDown(notifier.dispose);
    await pumpEventQueue();

    expect(notifier.state.recitations.map((r) => r.textId), ['1']);
    expect(notifier.state.error, isNull);
    expect(notifier.state.isLoading, isFalse);
  });

  test('nothing stored and no network is an error state', () async {
    remote.error = const NetworkException('offline');
    final notifier = PracticeRecitationsNotifier(
      datasource: remote,
      store: store,
      languageCode: 'en',
      includeCollections: false,
    );
    addTearDown(notifier.dispose);
    await pumpEventQueue();

    expect(notifier.state.isEmpty, isTrue);
    expect(notifier.state.error, isNotNull);
  });
}
