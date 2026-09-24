import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/library/data/datasource/library_remote_datasource.dart';
import 'package:flutter_pecha/features/library/data/models/library_edition.dart';
import 'package:flutter_pecha/features/library/data/models/library_reader_models.dart';
import 'package:flutter_pecha/features/library/data/models/library_search_result.dart';
import 'package:flutter_pecha/features/library/data/models/library_segment.dart';
import 'package:flutter_pecha/features/library/data/models/library_text.dart';
import 'package:flutter_pecha/features/library/data/models/library_toc.dart';
import 'package:flutter_pecha/features/library/domain/library_content_slicer.dart';

/// Composes the library API calls into what the reader and chant list need.
class LibraryRepository {
  LibraryRepository({
    required LibraryRemoteDatasource datasource,
    this.segmentPageSize = 500,
    this.relatedPageSize = 20,
    this.maxPages = 1000,
    this.segmentCacheSize = 6,
  }) : _datasource = datasource;

  final LibraryRemoteDatasource _datasource;
  final int segmentPageSize;
  final int relatedPageSize;

  /// Upper bound on pages walked for one list (500,000 segments at 500).
  final int maxPages;

  /// Editions whose full segment list stays in memory; the parallel reader
  /// needs two at once.
  final int segmentCacheSize;
  final _logger = AppLogger('LibraryRepository');

  // Library metadata never changes, so each id is fetched once per session.
  // The large per-edition and per-segment results are capped (see [_memo]).
  final Map<String, Future<LibraryText>> _texts = {};
  final Map<String, Future<LibraryEdition>> _editions = {};
  final Map<String, Future<List<LibrarySegment>>> _segments = {};
  final Map<String, Future<List<LibraryText>>> _families = {};
  final Map<String, Future<LibrarySegmentResources>> _resources = {};
  final Map<String, Future<LibraryEdition>> _resolvedEditions = {};
  final Map<String, Future<List<LibraryTocSection>>> _tocs = {};
  Future<Map<String, String>>? _languageNames;

  Future<LibraryTextPage> fetchChants({
    required String tagId,
    String? language,
    String? title,
    required int limit,
    required int offset,
  }) {
    return _datasource.fetchTexts(
      tagId: tagId,
      language: language,
      title: title,
      limit: limit,
      offset: offset,
    );
  }

  Future<LibraryText> getText(String textId) =>
      _memo(_texts, textId, () => _datasource.fetchText(textId));

  Future<LibraryEdition> getEdition(String editionId) =>
      _memo(_editions, editionId, () => _datasource.fetchEdition(editionId));

  /// Ids handed to the reader are edition ids; a text id still resolves to
  /// that text's first edition so older links keep working.
  Future<LibraryEdition> resolveEdition(String id) {
    return _memo(_resolvedEditions, id, () async {
      try {
        return await getEdition(id);
      } catch (e) {
        if (!_isNotFound(e)) rethrow;
      }
      final LibraryText text;
      try {
        text = await getText(id);
      } catch (e) {
        if (_isNotFound(e)) throw NotFoundException('Edition $id not found');
        rethrow;
      }
      final editionId = text.primaryEditionId;
      if (editionId == null) {
        throw NotFoundException('Text $id has no edition');
      }
      return getEdition(editionId);
    });
  }

  Future<LibrarySegment> getSegment(String segmentId) =>
      _datasource.fetchSegment(segmentId);

  Future<List<LibrarySearchResult>> search({
    required String query,
    String? textId,
    String? editionId,
    int limit = 50,
  }) {
    return _datasource.searchContent(
      query: query,
      textId: textId,
      editionId: editionId,
      limit: limit,
    );
  }

  /// Language code to display name, from `/v2/languages`.
  Future<Map<String, String>> getLanguageNames() {
    return _languageNames ??= () async {
      try {
        final languages = await _datasource.fetchLanguages();
        return {for (final l in languages) l.code: l.name};
      } catch (_) {
        _languageNames = null;
        rethrow;
      }
    }();
  }

  /// Every segment of [editionId] that has lines, in reading order.
  Future<List<LibrarySegment>> getEditionSegments(String editionId) {
    return _memo(_segments, editionId, capacity: segmentCacheSize, () async {
      final all = await _fetchAllPages(
        (offset) => _datasource.fetchEditionSegments(
          editionId,
          limit: segmentPageSize,
          offset: offset,
        ),
      );
      return all.where((s) => s.lines.isNotEmpty).toList(growable: false);
    });
  }

  /// Headings of [editionId]'s table of contents; empty when it has none.
  Future<List<LibraryTocSection>> getTableOfContents(String editionId) {
    return _memo(_tocs, editionId, capacity: segmentCacheSize, () async {
      final List<LibraryTableOfContents> tocs;
      try {
        tocs = await _datasource.fetchTableOfContents(editionId);
      } catch (e) {
        if (_isNotFound(e)) return const [];
        rethrow;
      }
      for (final toc in tocs) {
        if (toc.sections.isNotEmpty) return toc.sections;
      }
      return const [];
    });
  }

