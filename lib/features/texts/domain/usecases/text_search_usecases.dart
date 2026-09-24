import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_pecha/features/texts/data/repositories/texts_repository.dart';

/// Multilingual search use case.
class MultilingualSearchUseCase extends UseCase<MultilingualSearchResponse, MultilingualSearchParams> {
  final TextsRepository _repository;

  MultilingualSearchUseCase(this._repository);

  @override
  Future<Either<Failure, MultilingualSearchResponse>> call(MultilingualSearchParams params) async {
    if (params.query.trim().isEmpty) {
      return const Left(ValidationFailure('Search query cannot be empty'));
    }
    return await _repository.multilingualSearchRepository(
      query: params.query,
      language: params.language,
      textId: params.textId,
    );
  }
}

class MultilingualSearchParams {
  final String query;
  final String? language;
  final String? textId;

  const MultilingualSearchParams({
    required this.query,
    this.language,
    this.textId,
  });
}
