import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/library/data/datasource/library_remote_datasource.dart';
import 'package:flutter_pecha/features/library/data/models/library_edition.dart';
import 'package:flutter_pecha/features/library/data/models/library_reader_models.dart';
import 'package:flutter_pecha/features/library/data/models/library_search_result.dart';
import 'package:flutter_pecha/features/library/data/models/library_segment.dart';
import 'package:flutter_pecha/features/library/data/models/library_text.dart';
import 'package:flutter_pecha/features/library/domain/library_content_slicer.dart';

/// Composes the library API calls into what the reader and chant list need.
class LibraryRepository {
  LibraryRepository({
    required LibraryRemoteDatasource datasource,
    this.segmentPageSize = 500,
    this.relatedPageSize = 20,
  }) : _datasource = datasource;

  final LibraryRemoteDatasource _datasource;
  final int segmentPageSize;
  final int relatedPageSize;
  final _logger = AppLogger('LibraryRepository');

  // Library metadata never changes, so each id is fetched once per session.
  final Map<String, Future<LibraryText>> _texts = {};
  final Map<String, Future<LibraryEdition>> _editions = {};
  final Map<String, Future<List<LibrarySegment>>> _segments = {};
  final Map<String, Future<List<LibraryText>>> _families = {};
  final Map<String, Future<LibrarySegmentResources>> _resources = {};
  final Map<String, Future<LibraryReaderSegment?>> _firstSegments = {};
  final Map<String, Future<LibraryEdition>> _resolvedEditions = {};
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

  /// The first verse of [editionId], for list previews; null when empty.
  Future<LibraryReaderSegment?> loadFirstSegment(String editionId) {
    return _memo(_firstSegments, editionId, () async {
      final page = await _datasource.fetchEditionSegments(
        editionId,
        limit: 1,
        offset: 0,
      );
      LibrarySegment? first;
      for (final segment in page.items) {
        if (segment.lines.isNotEmpty) {
          first = segment;
          break;
        }
      }
      if (first == null) return null;

      final spanStart = first.spanStart!;
      final content = await _datasource.fetchEditionContent(
        editionId,
        spanStart: spanStart,
        spanEnd: first.spanEnd!,
      );
      return LibraryReaderSegment(
        id: first.id,
        reference: first.reference,
        type: first.type,
        number: 1,
        lines: sliceLibraryLines(content, first.lines, spanStart: spanStart),
      );
    });
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
    return _memo(_segments, editionId, () async {
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

  /// The root text first, then its translations; [textId] may be any member.
  Future<List<LibraryText>> getTextFamily(String textId) async {
    final text = await getText(textId);
    final rootId = text.isTranslation ? text.translationOf! : text.id;
    return _memo(_families, rootId, () async {
      final root = rootId == text.id ? text : await getText(rootId);
      final ids = <String>{root.id, ...root.translations, text.id};
      return Future.wait(ids.map(getText));
    });
  }

  /// One page of [editionId]. `next` starts at the anchor (first page when
  /// null); `previous` ends just before it. Positions are 1-based.
  Future<LibraryContentWindow> loadWindow({
    required String editionId,
    String? anchorSegmentId,
    required String direction,
    required int size,
  }) async {
    final segments = await getEditionSegments(editionId);
    final total = segments.length;
    final anchorIndex =
        anchorSegmentId == null
            ? -1
            : segments.indexWhere((s) => s.id == anchorSegmentId);

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
          ),
      ],
      currentPosition: start + 1,
      totalSegments: total,
    );
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
    return _memo(_resources, segmentId, () async {
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

  Future<T> _memo<T>(
    Map<String, Future<T>> cache,
    String key,
    Future<T> Function() load,
  ) {
    return cache.putIfAbsent(key, () async {
      try {
        return await load();
      } catch (_) {
        cache.remove(key);
        rethrow;
      }
    });
  }

  Future<List<LibrarySegment>> _fetchAllPages(
    Future<LibrarySegmentPage> Function(int offset) fetchPage,
  ) async {
    final items = <LibrarySegment>[];
    var offset = 0;
    while (true) {
      final page = await fetchPage(offset);
      items.addAll(page.items);
      if (!page.hasMore || page.items.isEmpty) break;
      offset += page.items.length;
    }
    return items;
  }
}
