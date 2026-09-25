import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global on/off for the dual-slot reader layout. Persisted because it's a
/// stable UX preference ("I usually want a translation underneath").
class ReaderSecondaryEnabledNotifier extends StateNotifier<bool> {
  ReaderSecondaryEnabledNotifier({required LocalStorageService localStorage})
      : _storage = localStorage,
        super(false) {
    _loadFuture = _load();
  }

  final LocalStorageService _storage;
  late final Future<void> _loadFuture;

  /// Set by the first real change, so a slower startup read cannot revert it.
  bool _edited = false;

  /// Resolves once the persisted value has been read (or determined absent).
  Future<void> get loaded => _loadFuture;

  Future<void> _load() async {
    final stored = await _storage.get<bool>(
      StorageKeys.readerSecondaryEnabled,
    );
    if (stored == null || !mounted || _edited) return;
    state = stored;
  }

  void setEnabled(bool enabled) {
    if (state == enabled) return;
    _edited = true;
    state = enabled;
    _storage.set<bool>(StorageKeys.readerSecondaryEnabled, enabled);
  }
}

final readerSecondaryEnabledProvider =
    StateNotifierProvider<ReaderSecondaryEnabledNotifier, bool>((ref) {
  return ReaderSecondaryEnabledNotifier(
    localStorage: ref.read(localStorageServiceProvider),
  );
});

/// Global on/off for the original text when a translation is showing
/// ("translation only"). Persisted like [ReaderSecondaryEnabledNotifier];
/// default on.
class ReaderOriginalVisibleNotifier extends StateNotifier<bool> {
  ReaderOriginalVisibleNotifier({required LocalStorageService localStorage})
      : _storage = localStorage,
        super(true) {
    _loadFuture = _load();
  }

  final LocalStorageService _storage;
  late final Future<void> _loadFuture;

  /// Set by the first real change, so a slower startup read cannot revert it.
  bool _edited = false;

  /// Resolves once the persisted value has been read (or determined absent).
  Future<void> get loaded => _loadFuture;

  Future<void> _load() async {
    final stored = await _storage.get<bool>(StorageKeys.readerOriginalVisible);
    if (stored == null || !mounted || _edited) return;
    state = stored;
  }

  void setVisible(bool visible) {
    if (state == visible) return;
    _edited = true;
    state = visible;
    _storage.set<bool>(StorageKeys.readerOriginalVisible, visible);
  }
}

final readerOriginalVisibleProvider =
    StateNotifierProvider<ReaderOriginalVisibleNotifier, bool>((ref) {
  return ReaderOriginalVisibleNotifier(
    localStorage: ref.read(localStorageServiceProvider),
  );
});

/// Per-text dual-slot settings (the toggle + both slot configs).
///
/// `secondaryEnabled` is mirrored from the global
/// [readerSecondaryEnabledProvider] so toggling it persists once and is
/// observed by every text consistently.
///
/// `primary` and `secondary` slot picks live in memory only because their
/// `versionId` / `scriptId` are scoped to a specific text and cannot
/// meaningfully transfer to another text. autoDispose ensures they reset
/// the next time this text is opened.
class ReaderDualSettingsNotifier extends StateNotifier<ReaderDualLayoutSettings> {
  ReaderDualSettingsNotifier({required Ref ref})
      : _ref = ref,
        super(ReaderDualLayoutSettings.initial()) {
    _ref.listen<bool>(
      readerSecondaryEnabledProvider,
      (_, enabled) {
        if (!mounted) return;
        if (state.secondaryEnabled == enabled) return;
        state = state.copyWith(secondaryEnabled: enabled);
      },
      fireImmediately: true,
    );
    _ref.listen<bool>(
      readerOriginalVisibleProvider,
      (_, visible) {
        if (!mounted) return;
        if (state.originalVisible == visible) return;
        state = state.copyWith(originalVisible: visible);
      },
      fireImmediately: true,
    );
  }

  final Ref _ref;

