import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/library/data/datasource/library_remote_datasource.dart';
import 'package:flutter_pecha/features/library/data/models/library_alignment.dart';
import 'package:flutter_pecha/features/library/data/models/library_edition.dart';
import 'package:flutter_pecha/features/library/data/models/library_page.dart';
import 'package:flutter_pecha/features/library/data/models/library_reader_models.dart';
import 'package:flutter_pecha/features/library/data/models/library_search_result.dart';
import 'package:flutter_pecha/features/library/data/models/library_segment.dart';
import 'package:flutter_pecha/features/library/data/models/library_text.dart';
import 'package:flutter_pecha/features/library/data/models/library_toc.dart';
import 'package:flutter_pecha/features/library/data/models/library_yigchung.dart';
import 'package:flutter_pecha/features/library/domain/library_content_slicer.dart';

/// Composes the library API calls into what the reader and chant list need.
class LibraryRepository {
  LibraryRepository({
    required LibraryRemoteDatasource datasource,
    this.segmentPageSize = 500,
    this.relatedPageSize = 20,
    this.maxPages = 1000,
    this.segmentCacheSize = 6,
    this.yigchungTimeout = const Duration(seconds: 5),
  }) : _datasource = datasource;

  final LibraryRemoteDatasource _datasource;
  final int segmentPageSize;
  final int relatedPageSize;

  /// How long a page waits for its yigchung marks before opening without.
  final Duration yigchungTimeout;

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
  final Map<String, Future<List<LibraryLineSpan>>> _yigchungs = {};
  final Map<String, Future<Map<String, List<String>>>> _alignments = {};
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
        (s) => s.id,
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

  /// Spans of [editionId]'s yigchung (small text) runs, sorted by start;
  /// empty when it has none.
  Future<List<LibraryLineSpan>> getYigchungs(String editionId) {
    return _memo(_yigchungs, editionId, capacity: segmentCacheSize, () async {
      final List<LibraryYigchung> yigchungs;
      try {
        yigchungs = await _datasource.fetchYigchungs(editionId);
      } catch (e) {
        if (_isNotFound(e)) return const [];
        rethrow;
      }
      return yigchungs.map((y) => y.span).toList(growable: false)
        ..sort((a, b) => a.start.compareTo(b.start));
    });
  }

  /// Segment ids of [targetEditionId] aligned to each segment of
  /// [sourceEditionId], in reading order; empty when the pair has none.
  Future<Map<String, List<String>>> getAlignment(
    String sourceEditionId,
    String targetEditionId,
  ) {
    final key = '$sourceEditionId>$targetEditionId';
    return _memo(_alignments, key, capacity: segmentCacheSize, () async {
      final List<LibraryAlignment> pairs;
      try {
        pairs = await _fetchAllPages(
          (offset) => _datasource.fetchAlignments(
            sourceEditionId,
            targetEditionId,
            limit: segmentPageSize,
            offset: offset,
          ),
          (pair) => '${pair.source.id}>${pair.target.id}',
        );
      } catch (e) {
        if (_isNotFound(e)) return const {};
        rethrow;
      }
      final targets = <String, List<String>>{};
      for (final pair in pairs) {
        targets.putIfAbsent(pair.source.id, () => []).add(pair.target.id);
      }
      return targets;
    });
  }

