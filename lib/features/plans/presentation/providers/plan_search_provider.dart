import 'dart:async';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plans_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/plan_analytics.dart';

/// State for plan search with pagination
class PlanSearchState {
  final String query;
  final List<Plan> results;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  const PlanSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
  });

  PlanSearchState copyWith({
    String? query,
    List<Plan>? results,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
  }) {
    return PlanSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
    );
  }
}

/// StateNotifier for managing search with debounce and pagination
class PlanSearchNotifier extends StateNotifier<PlanSearchState> {
  final GetPlansUseCase getPlansUseCase;
  final String languageCode;
  final PlanAnalytics? analytics;
  Timer? _debounceTimer;
  static const int _limit = 20;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  PlanSearchNotifier({
    required this.getPlansUseCase,
    required this.languageCode,
    this.analytics,
  }) : super(const PlanSearchState());

  /// Search with debounce
  void search(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Update query immediately for UI feedback
    state = state.copyWith(query: query, isLoading: true, error: null);

    if (query.trim().isEmpty) {
      state = const PlanSearchState();
      return;
    }

    // Set up debounced search
    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(query, reset: true);
    });
  }

  /// Perform the actual search
  Future<void> _performSearch(String query, {bool reset = false}) async {
    if (query.trim().isEmpty) {
      state = const PlanSearchState();
      return;
    }

    final skip = reset ? 0 : state.skip;

    if (reset) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        skip: 0,
        hasMore: true,
      );
    } else {
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    final result = await getPlansUseCase(GetPlansParams(
      language: languageCode,
      search: query.trim(),
      skip: skip,
      limit: _limit,
    ));

    result.fold(
      (failure) {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            error: failure.message,
          );
        }
      },
      (results) {
        if (mounted) {
          if (reset) {
            analytics?.planSearched(
              queryLength: query.trim().length,
              resultCount: results.length,
            );
          }
          final hasMore = results.length >= _limit;
          final newSkip = skip + results.length;

          state = state.copyWith(
            results: reset ? results : [...state.results, ...results],
            isLoading: false,
            isLoadingMore: false,
            hasMore: hasMore,
            skip: newSkip,
            error: null,
          );
        }
      },
    );
  }

  /// Load more results
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.query.trim().isEmpty) {
      return;
    }

    await _performSearch(state.query, reset: false);
  }

  /// Retry search
  void retry() {
    if (state.query.isNotEmpty) {
      _performSearch(state.query, reset: true);
    }
  }

  /// Clear search
  void clear() {
    _debounceTimer?.cancel();
    state = const PlanSearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
