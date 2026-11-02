import 'dart:convert';

import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/text_outline.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/data/repositories/texts_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FakeRemote implements TextRemoteDatasource {
  ReaderResponse? page;
  Exception? error;
  int calls = 0;

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
    calls++;
    if (error != null) throw error!;
    return page!;
  }

  @override
  Future<MultilingualSearchResponse> multilingualSearch({
    required String query,
    String? language,
    String? textId,
  }) => throw UnimplementedError();

  @override
  Future<String?> alignSegment({
    required String segmentId,
    required String sourceTextId,
    required String targetTextId,
  }) async => null;

  @override
  Future<TextOutline> fetchOutline({
    required String textId,
    String? versionId,
  }) => throw UnimplementedError();
}

ReaderResponse _page(String content, {bool partial = false}) {
  return ReaderResponse(
    textDetail: TextDetail(
      id: 'E1',
      title: 'Title',
      language: 'en',
      type: 'text',
      groupId: '',
      isPublished: true,
      createdDate: '',
      updatedDate: '',
      publishedDate: '',
      publishedBy: '',
    ),
    content: Toc(
      id: 'E1',
      textId: 'T1',
      sections: [
        Section(
          id: 'E1',
          sectionNumber: 1,
          segments: [
            Segment(segmentId: 'E1-1', segmentNumber: 1, content: content),
          ],
          sections: const [],
        ),
      ],
    ),
    size: 20,
    paginationDirection: 'next',
    currentSegmentPosition: 1,
    lastSegmentPosition: 1,
    totalSegments: 1,
    isPartial: partial,
  );
}

String? _content(ReaderResponse r) =>
    r.content.sections.first.segments.first.content;

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  late TextsRepository repo;

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
    repo = TextsRepository(remoteDatasource: remote, store: store);
  });

  test('first load fetches and stores the page', () async {
    remote.page = _page('a');
    final result = await repo.fetchTextDetails(textId: 'E1', language: 'en');
    expect(result.map(_content).toNullable(), 'a');
    expect(store.entries.values.single, jsonEncode(_page('a').toJson()));
  });

  test('a stored page returns at once and refreshes in the background',
      () async {
    remote.page = _page('a');
    await repo.fetchTextDetails(textId: 'E1', language: 'en');
    remote.page = _page('b');

    final result = await repo.fetchTextDetails(textId: 'E1', language: 'en');
    expect(result.map(_content).toNullable(), 'a');
    await pumpEventQueue();
    expect(remote.calls, 2);
    expect(store.entries.values.single, jsonEncode(_page('b').toJson()));
  });

  test('a partial page never replaces a stored complete one', () async {
    remote.page = _page('a');
    await repo.fetchTextDetails(textId: 'E1', language: 'en');
    remote.page = _page('b', partial: true);

    final result = await repo.fetchTextDetails(
      textId: 'E1',
      language: 'en',
      forceRefresh: true,
    );
    expect(result.map(_content).toNullable(), 'a');
    expect(store.entries.values.single, jsonEncode(_page('a').toJson()));
  });

  test('offline with a stored page still opens it', () async {
    remote.page = _page('a');
    await repo.fetchTextDetails(textId: 'E1', language: 'en');
    remote.error = const NetworkException('offline');

    final result = await repo.fetchTextDetails(textId: 'E1', language: 'en');
    expect(result.map(_content).toNullable(), 'a');
  });
}
