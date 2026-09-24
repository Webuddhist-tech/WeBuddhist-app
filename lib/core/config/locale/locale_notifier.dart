/// UI locale vs content language.
///
/// The app keeps two independent language axes. Use [localeProvider] for
/// chrome strings (`context.l10n`, Material, Tolgee). Use
/// [contentLanguageProvider] as the `language` query param on backend content
/// APIs (traditions, series, texts, plans, …). They diverge when the user
/// picks a content language the app has no ARB for — UI falls back to English
/// while content stays on the selected code.
///
/// See this folder's `README.md` for the full split, storage keys, and
/// which provider to watch.
library;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/content_language_analytics.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/localization/data/languages_remote_datasource.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/l10n/l10n.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';

/// Owns the app's **UI locale** — the language its own strings render in.
///
/// This is a bounded axis: the UI can only display a language the app ships an
/// ARB translation for (see [L10n.all]). It is deliberately separate from the
/// content language sent to the backend, which is open-ended and owned by
/// [ContentLanguageNotifier]. Selecting a content language the app cannot
/// localize into keeps the UI in English while content stays in that language.
class LocaleNotifier extends StateNotifier<Locale> {
  final LocalStorageService _localStorageService;
  bool _isInitialized = false;
  // An explicit selection always wins over an in-flight startup read.
  bool _userSelected = false;
  // Concurrent ensureInitialized() callers share this so they await the same
  // storage read instead of returning early once init has merely started.
  Future<void>? _initFuture;

  LocaleNotifier({required LocalStorageService localStorageService})
    : _localStorageService = localStorageService,
      super(const Locale(AppConfig.defaultLanguage)) {
    _initFuture = _initializeLocale();
  }

  /// Initialize locale from storage
  /// This method ensures the locale is loaded before the notifier is used
  Future<void> _initializeLocale() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final locale = await _localStorageService.get<String>(
        StorageKeys.preferredLanguage,
      );
      if (_userSelected) return;
      if (locale != null) {
        state = Locale(locale);
      }
    } catch (e) {
      // If loading fails, keep the default locale
      // Error is silently handled to prevent app crash
    }
  }

  /// Ensure locale is loaded before accessing state.
  /// Concurrent callers await the same in-flight initialization Future.
  Future<void> ensureInitialized() async =>
      _initFuture ??= _initializeLocale();

  Future<void> setLocale(Locale locale) async {
    final isSupported = L10n.all.any(
      (l) => l.languageCode == locale.languageCode,
    );
    if (!isSupported) {
      throw Exception("Locale ${locale.languageCode} is not supported");
    }

    _userSelected = true;
    state = locale;
    await _localStorageService.set(
      StorageKeys.preferredLanguage,
      locale.languageCode,
    );
  }

  /// Applies the UI locale for a chosen content-language [code].
  ///
  /// The UI localizes into [code] when the app bundles an ARB translation for
  /// it; otherwise it falls back to English. This is the "system localization"
  /// half of the system-vs-content split — it never throws for unknown codes.
  Future<void> applyUiLocaleForContent(String code) async {
    final uiCode = AppConfig.resolveContentLanguage(code);
    final locale = Locale(uiCode);
    _userSelected = true;
    state = locale;
    await _localStorageService.set(
      StorageKeys.preferredLanguage,
      locale.languageCode,
    );
  }

  /// Maps onboarding language preference to app locale
  ///
  /// Onboarding uses strings like 'tibetan', 'english', 'chinese'
  /// This maps them to Flutter locale codes: 'bo', 'en', 'zh'
  Future<void> setLocaleFromOnboardingPreference(
    String? languagePreference,
  ) async {
    if (languagePreference == null) return;

    Locale? locale;
    switch (languagePreference.toLowerCase()) {
      case 'tibetan':
        locale = const Locale(AppConfig.tibetanLanguageCode);
        break;
      case 'english':
        locale = const Locale(AppConfig.englishLanguageCode);
        break;
      case 'chinese':
        locale = const Locale(AppConfig.chineseLanguageCode);
        break;
      default:
        // Unknown preference, don't change locale
        return;
    }

    // Only set if the locale is supported
    if (L10n.all.any((l) => l.languageCode == locale!.languageCode)) {
      await setLocale(locale);
    }
  }
}

/// Owns the **content language** sent to backend APIs.
///
/// Unlike the UI locale this is open-ended: it may be any code the backend
/// serves (see `availableContentLanguagesProvider`), including languages the
/// app has no UI translation for. The raw code is stored and sent verbatim as
/// the `language` query parameter across content endpoints.
class ContentLanguageNotifier extends StateNotifier<String> {
  final LocalStorageService _localStorageService;
  final ContentLanguageAnalytics? _analytics;
  bool _isInitialized = false;
  // An explicit user selection always wins over an in-flight startup read, so
  // the async initializer can never clobber a language the user just chose.
  bool _userSelected = false;
  Future<void>? _initFuture;