  // "User has edited this slot" flags. Needed because the slot config alone
  // can't tell "untouched defaults" apart from "user picked something that
  // happens to match the defaults" (e.g. picking English when defaults are
  // English). The settings UI reads these to decide whether to show the
  // reader's loaded state or the user's explicit pick.
  bool _primaryEdited = false;
  bool _secondaryEdited = false;
  int _secondaryResolveGeneration = 0;
  int _secondaryEnabledGeneration = 0;

  bool get isPrimaryEdited => _primaryEdited;
  bool get isSecondaryEdited => _secondaryEdited;

  /// Bumped on every secondary slot write so in-flight version resolves can
  /// tell whether they still own the slot (including same-language picks).
  int get secondaryResolveGeneration => _secondaryResolveGeneration;

  /// Bumped when the parallel-on toggle actually changes so a pending
  /// Settings-language fill does not turn translation back on after the user
  /// disables it.
  int get secondaryEnabledGeneration => _secondaryEnabledGeneration;

  // The flags are written here as well as globally: after
  // [openAsTranslation] this text can differ from the persisted value, which
  // then has nothing to mirror back.
  void setSecondaryEnabled(bool enabled) {
    if (state.secondaryEnabled == enabled) return;
    _secondaryEnabledGeneration++;
    state = state.copyWith(secondaryEnabled: enabled);
    _ref.read(readerSecondaryEnabledProvider.notifier).setEnabled(enabled);
    // Turning the translation off must not leave nothing on screen.
    if (!enabled) setOriginalVisible(true);
  }

  /// Show or hide the original text. One layer is always on: hiding the
  /// original switches the translation on (the sheet then picks a version),
  /// and the widgets keep showing the original until that version exists.
  void setOriginalVisible(bool visible) {
    if (state.originalVisible == visible) return;
    state = state.copyWith(originalVisible: visible);
    _ref.read(readerOriginalVisibleProvider.notifier).setVisible(visible);
    if (!visible && !state.secondaryEnabled) setSecondaryEnabled(true);
  }

  /// Opens a translation as the Translation layer of its root text: the root
  /// is the primary, the opened edition the secondary, and only the
  /// translation shows, so the page reads as before. This text only; the
  /// persisted preferences are left alone.
  void openAsTranslation({
    required ReaderSlotConfig original,
    required ReaderSlotConfig translation,
  }) {
    _primaryEdited = true;
    _secondaryEdited = true;
    _secondaryResolveGeneration++;
    _secondaryEnabledGeneration++;
    state = state.copyWith(
      primary: original,
      secondary: translation,
      secondaryEnabled: true,
      originalVisible: false,
    );
  }

  void replacePrimary(ReaderSlotConfig config) {
    _primaryEdited = true;
    state = state.copyWith(primary: config);
  }

  void replaceSecondary(ReaderSlotConfig config) {
    _secondaryEdited = true;
    _secondaryResolveGeneration++;
    state = state.copyWith(secondary: config);
  }

  void updatePrimary(
    ReaderSlotConfig Function(ReaderSlotConfig current) update,
  ) {
    _primaryEdited = true;
    state = state.copyWith(primary: update(state.primary));
  }

  void updateSecondary(
    ReaderSlotConfig Function(ReaderSlotConfig current) update,
  ) {
    _secondaryEdited = true;
    _secondaryResolveGeneration++;
    state = state.copyWith(secondary: update(state.secondary));
  }
}

final readerDualSettingsProvider = StateNotifierProvider.autoDispose
    .family<ReaderDualSettingsNotifier, ReaderDualLayoutSettings, String>(
  (ref, _) => ReaderDualSettingsNotifier(ref: ref),
);

/// Transient (not persisted): true while the secondary slot's version is being
/// auto-resolved after a language change. Drives the version row's loading
/// state and blocks language edits until resolution completes.
final readerSecondaryResolvingProvider =
    StateProvider.autoDispose.family<bool, String>((ref, _) => false);
