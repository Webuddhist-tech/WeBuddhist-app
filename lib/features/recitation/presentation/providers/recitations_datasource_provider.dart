import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/env.dart';
import 'package:flutter_pecha/features/library/data/adapters/library_recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/library/presentation/providers/library_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/my_recitation_collections_providers.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one recitations datasource: chant lists and search from the library,
/// saved chants and collections from the main API.
final recitationsRemoteDatasourceProvider = Provider<RecitationsRemoteDatasource>(
  (ref) {
    return LibraryRecitationsRemoteDatasource(
      dio: ref.watch(dioProvider),
      library: ref.watch(libraryRepositoryProvider),
      collections: ref.watch(myRecitationCollectionsRemoteDatasourceProvider),
      tagId: Env.libraryChantsTagId,
    );
  },
);
