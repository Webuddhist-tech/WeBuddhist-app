import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/recitations_repository.dart';
import '../../data/models/recitation_model.dart';
import 'recitations_datasource_provider.dart';

// Repository provider
final recitationsRepositoryProvider = Provider<RecitationsRepository>((ref) {
  return RecitationsRepository(
    recitationsRemoteDatasource: ref.watch(recitationsRemoteDatasourceProvider),
  );
});

// Get all recitations provider
final recitationsFutureProvider = FutureProvider<Either<Failure, List<RecitationModel>>>((ref) {
  final languageCode = ref.watch(contentLanguageProvider);
  return ref
      .watch(recitationsRepositoryProvider)
      .getRecitations(language: languageCode);
});
