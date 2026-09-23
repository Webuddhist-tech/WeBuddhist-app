import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/library/data/models/library_search_result.dart';
import 'package:flutter_pecha/features/library/data/models/library_text.dart';
import 'package:flutter_pecha/features/library/data/repositories/library_repository.dart';
import 'package:flutter_pecha/features/texts/constants/text_details_constants.dart';
import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_source_result.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/data/models/translation.dart';

/// Serves the reader's text details and in-text search from the library API.
class LibraryTextRemoteDatasource implements TextRemoteDatasource {
  LibraryTextRemoteDatasource({required LibraryRepository library})
    : _library = library;

  final LibraryRepository _library;

  static const int _searchLimit = 50;

  /// A version id is a library text id; its content is the first edition.
  /// With [versionId] set (the parallel reader) the companion's lines go in
  /// `translation.content` and its own segment ids drive pagination.
  @override
  Future<ReaderResponse> fetchTextDetails({
    required String textId,
    String? contentId,
    String? versionId,
    String? segmentId,
    String? direction,
    String? language,
    int? size,
  }) async {
    final isSecondary =
        versionId != null && versionId.isNotEmpty && versionId != textId;
    final loadTextId = isSecondary ? versionId : textId;
    final text = await _library.getText(loadTextId);
    final editionId = text.primaryEditionId;
    if (editionId == null) {
      throw NotFoundException('Text $loadTextId has no edition');
    }

    final pageSize = size ?? TextDetailsConstants.defaultPageSize;
    final pageDirection = direction ?? 'next';
    final window = await _library.loadWindow(
      editionId: editionId,
      anchorSegmentId: segmentId,
      direction: pageDirection,
      size: pageSize,
    );

    final segments = [
      for (final s in window.segments)
        Segment(
          segmentId: s.id,
          segmentNumber: s.number,
          content: isSecondary ? null : s.html,
          translation:
              isSecondary
                  ? Translation(
                    textId: loadTextId,
                    language: text.language,
                    content: s.html,
                  )
                  : null,
        ),
    ];

    return ReaderResponse(
      textDetail: _textDetail(text, id: loadTextId),
      content: Toc(
        id: editionId,
        textId: loadTextId,
        sections: [
          Section(
            id: editionId,
            sectionNumber: 1,
            segments: segments,
            sections: const [],
          ),
        ],
      ),
      size: pageSize,
      paginationDirection: pageDirection,
      currentSegmentPosition: window.currentPosition,
      totalSegments: window.totalSegments,
    );
  }

  @override
  Future<MultilingualSearchResponse> multilingualSearch({
    required String query,
    String? language,
    String? textId,
  }) async {
    final results = await _library.search(
      query: query,
      textId: textId,
      limit: _searchLimit,
    );
    final byText = <String, List<LibrarySearchResult>>{};
    for (final result in results) {
      byText.putIfAbsent(result.textId, () => []).add(result);
    }

    final sources = <MultilingualSourceResult>[];
    for (final entry in byText.entries) {
      final text = await _library.getText(entry.key);
      final seen = <String>{};
      final matches = <MultilingualSegmentMatch>[];
      for (final result in entry.value) {
        for (final segmentId in result.segmentIds) {
          if (!seen.add(segmentId)) continue;
          matches.add(
            MultilingualSegmentMatch(
              segmentId: segmentId,
              content: result.context,
              relevanceScore: result.score,
              pechaSegmentId: segmentId,
            ),
          );
        }
      }
      sources.add(
        MultilingualSourceResult(
          text: TextIndex(
            textId: text.id,
            language: text.language,
            title: text.displayTitle,
            publishedDate: '',
          ),
          segmentMatches: matches,
        ),
      );
    }

    return MultilingualSearchResponse(
      query: query,
      searchType: 'exact',
      sources: sources,
      skip: 0,
      limit: _searchLimit,
      total: sources.length,
    );
  }

  static TextDetail _textDetail(LibraryText text, {required String id}) {
    return TextDetail(
      id: id,
      title: text.displayTitle,
      language: text.language,
      type: 'text',
      groupId: '',
      isPublished: true,
      createdDate: '',
      updatedDate: '',
      publishedDate: '',
      publishedBy: '',
      license: text.license,
      parentId: text.translationOf,
    );
  }
}
