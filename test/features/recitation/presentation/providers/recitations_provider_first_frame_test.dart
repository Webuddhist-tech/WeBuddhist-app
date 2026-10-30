import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitations_page_response.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_datasource_provider.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemote extends RecitationsRemoteDatasource {
  List<RecitationModel> recitations = const [];

  @override
  Future<RecitationsPageResponse> fetchRecitationsPage({
    RecitationsQueryParams? queryParams,
  }) async {
    return RecitationsPageResponse(
      recitations: recitations,
      skip: 0,
      limit: 20,
      total: recitations.length,
    );
  }
}

void main() {
  test('the stored chant list is the state on the very first read', () async {
    final store = FakeScreenCacheStore();
    final key = ScreenCacheKey.public('recitations', language: 'en');
    store.entries[key] = '[{"text_id":"1","title":"Old","language":"en"}]';
    final remote =
        _FakeRemote()
          ..recitations = [
            RecitationModel(textId: '1', title: 'Old', language: 'en'),
            RecitationModel(textId: '2', title: 'New', language: 'en'),
          ];
    final container = ProviderContainer(
      overrides: [
        screenCacheStoreProvider.overrideWithValue(store),
        recitationsRemoteDatasourceProvider.overrideWithValue(remote),
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(recitationsFutureProvider, (_, __) {});

    List<String> titles(AsyncValue<dynamic> v) =>
        (v.valueOrNull?.fold((_) => const [], (l) => l) as List<RecitationModel>?)
            ?.map((r) => r.title)
            .toList() ??
        const [];

    final first = container.read(recitationsFutureProvider);
    expect(first.isLoading, isFalse);
    expect(titles(first), ['Old']);

    await pumpEventQueue();
    expect(titles(container.read(recitationsFutureProvider)), ['Old', 'New']);
  });
}
