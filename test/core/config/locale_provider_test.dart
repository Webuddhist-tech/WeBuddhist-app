import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'locale_provider_test.mocks.dart';

// Generate mock using build_runner:
// dart run build_runner build
@GenerateMocks([LocalStorageService])
void main() {
  late MockLocalStorageService mockLocalStorageService;
  late LocaleNotifier localeNotifier;

  /// Waits for the async init started in [LocaleNotifier]'s ctor.
  Future<LocaleNotifier> createLocaleNotifier() async {
    final notifier = LocaleNotifier(
      localStorageService: mockLocalStorageService,
    );
    await notifier.ensureInitialized();
    return notifier;
  }

  setUp(() {
    mockLocalStorageService = MockLocalStorageService();
  });

  tearDown(() {
    // Clean up after each test
    localeNotifier.dispose();
  });

  group('LocaleNotifier - Valid Scenarios', () {
    test('should load valid stored locale "en" on initialization', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => 'en');

      // Act
      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero); // Wait for async initialization

      // Assert
      expect(localeNotifier.state.languageCode, 'en');
      verify(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).called(1);
    });

    test('should load valid stored locale "bo" on initialization', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => 'bo');

      // Act
      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);

      // Assert
      expect(localeNotifier.state.languageCode, 'bo');
      verify(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).called(1);
    });

    test('should load valid stored locale "zh" on initialization', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => 'zh');

      // Act
      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);

      // Assert
      expect(localeNotifier.state.languageCode, 'zh');
      verify(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).called(1);
    });

    test('should load stored Simplified Chinese with its script', () async {
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => 'zh-Hans');

      localeNotifier = await createLocaleNotifier();

      expect(localeNotifier.state.languageCode, 'zh');
      expect(localeNotifier.state.scriptCode, 'Hans');
    });

    test('should persist Simplified Chinese chosen as content', () async {
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => null);
      when(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, any),
      ).thenAnswer((_) async => true);
      localeNotifier = await createLocaleNotifier();

      await localeNotifier.applyUiLocaleForContent('zh-hans');

      expect(localeNotifier.state.toLanguageTag(), 'zh-Hans');
      verify(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, 'zh-Hans'),
      ).called(1);
    });

    test('should localize the UI into Thai, Burmese and Vietnamese', () async {
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => null);
      when(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, any),
      ).thenAnswer((_) async => true);
      localeNotifier = await createLocaleNotifier();

      for (final String code in <String>['th', 'my', 'vi']) {
        await localeNotifier.applyUiLocaleForContent(code);

        expect(localeNotifier.state, Locale(code), reason: code);
      }
    });

    test('should set and persist new locale', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => null);
      when(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, any),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);

      // Act
      await localeNotifier.setLocale(const Locale('bo'));

      // Assert
      expect(localeNotifier.state.languageCode, 'bo');
      verify(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, 'bo'),
      ).called(1);
    });

    test(
      'should default to "en" on first launch with no stored data',
      () async {
        // Arrange
        when(
          mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
        ).thenAnswer((_) async => null);

        // Act
        localeNotifier = LocaleNotifier(
          localStorageService: mockLocalStorageService,
        );
        await Future.delayed(Duration.zero);

        // Assert
        expect(localeNotifier.state.languageCode, 'en');
        verify(
          mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
        ).called(1);
      },
    );

    test('should persist locale change correctly', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => 'en');
      when(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, any),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);

      // Act
      await localeNotifier.setLocale(const Locale('zh'));
      await localeNotifier.setLocale(const Locale('bo'));

      // Assert
      expect(localeNotifier.state.languageCode, 'bo');
      verify(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, 'zh'),
      ).called(1);
      verify(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, 'bo'),
      ).called(1);
    });
  });

  group('LocaleNotifier - Invalid Scenarios', () {
    test(
      'should load unsupported locale when stored (fr) - no validation on load',
      () async {
        // Arrange
        when(
          mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
        ).thenAnswer((_) async => 'fr');

        // Act
        localeNotifier = LocaleNotifier(
          localStorageService: mockLocalStorageService,
        );
        await Future.delayed(Duration.zero);

        // Assert - Implementation doesn't validate on load, so it sets the locale
        expect(localeNotifier.state.languageCode, 'fr');
        verify(
          mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
        ).called(1);
      },
    );

    test(
      'should load unsupported locale when stored (de) - no validation on load',
      () async {
        // Arrange
        when(
          mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
        ).thenAnswer((_) async => 'de');

        // Act
        localeNotifier = LocaleNotifier(
          localStorageService: mockLocalStorageService,
        );
        await Future.delayed(Duration.zero);

        // Assert - Implementation doesn't validate on load, so it sets the locale
        expect(localeNotifier.state.languageCode, 'de');
        verify(
          mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
        ).called(1);
      },
    );

    test(
      'should load unsupported locale when stored (es) - no validation on load',
      () async {
        // Arrange
        when(
          mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
        ).thenAnswer((_) async => 'es');

        // Act
        localeNotifier = LocaleNotifier(
          localStorageService: mockLocalStorageService,
        );
        await Future.delayed(Duration.zero);

        // Assert - Implementation doesn't validate on load, so it sets the locale
        expect(localeNotifier.state.languageCode, 'es');
        verify(
          mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
        ).called(1);
      },
    );

    test('should default to "en" when stored value is null', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => null);

      // Act
      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);

      // Assert
      expect(localeNotifier.state.languageCode, 'en');
      verify(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).called(1);
    });

    test('should default to "en" when stored value is empty string', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => '');

      // Act
      localeNotifier = await createLocaleNotifier();

      // Assert — Flutter normalizes Locale('') to languageCode 'en'
      expect(localeNotifier.state.languageCode, 'en');
      verify(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).called(1);
    });

    test(
      'should throw exception when setLocale is called with unsupported locale',
      () async {
        // Arrange
        when(
          mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
        ).thenAnswer((_) async => 'en');

        localeNotifier = LocaleNotifier(
          localStorageService: mockLocalStorageService,
        );
        await Future.delayed(Duration.zero);

        // Act & Assert — validation throws before state is updated
        await expectLater(
          localeNotifier.setLocale(const Locale('fr')),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Locale fr is not supported'),
            ),
          ),
        );
        expect(localeNotifier.state.languageCode, 'en');
      },
    );

    test(
      'should load invalid locale when stored - no validation on load',
      () async {
        // Arrange
        when(
          mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
        ).thenAnswer((_) async => 'invalid-locale-123');

        // Act
        localeNotifier = LocaleNotifier(
          localStorageService: mockLocalStorageService,
        );
        await Future.delayed(Duration.zero);

        // Assert - Implementation doesn't validate on load, so it sets the locale
        expect(localeNotifier.state.languageCode, 'invalid-locale-123');
        verify(
          mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
        ).called(1);
      },
    );
  });

  group('LocaleNotifier - Edge Cases', () {
    test('should handle storage service failure gracefully', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(
        () =>
            localeNotifier = LocaleNotifier(
              localStorageService: mockLocalStorageService,
            ),
        returnsNormally,
      );
      // Should use default "en" locale
      expect(localeNotifier.state.languageCode, 'en');
    });

    test('should handle concurrent locale changes correctly', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => 'en');
      when(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, any),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);

      // Act - Simulate concurrent changes
      final futures = [
        localeNotifier.setLocale(const Locale('bo')),
        localeNotifier.setLocale(const Locale('zh')),
        localeNotifier.setLocale(const Locale('en')),
      ];
      await Future.wait(futures);

      // Assert - Last change should win
      expect(localeNotifier.state.languageCode, 'en');
      verify(mockLocalStorageService.set(StorageKeys.preferredLanguage, any)).called(3);
    });

    test('should verify locale is persisted after setting', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => 'en');
      when(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, 'zh'),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);

      // Act
      await localeNotifier.setLocale(const Locale('zh'));

      // Assert
      verify(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, 'zh'),
      ).called(1);
      expect(localeNotifier.state.languageCode, 'zh');
    });

    test('should handle storage set failure gracefully', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => 'en');
      when(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, any),
      ).thenThrow(Exception('Failed to save'));

      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);

      // Act & Assert — state updates before persistence; save failure propagates
      await expectLater(
        localeNotifier.setLocale(const Locale('bo')),
        throwsA(isA<Exception>()),
      );
      expect(localeNotifier.state.languageCode, 'bo');
    });

    test('should maintain state consistency across multiple changes', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => null);
      when(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, any),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);

      // Act - Multiple sequential changes
      expect(localeNotifier.state.languageCode, 'en');

      await localeNotifier.setLocale(const Locale('bo'));
      expect(localeNotifier.state.languageCode, 'bo');

      await localeNotifier.setLocale(const Locale('zh'));
      expect(localeNotifier.state.languageCode, 'zh');

      await localeNotifier.setLocale(const Locale('en'));
      expect(localeNotifier.state.languageCode, 'en');

      // Assert
      verify(mockLocalStorageService.set(StorageKeys.preferredLanguage, any)).called(3);
    });
  });

  group('LocaleNotifier - Integration Scenarios', () {
    test('should handle app restart simulation with valid locale', () async {
      // Arrange - First app session
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => null);
      when(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, any),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);
      await localeNotifier.setLocale(const Locale('bo'));
      localeNotifier.dispose();

      // Arrange - Second app session (restart)
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => 'bo');

      // Act
      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);

      // Assert - Should restore previous locale
      expect(localeNotifier.state.languageCode, 'bo');
    });

    test(
      'should load unsupported locale on app update - no validation on load',
      () async {
        // Arrange - Simulate old app version stored unsupported locale
        when(
          mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
        ).thenAnswer((_) async => 'unsupported_old_locale');

        // Act
        localeNotifier = LocaleNotifier(
          localStorageService: mockLocalStorageService,
        );
        await Future.delayed(Duration.zero);

        // Assert - Implementation doesn't validate on load, so it sets the locale
        expect(localeNotifier.state.languageCode, 'unsupported_old_locale');
      },
    );

    test('should handle clear data scenario', () async {
      // Arrange
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => 'bo');
      when(
        mockLocalStorageService.set(StorageKeys.preferredLanguage, any),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);
      expect(localeNotifier.state.languageCode, 'bo');
      localeNotifier.dispose();

      // Act - Simulate app data cleared
      when(
        mockLocalStorageService.get<String>(StorageKeys.preferredLanguage),
      ).thenAnswer((_) async => null);

      localeNotifier = LocaleNotifier(
        localStorageService: mockLocalStorageService,
      );
      await Future.delayed(Duration.zero);

      // Assert - Should use default
      expect(localeNotifier.state.languageCode, 'en');
    });
  });
}
