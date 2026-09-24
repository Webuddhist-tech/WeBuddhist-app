import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart'
    show ReaderDualLayoutSettings, ReaderSlotConfig;
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_pecha/features/reader/data/models/secondary_reader_state.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_flattener_service.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_merger_service.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_secondary_content_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_analytics.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
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
class ReaderNotifier extends StateNotifier<ReaderState>
    with WidgetsBindingObserver {
  final Ref _ref;
  final ReaderParams _params;
  final SectionFlattenerService _flattener;
  final SectionMergerService _merger;
  final ReaderAnalytics _analytics;
  final _session = ReaderSessionTracker();
  final _logger = AppLogger('ReaderNotifier');

  Timer? _highlightTimer;
  Timer? _backgroundTimer;
  bool _isDisposed = false;
  bool _openTracked = false;
  int _pagesFetched = 0;

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
    ReaderAnalytics? analytics,
  }) : _ref = ref,
       _params = params,
       _flattener = flattener ?? const SectionFlattenerService(),
       _merger = merger ?? SectionMergerService(),
       _analytics = analytics ?? ref.read(readerAnalyticsProvider),
       super(ReaderState.initial(params.textId)) {
    _ref.listen<ReaderDualLayoutSettings>(
      readerDualSettingsProvider(params.textId),
      _onDualSettingsChanged,
      fireImmediately: false,
    );
    WidgetsBinding.instance.addObserver(this);
    _session.start();
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
    _activeVersionId = newVersionId;
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

    var initialSegmentId = useNavParams ? _params.segmentId : null;
    final initialSize =
        useNavParams ? _params.navigationContext?.initialPageSize : null;

    state = state.copyWith(
      status: ReaderStatus.loading,
      navigationContext: _params.navigationContext,
    );

    try {
      if (useNavParams) await _openAsTranslation();
      if (_isDisposed) return;
      if (initialSegmentId != null) {
        initialSegmentId = state.loadedSegmentId(initialSegmentId);
      }
      _logger.debug(
        'ReaderNotifier fetching content with params: $initialSegmentId',
      );
      final window = await _fetchWindow(
        segmentId: initialSegmentId,
        size: initialSize,
      );
      if (_isDisposed) return;
      if (state.openedTranslation != null) {
        await _prefetchTranslation(window.content);
        if (_isDisposed) return;
      }
      final response = window.response;
      _logger.debug('ReaderNotifier initialized with response: $response');

      state = state.copyWith(
        status: ReaderStatus.loaded,
        textDetail: response.textDetail,
        content: window.content,
        currentSegmentPosition: response.currentSegmentPosition,
        totalSegments: response.totalSegments,
        hasNextPage: response.hasNextPage,
        hasPreviousPage: window.hasPreviousPage,
      );
      // The edition the user opened, not the original it is shown under.
      _trackOpened(state.openedText ?? response.textDetail);

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

  /// A translation opens as the Translation layer of its root text: the root
  /// loads as the primary and the opened edition as the secondary, shown
  /// alone, so the page reads as before while the Languages sheet names the
  /// real original. Anything failing, or a requested verse the root lacks,
  /// keeps the opened edition as the primary.
  ///
  /// The layout lives per text, so a reader still on screen (a plan's
  /// previous item during `pushReplacement`) may already have set it up for
  /// this translation; this reader then adopts it instead of backing off as
  /// it does from a layout the user picked.
  Future<void> _openAsTranslation() async {
    final dual = _ref.read(readerDualSettingsProvider(_params.textId).notifier);
    bool userLayout() => dual.isPrimaryEdited || dual.isSecondaryEdited;
    final ReaderVersionDetail opened;
    final ReaderVersionDetail root;
    final Map<String, String> aliases;
    try {
      final settings = _ref.read(readerSettingsRemoteDatasourceProvider);
      opened = await settings.fetchVersionInfo(versionId: _params.textId);
      final rootId = opened.parentId;
      if (rootId == null || rootId.isEmpty) return;
      if (userLayout() && !_isOpenedUnder(rootId, opened.id)) return;
      root = await settings.fetchVersionInfo(versionId: rootId);
      aliases = await _alignNavigationSegments(root.id);
      final requested = _params.segmentId;
      // Already under the root, the root stays the primary regardless; the
      // repository still places the verse through its own edition.
      if (requested != null &&
          !aliases.containsKey(requested) &&
          !_isOpenedUnder(root.id, opened.id)) {
        _logger.debug('$requested has no verse in ${root.id}; kept as opened');
        return;
      }
      // The persisted flags load asynchronously and would otherwise land on
      // top of the per-text layout set below.
      await Future.wait([
        _ref.read(readerSecondaryEnabledProvider.notifier).loaded,
        _ref.read(readerOriginalVisibleProvider.notifier).loaded,
      ]);
    } catch (e) {
      _logger.warning('Original of ${_params.textId} not resolved', e);
      return;
    }
    if (_isDisposed) return;
    final adopted = _isOpenedUnder(root.id, opened.id);
    if (!adopted && userLayout()) return;
    // Same id the primary is about to load with, so the settings listener
    // does not reload it.
    _activeVersionId = root.id;
    // An adopted layout keeps whatever the user toggled on the other screen.
    if (!adopted) {
      dual.openAsTranslation(
        original: _slot(root),
        translation: _slot(opened),
      );
    }
    state = state.copyWith(
      openedTranslation: _textDetail(opened),
      segmentAliases: aliases,
    );
  }

  /// True when this text's layout already shows [translationId] as the
  /// translation of [rootId].
  bool _isOpenedUnder(String rootId, String translationId) {
    final dual = _ref.read(readerDualSettingsProvider(_params.textId));
    return dual.primary.versionId == rootId &&
        dual.secondary.versionId == translationId;
  }

  /// The first page of the translation an opened translation is shown as,
  /// fetched before the page is shown so the original never appears in the
  /// meantime. It is the request the translation stream makes first, so the
  /// stream finds it cached; a failure is left for that stream to report.
  Future<void> _prefetchTranslation(FlattenedContent content) async {
    final dual = _ref.read(readerDualSettingsProvider(_params.textId));
    final primaryId = dual.primary.versionId;
    final translationId = dual.secondary.versionId;
    if (!dual.secondaryEnabled || primaryId == null || translationId == null) {
      return;
    }
    final key = SecondaryReaderKey(
      textId: primaryId,
      versionId: translationId,
      initialSegmentId: secondaryInitialAnchor(
        navigationContext: _params.navigationContext,
        segmentId: _params.segmentId,
        content: content,
      ),
      initialSize: _params.navigationContext?.initialPageSize,
    );
    try {
      await _ref.read(
        textDetailsFutureProvider(secondaryInitialParams(key)).future,
      );
    } catch (e) {
      _logger.debug('Translation page not fetched ahead: $e');
    }
  }

  /// Navigation names verses of the opened translation (a plan's range, a
  /// bookmark); these are the root's matching verses, by verse number. A
  /// verse with no counterpart is left out and keeps its own id.
  Future<Map<String, String>> _alignNavigationSegments(String rootId) async {
    final ids = <String>{
      if (_params.segmentId != null) _params.segmentId!,
      ...?_params.navigationContext?.currentSegmentIds,
    };
    if (ids.isEmpty) return const {};
    final texts = _ref.read(textsRepositoryProvider);
    final aligned = await Future.wait(
      ids.map(
        (id) => texts.alignSegment(
          segmentId: id,
          sourceTextId: _params.textId,
          targetTextId: rootId,
        ),
      ),
    );
    final aliases = <String, String>{};
    var i = 0;
    for (final id in ids) {
      final target = aligned[i++];
      if (target != null && target != id) aliases[id] = target;
    }
    return aliases;
  }

  // Labels are localized by the sheet from the code.
  static ReaderSlotConfig _slot(ReaderVersionDetail version) => ReaderSlotConfig(
    languageCode: version.language,
    languageLabel: version.language,
    versionId: version.id,
    versionLabel: version.title,
  );

  static TextDetail _textDetail(ReaderVersionDetail version) => TextDetail(
    id: version.id,
    title: version.title,
    language: version.language,
    type: version.type ?? 'text',
    groupId: version.groupId ?? '',
    isPublished: version.isPublished,
    createdDate: version.createdDate ?? '',
    updatedDate: version.updatedDate ?? '',
    publishedDate: version.publishedDate ?? '',
    publishedBy: version.publishedBy ?? '',
    sourceLink: version.sourceLink,
    license: version.license,
    parentId: version.parentId,
  );

  /// The page at [segmentId] (the first page when null). When the target sits
  /// near the top, the previous page is merged in first so the widget gets
  /// it at a stable index. Throws when the page itself cannot be fetched.
  Future<_ContentWindow> _fetchWindow({String? segmentId, int? size}) async {
    final response = await _fetchContent(
      segmentId: segmentId,
      direction: 'next',
      size: size,
    );
    var content = _flattener.flatten(response.content.sections);
    var hasPreviousPage = response.currentSegmentPosition > 1;

    if (hasPreviousPage && segmentId != null && !_isDisposed) {
      final targetIndex = content.getSegmentIndex(segmentId);
      final firstSegmentId = content.firstSegmentId;
      if (targetIndex != null &&
          targetIndex <= ReaderConstants.previousLoadThreshold &&
          firstSegmentId != null) {
        try {
          final prevResponse = await _fetchContent(
            segmentId: firstSegmentId,
            direction: 'previous',
          );
          if (!_isDisposed) {
            content = _merger.merge(
              content,
              prevResponse.content.sections,
              PaginationDirection.previous,
            );
            hasPreviousPage = prevResponse.currentSegmentPosition > 1;
          }
        } catch (e) {
          // Graceful fallback — the widget loads it via normal pagination.
          _logger.debug('Pre-load previous page failed, skipping: $e');
        }
      }
    }

    return _ContentWindow(
      response: response,
      content: content,
      hasPreviousPage: hasPreviousPage,
    );
  }

  /// Replaces the loaded window with the page around [segmentId], for a live
  /// position outside what pagination has fetched, and returns this
  /// version's id for it. Null when the text does not have that segment (or
  /// the fetch failed), so the caller can report being out of sync instead of
  /// jumping.
  ///
  /// [segmentId] is the operator's. When they read another edition or
  /// language of this text ([sourceTextId]), it never matches this version's
  /// ids literally, so it is first aligned to the same verse here. Segments'
  /// `mappings` still resolve it too.
  Future<String?> jumpToSegment(
    String segmentId, {
    String? sourceTextId,
  }) async {
    if (_isDisposed) return null;
    final loaded = _localSegmentId(state.content, segmentId);
    if (loaded != null) return loaded;
    try {
      var target = segmentId;
      if (sourceTextId != null && sourceTextId.isNotEmpty) {
        final aligned = await _ref
            .read(textsRepositoryProvider)
            .alignSegment(
              segmentId: segmentId,
              sourceTextId: sourceTextId,
              targetTextId: await _resolveDetailsTextId(),
            );
        if (_isDisposed) return null;
        if (aligned != null) target = aligned;
        final alreadyLoaded = _localSegmentId(state.content, target);
        if (alreadyLoaded != null) return alreadyLoaded;
      }
      final window = await _fetchWindow(segmentId: target);
      if (_isDisposed) return null;
      final local = _localSegmentId(window.content, target);
      if (local == null) return null;
      final response = window.response;
      state = state.copyWith(
        content: window.content,
        currentSegmentPosition: response.currentSegmentPosition,
        totalSegments: response.totalSegments,
        hasNextPage: response.hasNextPage,
        hasPreviousPage: window.hasPreviousPage,
        isLoadingNext: false,
        isLoadingPrevious: false,
      );
      return local;
    } catch (e) {
      _logger.debug('Jump to segment $segmentId failed: $e');
      return null;
    }
  }

  /// [content]'s own id for [segmentId], directly or through `mappings`.
  static String? _localSegmentId(FlattenedContent? content, String segmentId) {
    final index = content?.resolveSegmentIndex(segmentId);
    return index == null ? null : content!.items[index].segmentId;
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

    final stopwatch = Stopwatch()..start();
    final result = await _ref.read(textDetailsFutureProvider(params).future);
    stopwatch.stop();
    return result.fold(
      (failure) =>
          throw Exception('Failed to fetch content: ${failure.message}'),
      (response) {
        _trackPageLoaded(response, stopwatch.elapsedMilliseconds);
        return response;
      },
    );
  }

  /// Fired once, when the first page is on screen, so the loaded text's
  /// title, language and version are known.
  void _trackOpened(TextDetail textDetail) {
    if (_openTracked) return;
    _openTracked = true;
    final layout = readerLayoutFor(
      _ref.read(readerDualSettingsProvider(_params.textId)),
    );
    _analytics.readerOpened(
      textId: _params.textId,
      textTitle: textDetail.title,
      source: readerOpenSourceFor(_params.navigationContext?.source),
      language: textDetail.language,
      versionId: textDetail.id,
      script: _ref.read(readerScriptForLanguageProvider(textDetail.language)),
      layout: layout,
      entrySegment: _params.segmentId,
    );
  }

  void _trackPageLoaded(ReaderResponse response, int loadMs) {
    if (_isDisposed) return;
    _session.pageLoaded();
    _analytics.readerPageLoaded(
      textId: _params.textId,
      pageNumber: ++_pagesFetched,
      segmentCount: _countSegments(response.content.sections),
      loadMs: loadMs,
    );
  }

  int _countSegments(List<Section> sections) {
    var count = 0;
    for (final section in sections) {
      count += section.segments.length;
      count += _countSegments(section.sections ?? const []);
    }
    return count;
  }

  /// The deepest segment scrolled into view, for the session summary.
  void markSegmentReached(int segmentNumber) {
    if (_isDisposed) return;
    _session.segmentReached(segmentNumber);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onForeground();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _onBackground();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Out of sight: the session ends unless the app is back within the grace.
  void _onBackground() {
    _session.background();
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer(ReaderSessionTracker.backgroundGrace, _endSession);
  }

  /// A suspended app fires the timer late, so the grace is checked here too.
  void _onForeground() {
    _backgroundTimer?.cancel();
    if (_session.backgroundedFor >= ReaderSessionTracker.backgroundGrace) {
      _endSession();
    }
    if (_session.isActive) {
      _session.foreground();
    } else {
      _session.start();
    }
  }

  void _endSession() {
    final summary = _session.end();
    if (summary == null) return;
    _analytics.readerSessionEnded(
      textId: _params.textId,
      session: summary,
      segmentsTotal: state.totalSegments,
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
            ReaderLanguageQuery(textId: _params.textId, language: language),
          ).future,
        );
        if (versions.isNotEmpty) {
          final id = versions.first.id.trim();
          if (id.isNotEmpty) {
            _resolvedLanguageTextId = id;
            _logger.debug('Resolved chant language "$language" to text_id $id');
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
        hasNextPage: response.hasNextPage,
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
    _backgroundTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _endSession();
    super.dispose();
  }
}

/// One fetched page, flattened, with the previous page merged when needed.
class _ContentWindow {
  final ReaderResponse response;
  final FlattenedContent content;
  final bool hasPreviousPage;

  const _ContentWindow({
    required this.response,
    required this.content,
    required this.hasPreviousPage,
  });
}

/// Provider for reader notifier
final readerNotifierProvider = StateNotifierProvider.autoDispose
    .family<ReaderNotifier, ReaderState, ReaderParams>(
      (ref, params) => ReaderNotifier(ref: ref, params: params),
    );