  /// Every version of [textId]'s work: the root first, then translations
  /// level by level. Translations chain (English of a Tibetan that is itself
  /// a translation of a Sanskrit root), so the walk goes up to the top and
  /// back down through each text's translations.
  Future<List<LibraryText>> getTextFamily(String textId) async {
    final chain = await _translationChain(await getText(textId));
    final family = await _memo(_families, chain.last.id, () async {
      final members = <LibraryText>[chain.last];
      final seen = <String>{chain.last.id};
      var level = [chain.last];
      while (level.isNotEmpty && seen.length < _maxFamilySize) {
        final ids = [
          for (final text in level)
            for (final id in text.translations)
              if (seen.add(id)) id,
        ];
        level = await Future.wait(ids.map(getText));
        members.addAll(level);
      }
      return members;
    });
    // A text its parent does not list still belongs with its chain.
    final missing = chain.where((t) => !family.contains(t));
    return missing.isEmpty ? family : [...family, ...missing.toList().reversed];
  }

  static const _maxFamilySize = 500;
  static const _maxChainLength = 10;

  /// [text], the text it translates, and so on up to the root, which is last.
  /// A missing or cyclic parent ends the chain.
  Future<List<LibraryText>> _translationChain(LibraryText text) async {
    final chain = [text];
    final seen = {text.id};
    var current = text;
    while (current.isTranslation && chain.length < _maxChainLength) {
      final parentId = current.translationOf!;
      if (!seen.add(parentId)) break;
      try {
        current = await getText(parentId);
      } catch (e) {
        if (_isNotFound(e)) break;
        rethrow;
      }
      chain.add(current);
    }
    return chain;
  }

  /// One page of [editionId]. `next` starts at the anchor (first page when
  /// null); `previous` ends just before it. Positions are 1-based. An anchor
  /// from [anchorEditionId] (the parallel reader's primary) is mapped across
  /// by verse number.
  Future<LibraryContentWindow> loadWindow({
    required String editionId,
    String? anchorSegmentId,
    String? anchorEditionId,
    required String direction,
    required int size,
  }) async {
    final segments = await getEditionSegments(editionId);
    final total = segments.length;
    var anchorIndex =
        anchorSegmentId == null
            ? -1
            : segments.indexWhere((s) => s.id == anchorSegmentId);
    if (anchorIndex < 0 && anchorSegmentId != null) {
      anchorIndex = await _foreignAnchorIndex(
        anchorSegmentId,
        anchorEditionId: anchorEditionId,
        target: segments,
        targetEditionId: editionId,
      );
    }

    final int start;
    final int end;
    if (direction == 'previous') {
      end = anchorIndex < 0 ? 0 : anchorIndex;
      start = end - size < 0 ? 0 : end - size;
    } else {
      start = anchorIndex < 0 ? 0 : anchorIndex;
      end = start + size > total ? total : start + size;
    }
    final page = segments.sublist(start, end);
    if (page.isEmpty) {
      return LibraryContentWindow(
        editionId: editionId,
        segments: const [],
        currentPosition: start + 1,
        lastPosition: end,
        totalSegments: total,
      );
    }

    final spanStart = page.first.spanStart!;
    final content = await _datasource.fetchEditionContent(
      editionId,
      spanStart: spanStart,
      spanEnd: page.last.spanEnd!,
    );
    final numbers = segmentNumbers(segments);
    return LibraryContentWindow(
      editionId: editionId,
      segments: [
        for (var i = start; i < end; i++)
          LibraryReaderSegment(
            id: segments[i].id,
            reference: segments[i].reference,
            type: segments[i].type,
            number: numbers[i],
            lines: sliceLibraryLines(
              content,
              segments[i].lines,
              spanStart: spanStart,
            ),
            spanStart: segments[i].spanStart!,
            spanEnd: segments[i].spanEnd!,
          ),
      ],
      currentPosition: start + 1,
      lastPosition: end,
      totalSegments: total,
    );
  }

  /// The id in [targetId]'s edition of the verse numbered like [segmentId] in
  /// [sourceId]'s, the same alignment [loadWindow] gives the parallel reader.
  /// Both ids may be text or edition ids. Null when they are editions of
  /// unrelated texts (verse numbers would match by accident) or the verse is
  /// missing.
  Future<String?> alignSegment({
    required String segmentId,
    required String sourceId,
    required String targetId,
  }) async {
    final source = await resolveEdition(sourceId);
    final target = await resolveEdition(targetId);
    if (source.id == target.id) return segmentId;
    if (source.textId != target.textId) {
      final family = await getTextFamily(target.textId);
      if (!family.any((t) => t.id == source.textId)) return null;
    }
    final segments = await getEditionSegments(target.id);
    final index = await _alignedIndex(source.id, segmentId, segments);
    return index < 0 ? null : segments[index].id;
  }

