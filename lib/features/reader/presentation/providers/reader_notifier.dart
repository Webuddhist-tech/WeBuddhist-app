import 'dart:async';
import 'dart:ui' show VoidCallback;

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart'
    show ReaderDualLayoutSettings;
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_flattener_service.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_merger_service.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parameters for initializing the reader
class ReaderParams {
  final String textId;
  final String? segmentId;
  final NavigationContext? navigationContext;

  const ReaderParams({
    required this.textId,
    this.segmentId,
    this.navigationContext,
  });

  /// Language requested by navigation (e.g. the All chants picker).
  String? get language => navigationContext?.language;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderParams &&
        other.textId == textId &&
        other.segmentId == segmentId &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hash(textId, segmentId, language);
}

/// Notifier for managing reader state
class ReaderNotifier extends StateNotifier<ReaderState> {
  final Ref _ref;
  final ReaderParams _params;
  final SectionFlattenerService _flattener;
  final SectionMergerService _merger;
  final _logger = AppLogger('ReaderNotifier');

  Timer? _highlightTimer;
  bool _isDisposed = false;

  /// Tracks the `versionId` used for the current/last fetch so we can decide
  /// when a settings change actually warrants a reload. Starts `null` —
  /// matches "no `version_id` sent" which the API treats as "main text".
  String? _activeVersionId;

  /// Path id for `/texts/{id}/details` when opening from the chant list.
  /// Resolved once from [readerVersionsProvider] if that language has versions.
  /// Not written into dual-settings primary — chant text stays on top.
  String? _resolvedLanguageTextId;
  bool _didResolveLanguageTextId = false;

  ReaderNotifier({
    required Ref ref,
    required ReaderParams params,
    SectionFlattenerService? flattener,
    SectionMergerService? merger,
  }) : _ref = ref,
       _params = params,
       _flattener = flattener ?? const SectionFlattenerService(),
       _merger = merger ?? SectionMergerService(),
       super(ReaderState.initial(params.textId)) {
    _ref.listen<ReaderDualLayoutSettings>(
      readerDualSettingsProvider(params.textId),
      _onDualSettingsChanged,
      fireImmediately: false,
    );
    Future<void>(_initialize);
  }

  /// Reload primary content when the user picks a different version of the
  /// main text in Reader Settings. Other primary-slot fields (language,
  /// script, labels) are display-only here — they only translate into a new
  /// API request when paired with a `version_id`.
  void _onDualSettingsChanged(
    ReaderDualLayoutSettings? previous,
    ReaderDualLayoutSettings next,
  ) {
    if (_isDisposed) return;
    final newVersionId = next.primary.versionId;
    if (newVersionId == null) {
      // User cleared the version (typical path: they changed the language,
      // which resets the version field). Wait for an explicit version pick
      // before reloading — fetching with `versionId: null` would just return
      // the same default we already have on screen.
      return;
    }
    if (newVersionId == _activeVersionId) return;
    _logger.debug(
      'Primary versionId changed: $_activeVersionId -> $newVersionId. '
      'Reloading reader content.',
    );
    _reloadForVersionChange();
  }

  /// Fresh fetch driven by a primary version switch. We drop any
  /// pagination-state segmentId so the new version starts from
  /// its own first page rather than trying to resolve the previous version's
  /// segment id (which is meaningless against the new version).
  Future<void> _reloadForVersionChange() async {
    if (_isDisposed) return;
    state = ReaderState.initial(_params.textId).copyWith(
      status: ReaderStatus.loading,
      navigationContext: _params.navigationContext,
    );
    await _initialize(useNavParams: false);
  }

