import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/localization/data/languages_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Datasource for the backend content-language list.
final languagesRemoteDatasourceProvider = Provider<LanguagesRemoteDatasource>((
  ref,
) {
  return LanguagesRemoteDatasource(dio: ref.watch(dioProvider));
});

/// Stored list per endpoint; languages are not themselves localized.
ScreenCacheSource<List<AppLanguage>> _languagesSource(
  Ref ref, {
  required bool recitationOnly,
}) {
  final datasource = ref.watch(languagesRemoteDatasourceProvider);
  return ScreenCacheSource<List<AppLanguage>>(
    store: ref.watch(screenCacheStoreProvider),
    key: ScreenCacheKey.public(
      recitationOnly ? 'languages_recitation' : 'languages',
      language: 'all',
    ),
    fetchJson:
        () async =>
            (await datasource.fetchLanguages(recitationOnly: recitationOnly))
                .map((language) => language.toJson())
                .toList(),
    fromJson:
        (json) =>
            (json as List)
                .map((e) => AppLanguage.fromJson(e as Map<String, dynamic>))
                .toList(),
    failureMessage: 'Failed to load languages',
  );
}

/// Content languages the backend can serve, used to build the language picker.
///
/// The stored list shows first; the server answer then replaces it and runs the
/// kill-switch reconciliation. Falls back to [AppLanguage.bundledFallback] when
/// nothing is stored and the fetch fails, so the picker always has something to
/// show. When the backend returns an empty list, the bundled set is used too.
final availableContentLanguagesProvider = StreamProvider<List<AppLanguage>>((
  ref,
) async* {
  final source = _languagesSource(ref, recitationOnly: false);
  final cached = source.read();
  if (cached != null && cached.isNotEmpty) yield cached;

  final result = await source.refresh();
  final languages = result.getRight().toNullable();
  if (languages == null) {
    // Offline / parse error: keep the stored selection untouched and show the
    // bundled list. Reconciliation deliberately does not run on this path.
    if (cached == null || cached.isEmpty) yield AppLanguage.bundledFallback;
    return;
  }

  // An authoritative answer (an empty list included): enforce the server-side
  // kill switch before the empty list is ever swapped for the bundled fallback,
  // and keep the UI locale paired with the content language.
  try {
    final switched = await ref
        .read(contentLanguageProvider.notifier)
        .reconcileToAvailable(languages.map((l) => l.code).toList());
    if (switched != null) {
      await ref.read(localeProvider.notifier).applyUiLocaleForContent(switched);
    }
  } catch (_) {}

  yield languages.isNotEmpty ? languages : AppLanguage.bundledFallback;
});

/// Synchronous view of [availableContentLanguagesProvider] for UI that needs a
/// list immediately. Uses the fetched value when ready; otherwise
/// [AppLanguage.bundledFallback] (loading / no value yet).
final resolvedContentLanguagesProvider = Provider<List<AppLanguage>>((ref) {
  return ref.watch(availableContentLanguagesProvider).valueOrNull ??
      AppLanguage.bundledFallback;
});

final recitationContentLanguagesProvider = StreamProvider<List<AppLanguage>>((
  ref,
) async* {
  final source = _languagesSource(ref, recitationOnly: true);
  final cached = source.read();
  if (cached != null && cached.isNotEmpty) yield cached;

  final result = await source.refresh();
  final languages = result.getRight().toNullable();
  if (languages != null) {
    yield languages;
  } else if (cached == null || cached.isEmpty) {
    yield AppLanguage.bundledFallback;
  }
});