  /// Places an anchor that is not in [target]: by verse number from
  /// [anchorEditionId], else from the segment's own edition (a bookmark or
  /// search hit of a translation whose root is now the primary). -1 when it
  /// cannot be placed.
  Future<int> _foreignAnchorIndex(
    String segmentId, {
    required String? anchorEditionId,
    required List<LibrarySegment> target,
    required String targetEditionId,
  }) async {
    if (anchorEditionId != null && anchorEditionId != targetEditionId) {
      final index = await _alignedIndex(anchorEditionId, segmentId, target);
      if (index >= 0) return index;
    }
    final String? sourceEditionId;
    try {
      sourceEditionId = (await getSegment(segmentId)).editionId;
    } catch (e) {
      _logger.debug('Anchor $segmentId could not be looked up: $e');
      return -1;
    }
    if (sourceEditionId == null ||
        sourceEditionId == targetEditionId ||
        sourceEditionId == anchorEditionId) {
      return -1;
    }
    return _alignedIndex(sourceEditionId, segmentId, target);
  }

  /// Index in [target] of the verse numbered like [segmentId] in [editionId].
  Future<int> _alignedIndex(
    String editionId,
    String segmentId,
    List<LibrarySegment> target,
  ) async {
    final source = await getEditionSegments(editionId);
    final sourceIndex = source.indexWhere((s) => s.id == segmentId);
    if (sourceIndex < 0) return -1;
    final number = segmentNumbers(source)[sourceIndex];
    return segmentNumbers(target).indexOf(number);
  }

  /// Numeric references when unique across the edition, else positions.
  static List<int> segmentNumbers(List<LibrarySegment> segments) {
    final numbers = <int>[];
    final seen = <int>{};
    for (final segment in segments) {
      final number = int.tryParse(segment.reference);
      if (number == null || number <= 0 || !seen.add(number)) {
        return List<int>.generate(segments.length, (i) => i + 1);
      }
      numbers.add(number);
    }
    return numbers;
  }

  /// Related segments of [segmentId], split by their text's `commentary_of`.
  Future<LibrarySegmentResources> loadSegmentResources(String segmentId) {
    return _memo(_resources, segmentId, capacity: 200, () async {
      final related = await _fetchAllPages(
        (offset) => _datasource.fetchRelatedSegments(
          segmentId,
          limit: relatedPageSize,
          offset: offset,
        ),
      );
      final usable =
          related
              .where((s) => s.textId != null && s.editionId != null)
              .toList();
      final texts = await Future.wait(usable.map((s) => getText(s.textId!)));

      final commentaries = <LibraryRelatedResource>[];
      final versions = <LibraryRelatedResource>[];
      for (var i = 0; i < usable.length; i++) {
        final resource = LibraryRelatedResource(
          segment: usable[i],
          text: texts[i],
        );
        (resource.kind == LibraryResourceKind.commentary
                ? commentaries
                : versions)
            .add(resource);
      }
      return LibrarySegmentResources(
        commentaries: commentaries,
        versions: versions,
      );
    });
  }

  /// A related segment's lines plus its edition's source, when available.
  Future<LibraryResourceContent> loadResourceContent(
    LibrarySegment segment,
  ) async {
    final editionId = segment.editionId;
    final editionFuture =
        editionId == null
            ? Future<LibraryEdition?>.value(null)
            : getEdition(editionId).then<LibraryEdition?>((e) => e).catchError((
              Object error,
            ) {
              _logger.warning('Edition $editionId failed', error);
              return null;
            });

    final content = await _datasource.fetchSegmentContent(segment.id);
    final edition = await editionFuture;
    return LibraryResourceContent(
      lines: sliceLibraryLines(
        content,
        segment.lines,
        spanStart: segment.spanStart ?? 0,
      ),
      source: edition?.source,
    );
  }

  static bool _isNotFound(Object error) =>
      error is NotFoundException ||
      (error is DioException && error.response?.statusCode == 404);

  /// Caches [load] under [key]; failures are dropped so they retry. With
  /// [capacity] the least recently used entries are evicted beyond it.
  Future<T> _memo<T>(
    Map<String, Future<T>> cache,
    String key,
    Future<T> Function() load, {
    int? capacity,
  }) {
    final hit = cache.remove(key);
    if (hit != null) return cache[key] = hit;
    final future = () async {
      try {
        return await load();
      } catch (_) {
        cache.remove(key);
        rethrow;
      }
    }();
    cache[key] = future;
    if (capacity != null) {
      while (cache.length > capacity) {
        cache.remove(cache.keys.first);
      }
    }
    return future;
  }

  /// Stops on a page with nothing new, and after [maxPages], so a server
  /// that keeps saying `has_more` without advancing cannot loop it.
  Future<List<LibrarySegment>> _fetchAllPages(
    Future<LibrarySegmentPage> Function(int offset) fetchPage,
  ) async {
    final items = <LibrarySegment>[];
    final seen = <String>{};
    var offset = 0;
    for (var i = 0; i < maxPages; i++) {
      final page = await fetchPage(offset);
      final fresh = page.items.where((s) => seen.add(s.id)).toList();
      items.addAll(fresh);
      if (!page.hasMore || fresh.isEmpty) return items;
      offset += page.items.length;
    }
    _logger.warning('Stopped paging after $maxPages pages');
    return items;
  }
}
