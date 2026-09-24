import 'package:flutter_pecha/features/texts/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final segmentInfoFutureProvider = FutureProvider.family((
  ref,
  String segmentId,
) {
  final useCase = ref.watch(getSegmentInfoUseCaseProvider);
  return useCase(segmentId);
});

final segmentCommentaryFutureProvider = FutureProvider.family((
  ref,
  String segmentId,
) {
  final useCase = ref.watch(getSegmentCommentariesUseCaseProvider);
  return useCase(segmentId);
});

final segmentTranslationsFutureProvider = FutureProvider.family((
  ref,
  String segmentId,
) {
  final useCase = ref.watch(getSegmentTranslationsUseCaseProvider);
  return useCase(segmentId);
});

final segmentRootTextsFutureProvider = FutureProvider.family((
  ref,
  String segmentId,
) {
  final useCase = ref.watch(getSegmentRootTextsUseCaseProvider);
  return useCase(segmentId);
});
