import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/library/data/datasource/library_remote_datasource.dart';
import 'package:flutter_pecha/features/library/data/repositories/library_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final libraryRemoteDatasourceProvider = Provider<LibraryRemoteDatasource>((
  ref,
) {
  return LibraryRemoteDatasource(dio: ref.watch(libraryDioProvider));
});

/// One instance per app so text, edition and segment lookups stay memoized.
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(
    datasource: ref.watch(libraryRemoteDatasourceProvider),
  );
});
