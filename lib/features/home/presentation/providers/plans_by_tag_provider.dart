import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plans_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stored page first (the repository reads Hive), then each refresh written to it.
final plansByTagProvider =
    StreamProvider.family<Either<Failure, List<Plan>>, String>((ref, tag) async* {
      final languageCode = ref.watch(contentLanguageProvider);
      final getPlansUseCase = ref.watch(getPlansUseCaseProvider);
      final local = ref.watch(plansLocalDatasourceProvider);

      yield await getPlansUseCase(
        GetPlansParams(language: languageCode, tag: tag),
      );

      final key = local.plansKey(language: languageCode, tag: tag);
      await for (final _ in local.watchKey(key)) {
        final cached = local.readPlans(language: languageCode, tag: tag);
        if (cached != null) {
          yield Right(cached.map((plan) => plan.toEntity()).toList());
        }
      }
    });
