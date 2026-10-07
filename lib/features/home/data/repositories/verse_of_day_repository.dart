import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_local_datasource.dart';
import 'package:flutter_pecha/features/home/data/datasource/verse_of_day_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day_engagement.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';

class VerseOfDayRepository implements VerseOfDayRepositoryInterface {
  final VerseOfDayRemoteDatasource remote;
  final HomeLocalDatasource local;

  VerseOfDayRepository({required this.remote, required this.local});

  @override
  Future<Either<Failure, VerseOfDay>> getVerseOfDay({
    required String language,
  }) async {
    final cached = local.readVerseOfDay(language);
    if (cached != null) {
      unawaited(_refresh(language));
      return Right(cached.toEntity());
    }

    try {
      final model = await remote.fetchVerseOfDay(language: language);
      await local.saveVerseOfDay(language, model);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to get verse of day'));
    }
  }

  @override
  Stream<Either<Failure, VerseOfDay>> watchVerseOfDay({
    required String language,
  }) async* {
    final key = local.verseOfDayKey(language);
    final cached = local.readVerseOfDay(language);
    if (cached != null) yield Right(cached.toEntity());

    try {
      await _refresh(language);
      final refreshed = local.readVerseOfDay(language);
      if (refreshed != null) yield Right(refreshed.toEntity());
    } catch (e) {
      if (cached == null) {
        yield Left(_toFailure(e, 'Failed to get verse of day'));
      }
    }

    await for (final _ in local.watchKey(key)) {
      final latest = local.readVerseOfDay(language);
      if (latest != null) yield Right(latest.toEntity());
    }
  }

  @override
  Future<Either<Failure, VerseOfDayLikes>> getLikes(String verseId) async {
    try {
      final model = await remote.fetchLikes(verseId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to load likes'));
    }
  }

  @override
  Future<Either<Failure, Unit>> likeVerse(String verseId) async {
    try {
      await remote.likeVerse(verseId);
      return const Right(unit);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to like verse'));
    }
  }

  @override
  Future<Either<Failure, Unit>> unlikeVerse(String verseId) async {
    try {
      await remote.unlikeVerse(verseId);
      return const Right(unit);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to unlike verse'));
    }
  }

  @override
  Future<Either<Failure, VerseOfDayLikersPage>> getLikers({
    required String verseId,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final model = await remote.fetchLikers(
        verseId: verseId,
        skip: skip,
        limit: limit,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to load likers'));
    }
  }

  @override
  Future<Either<Failure, VerseOfDayCommentsPage>> getComments({
    required String verseId,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final model = await remote.fetchComments(
        verseId: verseId,
        skip: skip,
        limit: limit,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to load comments'));
    }
  }

  @override
  Future<Either<Failure, VerseOfDayComment>> getComment({
    required String verseId,
    required String commentId,
  }) async {
    try {
      final model = await remote.fetchComment(
        verseId: verseId,
        commentId: commentId,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to load comment'));
    }
  }

  @override
  Future<Either<Failure, VerseOfDayComment>> createComment({
    required String verseId,
    required String text,
    String? parentCommentId,
  }) async {
    try {
      final model = await remote.createComment(
        verseId: verseId,
        text: text,
        parentCommentId: parentCommentId,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to post comment'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteComment(String commentId) async {
    try {
      await remote.deleteComment(commentId);
      return const Right(unit);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to delete comment'));
    }
  }

  @override
  Future<Either<Failure, Unit>> likeComment(String commentId) async {
    try {
      await remote.likeComment(commentId);
      return const Right(unit);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to like comment'));
    }
  }

  @override
  Future<Either<Failure, Unit>> unlikeComment(String commentId) async {
    try {
      await remote.unlikeComment(commentId);
      return const Right(unit);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to unlike comment'));
    }
  }

  Future<void> _refresh(String language) async {
    final model = await remote.fetchVerseOfDay(language: language);
    await local.saveVerseOfDay(language, model);
  }

  Failure _toFailure(Object error, String fallback) {
    if (error is ServerException) return ServerFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is AuthenticationException) {
      return AuthenticationFailure(error.message);
    }
    if (error is RateLimitException) return RateLimitFailure(error.message);
    return UnknownFailure('$fallback: $error');
  }
}
