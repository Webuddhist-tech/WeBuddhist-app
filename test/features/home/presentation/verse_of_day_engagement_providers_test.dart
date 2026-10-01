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
  final likes = Completer<Either<Failure, VerseOfDayLikes>>();
  var commentsReply = Completer<Either<Failure, VerseOfDayCommentsPage>>();
  int likeCalls = 0;

  @override
  Future<Either<Failure, VerseOfDayLikes>> getLikes(String verseId) =>
      likes.future;

  @override
  Future<Either<Failure, Unit>> likeVerse(String verseId) async {
    likeCalls++;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, VerseOfDayCommentsPage>> getComments({
    required String verseId,
    int skip = 0,
    int limit = 20,
  }) => commentsReply.future;

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
