import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_context_layout_prefs.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The picks a person made inside one [ReaderLayoutContext], persisted as
/// JSON under `reader_layout_<context>`. Only what they changed is stored;
/// the library context never uses this (its picks are the app-wide reader
/// settings).
class ReaderContextLayoutNotifier extends StateNotifier<ReaderContextLayoutPrefs> {
  ReaderContextLayoutNotifier({
    required LocalStorageService localStorage,
    required this.context,
  }) : _storage = localStorage,
       _key = StorageKeys.readerLayoutPrefs(context.name),
       super(ReaderContextLayoutPrefs.empty) {
    _loadFuture = _load();
  }

  final ReaderLayoutContext context;
  final LocalStorageService _storage;
  final String _key;
  late final Future<void> _loadFuture;
  bool _loaded = false;

  /// Edits made before the stored value arrived, replayed over it so the
  /// load neither reverts them nor drops what was stored.
  final List<ReaderContextLayoutPrefs Function(ReaderContextLayoutPrefs)>
  _pending = [];

  /// Resolves once the persisted value has been read (or determined absent).
  Future<void> get loaded => _loadFuture;

  Future<void> _load() async {
    final stored = await _storage.get<String>(_key);
    _loaded = true;
    if (!mounted) return;
    var prefs =
        stored == null
            ? ReaderContextLayoutPrefs.empty
            : ReaderContextLayoutPrefs.decode(stored);
    if (_pending.isEmpty) {
      if (stored != null) state = prefs;
      return;
    }
    for (final edit in _pending) {
      prefs = edit(prefs);
    }
    _pending.clear();
    state = prefs;
    _persist(prefs);
  }

  void setOriginalVisible(bool visible) =>
      _update((prefs) => prefs.copyWith(originalVisible: visible));

  void setTranslationOn(bool on) =>
      _update((prefs) => prefs.copyWith(translationOn: on));

  void setTranslationLanguage(String code) => _update(
    (prefs) => prefs.copyWith(
      translationLanguage: TransliterationService.normalizeLanguage(code),
    ),
  );

  /// Records [versionId] as the translation edition picked for [textId].
  void setTranslationVersion(String textId, String versionId) => _update(
    (prefs) => prefs.withTranslationVersion(textId, versionId),
  );

  /// Records [scriptId] for [language]; null is a deliberate "as written".
  void setScript(String language, String? scriptId) => _update(
    (prefs) => prefs.withScript(
      TransliterationService.normalizeLanguage(language),
      scriptId,
    ),
  );

  void _update(
    ReaderContextLayoutPrefs Function(ReaderContextLayoutPrefs) edit,
  ) {
    final next = edit(state);
    if (next == state) return;
    if (!_loaded) _pending.add(edit);
    state = next;
    if (_loaded) _persist(next);
  }

  void _persist(ReaderContextLayoutPrefs prefs) {
    _storage.set<String>(_key, prefs.encode());
  }
}

final readerContextLayoutProvider = StateNotifierProvider.family<
  ReaderContextLayoutNotifier,
  ReaderContextLayoutPrefs,
  ReaderLayoutContext
>((ref, context) {
  return ReaderContextLayoutNotifier(
    localStorage: ref.read(localStorageServiceProvider),
    context: context,
  );
});
