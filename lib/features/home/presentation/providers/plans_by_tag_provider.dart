import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_local_datasource.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plans_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

// Each refresh written to Hive re-emits here.
Stream<Either<Failure, List<Plan>>> _updates(
  GetPlansUseCase getPlans,
  PlansLocalDatasource local, {
  required String language,
  required String tag,
}) async* {
  yield await getPlans(GetPlansParams(language: language, tag: tag));

  final key = local.plansKey(language: language, tag: tag);
  await for (final _ in local.watchKey(key)) {
    final cached = local.readPlans(language: language, tag: tag);
    if (cached != null) {
      yield Right(cached.map((plan) => plan.toEntity()).toList());
    }
  }
}

// Stored page (from Hive) is the first state, then each refresh.
final plansByTagProvider = AsyncNotifierProvider.family<
  ScreenCacheFamilyNotifier<List<Plan>, Either<Failure, List<Plan>>, String>,
  Either<Failure, List<Plan>>,
  String
>(() {
  return ScreenCacheFamilyNotifier((ref, tag, bind) {
    final languageCode = ref.watch(contentLanguageProvider);
    final getPlansUseCase = ref.watch(getPlansUseCaseProvider);
    final local = ref.watch(plansLocalDatasourceProvider);
    final stored = local
        .readPlans(language: languageCode, tag: tag)
        ?.map((plan) => plan.toEntity())
        .toList();
    return bind.stream(
      stored == null ? null : Right(stored),
      _updates(getPlansUseCase, local, language: languageCode, tag: tag),
    );
  });
});
