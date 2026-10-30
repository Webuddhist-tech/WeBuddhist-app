import 'dart:async';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_local_datasource.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plans_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('FindPlansNotifier');

/// State for paginated plans list
class FindPlansState {
  final List<Plan> plans;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  const FindPlansState({
    this.plans = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
  });

  FindPlansState copyWith({
    List<Plan>? plans,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
  }) {
    return FindPlansState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
    );
  }
}

/// StateNotifier for paginated find plans
class FindPlansNotifier extends StateNotifier<FindPlansState> {
  FindPlansNotifier({
    required this.getPlansUseCase,
    required this.languageCode,
    required this.local,
  }) : super(const FindPlansState()) {
    _logger.debug('🏗️ FindPlansNotifier CREATED with language: $languageCode');
    unawaited(_initialize());
  }

  final GetPlansUseCase getPlansUseCase;
  final String languageCode;
  final PlansLocalDatasource local;
  static const int _limit = 20;

  // Blocks paging while page one is being read again; stale pages are dropped.
  bool _firstPageInFlight = false;
  int _pageEpoch = 0;

  Future<void> _initialize() async {
    _seedFromCache();
    await loadInitial();
  }

  void _seedFromCache() {
    final cached = local.readPlans(
      language: languageCode,
      skip: 0,
      limit: _limit,
    );
    if (cached != null && mounted) {
      state = state.copyWith(
        plans: cached.map((plan) => plan.toEntity()).toList(),
        hasMore: cached.length >= _limit,
        skip: cached.length,
      );
    }
  }

  @override
  void dispose() {
    _logger.debug('💥 FindPlansNotifier DISPOSED - this will reset state!');
    super.dispose();
  }

  /// Load initial plans — shows cached data immediately when available.
  Future<void> loadInitial() async {
    _logger.debug('🔄 loadInitial() called - current state: ${state.plans.length} plans, isLoading: ${state.isLoading}');

    if (state.isLoading) {
      _logger.debug('⏸️ Already loading, skipping');
      return;
    }

    final hasCachedData = state.plans.isNotEmpty;
    if (!hasCachedData) {
      _logger.debug('📊 Setting isLoading: true');
      state = state.copyWith(isLoading: true, error: null);
    }

    _firstPageInFlight = true;
    final result = await getPlansUseCase(GetPlansParams(
      language: languageCode,
      skip: 0,
      limit: _limit,
    ));
    _firstPageInFlight = false;

    result.fold(
      (failure) {
        _logger.error('❌ Error loading plans: ${failure.message}');
        if (mounted) {
          if (state.plans.isEmpty) {
            state = state.copyWith(isLoading: false, error: failure.message);
          } else {
            state = state.copyWith(isLoading: false);
          }
        }
      },
      (plans) {
        _logger.debug('✅ Got ${plans.length} plans from use case');
        if (mounted) {
          _pageEpoch++;
          state = state.copyWith(
            plans: plans,
            isLoading: false,
            hasMore: plans.length >= _limit,
            skip: plans.length,
            error: null,
          );
        }
      },
    );

    _logger.debug('🏁 loadInitial() finished - final state: ${state.plans.length} plans, isLoading: ${state.isLoading}');
  }

  /// Load more plans
  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.isLoading ||
        _firstPageInFlight) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);
    final epoch = _pageEpoch;

    final result = await getPlansUseCase(GetPlansParams(
      language: languageCode,
      skip: state.skip,
      limit: _limit,
    ));

    // Page one was replaced meanwhile; this page belongs to the old list.
    if (epoch != _pageEpoch) {
      if (mounted) state = state.copyWith(isLoadingMore: false);
      return;
    }

    result.fold(
      (failure) {
        if (mounted) {
          state = state.copyWith(isLoadingMore: false, error: failure.message);
        }
      },
      (newPlans) {
        if (mounted) {
          state = state.copyWith(
            plans: [...state.plans, ...newPlans],
            isLoadingMore: false,
            hasMore: newPlans.length >= _limit,
            skip: state.skip + newPlans.length,
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
    await loadInitial();
  }
}
