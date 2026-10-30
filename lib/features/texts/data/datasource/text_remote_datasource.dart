import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/text_outline.dart';

/// Reader text details and in-text search; implemented by the library adapter.
abstract class TextRemoteDatasource {
  Future<ReaderResponse> fetchTextDetails({
    required String textId,
    String? contentId,
    String? versionId,
    String? segmentId,
    String? direction,
    String? language,
    int? size,
  });

  Future<MultilingualSearchResponse> multilingualSearch({
    required String query,
    String? language,
    String? textId,
  });

  /// This reader's id for [segmentId] of [sourceTextId]: the same verse in
  /// [targetTextId], another edition or language of the same text. Null when
  /// the texts are unrelated or the verse has no counterpart.
  Future<String?> alignSegment({
    required String segmentId,
    required String sourceTextId,
    required String targetTextId,
  });

  /// [textId]'s whole table of contents, placed on its verses. With
  /// [versionId], that edition's instead, numbered like [textId]'s verses
  /// the way the parallel reader pairs them. Empty when it has none.
  Future<TextOutline> fetchOutline({required String textId, String? versionId});
}
