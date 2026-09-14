import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/texts/data/models/text/detail_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/version_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/commentary_text_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/title_search_response.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/text_content_usecases.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/text_search_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'use_case_providers.dart';

// Re-export the search param classes for backward compatibility
export 'package:flutter_pecha/features/texts/domain/usecases/text_search_usecases.dart'
    show TitleSearchParams, AuthorSearchParams;

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

final textsFutureProvider = FutureProvider.family<Either<Failure, TextDetailResponse>, String>((ref, String termId) {
  final languageCode = ref.watch(contentLanguageProvider);
  final repository = ref.watch(textsRepositoryProvider);
  return repository.getTexts(termId: termId, language: languageCode);
});

final textContentFutureProvider = FutureProvider.family<Either<Failure, TocResponse>, String>((ref, String textId) async {
  final languageCode = ref.watch(contentLanguageProvider);
  final getTextContentUseCase = ref.watch(getTextContentUseCaseProvider);

  return getTextContentUseCase(GetTextContentParams(
    textId: textId,
    language: languageCode,
  ));
});

final textVersionFutureProvider = FutureProvider.family<Either<Failure, VersionResponse>, String>((ref, String textId) async {
  final languageCode = ref.watch(contentLanguageProvider);
  final getTextVersionUseCase = ref.watch(getTextVersionUseCaseProvider);

  return getTextVersionUseCase(GetTextVersionParams(
    textId: textId,
    language: languageCode,
  ));
});

final commentaryTextFutureProvider = FutureProvider.family<Either<Failure, CommentaryTextResponse>, String>((
  ref,
  String textId,
) async {
  final languageCode = ref.watch(contentLanguageProvider);
  final getCommentaryTextUseCase = ref.watch(getCommentaryTextUseCaseProvider);

  return getCommentaryTextUseCase(GetCommentaryTextParams(
    textId: textId,
    language: languageCode,
  ));
});

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

class SearchTextParams {
  final String query;
  final String textId;
  const SearchTextParams({required this.query, required this.textId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchTextParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          textId == other.textId;

  @override
  int get hashCode => query.hashCode ^ textId.hashCode;
}

final searchTextFutureProvider = FutureProvider.family<Either<Failure, SearchResponse>, SearchTextParams>((
  ref,
  SearchTextParams params,
) async {
  final searchTextInTextUseCase = ref.watch(searchTextInTextUseCaseProvider);

  return searchTextInTextUseCase(SearchTextInTextParams(
    query: params.query,
    textId: params.textId,
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

final librarySearchProvider = FutureProvider.family<Either<Failure, SearchResponse>, LibrarySearchParams>((
  ref,
  LibrarySearchParams params,
) async {
  final searchTextInTextUseCase = ref.watch(searchTextInTextUseCaseProvider);

  return searchTextInTextUseCase(SearchTextInTextParams(
    query: params.query,
    textId: params.textId,
  ));
});

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

// Export the param classes from use cases for backward compatibility
final titleSearchProvider = FutureProvider.family<Either<Failure, TitleSearchResponse>, TitleSearchParams>((
  ref,
  TitleSearchParams params,
) async {
  final titleSearchUseCase = ref.watch(titleSearchUseCaseProvider);

  return titleSearchUseCase(params);
});

final authorSearchProvider = FutureProvider.family<Either<Failure, TitleSearchResponse>, AuthorSearchParams>((
  ref,
  AuthorSearchParams params,
) async {
  final authorSearchUseCase = ref.watch(authorSearchUseCaseProvider);

  return authorSearchUseCase(params);
});
