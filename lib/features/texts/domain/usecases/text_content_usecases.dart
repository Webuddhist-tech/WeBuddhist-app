import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/version_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/commentary_text_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_pecha/features/texts/data/repositories/texts_repository.dart';

/// Get text content (TOC) use case.
class GetTextContentUseCase extends UseCase<TocResponse, GetTextContentParams> {
  final TextsRepository _repository;

  GetTextContentUseCase(this._repository);

  @override
  Future<Either<Failure, TocResponse>> call(GetTextContentParams params) async {
    if (params.textId.isEmpty) {
      return const Left(ValidationFailure('Text ID cannot be empty'));
    }
    return await _repository.fetchTextContent(
      textId: params.textId,
      language: params.language,
    );
  }
}

class GetTextContentParams {
  final String textId;
  final String? language;

  const GetTextContentParams({
    required this.textId,
    this.language,
  });
}

/// Get text version use case.
class GetTextVersionUseCase extends UseCase<VersionResponse, GetTextVersionParams> {
  final TextsRepository _repository;

  GetTextVersionUseCase(this._repository);

  @override
  Future<Either<Failure, VersionResponse>> call(GetTextVersionParams params) async {
    if (params.textId.isEmpty) {
      return const Left(ValidationFailure('Text ID cannot be empty'));
    }
    return await _repository.fetchTextVersion(
      textId: params.textId,
      language: params.language,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetTextVersionParams {
  final String textId;
  final String? language;
  final bool forceRefresh;

  const GetTextVersionParams({
    required this.textId,
    this.language,
    this.forceRefresh = false,
  });
}

/// Get commentary text use case.
class GetCommentaryTextUseCase extends UseCase<CommentaryTextResponse, GetCommentaryTextParams> {
  final TextsRepository _repository;

  GetCommentaryTextUseCase(this._repository);

  @override
  Future<Either<Failure, CommentaryTextResponse>> call(GetCommentaryTextParams params) async {
    if (params.textId.isEmpty) {
      return const Left(ValidationFailure('Text ID cannot be empty'));
    }
    return await _repository.fetchCommentaryText(
      textId: params.textId,
      language: params.language,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetCommentaryTextParams {
  final String textId;
  final String? language;
  final bool forceRefresh;

  const GetCommentaryTextParams({
    required this.textId,
    this.language,
    this.forceRefresh = false,
  });
}

/// Get text details (reader content) use case.
class GetTextDetailsUseCase extends UseCase<ReaderResponse, GetTextDetailsParams> {
  final TextsRepository _repository;

  GetTextDetailsUseCase(this._repository);

  @override
  Future<Either<Failure, ReaderResponse>> call(GetTextDetailsParams params) async {
    if (params.textId.isEmpty) {
      return const Left(ValidationFailure('Text ID cannot be empty'));
    }
    return await _repository.fetchTextDetails(
      textId: params.textId,
      contentId: params.contentId,
      versionId: params.versionId,
      segmentId: params.segmentId,
      direction: params.direction,
      language: params.language,
      size: params.size,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetTextDetailsParams {
  final String textId;
  final String? contentId;
  final String? versionId;
  final String? segmentId;
  final String? direction;
  final String? language;
  final int? size;
  final bool forceRefresh;

  const GetTextDetailsParams({
    required this.textId,
    this.contentId,
    this.versionId,
    this.segmentId,
    this.direction,
    this.language,
    this.size,
    this.forceRefresh = false,
  });
}