  /// [editionId]'s marks, or null when they fail; never throws.
  Future<List<LibraryLineSpan>?> _yigchungsOrNull(String editionId) async {
    try {
      return await getYigchungs(editionId);
    } catch (e) {
      _logger.warning('Yigchungs for $editionId failed', e);
      return null;
    }
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
  Future<List<LibraryText>> _translationChain(
    LibraryText text, {
    int maxLength = _maxChainLength,
  }) async {
    final chain = [text];
    final seen = {text.id};
    var current = text;
    while (current.isTranslation && chain.length < maxLength) {
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
  /// null); `previous` ends just before it. Positions are 1-based. With
  /// [primaryEditionId] (the parallel reader's primary) the page holds only
  /// the verses aligned to it, numbered like it, and an anchor from it is
  /// mapped across.
  Future<LibraryContentWindow> loadWindow({
    required String editionId,
    String? anchorSegmentId,
    String? primaryEditionId,
    required String direction,
    required int size,
  }) async {
    var segments = await getEditionSegments(editionId);
    List<int>? numbers;
    if (primaryEditionId != null && primaryEditionId != editionId) {
      final paired = await _alignedToPrimary(
        editionId,
        primaryEditionId,
        segments,
      );
      if (paired != null) {
        segments = paired.segments;
        numbers = paired.numbers;
      }
    }
    numbers ??= segmentNumbers(segments);
    final total = segments.length;
    var anchorIndex =
        anchorSegmentId == null
            ? -1
            : segments.indexWhere((s) => s.id == anchorSegmentId);
    if (anchorIndex < 0 && anchorSegmentId != null) {
      anchorIndex = await _foreignAnchorIndex(
        anchorSegmentId,
        anchorEditionId: primaryEditionId,
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
    final spanEnd = page.last.spanEnd!;
    // Marks load alongside the content and get [yigchungTimeout] in all, so
    // ones that land while the content is still loading are kept. A slow
    // fetch keeps going so later pages get them.
    final clock = Stopwatch()..start();
    final yigchungsFuture = _yigchungsOrNull(editionId);
    final content = await _datasource.fetchEditionContent(
      editionId,
      spanStart: spanStart,
      spanEnd: spanEnd,
    );
    final left = yigchungTimeout - clock.elapsed;
    final yigchungs = await yigchungsFuture.timeout(
      left.isNegative ? Duration.zero : left,
      onTimeout: () {
        _logger.warning('Yigchungs for $editionId are slow; page opens bare');
        return null;
      },
    );
    final marks = (yigchungs ?? const <LibraryLineSpan>[])
        .where((y) => y.end > spanStart && y.start < spanEnd)
        .toList(growable: false);
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
            html: sliceLibraryHtml(
              content,
              segments[i].lines,
              spanStart: spanStart,
              yigchungs: marks,
            ),
            spanStart: segments[i].spanStart!,
            spanEnd: segments[i].spanEnd!,
          ),
      ],
      currentPosition: start + 1,
      lastPosition: end,
      totalSegments: total,
      isPartial: yigchungs == null,
    );
  }

  /// The id in [targetId]'s edition of [segmentId]'s counterpart in
  /// [sourceId]'s, paired the way [loadWindow] pairs the parallel reader.
  /// Both ids may be text or edition ids. Null when they are editions of
  /// unrelated texts (verse numbers would match by accident) or the verse has
  /// no counterpart.
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
    final index = await _alignedIndex(
      source.id,
      segmentId,
      target.id,
      segments,
    );
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
      final index = await _alignedIndex(
        anchorEditionId,
        segmentId,
        targetEditionId,
        target,
        orNext: true,
      );
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
    return _alignedIndex(
      sourceEditionId,
      segmentId,
      targetEditionId,
      target,
      orNext: true,
    );
  }

  /// Index in [target] of [segmentId]'s counterpart: by the alignment, else
  /// by verse number. [orNext] settles for the nearest later verse with one.
  Future<int> _alignedIndex(
    String editionId,
    String segmentId,
    String targetEditionId,
    List<LibrarySegment> target, {
    bool orNext = false,
  }) async {
    final source = await getEditionSegments(editionId);
    final sourceIndex = source.indexWhere((s) => s.id == segmentId);
    if (sourceIndex < 0) return -1;
    final aligned = await _alignedIds(editionId, targetEditionId);
    if (aligned.isEmpty) {
      final number = segmentNumbers(source)[sourceIndex];
      return segmentNumbers(target).indexOf(number);
    }
    final indexOf = {for (var i = 0; i < target.length; i++) target[i].id: i};
    final last = orNext ? source.length - 1 : sourceIndex;
    for (var i = sourceIndex; i <= last; i++) {
      for (final id in aligned[source[i].id] ?? const <String>[]) {
        final index = indexOf[id];
        if (index != null) return index;
      }
    }
    return -1;
  }

  /// Ids in [targetId] aligned to each segment of [sourceId]. The library
  /// stores a pair one way round, so the reverse is read when that is it.
  Future<Map<String, List<String>>> _alignedIds(
    String sourceId,
    String targetId,
  ) async {
    final forward = await getAlignment(sourceId, targetId);
    if (forward.isNotEmpty) return forward;
    final inverted = <String, List<String>>{};
    for (final entry in (await getAlignment(targetId, sourceId)).entries) {
      for (final id in entry.value) {
        inverted.putIfAbsent(id, () => []).add(entry.key);
      }
    }
    return inverted;
  }

  /// [segments] of [editionId] that have a counterpart in [primaryEditionId],
  /// numbered like it (the first one when several). Null when the pair has
  /// no alignment, or one naming none of the verses.
  Future<({List<LibrarySegment> segments, List<int> numbers})?>
  _alignedToPrimary(
    String editionId,
    String primaryEditionId,
    List<LibrarySegment> segments,
  ) async {
    final counterparts = await _alignedIds(editionId, primaryEditionId);
    if (counterparts.isEmpty) return null;
    final primary = await getEditionSegments(primaryEditionId);
    final primaryNumbers = segmentNumbers(primary);
    final numberOf = {
      for (var i = 0; i < primary.length; i++) primary[i].id: primaryNumbers[i],
    };
    final kept = <LibrarySegment>[];
    final numbers = <int>[];
    for (final segment in segments) {
      int? number;
      for (final id in counterparts[segment.id] ?? const <String>[]) {
        final n = numberOf[id];
        if (n != null && (number == null || n < number)) number = n;
      }
      if (number == null) continue;
      kept.add(segment);
      numbers.add(number);
    }
    if (kept.isEmpty) return null;
    return (segments: kept, numbers: numbers);
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

  /// Related editions of [segmentId], sorted by work the way the website
  /// does it (see [LibrarySegmentResources]). Segments of the open text are
  /// dropped; each remaining edition becomes one card with its aligned
  /// segments in reading order.
  Future<LibrarySegmentResources> loadSegmentResources(String segmentId) {
    return _memo(_resources, segmentId, capacity: 200, () async {
      final openTextId = await _textIdOfSegment(segmentId);
      final related = await _fetchAllPages(
        (offset) => _datasource.fetchRelatedSegments(
          segmentId,
          limit: relatedPageSize,
          offset: offset,
        ),
        (s) => s.id,
      );
      final usable =
          related
              .where(
                (s) =>
                    s.textId != null &&
                    s.editionId != null &&
                    s.textId != openTextId,
              )
              .toList();

      final textIds = {
        if (openTextId != null) openTextId,
        for (final s in usable) s.textId!,
      };
      final texts = <String, LibraryText?>{};
      await Future.wait(
        textIds.map((id) async => texts[id] = await _tryGetText(id)),
      );
      final works = <String, String?>{};
      await Future.wait(
        texts.entries.map((e) async {
          final text = e.value;
          works[e.key] = text == null ? null : await _workId(text);
        }),
      );
      // Originals reached only through a chain are cached; make them visible.
      for (final workId in works.values.whereType<String>().toSet()) {
        texts[workId] ??= await _tryGetText(workId);
      }

      final openWorkId = openTextId == null ? null : works[openTextId];
      final openWork =
          openWorkId == null
              ? null
              : (texts[openWorkId] ?? await _tryGetText(openWorkId));
      String? rootWorkId;
      if (openWork != null && openWork.isCommentary) {
        final root = await _tryGetText(openWork.commentaryOf!);
        rootWorkId = root == null ? null : await _workId(root);
      }

      // Cards, one per edition, in first-seen order.
      final byEdition = <String, List<LibrarySegment>>{};
      for (final s in usable) {
        byEdition.putIfAbsent(s.editionId!, () => []).add(s);
      }
      final cards = <LibraryRelatedEdition>[];
      for (final entry in byEdition.entries) {
        final segments = [...entry.value]
          ..sort((a, b) => (a.spanStart ?? 0).compareTo(b.spanStart ?? 0));
        cards.add(
          LibraryRelatedEdition(
            editionId: entry.key,
            text: texts[segments.first.textId],
            segments: segments,
          ),
        );
      }

      final translations = <LibraryRelatedEdition>[];
      final rootTexts = <LibraryRelatedEdition>[];
      final commentaryCards = <LibraryRelatedEdition>[];
      for (final card in cards) {
        final text = card.text;
        final workId = text == null ? null : works[text.id];
        final work = workId == null ? null : texts[workId];
        if (text == null || workId == null) {
          translations.add(card);
        } else if (workId == openWorkId) {
          translations.add(card);
        } else if (rootWorkId != null && workId == rootWorkId) {
          rootTexts.add(card);
        } else if ((work ?? text).isCommentary) {
          commentaryCards.add(card);
        } else {
          translations.add(card);
        }
      }

      return LibrarySegmentResources(
        translations: translations,
        commentaries: _nestCommentaryTranslations(commentaryCards, works),
        rootTexts: rootTexts,
        hasRootWork: rootWorkId != null,
      );
    });
  }

  /// Translations of a commentary go under that commentary's card, grouped
  /// by work. A translation whose original is not itself related stays a card.
  static List<LibraryRelatedEdition> _nestCommentaryTranslations(
    List<LibraryRelatedEdition> cards,
    Map<String, String?> works,
  ) {
    final byWork = <String, List<LibraryRelatedEdition>>{};
    for (final card in cards) {
      byWork.putIfAbsent(works[card.textId] ?? card.textId, () => []).add(card);
    }
    final result = <LibraryRelatedEdition>[];
    for (final entry in byWork.entries) {
      final originals =
          entry.value.where((c) => c.textId == entry.key).toList();
      if (originals.isEmpty) {
        result.addAll(entry.value);
        continue;
      }
      final translated = entry.value.where((c) => c.textId != entry.key);
      result.add(originals.first.withTranslations(translated.toList()));
      result.addAll(originals.skip(1));
    }
    return result;
  }

  /// Text of [segmentId]: from an edition already in memory (the reader
  /// loaded it), else from the segment itself. Null when it cannot be known.
  Future<String?> _textIdOfSegment(String segmentId) async {
    for (final entry in _segments.entries) {
      final segments = await entry.value.catchError((_) => <LibrarySegment>[]);
      if (segments.any((s) => s.id == segmentId)) {
        return (await _tryGetEdition(entry.key))?.textId;
      }
    }
    try {
      final segment = await getSegment(segmentId);
      if (segment.textId != null) return segment.textId;
      final editionId = segment.editionId;
      if (editionId != null) return (await _tryGetEdition(editionId))?.textId;
    } catch (e) {
      _logger.warning('Segment $segmentId could not be looked up', e);
    }
    return null;
  }

  Future<LibraryText?> _tryGetText(String id) async {
    try {
      return await getText(id);
    } catch (e) {
      _logger.warning('Text $id failed', e);
      return null;
    }
  }

  Future<LibraryEdition?> _tryGetEdition(String id) async {
    try {
      return await getEdition(id);
    } catch (e) {
      _logger.warning('Edition $id failed', e);
      return null;
    }
  }

  /// Bound on `translation_of` hops when resolving a text's work.
  static const _maxWorkSteps = 5;

  /// The original at the top of [text]'s translation chain: its work.
  Future<String> _workId(LibraryText text) async {
    final chain = await _translationChain(text, maxLength: _maxWorkSteps + 1);
    return chain.last.id;
  }

  /// The segments of a related edition sliced from one content fetch, plus
  /// the edition's source when available.
  Future<LibraryEditionContent> loadEditionContent(
    LibraryRelatedEdition edition,
  ) async {
    final spanned = edition.segments.where((s) => s.lines.isNotEmpty);
    if (spanned.isEmpty) {
      return LibraryEditionContent(
        segmentLines: [for (final _ in edition.segments) const []],
      );
    }
    final editionFuture = _tryGetEdition(edition.editionId);
    final spanStart = spanned
        .map((s) => s.spanStart!)
        .reduce((a, b) => a < b ? a : b);
    final spanEnd = spanned
        .map((s) => s.spanEnd!)
        .reduce((a, b) => a > b ? a : b);
    final content = await _datasource.fetchEditionContent(
      edition.editionId,
      spanStart: spanStart,
      spanEnd: spanEnd,
    );
    return LibraryEditionContent(
      segmentLines: [
        for (final s in edition.segments)
          sliceLibraryLines(content, s.lines, spanStart: spanStart),
      ],
      source: (await editionFuture)?.source,
    );
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
  Future<List<T>> _fetchAllPages<T>(
    Future<LibraryPage<T>> Function(int offset) fetchPage,
    String Function(T item) keyOf,
  ) async {
    final items = <T>[];
    final seen = <String>{};
    var offset = 0;
    for (var i = 0; i < maxPages; i++) {
      final page = await fetchPage(offset);
      final fresh = page.items.where((s) => seen.add(keyOf(s))).toList();
      items.addAll(fresh);
      if (!page.hasMore || fresh.isEmpty) return items;
      offset += page.items.length;
    }
    _logger.warning('Stopped paging after $maxPages pages');
    return items;
  }
}
