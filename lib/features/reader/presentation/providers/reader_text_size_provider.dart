import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_text_size.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The reader's size steps and spacing, kept in local storage.
///
/// The first load moves an old single font size over: 18 becomes step 3 and
/// any other size the nearest step, for both lines.
class ReaderTextSizeNotifier extends StateNotifier<ReaderTextSize> {
  ReaderTextSizeNotifier({required LocalStorageService localStorageService})
    : _storage = localStorageService,
      super(const ReaderTextSize()) {
    _ready = _load();
  }

  final LocalStorageService _storage;
  late final Future<void> _ready;

  /// Completes once the stored settings are in [state].
  Future<void> get ready => _ready;

  Future<void> _load() async {
    final original = await _storage.get<int>(StorageKeys.readerOriginalStep);
    final translation = await _storage.get<int>(
      StorageKeys.readerTranslationStep,
    );
    final spacing = await _storage.get<String>(StorageKeys.readerSpacing);
    if (!mounted) return;

    if (original == null && translation == null) {
      final legacy = await _storage.get<double>(StorageKeys.fontSize);
      if (!mounted) return;
      if (legacy != null) {
        final step = ReaderTextSize.stepForLegacyFontSize(legacy);
        state = state.copyWith(
          originalStep: step,
          translationStep: step,
          spacing: ReaderSpacing.fromName(spacing),
        );
        await _saveSteps();
        return;
      }
    }
    state = state.copyWith(
      originalStep: original,
      translationStep: translation,
      spacing: ReaderSpacing.fromName(spacing),
    );
  }

  /// Moves both lines one step up ([delta] 1) or down (-1); a line already
  /// at the end stays there.
  Future<void> stepBoth(int delta) async {
    await _ready;
    state = state.copyWith(
      originalStep: state.originalStep + delta,
      translationStep: state.translationStep + delta,
    );
    await _saveSteps();
  }

  Future<void> setOriginalStep(int step) async {
    await _ready;
    state = state.copyWith(originalStep: step);
    await _saveSteps();
  }

  Future<void> setTranslationStep(int step) async {
    await _ready;
    state = state.copyWith(translationStep: step);
    await _saveSteps();
  }

  Future<void> setSpacing(ReaderSpacing spacing) async {
    await _ready;
    state = state.copyWith(spacing: spacing);
    await _storage.set<String>(StorageKeys.readerSpacing, spacing.name);
  }

  Future<void> _saveSteps() async {
    await _storage.set<int>(StorageKeys.readerOriginalStep, state.originalStep);
    await _storage.set<int>(
      StorageKeys.readerTranslationStep,
      state.translationStep,
    );
  }
}

final readerTextSizeProvider =
    StateNotifierProvider<ReaderTextSizeNotifier, ReaderTextSize>(
      (ref) => ReaderTextSizeNotifier(
        localStorageService: ref.read(localStorageServiceProvider),
      ),
    );
