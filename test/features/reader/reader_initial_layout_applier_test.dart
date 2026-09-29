import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_initial_layout_applier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('readerInitialLayoutStep', () {
    const loaded = AsyncData<List<ReaderLanguageOption>>([]);
    const loading = AsyncLoading<List<ReaderLanguageOption>>();
    const failed = AsyncError<List<ReaderLanguageOption>>(
      'offline',
      StackTrace.empty,
    );

    test('waits until the text and its list of translations are known', () {
      expect(
        readerInitialLayoutStep(applied: false, hasText: false, languages: loaded),
        ReaderInitialLayoutStep.wait,
      );
      expect(
        readerInitialLayoutStep(applied: false, hasText: true, languages: loading),
        ReaderInitialLayoutStep.wait,
      );
    });

    test('applies once both are known, and only once', () {
      expect(
        readerInitialLayoutStep(applied: false, hasText: true, languages: loaded),
        ReaderInitialLayoutStep.apply,
      );
      expect(
        readerInitialLayoutStep(applied: true, hasText: true, languages: loaded),
        ReaderInitialLayoutStep.wait,
      );
    });

    test('only seeds while the list failed to load, so a retry can still apply', () {
      expect(
        readerInitialLayoutStep(applied: false, hasText: true, languages: failed),
        ReaderInitialLayoutStep.seedOnly,
      );
      expect(
        readerInitialLayoutStep(applied: false, hasText: false, languages: failed),
        ReaderInitialLayoutStep.wait,
      );
    });
  });

  group('readerOpenedTranslationNeedsRefill', () {
    bool needsRefill({
      String? openedLanguage = 'en',
      String? openedVersionId = 'v-en',
      String? currentVersionId = 'v-en',
      String? rememberedLanguage,
      String? rememberedVersionId,
      bool pinnedByList = false,
    }) => readerOpenedTranslationNeedsRefill(
      openedLanguage: openedLanguage,
      openedVersionId: openedVersionId,
      currentVersionId: currentVersionId,
      rememberedLanguage: rememberedLanguage,
      rememberedVersionId: rememberedVersionId,
      pinnedByList: pinnedByList,
    );

    test('nothing remembered keeps the opened edition', () {
      expect(needsRefill(), isFalse);
    });

    test('another language picked in this context replaces it', () {
      expect(needsRefill(rememberedLanguage: 'zh'), isTrue);
      expect(
        needsRefill(rememberedLanguage: ' EN'),
        isFalse,
        reason: 'the same language, whatever the case',
      );
    });

    test('another edition picked for this text replaces it', () {
      expect(needsRefill(rememberedVersionId: 'v-en-2'), isTrue);
      expect(needsRefill(rememberedVersionId: 'v-en'), isFalse);
    });

    test('a slot written since opening is left alone', () {
      expect(
        needsRefill(currentVersionId: 'v-zh', rememberedLanguage: 'hi'),
        isFalse,
      );
    });

    test('a chant picked in the opened language keeps it', () {
      expect(
        needsRefill(rememberedLanguage: 'zh', pinnedByList: true),
        isFalse,
      );
    });

    test('a text that was not opened as a translation has nothing to swap', () {
      expect(
        needsRefill(
          openedLanguage: null,
          openedVersionId: null,
          rememberedLanguage: 'zh',
        ),
        isFalse,
      );
    });
  });
}
