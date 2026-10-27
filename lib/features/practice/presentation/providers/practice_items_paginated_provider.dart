import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/data/datasource/practice_items_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/repositories/practice_items_repository_impl.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_item.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_items_page.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_items_tab.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/practice_items_repository.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/get_practice_items_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('PracticeItemsNotifier');

/// Default page size for the practice picker. Matches the existing
/// find-plans `_limit` so list behavior feels identical end-to-end.
const int _defaultPageSize = 20;

// ─── DI providers ───

final practiceItemsRemoteDatasourceProvider =
    Provider<PracticeItemsRemoteDatasource>((ref) {
      return PracticeItemsRemoteDatasource(dio: ref.watch(dioProvider));
    });

final practiceItemsRepositoryProvider = Provider<PracticeItemsRepository>((
  ref,
) {
  return PracticeItemsRepositoryImpl(
    datasource: ref.watch(practiceItemsRemoteDatasourceProvider),
    store: ref.watch(screenCacheStoreProvider),
  );
});

final getPracticeItemsUseCaseProvider = Provider<GetPracticeItemsUseCase>((
  ref,
) {
  return GetPracticeItemsUseCase(ref.watch(practiceItemsRepositoryProvider));
});

// ─── State ───

/// Immutable view-state for the paginated practice items list.
class PracticeItemsState {
  final List<PracticeItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;

  /// 1-based; `0` means "nothing fetched yet".
  final int page;

  const PracticeItemsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.page = 0,
  });

  PracticeItemsState copyWith({
    List<PracticeItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? page,
  }) {
    return PracticeItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      // Pass `error` explicitly so callers can clear it by passing null.
      error: error,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

/// Page-based paginated notifier for `GET /practice/items`.
///
/// Mirrors the public surface of `FindPlansNotifier` (`loadInitial`,
/// `loadMore`, `retry`, `refresh`) so the UI can swap providers without
/// behavioral churn — only the underlying pagination math changes from
/// `skip/limit` to `page/total_pages`.
class PracticeItemsNotifier extends StateNotifier<PracticeItemsState> {
  final GetPracticeItemsUseCase _useCase;
  final PracticeItemsRepository _repository;
  final PracticeItemsTab _tab;
  final String _languageCode;

  PracticeItemsNotifier({
    required GetPracticeItemsUseCase useCase,
    required PracticeItemsRepository repository,
    required PracticeItemsTab tab,
    required String languageCode,
  }) : _useCase = useCase,
       _repository = repository,
       _tab = tab,
       _languageCode = languageCode,
       super(const PracticeItemsState()) {
    loadInitial();
  }

  void _applyFirstPage(PracticeItemsPage page) {
    state = PracticeItemsState(
      items: page.items,
      isLoading: false,
      isLoadingMore: false,
      hasMore: page.hasMore,
      page: page.page,
    );
  }

  /// Stored page 1 renders at once; the server page replaces it if changed.
  Future<void> loadInitial() async {
    if (state.isLoading) return;
    final cached =
        state.items.isEmpty
            ? _repository.readFirstPage(
              tab: _tab,
              language: _languageCode,
              pageSize: _defaultPageSize,
            )
            : null;
    if (cached != null) {
      _applyFirstPage(cached);
    } else if (state.items.isEmpty) {
      state = state.copyWith(isLoading: true);
    }

    final result = await _repository.refreshFirstPage(
      tab: _tab,
      language: _languageCode,
      pageSize: _defaultPageSize,
    );

    if (!mounted) return;
    result.fold(
      (failure) {
        _logger.error('Initial load failed: ${failure.message}');
        if (state.items.isEmpty) {
          state = state.copyWith(isLoading: false, error: failure.message);
        }
      },
      _applyFirstPage,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;

    final result = await _useCase(
      tab: _tab,
      language: _languageCode,
      page: nextPage,
      pageSize: _defaultPageSize,
    );

    if (!mounted) return;
    result.fold(
      (failure) {
        _logger.error('Load more failed: ${failure.message}');
        state = state.copyWith(
          isLoadingMore: false,
          error: failure.message,
        );
      },
      (page) {
        state = state.copyWith(
          items: [...state.items, ...page.items],
          isLoadingMore: false,
          hasMore: page.hasMore,
          page: page.page,
        );
      },
    );
  }

  void retry() {
    if (state.items.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }

  /// Pull-to-refresh keeps the current list visible while page 1 reloads.
  Future<void> refresh() => loadInitial();
}

/// Family keyed by the tab so the screen can have independent providers
/// per tab if needed. Default usage in the picker is `PracticeItemsTab.all`.
final practiceItemsPaginatedProvider = StateNotifierProvider.autoDispose
    .family<PracticeItemsNotifier, PracticeItemsState, PracticeItemsTab>((
      ref,
      tab,
    ) {
      final languageCode = ref.watch(contentLanguageProvider);
      return PracticeItemsNotifier(
        useCase: ref.watch(getPracticeItemsUseCaseProvider),
        repository: ref.watch(practiceItemsRepositoryProvider),
        tab: tab,
        languageCode: languageCode,
      );
    });
