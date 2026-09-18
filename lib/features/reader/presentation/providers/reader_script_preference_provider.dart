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

  /// Resolves once the persisted value has been read (or determined absent).
  Future<void> get loaded => _loadFuture;

  Future<void> _load() async {
    final stored = await _storage.get<String>(
      StorageKeys.readerScriptPreference,
    );
    if (stored == null || !mounted) return;
    state = decode(stored);
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
    final next = Map<String, String>.from(state);
    if (scriptId == null) {
      if (next.remove(key) == null) return;
    } else {
      if (next[key] == scriptId) return;
      next[key] = scriptId;
    }
    state = next;
    _storage.set<String>(StorageKeys.readerScriptPreference, jsonEncode(next));
  }
}

final readerScriptPreferenceProvider = StateNotifierProvider<
    ReaderScriptPreferenceNotifier, Map<String, String>>((ref) {
  return ReaderScriptPreferenceNotifier(
    localStorage: ref.read(localStorageServiceProvider),
  );
});

/// The script picked for one language, so segment widgets rebuild only when
/// their own language's pick changes.
final readerScriptForLanguageProvider = Provider.family<String?, String>((
  ref,
  languageCode,
) {
  final key = TransliterationService.normalizeLanguage(languageCode);
  return ref.watch(readerScriptPreferenceProvider.select((prefs) => prefs[key]));
});
