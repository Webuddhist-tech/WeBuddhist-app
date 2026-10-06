import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day_engagement.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/home/presentation/providers/verse_of_day_engagement_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth() : super(const AuthState(isLoggedIn: true));

  void signOut() => state = const AuthState(isLoggedIn: false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repo implements VerseOfDayRepositoryInterface {
  var likes = Completer<Either<Failure, VerseOfDayLikes>>();
  var commentsReply = Completer<Either<Failure, VerseOfDayCommentsPage>>();
  int likeCalls = 0;
  Either<Failure, Unit> commentLikeReply = const Right(unit);
  final commentLikeCalls = <String>[];
  final likersSkips = <int>[];

  @override
  Future<Either<Failure, VerseOfDayLikes>> getLikes(String verseId) =>
      likes.future;

  @override
  Future<Either<Failure, Unit>> likeVerse(String verseId) async {
    likeCalls++;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteComment(String commentId) async =>
      const Right(unit);

  @override
  Future<Either<Failure, VerseOfDayCommentsPage>> getComments({
    required String verseId,
    int skip = 0,
    int limit = 20,
  }) => commentsReply.future;

  @override
  Future<Either<Failure, Unit>> likeComment(String commentId) async {
    commentLikeCalls.add('like');
    return commentLikeReply;
  }

  @override
  Future<Either<Failure, Unit>> unlikeComment(String commentId) async {
    commentLikeCalls.add('unlike');
    return commentLikeReply;
  }

  @override
  Future<Either<Failure, VerseOfDayLikersPage>> getLikers({
    required String verseId,
    int skip = 0,
    int limit = 20,
  }) async {
    likersSkips.add(skip);
    return Right(
      VerseOfDayLikersPage(
        likers: [
          VerseOfDayLiker(
            userId: 'u$skip',
            user: const VerseOfDayCommentUser(firstName: 'Pema'),
          ),
        ],
        skip: skip,
        limit: limit,
        total: 2,
      ),
    );
  }

  @override
  Future<Either<Failure, VerseOfDayComment>> createComment({
    required String verseId,
    required String text,
  }) async => Right(_comment('new', text));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

VerseOfDayComment _comment(String id, [String text = 'hi']) =>
    VerseOfDayComment(
      id: id,
      verseId: 'v1',
      user: const VerseOfDayCommentUser(firstName: 'Pema'),
      text: text,
    );

void main() {
  late _Repo repo;
  late _Auth auth;
  late ProviderContainer container;

  setUp(() {
    repo = _Repo();
    auth = _Auth();
    container = ProviderContainer(
      overrides: [
        verseOfDayDomainRepositoryProvider.overrideWithValue(repo),
        authProvider.overrideWith((ref) => auth),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('like tap before the first load is ignored', () async {
    final sub = container.listen(verseOfDayLikesProvider('v1'), (_, _) {});
    final notifier = container.read(verseOfDayLikesProvider('v1').notifier);

    await notifier.toggle();
    expect(repo.likeCalls, 0);

    repo.likes.complete(
      const Right(
        VerseOfDayLikes(verseId: 'v1', likeCount: 4, likedByMe: true),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().likedByMe, isTrue);
    expect(sub.read().likeCount, 4);
  });

  test('failed likes load hides the count and a tap retries it', () async {
    final sub = container.listen(verseOfDayLikesProvider('v1'), (_, _) {});
    final notifier = container.read(verseOfDayLikesProvider('v1').notifier);

    repo.likes.complete(const Left(NetworkFailure('offline')));
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().isLoaded, isFalse);

    repo.likes = Completer();
    final tap = notifier.toggle();
    repo.likes.complete(
      const Right(
        VerseOfDayLikes(verseId: 'v1', likeCount: 4, likedByMe: false),
      ),
    );
    expect(await tap, isNull);
    expect(repo.likeCalls, 1);
    expect(sub.read().likedByMe, isTrue);
    expect(sub.read().likeCount, 5);
  });

  test('a tap on a failed load that turns out liked sends nothing', () async {
    final sub = container.listen(verseOfDayLikesProvider('v1'), (_, _) {});
    final notifier = container.read(verseOfDayLikesProvider('v1').notifier);
    repo.likes.complete(const Left(NetworkFailure('offline')));
    await Future<void>.delayed(Duration.zero);

    repo.likes =
        Completer()..complete(
          const Right(
            VerseOfDayLikes(verseId: 'v1', likeCount: 4, likedByMe: true),
          ),
        );
    expect(await notifier.toggle(), isNull);
    expect(repo.likeCalls, 0);
    expect(sub.read().likedByMe, isTrue);
    expect(sub.read().likeCount, 4);
  });

  test('a refresh that started before a tap does not undo it', () async {
    final sub = container.listen(verseOfDayLikesProvider('v1'), (_, _) {});
    final notifier = container.read(verseOfDayLikesProvider('v1').notifier);
    repo.likes.complete(
      const Right(
        VerseOfDayLikes(verseId: 'v1', likeCount: 4, likedByMe: false),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    repo.likes = Completer();
    final refresh = notifier.load();
    await notifier.toggle();
    repo.likes.complete(
      const Right(
        VerseOfDayLikes(verseId: 'v1', likeCount: 4, likedByMe: false),
      ),
    );
    await refresh;
    expect(sub.read().likedByMe, isTrue);
    expect(sub.read().likeCount, 5);
  });

  test(
    'refresh replaces the list but keeps new posts and drops deletes',
    () async {
      final sub = container.listen(verseOfDayCommentsProvider('v1'), (_, _) {});
      final notifier = container.read(
        verseOfDayCommentsProvider('v1').notifier,
      );
      repo.commentsReply.complete(
        Right(
          VerseOfDayCommentsPage(
            comments: [_comment('a'), _comment('b')],
            skip: 0,
            limit: 20,
            total: 2,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      repo.commentsReply = Completer();
      final refresh = notifier.loadInitial();
      await notifier.deleteComment('b');
      await notifier.submitComment('new');
      repo.commentsReply.complete(
        Right(
          VerseOfDayCommentsPage(
            comments: [_comment('c'), _comment('a'), _comment('b')],
            skip: 0,
            limit: 20,
            total: 3,
          ),
        ),
      );
      await refresh;

      expect(sub.read().comments.map((c) => c.id), ['new', 'c', 'a']);
    },
  );

  test('comment posted during the first load survives its reply', () async {
    final sub = container.listen(verseOfDayCommentsProvider('v1'), (_, _) {});
    final notifier = container.read(verseOfDayCommentsProvider('v1').notifier);

    await notifier.submitComment('new');
    repo.commentsReply.complete(
      Right(
        VerseOfDayCommentsPage(
          comments: [_comment('old')],
          skip: 0,
          limit: 20,
          total: 1,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final state = sub.read();
    expect(state.comments.map((c) => c.id), ['new', 'old']);
    expect(state.total, 2);
    expect(state.skip, 2);
  });

  test('comment like toggles optimistically and unlikes on the next tap', () async {
    final sub = container.listen(verseOfDayCommentsProvider('v1'), (_, _) {});
    final notifier = container.read(verseOfDayCommentsProvider('v1').notifier);
    await notifier.submitComment('new');

    final liking = notifier.toggleCommentLike('new');
    expect(sub.read().comments.single.likedByMe, isTrue);
    expect(sub.read().comments.single.likeCount, 1);
    expect(await liking, isNull);

    expect(await notifier.toggleCommentLike('new'), isNull);
    expect(sub.read().comments.single.likedByMe, isFalse);
    expect(sub.read().comments.single.likeCount, 0);
    expect(repo.commentLikeCalls, ['like', 'unlike']);
  });

  test('failed comment like reverts and reports the failure', () async {
    final sub = container.listen(verseOfDayCommentsProvider('v1'), (_, _) {});
    final notifier = container.read(verseOfDayCommentsProvider('v1').notifier);
    await notifier.submitComment('new');
    repo.commentLikeReply = const Left(ServerFailure('boom'));

    expect(await notifier.toggleCommentLike('new'), 'boom');
    expect(sub.read().comments.single.likedByMe, isFalse);
    expect(sub.read().comments.single.likeCount, 0);
  });

  test('likers load page by page until the total is reached', () async {
    final sub = container.listen(verseOfDayLikersProvider('v1'), (_, _) {});
    final notifier = container.read(verseOfDayLikersProvider('v1').notifier);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().likers.map((l) => l.userId), ['u0']);
    expect(sub.read().hasMore, isTrue);

    await notifier.loadMore();
    await notifier.loadMore();
    expect(sub.read().likers.map((l) => l.userId), ['u0', 'u1']);
    expect(sub.read().hasMore, isFalse);
    expect(repo.likersSkips, [0, 1]);
  });

  test('own comment ids reset when the account changes', () async {
    final sub = container.listen(verseOfDayCommentsProvider('v1'), (_, _) {});
    await container
        .read(verseOfDayCommentsProvider('v1').notifier)
        .submitComment('new');
    expect(sub.read().ownCommentIds, {'new'});

    repo.commentsReply = Completer();
    auth.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().ownCommentIds, isEmpty);
  });
}
