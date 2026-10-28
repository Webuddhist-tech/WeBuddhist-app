import 'dart:async';
import 'dart:convert';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

/// Shows the stored first page at once, then replaces it with the server's.
///
/// [apply] runs with the stored page (if [seed] and one exists) and again
/// with the fresh one; [fail] only when the fetch fails and the list is still
/// empty (`seed` false means the caller already shows a page). A notifier that must keep
/// its own request and failure messages passes [fetch] and [encode]; the
/// fresh page is then stored here instead of by the source.
Future<void> loadCachedFirstPage<T extends Object>(
  ScreenCacheSource<T> source, {
  required bool Function() isCurrent,
  required void Function(T page) apply,
  required void Function(Failure failure) fail,
  bool seed = true,
  Future<Either<Failure, T>> Function()? fetch,
  Object Function(T page)? encode,
}) async {
  final cached = seed ? source.read() : null;
  if (cached != null) apply(cached);

  final result = fetch == null ? await source.refresh() : await fetch();
  if (!isCurrent()) return;
  result.fold(
    (failure) {
      if (cached == null && seed) fail(failure);
    },
    (page) {
      apply(page);
      if (fetch == null || encode == null) return;
      unawaited(
        source.store
            .save(source.key, jsonEncode(encode(page)))
            .catchError((Object _) => false),
      );
    },
  );
}
