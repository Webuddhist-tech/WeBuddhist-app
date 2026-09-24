import 'dart:async';

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/home/data/datasource/series_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/utils/series_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SeriesSearchState {
  final String query;
  final List<Series> results;
  final bool isLoading;
  final String? error;

  const SeriesSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SeriesSearchState copyWith({
    String? query,
    List<Series>? results,
    bool? isLoading,
    String? error,
  }) {
    return SeriesSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SeriesSearchNotifier extends StateNotifier<SeriesSearchState> {
  SeriesSearchNotifier({
    required this.datasource,
    required this.languageCode,
    this.analytics,
  }) : super(const SeriesSearchState());

  final SeriesRemoteDatasource datasource;
  final String languageCode;
  final SeriesAnalytics? analytics;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  void search(String query) {
    _debounceTimer?.cancel();
    state = state.copyWith(query: query, isLoading: true, error: null);

    if (query.trim().isEmpty) {
      state = const SeriesSearchState();
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      state = const SeriesSearchState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final models = await datasource.fetchSeries(
        params: SeriesQueryParams(
          language: languageCode,
          search: query.trim(),
        ),
      );
      if (!mounted) return;
      state = state.copyWith(
        results: models.map((m) => m.toEntity(language: languageCode)).toList(),
        isLoading: false,
        error: null,
      );
      analytics?.seriesSearched(
        queryLength: query.trim().length,
        resultCount: models.length,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to search plans: $e',
      );
    }
  }

  void retry() {
    if (state.query.isNotEmpty) {
      _performSearch(state.query);
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const SeriesSearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final seriesSearchProvider =
    StateNotifierProvider<SeriesSearchNotifier, SeriesSearchState>((ref) {
  final dio = ref.watch(dioProvider);
  final languageCode = ref.watch(contentLanguageProvider);
  return SeriesSearchNotifier(
    datasource: SeriesRemoteDatasource(dio: dio),
    languageCode: languageCode,
    analytics: ref.watch(seriesAnalyticsProvider),
  );
});