  ContentLanguageNotifier({
    required LocalStorageService localStorageService,
    ContentLanguageAnalytics? analytics,
  }) : _localStorageService = localStorageService,
       _analytics = analytics,
       super(AppConfig.defaultLanguage) {
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final stored = await _localStorageService.get<String>(
        StorageKeys.contentLanguage,
      );
      if (_userSelected) return;
      if (stored != null && stored.isNotEmpty) {
        state = stored;
        return;
      }
      // Migration: existing users only have the UI locale persisted. Seed the
      // content language from it so behaviour is unchanged on upgrade.
      final legacyLocale = await _localStorageService.get<String>(
        StorageKeys.preferredLanguage,
      );
      if (_userSelected) return;
      if (legacyLocale != null && legacyLocale.isNotEmpty) {
        state = legacyLocale;
      }
    } catch (_) {
      // Keep the default on failure to avoid crashing at startup.
    }
  }

  Future<void> ensureInitialized() async => _initFuture ??= _initialize();

  /// Persists the raw [code] sent to content APIs. Accepts any non-empty code.
  Future<void> setContentLanguage(
    String code, {
    ContentLanguageSource? source,
  }) async {
    if (code.isEmpty) return;
    final previous = state;
    _userSelected = true;
    state = code;
    await _localStorageService.set(StorageKeys.contentLanguage, code);
    if (code == previous) return;
    _analytics?.contentLanguageChanged(
      from: previous,
      to: code,
      source: source,
    );
  }

  /// Enforces the server-side kill switch against [enabledCodes] — an
  /// authoritative, backend-returned list of enabled language codes.
  ///
  /// Returns the code it switched to, or `null` if the current selection was
  /// left unchanged (so the caller can keep the UI locale paired). If the
  /// stored code is not among [enabledCodes], switches to the app default when
  /// enabled, else the first enabled code. An **empty** list is a valid
  /// authoritative answer meaning "nothing enabled" and resolves to the app
  /// default.
  ///
  /// Must only be called for a *successful* backend response. Offline / error
  /// handling belongs at the call site (do not call this on the fallback path),
  /// so a valid selection is never clobbered when the backend is unreachable.
  Future<String?> reconcileToAvailable(List<String> enabledCodes) async {
    await ensureInitialized();
    if (enabledCodes.contains(state)) return null;
    final String fallback;
    if (enabledCodes.contains(AppConfig.defaultLanguage)) {
      fallback = AppConfig.defaultLanguage;
    } else if (enabledCodes.isNotEmpty) {
      fallback = enabledCodes.first;
    } else {
      // Degenerate: the backend enabled nothing. Fall back to the app default.
      fallback = AppConfig.defaultLanguage;
    }
    await setContentLanguage(fallback, source: ContentLanguageSource.reconcile);
    return fallback;
  }
}

/// Provider for managing the app's current UI locale.
/// The locale is loaded asynchronously from storage on first access
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final notifier = LocaleNotifier(
    localStorageService: ref.read(localStorageServiceProvider),
  );
  // Ensure locale is initialized when provider is first created
  // This happens asynchronously but starts immediately
  notifier.ensureInitialized();
  return notifier;
});

/// Language code sent to backend APIs for translatable content.
///
/// Stored independently of the UI locale so a user can read content in a
/// language the app has not been translated into. Falls back to English only
/// when nothing has been selected/persisted.
final contentLanguageProvider =
    StateNotifierProvider<ContentLanguageNotifier, String>((ref) {
      final notifier = ContentLanguageNotifier(
        localStorageService: ref.read(localStorageServiceProvider),
        analytics: ref.read(contentLanguageAnalyticsProvider),
      );
      notifier.ensureInitialized();
      return notifier;
    });

/// Applies a single language choice across both axes: the content code sent to
/// the backend (verbatim) and the UI locale (English when no translation
/// exists). This is the "one choice, split under the hood" entry point used by
/// the language picker and onboarding.
///
/// When the user is authenticated (not a guest), awaits
/// `PUT /users/me/language` first. Local prefs update only on success; on
/// failure the previous language is kept. Guests update locally only.
Future<void> selectAppLanguage(
  WidgetRef ref,
  String code, {
  ContentLanguageSource? source,
}) async {
  final auth = ref.read(authProvider);
  if (auth.isLoggedIn && !auth.isGuest) {
    try {
      // Constructed here (not via languagesRemoteDatasourceProvider) to avoid
      // a locale_notifier ↔ languages_providers import cycle.
      await LanguagesRemoteDatasource(
        dio: ref.read(dioProvider),
      ).updateLanguage(code);
    } catch (e, st) {
      AppLogger('selectAppLanguage').warning(
        'Failed to sync language to backend; keeping previous language',
        e,
        st,
      );
      return;
    }
  }

  await ref
      .read(contentLanguageProvider.notifier)
      .setContentLanguage(code, source: source);
  await ref.read(localeProvider.notifier).applyUiLocaleForContent(code);
}
