import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_pecha/features/texts/data/repositories/texts_repository.dart';

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
