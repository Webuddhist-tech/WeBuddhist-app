import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plans_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/author_repository.dart';
import '../../data/datasource/author_remote_datasource.dart';
import '../../data/models/author/author_model.dart';

// Repository provider
final authorRepositoryProvider = Provider<AuthorRepository>((ref) {
  return AuthorRepository(
    authorRemoteDatasource: AuthorRemoteDatasource(
      dio: ref.watch(dioProvider),
    ),
    store: ref.watch(screenCacheStoreProvider),
  );
});

// Stored author first, refreshed in the background (name kept for callers).
final authorByIdFutureProvider =
    StreamProvider.family<Either<Failure, AuthorModel>, String>((ref, id) {
      return ref.watch(authorRepositoryProvider).watchAuthorById(id);
    });

// Stored plans page first (repository reads Hive), filtered by author.
final authorPlansFutureProvider =
    StreamProvider.family<Either<Failure, List<Plan>>, String>((
      ref,
      authorId,
    ) async* {
      final getPlansUseCase = ref.watch(getPlansUseCaseProvider);
      final local = ref.watch(plansLocalDatasourceProvider);
      const language = 'en';
      const limit = 100;

      List<Plan> byAuthor(List<Plan> plans) =>
          plans.where((plan) => plan.authorId == authorId).toList();

      final result = await getPlansUseCase(
        const GetPlansParams(language: language, limit: limit),
      );
      yield result.map(byAuthor);

      final key = local.plansKey(language: language, limit: limit);
      await for (final _ in local.watchKey(key)) {
        final cached = local.readPlans(language: language, limit: limit);
        if (cached != null) {
          yield Right(byAuthor(cached.map((plan) => plan.toEntity()).toList()));
        }
      }
    });

// Author state notifier for managing local state
class AuthorState {
  final List<AuthorModel> authors;
  final bool isLoading;
  final String? errorMessage;

  const AuthorState({
    this.authors = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AuthorState copyWith({
    List<AuthorModel>? authors,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthorState(
      authors: authors ?? this.authors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthorNotifier extends StateNotifier<AuthorState> {
  final AuthorRepository repository;
  AuthorNotifier(this.repository) : super(const AuthorState());

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authorNotifierProvider =
    StateNotifierProvider<AuthorNotifier, AuthorState>((ref) {
      final repository = ref.watch(authorRepositoryProvider);
      return AuthorNotifier(repository);
    });
