import 'dart:math' as math;

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

/// Every loaded position of a paged list, read again from the top.
class LoadedWindow<T> {
  const LoadedWindow(this.rows, this.total);

  final List<T> rows;
  final int total;
}

/// Re-reads positions `[0, window())` of a paged list, [pageLimit] at most
/// a call. [window] is asked again after every page, so a page loaded while
/// the read is out is read too rather than overwritten. Null when a page
/// fails or [isCurrent] turns false.
Future<LoadedWindow<T>?> readLoadedWindow<T>({
  required int Function() window,
  required Future<Either<Failure, (List<T>, int)>> Function(int skip, int limit)
  fetch,
  required Object Function(T row) idOf,
  required bool Function() isCurrent,
  int pageLimit = 100,
}) async {
  final rows = <T>[];
  final seen = <Object>{};
  var total = 0;
  var skip = 0;
  while (skip < window()) {
    final limit = math.min(pageLimit, window() - skip);
    final result = await fetch(skip, limit);
    if (!isCurrent()) return null;
    final page = result.getRight().toNullable();
    if (page == null) return null;
    final (pageRows, pageTotal) = page;
    total = pageTotal;
    rows.addAll(pageRows.where((row) => seen.add(idOf(row))));
    skip += limit;
    if (pageRows.length < limit) break;
  }
  return LoadedWindow(rows, total);
}
