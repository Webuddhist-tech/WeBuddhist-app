import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_local_datasource.dart';
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

// Stored author is the first state (name kept for callers).
final authorByIdFutureProvider = AsyncNotifierProvider.family<
  ScreenCacheFamilyNotifier<AuthorModel, Either<Failure, AuthorModel>, String>,
  Either<Failure, AuthorModel>,
  String
>(() {
  return ScreenCacheFamilyNotifier((ref, id, bind) {
    return bind.source(ref.watch(authorRepositoryProvider).authorSource(id));
  });
});

const _authorPlansLanguage = 'en';
const _authorPlansLimit = 100;

// Each refresh written to Hive re-emits here.
Stream<Either<Failure, List<Plan>>> _authorPlansUpdates(
  GetPlansUseCase getPlans,
  PlansLocalDatasource local,
  List<Plan> Function(List<Plan>) byAuthor,
) async* {
  final result = await getPlans(
    const GetPlansParams(language: _authorPlansLanguage, limit: _authorPlansLimit),
  );
  yield result.map(byAuthor);

  final key = local.plansKey(
    language: _authorPlansLanguage,
    limit: _authorPlansLimit,
  );
  await for (final _ in local.watchKey(key)) {
    final cached = local.readPlans(
      language: _authorPlansLanguage,
      limit: _authorPlansLimit,
    );
    if (cached != null) {
      yield Right(byAuthor(cached.map((plan) => plan.toEntity()).toList()));
    }
  }
}

// Stored plans page (from Hive) is the first state, filtered by author.
final authorPlansFutureProvider = AsyncNotifierProvider.family<
  ScreenCacheFamilyNotifier<List<Plan>, Either<Failure, List<Plan>>, String>,
  Either<Failure, List<Plan>>,
  String
>(() {
  return ScreenCacheFamilyNotifier((ref, authorId, bind) {
    final getPlansUseCase = ref.watch(getPlansUseCaseProvider);
    final local = ref.watch(plansLocalDatasourceProvider);

    List<Plan> byAuthor(List<Plan> plans) =>
        plans.where((plan) => plan.authorId == authorId).toList();

    final stored = local.readPlans(
      language: _authorPlansLanguage,
      limit: _authorPlansLimit,
    );
    return bind.stream(
      stored == null
          ? null
          : Right(byAuthor(stored.map((plan) => plan.toEntity()).toList())),
      _authorPlansUpdates(getPlansUseCase, local, byAuthor),
    );
  });
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
