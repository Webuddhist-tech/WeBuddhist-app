import 'dart:async';

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/connect/domain/repositories/connect_repository.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupSearchState {
  final String query;
  final List<GroupProfile> results;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  const GroupSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
  });

  GroupSearchState copyWith({
    String? query,
    List<GroupProfile>? results,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool clearError = false,
  }) {
    return GroupSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
    );
  }
}

class GroupSearchNotifier extends StateNotifier<GroupSearchState> {
  GroupSearchNotifier({required this.repository, required this.language})
    : super(const GroupSearchState());

  final ConnectRepository repository;
  final String language;
  Timer? _debounceTimer;
  static const int _limit = 20;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  void search(String query) {
    _debounceTimer?.cancel();
    state = state.copyWith(query: query, isLoading: true, clearError: true);

    if (query.trim().isEmpty) {
      state = const GroupSearchState();
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(query, reset: true);
    });
  }

  Future<void> _performSearch(String query, {required bool reset}) async {
    if (query.trim().isEmpty) {
      state = const GroupSearchState();
      return;
    }

    final skip = reset ? 0 : state.skip;

    if (reset) {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        skip: 0,
        hasMore: true,
      );
    } else {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }

    final result = await repository.getDiscoverGroups(
      language: language,
      search: query.trim(),
      skip: skip,
      limit: _limit,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: failure.message,
        );
      },
      (page) {
        state = state.copyWith(
          results: reset ? page.groups : [...state.results, ...page.groups],
          isLoading: false,
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: skip + page.groups.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.query.trim().isEmpty) {
      return;
    }

    await _performSearch(state.query, reset: false);
  }

  void retry() {
    if (state.query.isNotEmpty) {
      _performSearch(state.query, reset: true);
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const GroupSearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final groupSearchProvider =
    StateNotifierProvider.autoDispose<GroupSearchNotifier, GroupSearchState>((
      ref,
    ) {
      final language = ref.watch(contentLanguageProvider);
      return GroupSearchNotifier(
        repository: ref.watch(connectRepositoryProvider),
        language: language,
      );
    });
