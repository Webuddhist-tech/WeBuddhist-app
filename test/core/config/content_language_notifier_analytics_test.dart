import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/config/locale/content_language_analytics.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../analytics/recording_analytics_service.dart';
import 'locale_provider_test.mocks.dart';

void main() {
  late MockLocalStorageService storage;
  late RecordingAnalyticsService service;
  late ContentLanguageNotifier notifier;

  setUp(() async {
    storage = MockLocalStorageService();
    when(storage.get<String>(any)).thenAnswer((_) async => 'en');
    when(storage.set<String>(any, any)).thenAnswer((_) async => true);
    service = RecordingAnalyticsService();
    notifier = ContentLanguageNotifier(
      localStorageService: storage,
      analytics: ContentLanguageAnalytics(service),
    );
    await notifier.ensureInitialized();
  });

  tearDown(() => notifier.dispose());

  test('a new content language fires once it is persisted', () async {
    await notifier.setContentLanguage(
      'bo',
      source: ContentLanguageSource.settings,
    );

    verify(storage.set<String>(StorageKeys.contentLanguage, 'bo')).called(1);
    expect(service.eventNames, [AnalyticsEvents.contentLanguageChanged]);
    expect(service.events.single.properties, {
      'from': 'en',
      'to': 'bo',
      'source': 'settings',
    });
  });

  test('re-selecting the current language is not a change', () async {
    await notifier.setContentLanguage('en');

    expect(service.events, isEmpty);
  });

  test('a failed persist fires nothing', () async {
    when(storage.set<String>(any, any)).thenThrow(Exception('disk full'));

    await expectLater(notifier.setContentLanguage('bo'), throwsException);
    expect(service.events, isEmpty);
  });

  test('the backend kill switch reports itself as the source', () async {
    await notifier.reconcileToAvailable(['zh']);

    expect(service.events.single.properties, {
      'from': 'en',
      'to': 'zh',
      'source': 'reconcile',
    });
  });
}
