import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/datasource/author_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/models/author/author_model.dart';
import 'package:flutter_pecha/features/plans/data/repositories/author_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FakeRemote extends AuthorRemoteDatasource {
  _FakeRemote() : super(dio: Dio());

  String bio = 'first';
  Exception? error;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetchAuthorJson(String authorId) async {
    calls++;
    if (error != null) throw error!;
    return _author(authorId, bio: bio);
  }
}

Map<String, dynamic> _author(String id, {required String bio}) => {
  'id': id,
  'firstname': 'Tenzin',
  'lastname': 'D',
  'email': 't@example.com',
  'bio': bio,
};

String? _bio(Either<Failure, AuthorModel> e) =>
    e.fold((_) => null, (author) => author.bio);

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  late AuthorRepository repo;
  final key = ScreenCacheKey.public('author', language: 'all', params: ['a1']);

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
    repo = AuthorRepository(authorRemoteDatasource: remote, store: store);
  });

  test('watch yields the stored author, then the changed one', () async {
    store.entries[key] = jsonEncode(_author('a1', bio: 'old'));
    remote.bio = 'new';

    final events = <Either<Failure, AuthorModel>>[];
    final sub = repo.watchAuthorById('a1').listen(events.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    expect(events.map(_bio), ['old', 'new']);
    expect(remote.calls, 1);
  });

  test('refresh writes the store and an open stream picks it up', () async {
    final events = <Either<Failure, AuthorModel>>[];
    final sub = repo.watchAuthorById('a1').listen(events.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    remote.bio = 'updated';
    final result = await repo.refreshAuthorById('a1');
    await pumpEventQueue();

    expect(_bio(result), 'updated');
    expect(_bio(events.last), 'updated');
  });

  test('a first load with no network is a NetworkFailure', () async {
    remote.error = const NetworkException('offline');
    final first = await repo.watchAuthorById('a1').first;
    expect(first.getLeft().toNullable(), isA<NetworkFailure>());
  });
}
