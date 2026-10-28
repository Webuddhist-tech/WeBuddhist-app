import 'dart:convert';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary_response.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/segment_usecases.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/segment_provider.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FakeUseCase implements GetSegmentCommentariesUseCase {
  Map<String, dynamic> json = _response('fresh');

  @override
  Future<SegmentCommentaryResponse> call(String segmentId) async =>
      SegmentCommentaryResponse.fromJson(json);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _response(String id) => {
  'parent_segment': {'segment_id': id, 'content': 'text'},
  'commentaries': <dynamic>[],
};

void main() {
  test('the stored panel is the state on the very first read', () async {
    final store = FakeScreenCacheStore();
    final key = ScreenCacheKey.public(
      'segment_commentaries',
      language: 'all',
      params: ['s1'],
    );
    store.entries[key] = jsonEncode(_response('stored'));
    final container = ProviderContainer(
      overrides: [
        screenCacheStoreProvider.overrideWithValue(store),
        getSegmentCommentariesUseCaseProvider.overrideWithValue(_FakeUseCase()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(segmentCommentaryFutureProvider('s1'), (_, __) {});

    final first = container.read(segmentCommentaryFutureProvider('s1'));
    expect(first.isLoading, isFalse);
    expect(first.requireValue.parentSegment.segmentId, 'stored');

    await pumpEventQueue();
    expect(
      container
          .read(segmentCommentaryFutureProvider('s1'))
          .requireValue
          .parentSegment
          .segmentId,
      'fresh',
    );
  });
}
