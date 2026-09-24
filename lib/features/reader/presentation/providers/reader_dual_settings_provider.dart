import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_context_layout_prefs.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_initial_layout.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_context_layout_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart';
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

/// Dual-slot settings of one text in one context (the toggles, the script of
/// the original and both slot configs), keyed by [ReaderSettingsScope].
///
/// In the library the toggles mirror the app-wide
/// [readerSecondaryEnabledProvider] / [readerOriginalVisibleProvider] and the
/// script comes from the app-wide script map, exactly as before contexts
/// existed. In an event, a chant or a plan they come from that context's
/// [readerContextLayoutProvider] (what the person changed there), and where
/// that store has no pick, from this visit's [seed].
///
/// `primary` and `secondary` slot picks live in memory only because their
/// `versionId` / `scriptId` are scoped to a specific text and cannot
/// meaningfully transfer to another text. autoDispose ensures they reset
/// the next time this text is opened.
class ReaderDualSettingsNotifier extends StateNotifier<ReaderDualLayoutSettings> {
  ReaderDualSettingsNotifier({required Ref ref, required this.scope})
      : _ref = ref,
        super(ReaderDualLayoutSettings.initial()) {
    if (isLibrary) {
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
    } else {
      _ref.listen<ReaderContextLayoutPrefs>(
        readerContextLayoutProvider(scope.context),
        (_, __) => _recompute(),
        fireImmediately: true,
      );
    }
  }

  final Ref _ref;

  /// The text and context these settings belong to.
  final ReaderSettingsScope scope;

  bool get isLibrary => scope.context == ReaderLayoutContext.library;

  /// This visit's defaults (outside the library), applied where the context
  /// store has no pick. Never persisted: the next text in this context gets
  /// its own.
  ReaderInitialLayout? _seed;
  String? _language;

  /// True once the seeded translation actually has a version to show, so the
  /// switch never reads "on" with nothing underneath.
  bool _seededTranslationOn = false;

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

  ReaderContextLayoutNotifier get _store =>
      _ref.read(readerContextLayoutProvider(scope.context).notifier);

  ReaderContextLayoutPrefs get _prefs =>
      _ref.read(readerContextLayoutProvider(scope.context));

  /// Outside the library: the context store's picks over this visit's seed.
  void _recompute() {
    if (!mounted || isLibrary) return;
    final prefs = _prefs;
    final language = _language;
    final String? script =
        language != null && prefs.hasScriptFor(language)
            ? prefs.scriptFor(language)
            : _seed?.originalScriptId;
    final next = state.copyWith(
      secondaryEnabled: prefs.translationOn ?? _seededTranslationOn,
      originalVisible: prefs.originalVisible ?? _seed?.originalVisible ?? true,
      originalScriptId: script,
      clearOriginalScriptId: script == null,
    );
    if (next != state) state = next;
  }

  /// Applies this visit's defaults for a text in [language] (outside the
  /// library). Stored picks for this context win over the seed; the seed's
  /// translation only switches on through [seedTranslationOn].
  void seed(ReaderInitialLayout layout, {required String language}) {
    if (isLibrary) return;
    _seed = layout;
    _language = TransliterationService.normalizeLanguage(language);
    _recompute();
  }

  /// Turns the seeded translation on once a version for it has been found.
  void seedTranslationOn() {
    if (isLibrary || _seededTranslationOn) return;
    _seededTranslationOn = true;
    _recompute();
  }

  void setSecondaryEnabled(bool enabled) {
    if (state.secondaryEnabled == enabled) return;
    _secondaryEnabledGeneration++;
    if (isLibrary) {
      _ref.read(readerSecondaryEnabledProvider.notifier).setEnabled(enabled);
    } else {
      _store.setTranslationOn(enabled);
    }
    // Turning the translation off must not leave nothing on screen.
    if (!enabled) setOriginalVisible(true);
  }

  /// Show or hide the original text. One layer is always on: hiding the
  /// original switches the translation on (the sheet then picks a version),
  /// and the widgets keep showing the original until that version exists.
  void setOriginalVisible(bool visible) {
    if (state.originalVisible == visible) return;
    if (isLibrary) {
      _ref.read(readerOriginalVisibleProvider.notifier).setVisible(visible);
    } else {
      _store.setOriginalVisible(visible);
    }
    if (!visible && !state.secondaryEnabled) setSecondaryEnabled(true);
  }

  /// Picks the script the original of a [language] text is shown in; null is
  /// "as written". App-wide in the library, per context elsewhere.
  void setOriginalScript(String language, String? scriptId) {
    if (isLibrary) {
      _ref
          .read(readerScriptPreferenceProvider.notifier)
          .setScript(language, scriptId);
      return;
    }
    _store.setScript(language, scriptId);
  }

  /// Remembers the translation language the person picked, for the next
  /// text opened in this context. The library does not remember one.
  void rememberTranslationLanguage(String languageCode) {
    if (isLibrary) return;
    _store.setTranslationLanguage(languageCode);
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

final readerDualSettingsProvider = StateNotifierProvider.autoDispose.family<
  ReaderDualSettingsNotifier,
  ReaderDualLayoutSettings,
  ReaderSettingsScope
>((ref, scope) => ReaderDualSettingsNotifier(ref: ref, scope: scope));

/// Transient (not persisted): true while the secondary slot's version is being
/// auto-resolved after a language change. Drives the version row's loading
/// state and blocks language edits until resolution completes.
final readerSecondaryResolvingProvider = StateProvider.autoDispose
    .family<bool, ReaderSettingsScope>((ref, _) => false);

/// One language's script pick as seen from one reader (text + context).
class ReaderScriptScope {
  ReaderScriptScope({required this.scope, required String language})
    : language = TransliterationService.normalizeLanguage(language);

  final ReaderSettingsScope scope;

  /// Normalised language code.
  final String language;

  @override
  bool operator ==(Object other) =>
      other is ReaderScriptScope &&
      other.scope == scope &&
      other.language == language;

  @override
  int get hashCode => Object.hash(scope, language);
}

/// The script the original is shown in for [ReaderScriptScope.language] in
/// the reader [ReaderScriptScope.scope]; null shows the text as written.
///
/// The library reads the app-wide script map straight away, so a stored pick
/// applies from the first frame; every other context reads the settings the
/// context store and this visit's seed produce.
final readerOriginalScriptProvider = Provider.autoDispose
    .family<String?, ReaderScriptScope>((ref, scriptScope) {
      if (scriptScope.scope.context == ReaderLayoutContext.library) {
        return ref.watch(readerScriptForLanguageProvider(scriptScope.language));
      }
      return ref.watch(
        readerDualSettingsProvider(
          scriptScope.scope,
        ).select((settings) => settings.originalScriptId),
      );
    });
