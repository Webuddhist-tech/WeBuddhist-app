import 'package:flutter_pecha/features/library/data/models/library_reader_models.dart';
import 'package:flutter_pecha/features/library/data/repositories/library_repository.dart';
import 'package:flutter_pecha/features/texts/data/models/commentary/parent_segment.dart';
import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary.dart';
import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary_response.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_detail_with_text.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_info.dart';
import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation.dart';
import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation_response.dart';
import 'package:flutter_pecha/features/texts/domain/repositories/segment_repository.dart';

/// Segment panels (commentaries, versions, root text, info) served by the
/// library API. Each card is one edition with all its aligned segments.
class LibrarySegmentRepository implements SegmentRepositoryInterface {
  LibrarySegmentRepository({required LibraryRepository library})
    : _library = library;

  final LibraryRepository _library;

  @override
  Future<SegmentDetailWithText> getSegmentWithTextDetails(
    String segmentId,
  ) async {
    final segment = await _library.getSegment(segmentId);
    final content = await _library.loadResourceContent(segment);
    final textId = segment.textId;
    final title =
        textId == null ? '' : (await _library.getText(textId)).displayTitle;
    return SegmentDetailWithText(
      id: segmentId,
      content: content.html,
      textTitle: title,
    );
  }

  // The library has no videos or sheets; counts are editions, not segments.
  @override
  Future<SegmentInfo> getSegmentInfo(String segmentId) async {
    final resources = await _library.loadSegmentResources(segmentId);
    return SegmentInfo(
      segmentId: segmentId,
      textId: '',
      translations: resources.translations.length,
      relatedText: SegmentRelatedTextInfo(
        commentaries: resources.commentaryEditionCount,
        rootText: resources.rootTexts.length,
        hasRootText: resources.hasRootWork,
      ),
      resources: const SegmentResourcesInfo(sheets: 0),
      videos: const [],
    );
  }

  @override
  Future<SegmentCommentaryResponse> getSegmentCommentaries(
    String segmentId,
  ) async {
    final resources = await _library.loadSegmentResources(segmentId);
    return SegmentCommentaryResponse(
      parentSegment: ParentSegment(segmentId: segmentId, content: ''),
      commentaries: await Future.wait(resources.commentaries.map(_commentary)),
    );
  }

  @override
  Future<SegmentTranslationResponse> getSegmentTranslations(
    String segmentId,
  ) async {
    final resources = await _library.loadSegmentResources(segmentId);
    return _translations(segmentId, resources.translations);
  }

  @override
  Future<SegmentTranslationResponse> getSegmentRootTexts(
    String segmentId,
  ) async {
    final resources = await _library.loadSegmentResources(segmentId);
    return _translations(segmentId, resources.rootTexts);
  }

  Future<SegmentTranslationResponse> _translations(
    String segmentId,
    List<LibraryRelatedEdition> editions,
  ) async {
    final contents = await Future.wait(
      editions.map(_library.loadEditionContent),
    );
    return SegmentTranslationResponse(
      parentSegment: ParentSegment(segmentId: segmentId, content: ''),
      translations: [
        for (var i = 0; i < editions.length; i++)
          SegmentTranslation(
            textId: editions[i].textId,
            title: editions[i].title,
            language: editions[i].language,
            source: contents[i].source,
            license: editions[i].text?.license,
            segments: [
              for (var j = 0; j < contents[i].segmentLines.length; j++)
                TranslationSegment(
                  id: editions[i].segments[j].id,
                  content: contents[i].htmls[j],
                ),
            ],
          ),
      ],
    );
  }

  Future<SegmentCommentary> _commentary(LibraryRelatedEdition edition) async {
    final content = await _library.loadEditionContent(edition);
    final nested = await Future.wait(edition.translations.map(_commentary));
    final htmls = content.htmls;
    return SegmentCommentary(
      textId: edition.textId,
      title: edition.title,
      language: edition.language,
      count: htmls.length,
      source: content.source,
      license: edition.text?.license,
      segments: [
        for (var j = 0; j < htmls.length; j++)
          MappedSegmentDTO(
            segmentId: edition.segments[j].id,
            content: htmls[j],
          ),
      ],
      translations: nested,
    );
  }
}
