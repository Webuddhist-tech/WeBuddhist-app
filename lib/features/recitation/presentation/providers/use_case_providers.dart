import 'package:flutter_pecha/features/recitation/data/repositories/recitation_repository_impl.dart';
import 'package:flutter_pecha/features/recitation/domain/repositories/recitation_repository.dart';
import 'package:flutter_pecha/features/recitation/domain/usecases/recitation_usecases.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_datasource_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Repository Providers ==========

/// Provider for RecitationRepository implementation.
final recitationRepositoryProvider = Provider<RecitationRepository>((ref) {
  return RecitationRepositoryImpl(
    datasource: ref.watch(recitationsRemoteDatasourceProvider),
  );
});

// ========== Use Case Providers ==========

/// Provider for GetRecitationsUseCase.
final getRecitationsUseCaseProvider = Provider<GetRecitationsUseCase>((ref) {
  final repository = ref.watch(recitationRepositoryProvider);
  return GetRecitationsUseCase(repository);
});

/// Provider for SearchRecitationsUseCase.
final searchRecitationsUseCaseProvider = Provider<SearchRecitationsUseCase>((ref) {
  final repository = ref.watch(recitationRepositoryProvider);
  return SearchRecitationsUseCase(repository);
});
