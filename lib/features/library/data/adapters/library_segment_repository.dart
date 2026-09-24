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

/// Segment panels (commentaries, versions, info) served by the library API.
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

  // The library has no videos or sheets; only the counts are meaningful.
  @override
  Future<SegmentInfo> getSegmentInfo(String segmentId) async {
    final resources = await _library.loadSegmentResources(segmentId);
    return SegmentInfo(
      segmentId: segmentId,
      textId: '',
      translations: resources.versions.length,
      relatedText: SegmentRelatedTextInfo(
        commentaries: resources.commentaries.length,
        rootText: resources.versions.where((r) => !r.text.isTranslation).length,
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
    final contents = await _contents(resources.commentaries);
    return SegmentCommentaryResponse(
      parentSegment: ParentSegment(segmentId: segmentId, content: ''),
      commentaries: [
        for (var i = 0; i < resources.commentaries.length; i++)
          SegmentCommentary(
            textId: resources.commentaries[i].text.id,
            title: resources.commentaries[i].title,
            segments: [
              MappedSegmentDTO(
                segmentId: resources.commentaries[i].segmentId,
                content: contents[i].html,
              ),
            ],
            language: resources.commentaries[i].language,
            count: 1,
            source: contents[i].source,
            license: resources.commentaries[i].text.license,
          ),
      ],
    );
  }

  @override
  Future<SegmentTranslationResponse> getSegmentTranslations(
    String segmentId,
  ) async {
    final resources = await _library.loadSegmentResources(segmentId);
    final contents = await _contents(resources.versions);
    return SegmentTranslationResponse(
      parentSegment: ParentSegment(segmentId: segmentId, content: ''),
      translations: [
        for (var i = 0; i < resources.versions.length; i++)
          SegmentTranslation(
            textId: resources.versions[i].text.id,
            title: resources.versions[i].title,
            language: resources.versions[i].language,
            source: contents[i].source,
            license: resources.versions[i].text.license,
            segments: [
              TranslationSegment(
                id: resources.versions[i].segmentId,
                content: contents[i].html,
              ),
            ],
          ),
      ],
    );
  }

  Future<List<LibraryResourceContent>> _contents(
    List<LibraryRelatedResource> resources,
  ) {
    return Future.wait(
      resources.map((r) => _library.loadResourceContent(r.segment)),
    );
  }
}
