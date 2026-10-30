import 'dart:async';

import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_fonts.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_script.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// The reader fonts picked for the original and the translation, kept in
/// local storage. Nothing picks one yet; the font pills come with the
/// reader's Display sheet.
class ReaderFontsNotifier extends StateNotifier<ReaderFontChoices> {
  ReaderFontsNotifier({required LocalStorageService localStorageService})
    : _storage = localStorageService,
      super(const ReaderFontChoices()) {
    _ready = _load();
  }

  final LocalStorageService _storage;
  late final Future<void> _ready;

  /// Completes once the stored picks are in [state].
  Future<void> get ready => _ready;

  Future<void> _load() async {
    final json = await _storage.get<String>(StorageKeys.readerFonts);
    if (!mounted) return;
    state = ReaderFontChoices.fromJson(json);
  }

  /// Sets [line]'s font for text in [script]. Picking the default clears
  /// the pick.
  Future<void> choose(
    ReaderFontLine line,
    ReaderScript script,
    ReaderFont font,
  ) async {
    await _ready;
    state = state.pick(line, script, font);
    await _storage.set<String>(StorageKeys.readerFonts, state.toJson());
  }
}

final readerFontsProvider =
    StateNotifierProvider<ReaderFontsNotifier, ReaderFontChoices>(
      (ref) => ReaderFontsNotifier(
        localStorageService: ref.read(localStorageServiceProvider),
      ),
    );

/// How long a page waits for a picked font before showing in a fallback.
const Duration readerFontPreloadTimeout = Duration(seconds: 2);

/// Loads the downloaded fonts with these ids (comma-separated, as
/// [readerFontPreloadKey] builds them). Completes once they are loaded, after
/// [readerFontPreloadTimeout] at the latest, and never fails: a font that
/// does not arrive leaves its lines in the fallback.
final readerFontPreloadProvider = FutureProvider.autoDispose
    .family<void, String>((ref, key) async {
      final ids = key.split(',').toSet();
      final fonts = [
        for (final script in ReaderScript.values)
          for (final font in ReaderFonts.forScript(script))
            if (font.isDownloaded && ids.contains(font.id)) font,
      ];
      for (final font in {...fonts}) {
        // The page's lines name the regular file and let weight and style
        // follow it; asking for its family starts the download.
        font.family();
      }
      try {
        await GoogleFonts.pendingFonts().timeout(readerFontPreloadTimeout);
      } catch (_) {
        // Offline or slow: the page shows in the fallback until it lands.
      }
    });

/// The [readerFontPreloadProvider] key for [fonts].
String readerFontPreloadKey(Iterable<ReaderFont> fonts) =>
    (fonts.map((font) => font.id).toSet().toList()..sort()).join(',');
