import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary_response.dart';
import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation_response.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

final segmentInfoFutureProvider = FutureProvider.family((
  ref,
  String segmentId,
) {
  final useCase = ref.watch(getSegmentInfoUseCaseProvider);
  return useCase(segmentId);
});

/// Stored panel is the first state, refreshed in the background; a failed
/// refresh with nothing stored surfaces as the error the panels already handle.
ScreenCacheSource<T> _panel<T extends Object>(
  Ref ref, {
  required String screen,
  required String segmentId,
  required Future<Object> Function() fetchJson,
  required T Function(Map<String, dynamic> json) fromJson,
}) {
  return ScreenCacheSource<T>(
    store: ref.watch(screenCacheStoreProvider),
    key: ScreenCacheKey.public(screen, language: 'all', params: [segmentId]),
    fetchJson: fetchJson,
    fromJson: (json) => fromJson(json as Map<String, dynamic>),
    failureMessage: 'Failed to load segment',
  );
}

T _orThrow<T extends Object>(Either<Failure, T> result) =>
    result.fold((failure) => throw Exception(failure.message), (v) => v);

typedef _PanelNotifier<T extends Object> =
    ScreenCacheFamilyNotifier<T, T, String>;

final segmentCommentaryFutureProvider = AsyncNotifierProvider.family<
  _PanelNotifier<SegmentCommentaryResponse>,
  SegmentCommentaryResponse,
  String
>(() {
  return _PanelNotifier((ref, segmentId, bind) {
    final useCase = ref.watch(getSegmentCommentariesUseCaseProvider);
    return bind.source(
      _panel(
        ref,
        screen: 'segment_commentaries',
        segmentId: segmentId,
        fetchJson: () async => (await useCase(segmentId)).toJson(),
        fromJson: SegmentCommentaryResponse.fromJson,
      ),
      select: _orThrow,
    );
  });
});

final segmentTranslationsFutureProvider = AsyncNotifierProvider.family<
  _PanelNotifier<SegmentTranslationResponse>,
  SegmentTranslationResponse,
  String
>(() {
  return _PanelNotifier((ref, segmentId, bind) {
    final useCase = ref.watch(getSegmentTranslationsUseCaseProvider);
    return bind.source(
      _panel(
        ref,
        screen: 'segment_translations',
        segmentId: segmentId,
        fetchJson: () async => (await useCase(segmentId)).toJson(),
        fromJson: SegmentTranslationResponse.fromJson,
      ),
      select: _orThrow,
    );
  });
});

final segmentRootTextsFutureProvider = AsyncNotifierProvider.family<
  _PanelNotifier<SegmentTranslationResponse>,
  SegmentTranslationResponse,
  String
>(() {
  return _PanelNotifier((ref, segmentId, bind) {
    final useCase = ref.watch(getSegmentRootTextsUseCaseProvider);
    return bind.source(
      _panel(
        ref,
        screen: 'segment_root_texts',
        segmentId: segmentId,
        fetchJson: () async => (await useCase(segmentId)).toJson(),
        fromJson: SegmentTranslationResponse.fromJson,
      ),
      select: _orThrow,
    );
  });
});
