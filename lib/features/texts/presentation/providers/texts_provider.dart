import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/text_content_usecases.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/text_search_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'use_case_providers.dart';

class TextDetailsParams {
  final String textId;
  final String? contentId;
  final String? versionId;
  final String? segmentId;
  final String? direction;
  final String? language;
  final int? size;
  final String key;
  const TextDetailsParams({
    required this.textId,
    this.contentId,
    this.versionId,
    this.segmentId,
    this.direction,
    this.language,
    this.size,
  }) : key =
           '${textId}_${contentId ?? ''}_${versionId ?? ''}_${segmentId ?? ''}_${direction ?? ''}_${language ?? ''}_${size ?? ''}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextDetailsParams &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}

final textDetailsFutureProvider = FutureProvider.family<Either<Failure, ReaderResponse>, TextDetailsParams>((
  ref,
  TextDetailsParams params,
) async {
  final getTextDetailsUseCase = ref.watch(getTextDetailsUseCaseProvider);

  return getTextDetailsUseCase(GetTextDetailsParams(
    textId: params.textId,
    contentId: params.contentId,
    versionId: params.versionId,
    segmentId: params.segmentId,
    direction: params.direction,
    language: params.language,
    size: params.size,
  ));
});

class LibrarySearchParams {
  final String query;
  final String? textId;
  final String? language;
  const LibrarySearchParams({required this.query, this.textId, this.language});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibrarySearchParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          textId == other.textId &&
          language == other.language;

  @override
  int get hashCode => query.hashCode ^ textId.hashCode ^ language.hashCode;
}

final multilingualSearchProvider = FutureProvider.family<Either<Failure, MultilingualSearchResponse>, LibrarySearchParams>((
  ref,
  LibrarySearchParams params,
) async {
  final multilingualSearchUseCase = ref.watch(multilingualSearchUseCaseProvider);
  // Use provided language parameter, otherwise fall back to locale
  final language = params.language ?? ref.watch(contentLanguageProvider);

  return multilingualSearchUseCase(MultilingualSearchParams(
    query: params.query,
    language: language,
    textId: params.textId,
  ));
});
