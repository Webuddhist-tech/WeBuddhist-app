import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/models/my_recitation_list_collection_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_search_provider.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_datasource_provider.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('PracticeRecitationsNotifier');

const int practiceRecitationsPageSize = 20;

class PracticeRecitationsState {
  final List<RecitationModel> recitations;
  final List<MyRecitationListCollectionModel> collections;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;
  final int total;

  const PracticeRecitationsState({
    this.recitations = const [],
    this.collections = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.total = 0,
  });

  bool get isEmpty => recitations.isEmpty && collections.isEmpty;

  PracticeRecitationsState copyWith({
    List<RecitationModel>? recitations,
    List<MyRecitationListCollectionModel>? collections,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    int? total,
  }) {
    return PracticeRecitationsState(
      recitations: recitations ?? this.recitations,
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      total: total ?? this.total,
    );
  }
}

class PracticeRecitationsNotifier extends StateNotifier<PracticeRecitationsState> {
  final RecitationsRemoteDatasource _datasource;
  final String _languageCode;
  final bool _includeCollections;
  bool _loadInFlight = false;

  PracticeRecitationsNotifier({
    required RecitationsRemoteDatasource datasource,
    required String languageCode,
    required bool includeCollections,
    bool deferLoad = false,
  }) : _datasource = datasource,
       _languageCode = languageCode,
       _includeCollections = includeCollections,
       super(
         deferLoad
             ? const PracticeRecitationsState(isLoading: true)
             : const PracticeRecitationsState(),
       ) {
    if (!deferLoad) {
      loadInitial();
    }
  }

  RecitationsQueryParams _queryParams({required int skip}) {
    return RecitationsQueryParams(
      language: _languageCode,
      skip: skip,
      limit: practiceRecitationsPageSize,
      shouldIncludeCollections: _includeCollections && skip == 0,
    );
  }

  Future<void> loadInitial() async {
    if (_loadInFlight) return;

    _loadInFlight = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = await _datasource.fetchRecitationsPage(
        queryParams: _queryParams(skip: 0),
      );

      if (!mounted) return;
      _logger.debug(
        'Loaded ${page.recitations.length} recitations, '
        '${page.collections.length} collections '
        '(includeCollections=$_includeCollections)',
      );
      state = PracticeRecitationsState(
        recitations: page.recitations,
        collections: page.collections,
        isLoading: false,
        hasMore: page.hasMore,
        skip: page.nextSkip,
        total: page.total,
      );
    } catch (e) {
      _logger.error('Initial recitations load failed', e);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final page = await _datasource.fetchRecitationsPage(
        queryParams: _queryParams(skip: state.skip),
      );

      if (!mounted) return;
      final updatedRecitations = [...state.recitations, ...page.recitations];
      state = state.copyWith(
        recitations: updatedRecitations,
        isLoadingMore: false,
        hasMore: page.hasMore,
        skip: page.nextSkip,
        total: page.total,
      );
    } catch (e) {
      _logger.error('Load more recitations failed', e);
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void retry() {
    if (state.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }

  Future<void> refresh() async {
    state = const PracticeRecitationsState(isLoading: true);
    await loadInitial();
  }
}

class PracticeRecitationsLanguageNotifier extends StateNotifier<String> {
  PracticeRecitationsLanguageNotifier({
    required LocalStorageService localStorageService,
    required String fallbackLanguage,
  }) : _localStorageService = localStorageService,
       super(_lastKnown ?? fallbackLanguage) {
    _initFuture = _initialize();
  }

  final LocalStorageService _localStorageService;
  // Kept static so a stored pick is re-applied synchronously when the notifier
  // is rebuilt (app content language change) instead of flashing that language.
  static String? _lastKnown;
  bool _userSelected = false;
  Future<void>? _initFuture;

  Future<void> _initialize() async {
    try {
      final stored = await _localStorageService.get<String>(
        StorageKeys.chantListLanguage,
      );
      if (_userSelected || !mounted) return;
      if (stored != null && stored.isNotEmpty) {
        _lastKnown = stored;
        state = stored;
      }
    } catch (e) {
      // Keep the seeded language on failure.
      _logger.warning('Reading stored chant list language failed', e);
    }
  }

  Future<void> ensureInitialized() async => _initFuture ??= _initialize();

  /// Callers fire this without awaiting, so a failed write is logged rather
  /// than thrown; the selection still applies for this session.
  Future<void> setLanguage(String languageCode) async {
    if (languageCode.isEmpty) return;
    _userSelected = true;
    _lastKnown = languageCode;
    state = languageCode;
    try {
      final persisted = await _localStorageService.set(
        StorageKeys.chantListLanguage,
        languageCode,
      );
      if (!persisted) {
        _logger.warning('Persisting chant list language failed');
      }
    } catch (e) {
      _logger.warning('Persisting chant list language failed', e);
    }
  }
}

/// Chant list language for [AllRecitationsScreen]. Does not change app locale.
/// Persisted, and kept alive so the pick survives navigation and restarts.
final practiceRecitationsLanguageProvider =
    StateNotifierProvider<PracticeRecitationsLanguageNotifier, String>((ref) {
      return PracticeRecitationsLanguageNotifier(
        localStorageService: ref.read(localStorageServiceProvider),
        fallbackLanguage: ref.watch(contentLanguageProvider),
      );
    });

final practiceRecitationsPaginatedProvider = StateNotifierProvider.autoDispose
    .family<PracticeRecitationsNotifier, PracticeRecitationsState, String>((
      ref,
      languageCode,
    ) {
      // Select the three fields this provider actually depends on. AuthState
      // has no `==`, so watching it whole rebuilds the notifier on every auth
      // emission — including the background onboarding fetch — discarding
      // loaded pages and the user's scroll position. Records compare
      // structurally, so this only rebuilds when one of the three changes.
      final (isAuthLoading, isLoggedIn, isGuest) = ref.watch(
        authProvider.select(
          (auth) => (auth.isLoading, auth.isLoggedIn, auth.isGuest),
        ),
      );

      // Defer the first fetch until auth is ready so a logged-in session
      // attaches Bearer + should_include_collections on the first request.
      final datasource = ref.watch(recitationsRemoteDatasourceProvider);
      if (isAuthLoading) {
        return PracticeRecitationsNotifier(
          datasource: datasource,
          languageCode: languageCode,
          includeCollections: false,
          deferLoad: true,
        );
      }

      return PracticeRecitationsNotifier(
        datasource: datasource,
        languageCode: languageCode,
        includeCollections: isLoggedIn && !isGuest,
      );
    });

final practiceRecitationSearchProvider = StateNotifierProvider.autoDispose
    .family<RecitationSearchNotifier, RecitationSearchState, String>((
      ref,
      languageCode,
    ) {
      return RecitationSearchNotifier(
        repository: ref.watch(recitationsRepositoryProvider),
        languageCode: languageCode,
      );
    });
