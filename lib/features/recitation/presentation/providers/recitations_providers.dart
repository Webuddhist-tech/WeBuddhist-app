import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/recitations_repository.dart';
import '../../data/models/recitation_model.dart';
import '../../data/models/recitation_content_model.dart';
import 'recitation_search_provider.dart';
import 'recitations_datasource_provider.dart';

// Params class for recitation content
class RecitationContentParams {
  final String textId;
  final String language;
  final List<String>? recitations;
  final List<String>? translations;
  final List<String>? transliterations;
  final List<String>? adaptations;

  const RecitationContentParams({
    required this.textId,
    required this.language,
    this.recitations,
    this.translations,
    this.transliterations,
    this.adaptations,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecitationContentParams &&
          runtimeType == other.runtimeType &&
          textId == other.textId &&
          language == other.language &&
          listEquals(recitations, other.recitations) &&
          listEquals(translations, other.translations) &&
          listEquals(transliterations, other.transliterations) &&
          listEquals(adaptations, other.adaptations);

  @override
  int get hashCode => Object.hash(
    textId,
    language,
    recitations != null ? Object.hashAll(recitations!) : null,
    translations != null ? Object.hashAll(translations!) : null,
    transliterations != null ? Object.hashAll(transliterations!) : null,
    adaptations != null ? Object.hashAll(adaptations!) : null,
  );
}

// Repository provider
final recitationsRepositoryProvider = Provider<RecitationsRepository>((ref) {
  return RecitationsRepository(
    recitationsRemoteDatasource: ref.watch(recitationsRemoteDatasourceProvider),
  );
});

// Get all recitations provider
final recitationsFutureProvider = FutureProvider<Either<Failure, List<RecitationModel>>>((ref) {
  final languageCode = ref.watch(contentLanguageProvider);
  return ref
      .watch(recitationsRepositoryProvider)
      .getRecitations(language: languageCode);
});

// Get saved recitations provider
final savedRecitationsFutureProvider = FutureProvider<Either<Failure, List<RecitationModel>>>((
  ref,
) {
  return ref.watch(recitationsRepositoryProvider).getSavedRecitations();
});

// Get recitation content by ID
final recitationContentProvider =
    FutureProvider.family<Either<Failure, RecitationContentModel>, RecitationContentParams>((
      ref,
      params,
    ) {
      return ref
          .watch(recitationsRepositoryProvider)
          .getRecitationContent(
            params.textId,
            params.language,
            params.recitations,
            params.translations,
            params.transliterations,
            params.adaptations,
          );
    });

// Search recitations provider
final searchRecitationsProvider =
    FutureProvider.family<Either<Failure, List<RecitationModel>>, String>((ref, searchQuery) {
      final languageCode = ref.watch(contentLanguageProvider);
      return ref
          .watch(recitationsRepositoryProvider)
          .getRecitations(language: languageCode, searchQuery: searchQuery);
    });

// Recitation search state provider with debounce
final recitationSearchProvider =
    StateNotifierProvider<RecitationSearchNotifier, RecitationSearchState>((
      ref,
    ) {
      final repository = ref.watch(recitationsRepositoryProvider);
      final languageCode = ref.watch(contentLanguageProvider);
      return RecitationSearchNotifier(
        repository: repository,
        languageCode: languageCode,
      );
    });

// Mutation providers for recitations
final saveRecitationProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, String>((ref, recitationId) {
  return ref.watch(recitationsRepositoryProvider).saveRecitation(recitationId);
});

final unsaveRecitationProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, String>((ref, recitationId) {
      return ref
          .watch(recitationsRepositoryProvider)
          .unsaveRecitation(recitationId);
    });

final updateRecitationsOrderProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, List<Map<String, dynamic>>>((ref, recitations) {
      return ref
          .watch(recitationsRepositoryProvider)
          .updateRecitationsOrder(recitations);
    });

// Toggle providers for showing/hiding second and third content segments
// The actual content type depends on the language's content order
final showSecondSegmentProvider = StateProvider<bool>((ref) => false);
final showThirdSegmentProvider = StateProvider<bool>((ref) => false);
