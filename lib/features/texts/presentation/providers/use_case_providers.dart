import 'package:flutter_pecha/features/library/data/adapters/library_segment_repository.dart';
import 'package:flutter_pecha/features/library/data/adapters/library_text_remote_datasource.dart';
import 'package:flutter_pecha/features/library/presentation/providers/library_providers.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_detail_with_text.dart';
import 'package:flutter_pecha/features/texts/data/repositories/texts_repository.dart';
import 'package:flutter_pecha/features/texts/domain/repositories/segment_repository.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/segment_usecases.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/text_content_usecases.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/text_search_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Repository Providers ==========

/// Provider for the TextsRepository (data layer implementation).
/// Reader details and in-text search come from the library API.
final textsRepositoryProvider = Provider<TextsRepository>((ref) {
  return TextsRepository(
    remoteDatasource: LibraryTextRemoteDatasource(
      library: ref.watch(libraryRepositoryProvider),
    ),
  );
});

/// Provider for the SegmentRepository implementation (domain interface).
final segmentDomainRepositoryProvider =
    Provider<SegmentRepositoryInterface>((ref) {
  return LibrarySegmentRepository(
    library: ref.watch(libraryRepositoryProvider),
  );
});

// ========== Content Use Case Providers ==========

/// Provider for GetTextDetailsUseCase.
final getTextDetailsUseCaseProvider = Provider<GetTextDetailsUseCase>((ref) {
  final repository = ref.watch(textsRepositoryProvider);
  return GetTextDetailsUseCase(repository);
});

// ========== Search Use Case Providers ==========

/// Provider for MultilingualSearchUseCase.
final multilingualSearchUseCaseProvider = Provider<MultilingualSearchUseCase>((ref) {
  final repository = ref.watch(textsRepositoryProvider);
  return MultilingualSearchUseCase(repository);
});

// ========== Segment Use Case Providers ==========

/// Provider for GetSegmentInfoUseCase.
final getSegmentInfoUseCaseProvider = Provider<GetSegmentInfoUseCase>((ref) {
  return GetSegmentInfoUseCase(ref.watch(segmentDomainRepositoryProvider));
});

/// Provider for GetSegmentCommentariesUseCase.
final getSegmentCommentariesUseCaseProvider =
    Provider<GetSegmentCommentariesUseCase>((ref) {
  return GetSegmentCommentariesUseCase(
    ref.watch(segmentDomainRepositoryProvider),
  );
});

/// Provider for GetSegmentTranslationsUseCase.
final getSegmentTranslationsUseCaseProvider =
    Provider<GetSegmentTranslationsUseCase>((ref) {
  return GetSegmentTranslationsUseCase(
    ref.watch(segmentDomainRepositoryProvider),
  );
});

// ========== Segment Detail Provider ==========

final segmentDetailProvider = FutureProvider.autoDispose
    .family<SegmentDetailWithText, String>((ref, segmentId) async {
  final repo = ref.watch(segmentDomainRepositoryProvider);
  return repo.getSegmentWithTextDetails(segmentId);
});
