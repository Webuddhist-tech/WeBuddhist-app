import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/more/domain/entities/series_day_completed.dart';
import 'package:flutter_pecha/features/more/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

// Stored page first, refreshed in the background.
final seriesDayCompletedProvider = StreamProvider.autoDispose<
    Either<Failure, SeriesDayCompletedPage>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
    return Stream.value(const Left(AuthenticationFailure('Not authenticated')));
  }

  final language = ref.watch(contentLanguageProvider);
  return ref
      .watch(userStatsRepositoryProvider)
      .watchSeriesDayCompleted(language: language);
});