  /// Initialize the reader with initial content.
  ///
  /// [useNavParams] is `true` for the very first load — we honour
  /// `_params.segmentId` so deep-links and search jumps
  /// work. After a primary-version change those original navigation params
  /// no longer apply (they belong to the previous version), so we ignore
  /// them and just fetch the new version's first page.
  Future<void> _initialize({bool useNavParams = true}) async {
    if (_isDisposed) return;
    _logger.debug('ReaderNotifier initializing with params: $_params');

    final initialSegmentId = useNavParams ? _params.segmentId : null;
    final initialSize =
        useNavParams ? _params.navigationContext?.initialPageSize : null;

    state = state.copyWith(
      status: ReaderStatus.loading,
      navigationContext: _params.navigationContext,
    );

    try {
      _logger.debug(
        'ReaderNotifier fetching content with params: $initialSegmentId',
      );
      final response = await _fetchContent(
        segmentId: initialSegmentId,
        direction: 'next',
        size: initialSize,
      );
      _logger.debug('ReaderNotifier initialized with response: $response');

      if (_isDisposed) return;

      // Flatten the content
      var flattenedContent = _flattener.flatten(response.content.sections);
      var hasPreviousPage = response.currentSegmentPosition > 1;

      // Pre-load previous page when target is near the top so the widget
      // receives content with the target already at a stable index.
      if (hasPreviousPage && initialSegmentId != null) {
        final targetIndex = flattenedContent.getSegmentIndex(initialSegmentId);
        if (targetIndex != null &&
            targetIndex <= ReaderConstants.previousLoadThreshold) {
          _logger.debug(
            'Pre-loading previous page during init (target at index $targetIndex)',
          );
          final firstSegmentId = flattenedContent.firstSegmentId;
          if (firstSegmentId != null) {
            try {
              final prevResponse = await _fetchContent(
                segmentId: firstSegmentId,
                direction: 'previous',
              );
              if (!_isDisposed) {
                flattenedContent = _merger.merge(
                  flattenedContent,
                  prevResponse.content.sections,
                  PaginationDirection.previous,
                );
                hasPreviousPage = prevResponse.currentSegmentPosition > 1;
                _logger.debug(
                  'Pre-loaded previous page during init. Total items: ${flattenedContent.itemCount}',
                );
              }
            } catch (e) {
              // Graceful fallback — widget will load via normal pagination
              _logger.debug('Pre-load previous page failed, skipping: $e');
            }
          }
        }
      }

      if (_isDisposed) return;

      state = state.copyWith(
        status: ReaderStatus.loaded,
        textDetail: response.textDetail,
        content: flattenedContent,
        currentSegmentPosition: response.currentSegmentPosition,
        totalSegments: response.totalSegments,
        hasNextPage: response.currentSegmentPosition < response.totalSegments,
        hasPreviousPage: hasPreviousPage,
      );

      // `version_id` in this API is just the loaded text's id. Capture it so
      // the dual-settings listener can treat a user pick of the same version
      // as a no-op instead of triggering a wasted reload.
      // _activeVersionId = response.textDetail.id;

      // Handle highlight if navigating to a specific segment
      if (initialSegmentId != null && _params.navigationContext != null) {
        _triggerHighlight(initialSegmentId, _params.navigationContext!.source);
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize reader', e, stackTrace);
      if (_isDisposed) return;
      state = state.copyWith(
        status: ReaderStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Fetch content from the repository.
  ///
  /// `version_id` is sourced from the per-text dual settings provider so the
  /// primary stream stays in lockstep with what Reader Settings → Main text
  /// reports. When no version is selected we omit it and the API returns the
  /// text's default version.
  ///
  /// Opening from the chant list also sends [NavigationContext.language] so
  /// the body matches the list picker. If the details endpoint still ignores
  /// `language`, we load the first version for that language as the path id
  /// (same as dual-version primary, without calling `replacePrimary`).
  Future<ReaderResponse> _fetchContent({
    String? segmentId,
    required String direction,
    int? size,
  }) async {
    // Note: do NOT update _activeVersionId here. It's the id of the
    // currently-LOADED version (set after a successful initial fetch in
    // `_initialize`), not the value we happen to pass to the API on each
    // call. Pagination calls reuse the same loaded version, so overwriting
    // it here would race with the pagination stale-version guard and leave
    // skeletons stuck on screen.

    final detailsTextId = await _resolveDetailsTextId();
    final language = _params.language?.trim();

    final params = TextDetailsParams(
      // A "version" is itself a text_id — different primary versions live at
      // different /texts/<id>/details endpoints. Route to the picked version's
      // text_id when set; otherwise stay on the navigated textId, which the
      // backend resolves to its default version.
      //
      // No body `versionId` for the primary stream — the picked id is already
      // in the path. Body `version_id` is the secondary's mechanism for
      // requesting a parallel-aligned translation of the same text.
      textId: detailsTextId,
      segmentId: segmentId,
      direction: direction,
      language: (language != null && language.isNotEmpty) ? language : null,
      size: size,
    );

    final result = await _ref.read(textDetailsFutureProvider(params).future);
    return result.fold(
      (failure) =>
          throw Exception('Failed to fetch content: ${failure.message}'),
      (response) => response,
    );
  }

  /// Dual-settings primary version wins. Otherwise, if navigation asked for a
  /// language and versions exist for it, use that version's `text_id`.
  Future<String> _resolveDetailsTextId() async {
    final dualSettings = _ref.read(readerDualSettingsProvider(_params.textId));
    final primaryVersionId = dualSettings.primary.versionId;
    if (primaryVersionId != null && primaryVersionId.isNotEmpty) {
      return primaryVersionId;
    }

    if (_resolvedLanguageTextId != null) {
      return _resolvedLanguageTextId!;
    }

    final language = _params.language?.trim();
    if (language == null || language.isEmpty) {
      return _params.textId;
    }

    if (!_didResolveLanguageTextId) {
      _didResolveLanguageTextId = true;
      try {
        final versions = await _ref.read(
          readerVersionsProvider(
            ReaderLanguageQuery(
              textId: _params.textId,
              language: language,
            ),
          ).future,
        );
        if (versions.isNotEmpty) {
          final id = versions.first.id.trim();
          if (id.isNotEmpty) {
            _resolvedLanguageTextId = id;
            _logger.debug(
              'Resolved chant language "$language" to text_id $id',
            );
            return id;
          }
        }
      } catch (e) {
        _logger.debug(
          'Could not resolve version for chant language $language: $e',
        );
      }
    }

    return _params.textId;
  }

  /// Load the next page of content
  Future<void> loadNextPage() async {
    if (_isDisposed || state.isLoadingNext || !state.hasNextPage) return;

    state = state.copyWith(isLoadingNext: true);
    final fetchVersionId = _activeVersionId;

    try {
      final lastSegmentId = state.content?.lastSegmentId;
      if (lastSegmentId == null) {
        state = state.copyWith(isLoadingNext: false);
        return;
      }

      final response = await _fetchContent(
        segmentId: lastSegmentId,
        direction: 'next',
      );

      if (_isDisposed) return;
      if (_activeVersionId != fetchVersionId) {
        // Primary version changed mid-pagination — discard the stale page.
        // Clear the loading flag so the bottom skeleton doesn't get stuck if
        // the version-change reload didn't reset state for some reason.
        _logger.debug(
          'Discarding stale next page from versionId=$fetchVersionId',
        );
        state = state.copyWith(isLoadingNext: false);
        return;
      }

      // Merge new content with existing
      final mergedContent = _merger.merge(
        state.content ?? FlattenedContent.empty(),
        response.content.sections,
        PaginationDirection.next,
      );

      state = state.copyWith(
        content: mergedContent,
        isLoadingNext: false,
        hasNextPage: response.currentSegmentPosition < response.totalSegments,
        totalSegments: response.totalSegments,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to load next page', e, stackTrace);
      if (_isDisposed) return;
      state = state.copyWith(isLoadingNext: false);
    }
  }

  /// Load the previous page of content
  Future<void> loadPreviousPage() async {
    if (_isDisposed || state.isLoadingPrevious || !state.hasPreviousPage) {
      return;
    }

    state = state.copyWith(isLoadingPrevious: true);
    final fetchVersionId = _activeVersionId;

    try {
      final firstSegmentId = state.content?.firstSegmentId;
      if (firstSegmentId == null) {
        state = state.copyWith(isLoadingPrevious: false);
        return;
      }

      final response = await _fetchContent(
        segmentId: firstSegmentId,
        direction: 'previous',
      );

      if (_isDisposed) return;
      if (_activeVersionId != fetchVersionId) {
        // Primary version changed mid-pagination — discard the stale page.
        // Clear the loading flag so the top skeleton doesn't get stuck if
        // the version-change reload didn't reset state for some reason.
        _logger.debug(
          'Discarding stale previous page from versionId=$fetchVersionId',
        );
        state = state.copyWith(isLoadingPrevious: false);
        return;
      }

      // Merge new content with existing
      final mergedContent = _merger.merge(
        state.content ?? FlattenedContent.empty(),
        response.content.sections,
        PaginationDirection.previous,
      );

      state = state.copyWith(
        content: mergedContent,
        isLoadingPrevious: false,
        hasPreviousPage: response.currentSegmentPosition > 1,
        currentSegmentPosition: response.currentSegmentPosition,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to load previous page', e, stackTrace);
      if (_isDisposed) return;
      state = state.copyWith(isLoadingPrevious: false);
    }
  }

  /// Select a segment
  void selectSegment(Segment? segment) {
    if (_isDisposed) return;

    if (segment == null) {
      state = state.copyWith(clearSelectedSegment: true);
    } else {
      state = state.copyWith(selectedSegment: segment);
    }
  }

  /// Toggle segment selection
  void toggleSegmentSelection(Segment segment) {
    if (_isDisposed) return;

    if (state.selectedSegment?.segmentId == segment.segmentId) {
      // Deselect if same segment
      state = state.copyWith(
        clearSelectedSegment: true,
        clearCommentarySegmentId: true,
        clearTranslationSegmentId: true,
      );
    } else {
      // Select new segment
      state = state.copyWith(selectedSegment: segment);

      // Update commentary if it's open
      if (state.isCommentaryOpen) {
        state = state.copyWith(commentarySegmentId: segment.segmentId);
      }
      // Update translation if it's open
      if (state.isTranslationOpen) {
        state = state.copyWith(translationSegmentId: segment.segmentId);
      }
    }
  }

  /// Open commentary panel for a segment
  void openCommentary(String segmentId) {
    if (_isDisposed) return;
    final isOpening = !state.isCommentaryOpen;
    state = state.copyWith(
      commentarySegmentId: segmentId,
      splitRatio:
          isOpening ? ReaderConstants.defaultSplitRatio : state.splitRatio,
    );
  }

  /// Close commentary panel
  void closeCommentary() {
    if (_isDisposed) return;
    state = state.copyWith(clearCommentarySegmentId: true);
  }

  /// Toggle commentary panel
  void toggleCommentary(String segmentId) {
    if (_isDisposed) return;

    if (state.commentarySegmentId == segmentId) {
      closeCommentary();
    } else {
      openCommentary(segmentId);
    }
  }

  /// Open translation panel for a segment
  void openTranslation(String segmentId) {
    if (_isDisposed) return;
    final isOpening = !state.isTranslationOpen;
    state = state.copyWith(
      translationSegmentId: segmentId,
      splitRatio:
          isOpening ? ReaderConstants.defaultSplitRatio : state.splitRatio,
    );
  }

  /// Close translation panel
  void closeTranslation() {
    if (_isDisposed) return;
    state = state.copyWith(clearTranslationSegmentId: true);
  }

  /// Toggle translation panel
  void toggleTranslation(String segmentId) {
    if (_isDisposed) return;

    if (state.translationSegmentId == segmentId) {
      closeTranslation();
    } else {
      openTranslation(segmentId);
    }
  }

  /// Update split ratio for commentary panel
  void updateSplitRatio(double ratio) {
    if (_isDisposed) return;
    final clampedRatio = ratio.clamp(
      ReaderConstants.minSplitRatio,
      ReaderConstants.maxSplitRatio,
    );
    state = state.copyWith(splitRatio: clampedRatio);
  }

  /// Update split ratio while dragging a panel handle. If the resulting panel
  /// height shrinks below [ReaderConstants.minPanelHeightBeforeDismiss], the
  /// caller is asked to dismiss the panel via [onDismiss] instead of resizing.
  /// Returns `true` when a dismiss was triggered so callers can stop emitting
  /// further drag updates for this gesture.
  bool updateSplitRatioOrDismiss({
    required double ratio,
    required double availableHeight,
    required VoidCallback onDismiss,
  }) {
    if (_isDisposed) return false;
    final panelHeight = availableHeight * (1 - ratio);
    if (panelHeight < ReaderConstants.minPanelHeightBeforeDismiss) {
      onDismiss();
      return true;
    }
    updateSplitRatio(ratio);
    return false;
  }

  /// Trigger highlight for a segment
  void _triggerHighlight(String segmentId, NavigationSource source) {
    if (_isDisposed) return;

    // Cancel any existing highlight timer
    _highlightTimer?.cancel();

    state = state.copyWith(
      highlightedSegmentId: segmentId,
      highlightSource: source,
    );

    // Get duration based on source
    final duration = switch (source) {
      NavigationSource.plan => ReaderConstants.planHighlightDuration,
      NavigationSource.search => ReaderConstants.searchHighlightDuration,
      NavigationSource.deepLink => ReaderConstants.deepLinkHighlightDuration,
      NavigationSource.normal => Duration.zero,
      NavigationSource.recitationList => Duration.zero,
      NavigationSource.routine => Duration.zero,
      NavigationSource.groupAccumulatorChant => Duration.zero,
      NavigationSource.groupRecitationCollection => Duration.zero,
      NavigationSource.myRecitationCollection => Duration.zero,
    };

    if (duration > Duration.zero) {
      _highlightTimer = Timer(duration, () {
        if (!_isDisposed) {
          state = state.copyWith(clearHighlightedSegmentId: true);
        }
      });
    }
  }

  /// Manually highlight a segment (for search navigation within reader)
  void highlightSegment(String segmentId, NavigationSource source) {
    _triggerHighlight(segmentId, source);
  }

  /// Clear highlight
  void clearHighlight() {
    if (_isDisposed) return;
    _highlightTimer?.cancel();
    state = state.copyWith(clearHighlightedSegmentId: true);
  }

  /// Reload content
  Future<void> reload() async {
    if (_isDisposed) return;
    // Clear any cached failures so _initialize hits the network fresh.
    // textDetailsFutureProvider is not autoDispose, so a prior Left(NetworkFailure)
    // would otherwise be returned instantly on every retry without touching the network.
    _ref.invalidate(textDetailsFutureProvider);
    await _initialize();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _highlightTimer?.cancel();
    super.dispose();
  }
}

/// Provider for reader notifier
final readerNotifierProvider = StateNotifierProvider.autoDispose
    .family<ReaderNotifier, ReaderState, ReaderParams>(
      (ref, params) => ReaderNotifier(ref: ref, params: params),
    );
