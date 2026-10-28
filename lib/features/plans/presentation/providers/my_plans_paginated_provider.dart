import 'dart:async';

import 'package:flutter_pecha/features/plans/data/datasource/plans_local_datasource.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/user_plans_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for paginated my plans list
class MyPlansState {
  final List<UserPlansModel> plans;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;
  final int total;

  const MyPlansState({
    this.plans = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.total = 0,
  });

  MyPlansState copyWith({
    List<UserPlansModel>? plans,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    int? total,
  }) {
    return MyPlansState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      total: total ?? this.total,
    );
  }
}

/// StateNotifier for paginated my plans
class MyPlansNotifier extends StateNotifier<MyPlansState> {
  MyPlansNotifier({
    required this.repository,
    required this.languageCode,
    required this.local,
  }) : super(const MyPlansState()) {
    unawaited(_initialize());
  }

  final UserPlansRepositoryInterface repository;
  final String languageCode;
  final PlansLocalDatasource local;
  static const int _limit = 20;

  Future<void> _initialize() async {
    _seedFromCache();
    await loadInitial();
  }

  // Synchronous so the first frame already shows the stored page.
  void _seedFromCache() {
    final userId = local.currentUserIdSync;
    if (userId == null || userId.isEmpty) return;

    final cached = local.readUserPlans(
      userId: userId,
      language: languageCode,
      skip: 0,
      limit: _limit,
    );
    if (cached != null && mounted) {
      state = state.copyWith(
        plans: cached.userPlans,
        hasMore: cached.userPlans.length >= _limit,
        skip: cached.userPlans.length,
        total: cached.total,
      );
    }
  }

  /// Load initial plans — shows cached data immediately when available.
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    final hasCachedData = state.plans.isNotEmpty;
    if (!hasCachedData) {
      state = state.copyWith(isLoading: true, error: null);
    }

    final result = await repository.getUserPlans(
      language: languageCode,
      skip: 0,
      limit: _limit,
    );

    result.fold(
      (failure) {
        if (mounted && state.plans.isEmpty) {
          state = state.copyWith(isLoading: false, error: failure.message);
        } else if (mounted) {
          state = state.copyWith(isLoading: false);
        }
      },
      (response) {
        if (mounted) {
          state = state.copyWith(
            plans: response.userPlans,
            isLoading: false,
            hasMore: response.userPlans.length >= _limit,
            skip: response.userPlans.length,
            total: response.total,
            error: null,
          );
        }
      },
    );
  }

  /// Load more plans
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);

    final result = await repository.getUserPlans(
      language: languageCode,
      skip: state.skip,
      limit: _limit,
    );

    result.fold(
      (failure) {
        if (mounted) {
          state = state.copyWith(isLoadingMore: false, error: failure.message);
        }
      },
      (response) {
        final allPlans = [...state.plans, ...response.userPlans]
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

        if (mounted) {
          state = state.copyWith(
            plans: allPlans,
            isLoadingMore: false,
            hasMore:
                state.plans.length + response.userPlans.length < response.total,
            skip: state.skip + response.userPlans.length,
            total: response.total,
            error: null,
          );
        }
      },
    );
  }

  /// Retry loading
  void retry() {
    if (state.plans.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }

  /// Refresh from start — keeps existing plans visible while re-fetching.
  Future<void> refresh() async {
    final hasCachedData = state.plans.isNotEmpty;
    state = state.copyWith(
      isLoading: !hasCachedData,
      error: null,
      skip: 0,
      hasMore: true,
    );

    final result = await repository.refreshUserPlans(
      language: languageCode,
      skip: 0,
      limit: _limit,
    );

    result.fold(
      (failure) {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            error: state.plans.isEmpty ? failure.message : null,
          );
        }
      },
      (response) {
        if (mounted) {
          state = state.copyWith(
            plans: response.userPlans,
            isLoading: false,
            hasMore: response.userPlans.length >= _limit,
            skip: response.userPlans.length,
            total: response.total,
            error: null,
          );
        }
      },
    );
  }
}
