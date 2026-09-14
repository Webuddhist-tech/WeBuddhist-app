import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/practice/data/datasource/my_recitation_collections_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';
import 'package:flutter_pecha/features/practice/data/repositories/my_recitation_collections_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final myRecitationCollectionsRemoteDatasourceProvider =
    Provider<MyRecitationCollectionsRemoteDatasource>((ref) {
      return MyRecitationCollectionsRemoteDatasource(
        dio: ref.watch(dioProvider),
      );
    });

final myRecitationCollectionsRepositoryProvider =
    Provider<MyRecitationCollectionsRepository>((ref) {
      return MyRecitationCollectionsRepository(
        remoteDatasource: ref.watch(
          myRecitationCollectionsRemoteDatasourceProvider,
        ),
      );
    });

/// `GET /users/me/recitation-collections/{collectionId}` for the detail screen.
final myRecitationCollectionDetailProvider = FutureProvider.autoDispose
    .family<Either<Failure, MyRecitationCollectionDetailModel>, String>((
      ref,
      collectionId,
    ) {
      return ref
          .watch(myRecitationCollectionsRepositoryProvider)
          .getCollectionDetail(collectionId);
    });

enum MyChantCompletionResult { completed, failed }

class MyRecitationCollectionCompletionState {
  final Set<String> completedChantIds;
  final Set<String> submittingChantIds;
  final bool hasCompletedChantThisSession;
  final bool isLoading;
  final String? error;

  const MyRecitationCollectionCompletionState({
    this.completedChantIds = const {},
    this.submittingChantIds = const {},
    this.hasCompletedChantThisSession = false,
    this.isLoading = false,
    this.error,
  });

  bool isCompleted(String chantId) =>
      completedChantIds.contains(chantId.trim());

  bool isSubmitting(String chantId) =>
      submittingChantIds.contains(chantId.trim());

  MyRecitationCollectionCompletionState copyWith({
    Set<String>? completedChantIds,
    Set<String>? submittingChantIds,
    bool? hasCompletedChantThisSession,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MyRecitationCollectionCompletionState(
      completedChantIds: completedChantIds ?? this.completedChantIds,
      submittingChantIds: submittingChantIds ?? this.submittingChantIds,
      hasCompletedChantThisSession:
          hasCompletedChantThisSession ?? this.hasCompletedChantThisSession,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class MyRecitationCollectionCompletionNotifier
    extends StateNotifier<MyRecitationCollectionCompletionState> {
  MyRecitationCollectionCompletionNotifier({
    required MyRecitationCollectionsRepository repository,
    required String collectionId,
    required bool isAuthenticated,
  }) : _repository = repository,
       _collectionId = collectionId,
       _isAuthenticated = isAuthenticated,
       super(const MyRecitationCollectionCompletionState());

  final MyRecitationCollectionsRepository _repository;
  final String _collectionId;
  final bool _isAuthenticated;
  int _requestGeneration = 0;

  Future<void> loadToday() async {
    if (!_isAuthenticated || state.isLoading) return;

    final generation = ++_requestGeneration;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getTodayCompletions(_collectionId);

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (completedChantIds) {
        state = state.copyWith(
          completedChantIds: {...state.completedChantIds, ...completedChantIds},
          isLoading: false,
          clearError: true,
        );
      },
    );
  }

  Future<MyChantCompletionResult> completeChant(String chantId) async {
    final trimmedChantId = chantId.trim();
    if (!_isAuthenticated || trimmedChantId.isEmpty) {
      return MyChantCompletionResult.failed;
    }
    if (state.completedChantIds.contains(trimmedChantId)) {
      return MyChantCompletionResult.completed;
    }
    if (state.submittingChantIds.contains(trimmedChantId)) {
      return MyChantCompletionResult.failed;
    }

    state = state.copyWith(
      submittingChantIds: {...state.submittingChantIds, trimmedChantId},
      clearError: true,
    );

    final result = await _repository.completeChant(
      collectionId: _collectionId,
      chantId: trimmedChantId,
    );

    if (!mounted) return MyChantCompletionResult.failed;

    final submitting = {...state.submittingChantIds}..remove(trimmedChantId);

    return result.fold(
      (failure) {
        state = state.copyWith(
          submittingChantIds: submitting,
          error: failure.message,
        );
        return MyChantCompletionResult.failed;
      },
      (_) {
        state = state.copyWith(
          completedChantIds: {...state.completedChantIds, trimmedChantId},
          submittingChantIds: submitting,
          hasCompletedChantThisSession: true,
          clearError: true,
        );
        return MyChantCompletionResult.completed;
      },
    );
  }
}

final myRecitationCollectionCompletionProvider = StateNotifierProvider
    .autoDispose
    .family<
      MyRecitationCollectionCompletionNotifier,
      MyRecitationCollectionCompletionState,
      String
    >((ref, collectionId) {
      final authState = ref.watch(authProvider);
      final notifier = MyRecitationCollectionCompletionNotifier(
        repository: ref.watch(myRecitationCollectionsRepositoryProvider),
        collectionId: collectionId,
        isAuthenticated: authState.isLoggedIn && !authState.isGuest,
      );
      notifier.loadToday();
      return notifier;
    });

final myRecitationCollectionDaysCountProvider = FutureProvider.autoDispose
    .family<Either<Failure, int>, String>((ref, collectionId) async {
      return ref
          .watch(myRecitationCollectionsRepositoryProvider)
          .getCompletionDaysCount(collectionId);
    });
