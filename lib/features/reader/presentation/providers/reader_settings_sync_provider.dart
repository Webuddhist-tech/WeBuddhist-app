import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart' show dioProvider;
import 'package:flutter_pecha/core/network/connectivity_service.dart'
    show connectivityStreamProvider;
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_recitations_paginated_provider.dart';
import 'package:flutter_pecha/features/reader/application/reader_settings_sync.dart';
import 'package:flutter_pecha/features/reader/data/datasource/user_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_context_layout_prefs.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/domain/sync/reader_settings_sync_plan.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_background_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_context_layout_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_fonts_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_text_size_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_verse_numbers_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_appearance_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [ReaderSyncLocalStore] over the app's settings providers.
class ProviderReaderSyncStore implements ReaderSyncLocalStore {
  ProviderReaderSyncStore(this._ref);

  final Ref _ref;

  ReaderContextLayoutNotifier get _chant =>
      _ref.read(readerContextLayoutProvider(ReaderLayoutContext.chant).notifier);

  @override
  Future<ReaderSyncBlocks> read() async {
    await Future.wait([
      _ref.read(readerBackgroundProvider.notifier).ready,
      _ref.read(readerTextSizeProvider.notifier).ready,
      _ref.read(readerFontsProvider.notifier).ready,
      _ref.read(readerVerseNumbersProvider.notifier).ready,
      _chant.loaded,
    ]);
    final appearance = ReaderAppearancePrefs(
      background: _ref.read(readerBackgroundProvider),
      textSize: _ref.read(readerTextSizeProvider),
      fonts: _ref.read(readerFontsProvider),
      verseNumbers: _ref.read(readerVerseNumbersProvider),
    );
    // The stored pick rather than the provider's state, which falls back to
    // the content language when nothing was picked.
    final listLanguage = await _ref
        .read(localStorageServiceProvider)
        .get<String>(StorageKeys.chantListLanguage);
    return ReaderSyncBlocks(
      appearance: appearance.toWire(),
      chant:
          _ref
              .read(readerContextLayoutProvider(ReaderLayoutContext.chant))
              .toWire(),
      listLanguage:
          listLanguage != null && listLanguage.isNotEmpty ? listLanguage : null,
    );
  }

  @override
  Future<String> contentLanguage() async {
    await _ref.read(contentLanguageProvider.notifier).ensureInitialized();
    return _ref.read(contentLanguageProvider);
  }

  @override
  Future<void> applyAppearance(Map<String, dynamic> appearance) async {
    final prefs = ReaderAppearancePrefs.fromWire(appearance);
    await _ref.read(readerBackgroundProvider.notifier).select(prefs.background);
    final sizes = _ref.read(readerTextSizeProvider.notifier);
    await sizes.setOriginalStep(prefs.textSize.originalStep);
    await sizes.setTranslationStep(prefs.textSize.translationStep);
    await sizes.setSpacing(prefs.textSize.spacing);
    await _ref.read(readerFontsProvider.notifier).replaceAll(prefs.fonts);
    await _ref
        .read(readerVerseNumbersProvider.notifier)
        .setShown(prefs.verseNumbers);
  }

  @override
  Future<void> applyChant(Map<String, dynamic> chant) async {
    await _chant.loaded;
    _chant.replaceAll(ReaderContextLayoutPrefs.fromWire(chant));
  }

  @override
  Future<void> applyListLanguage(String? language) => _ref
      .read(practiceRecitationsLanguageProvider.notifier)
      .applySynced(language);
}

/// Runs the reader settings sync for the app's lifetime: follows sign-in,
/// setting changes and the connection. Watched from `MyApp`.
final readerSettingsSyncProvider = Provider<ReaderSettingsSync>((ref) {
  final sync = ReaderSettingsSync(
    storage: ref.read(localStorageServiceProvider),
    remote: UserSettingsRemoteDatasource(dio: ref.read(dioProvider)),
    local: ProviderReaderSyncStore(ref),
  );
  ref.onDispose(sync.dispose);

  void changed() => sync.onLocalChanged();
  ref.listen(readerBackgroundProvider, (_, __) => changed());
  ref.listen(readerTextSizeProvider, (_, __) => changed());
  ref.listen(readerFontsProvider, (_, __) => changed());
  ref.listen(readerVerseNumbersProvider, (_, __) => changed());
  ref.listen(
    readerContextLayoutProvider(ReaderLayoutContext.chant),
    (_, __) => changed(),
  );
  ref.listen(practiceRecitationsLanguageProvider, (_, __) => changed());

  ref.listen<AsyncValue<bool>>(connectivityStreamProvider, (_, next) {
    if (next.valueOrNull == true) sync.onReconnected();
  });
  ref.listen<AuthState>(authProvider, (_, next) {
    sync.setAuthenticated(next.isLoggedIn && !next.isGuest);
  }, fireImmediately: true);

  return sync;
});
