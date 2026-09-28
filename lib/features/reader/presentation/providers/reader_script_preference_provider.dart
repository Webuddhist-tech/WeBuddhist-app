import 'dart:convert';

import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transliterationServiceProvider = Provider<TransliterationService>(
  (ref) => TransliterationService.standard(),
);

/// Which script the reader shows each source language in, keyed by language
/// code (e.g. `{'pi': 'si'}`). A language with no entry is shown as written.
///
/// Persisted globally, not per text: a reader who wants Pali in Sinhala wants
/// it for every Pali text, and script ids (unlike version ids) are valid
/// across texts.
class ReaderScriptPreferenceNotifier extends StateNotifier<Map<String, String>> {
  ReaderScriptPreferenceNotifier({required LocalStorageService localStorage})
      : _storage = localStorage,
        super(const {}) {
    _loadFuture = _load();
  }

  final LocalStorageService _storage;
  late final Future<void> _loadFuture;
  bool _loaded = false;

  /// Picks made before the stored ones arrived (null clears). Layered over
  /// the stored map once it loads, so the load neither reverts them nor lets
  /// an early write drop the other languages' picks.
  final Map<String, String?> _pendingPicks = {};

  /// Resolves once the persisted value has been read (or determined absent).
  Future<void> get loaded => _loadFuture;

  Future<void> _load() async {
    final stored = await _storage.get<String>(
      StorageKeys.readerScriptPreference,
    );
    _loaded = true;
    if (!mounted) return;
    if (_pendingPicks.isEmpty) {
      if (stored != null) state = decode(stored);
      return;
    }
    final merged = <String, String>{if (stored != null) ...decode(stored)};
    for (final MapEntry(:key, :value) in _pendingPicks.entries) {
      if (value == null) {
        merged.remove(key);
      } else {
        merged[key] = value;
      }
    }
    _pendingPicks.clear();
    state = merged;
    _persist(merged);
  }

  static Map<String, String> decode(String source) {
    try {
      final map = jsonDecode(source) as Map<String, dynamic>;
      return {
        for (final entry in map.entries)
          if (entry.value is String) entry.key: entry.value as String,
      };
    } catch (_) {
      return const {};
    }
  }

  String? scriptFor(String languageCode) =>
      state[TransliterationService.normalizeLanguage(languageCode)];

  /// Picks [scriptId] for [languageCode]; null shows the text as written.
  void setScript(String languageCode, String? scriptId) {
    final key = TransliterationService.normalizeLanguage(languageCode);
    // Recorded even when it looks like a no-op: the state is still empty.
    if (!_loaded) _pendingPicks[key] = scriptId;
    final next = Map<String, String>.from(state);
    if (scriptId == null) {
      if (next.remove(key) == null) return;
    } else {
      if (next[key] == scriptId) return;
      next[key] = scriptId;
    }
    state = next;
    if (_loaded) _persist(next);
  }

  void _persist(Map<String, String> picks) {
    _storage.set<String>(StorageKeys.readerScriptPreference, jsonEncode(picks));
  }
}

final readerScriptPreferenceProvider = StateNotifierProvider<
    ReaderScriptPreferenceNotifier, Map<String, String>>((ref) {
  return ReaderScriptPreferenceNotifier(
    localStorage: ref.read(localStorageServiceProvider),
  );
});

/// The app-wide script pick for one language (what the library shows), so
/// segment widgets rebuild only when their own language's pick changes.
/// Readers outside the library go through `readerOriginalScriptProvider`.
final readerScriptForLanguageProvider = Provider.family<String?, String>((
  ref,
  languageCode,
) {
  final key = TransliterationService.normalizeLanguage(languageCode);
  return ref.watch(readerScriptPreferenceProvider.select((prefs) => prefs[key]));
});
