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

/// Whether picks made under the app language [stamped] must go now that the
/// app reads [current]. Nothing recorded yet means nothing to drop.
bool readerLayoutsNeedReset({
  required String? stamped,
  required String current,
}) =>
    stamped != null &&
    TransliterationService.normalizeLanguage(stamped) !=
        TransliterationService.normalizeLanguage(current);

/// Ties the event, chant and plan picks to the app language they were made
/// under: when that language changes they are dropped, so the reader starts
/// from the new language's defaults, switching back included. Library reading
/// keeps its app-wide settings.
///
/// The app syncs once at startup as well as on each change. Picks stored
/// before the stamp existed are taken as made under the language the app
/// starts in, so a change made before any reader is opened still drops them.
class ReaderLayoutLanguageGuard {
  ReaderLayoutLanguageGuard({
    required LocalStorageService localStorage,
    required void Function() onCleared,
  }) : _storage = localStorage,
       _onCleared = onCleared;

  final LocalStorageService _storage;

  /// Restarts the live context stores once their stored picks are gone.
  final void Function() _onCleared;

  /// The sync in flight, if any: the next one queues behind it.
  Future<void> _last = Future.value();

  /// Drops the context picks when [language] is not the one they were made
  /// under, then records [language]. Returns whether anything was dropped.
  ///
  /// Syncs run one at a time, in the order they were asked for. Two quick
  /// language changes would otherwise both read the same old stamp, and
  /// whichever wrote last would set it — the earlier language, possibly —
  /// so the next reader open would drop picks made under the current one.
  Future<bool> sync(String language) {
    final run = _last.then((_) => _sync(language));
    _last = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<bool> _sync(String language) async {
    final current = TransliterationService.normalizeLanguage(language);
    if (current.isEmpty) return false;
    final stamped = await _storage.get<String>(StorageKeys.readerLayoutLanguage);
    final reset = readerLayoutsNeedReset(stamped: stamped, current: current);
    if (reset) {
      for (final context in ReaderLayoutContext.values) {
        if (context == ReaderLayoutContext.library) continue;
        await _storage.remove(StorageKeys.readerLayoutPrefs(context.name));
      }
      _onCleared();
    }
    if (stamped != current) {
      await _storage.set<String>(StorageKeys.readerLayoutLanguage, current);
    }
    return reset;
  }
}

final readerLayoutLanguageGuardProvider = Provider<ReaderLayoutLanguageGuard>((
  ref,
) {
  return ReaderLayoutLanguageGuard(
    localStorage: ref.read(localStorageServiceProvider),
    onCleared: () => ref.invalidate(readerContextLayoutProvider),
  );
});
