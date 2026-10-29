import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_items_page.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_items_tab.dart';
import 'package:fpdart/fpdart.dart';

/// Domain contract for `GET /practice/items`.
abstract class PracticeItemsRepository {
  /// Fetches a single page of practice items filtered by [tab] and
  /// localized by [language]. Page indexing is 1-based to mirror the API.
  Future<Either<Failure, PracticeItemsPage>> getPracticeItems({
    required PracticeItemsTab tab,
    required String language,
    required int page,
    required int pageSize,
  });

  /// The stored first page, if any, for an instant first render.
  PracticeItemsPage? readFirstPage({
    required PracticeItemsTab tab,
    required String language,
    required int pageSize,
  });

  /// Fetches page 1, stores it when changed, and returns it.
  Future<Either<Failure, PracticeItemsPage>> refreshFirstPage({
    required PracticeItemsTab tab,
    required String language,
    required int pageSize,
  });
}
