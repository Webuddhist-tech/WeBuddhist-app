import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/connect/data/models/connect_post_model.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_post_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_post_model.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_post_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote extends Fake implements GroupPostRemoteDatasource {
  final List<String> calls = [];
  Set<String> failing = {};

  Future<ConnectPostModel?> _step(String name) async {
    calls.add(name);
    if (failing.contains(name)) throw ServerException('$name failed');
    return null;
  }

  @override
  Future<ConnectPostModel?> updatePost(
    String groupId,
    String postId, {
    required String caption,
    required String status,
  }) => _step('caption');

  @override
  Future<ConnectPostModel?> updatePostMedia(
    String groupId,
    String postId,
    List<GroupPostMediaRequest> media,
  ) => _step('media');

  @override
  Future<ConnectPostModel?> updatePostLinks(
    String groupId,
    String postId,
    List<GroupPostLinkRequest> links,
  ) => _step('links');
}

void main() {
  const media = [GroupPostMediaRequest(mediaKey: 'k', displayOrder: 1)];
  const links = [
    GroupPostLinkRequest(type: 'WEB', url: 'https://x.y', displayOrder: 1),
  ];

  late _FakeRemote remote;
  late GroupPostRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    repository = GroupPostRepositoryImpl(remote: remote);
  });

  test('reports which parts persisted when a later request fails', () async {
    remote.failing = {'links'};

    final result = await repository.updatePost(
      'g1',
      'p1',
      caption: 'hi',
      media: media,
      links: links,
    );

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<PartialPostUpdateFailure>());
    final partial = failure as PartialPostUpdateFailure;
    expect(partial.captionSaved, isTrue);
    expect(partial.mediaSaved, isTrue);
    expect(partial.linksSaved, isFalse);
    expect(remote.calls, ['caption', 'media', 'links']);
  });

  test('stops at the first failure', () async {
    remote.failing = {'media'};

    final result = await repository.updatePost(
      'g1',
      'p1',
      caption: 'hi',
      media: media,
      links: links,
    );

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<PartialPostUpdateFailure>());
    final partial = failure as PartialPostUpdateFailure;
    expect(partial.captionSaved, isTrue);
    expect(partial.mediaSaved, isFalse);
    expect(partial.linksSaved, isFalse);
    expect(remote.calls, ['caption', 'media']);
  });

  test('returns a plain failure when nothing persisted', () async {
    remote.failing = {'caption'};

    final result = await repository.updatePost(
      'g1',
      'p1',
      caption: 'hi',
      media: media,
    );

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<ServerFailure>());
    expect(failure, isNot(isA<PartialPostUpdateFailure>()));
    expect(remote.calls, ['caption']);
  });

  test('succeeds with null when every request returns no body', () async {
    final result = await repository.updatePost('g1', 'p1', caption: 'hi');

    expect(result.isRight(), isTrue);
    expect(result.fold((_) => null, (post) => post), isNull);
  });
}
