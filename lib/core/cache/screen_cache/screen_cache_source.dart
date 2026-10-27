import 'dart:async';
import 'dart:convert';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:fpdart/fpdart.dart';

final _logger = AppLogger('ScreenCacheSource');

/// Stored copy first, API in the background, screen updated only on change.
class ScreenCacheSource<T extends Object> {
  const ScreenCacheSource({
    required this.store,
    required this.key,
    required this.fetchJson,
    required this.fromJson,
    required this.failureMessage,
  });

  final ScreenCacheStore store;
  final String key;

  /// Must bypass the HTTP cache (`no_cache`) and return a JSON-encodable value.
  final Future<Object> Function() fetchJson;
  final T Function(Object json) fromJson;
  final String failureMessage;

  T? read() => _decode(store.read(key));

  /// Cached value, then the refreshed one if it changed, then later writes.
  Stream<Either<Failure, T>> watch() {
    late final StreamController<Either<Failure, T>> controller;
    StreamSubscription<void>? changes;
    String? lastRaw;

    void emit(String raw) {
      if (controller.isClosed || raw == lastRaw) return;
      lastRaw = raw;
      final value = _decode(raw);
      if (value != null) controller.add(Right(value));
    }

    Future<void> start() async {
      final cached = _decode(store.read(key));
      if (cached != null) {
        lastRaw = store.read(key);
        controller.add(Right(cached));
      }
      changes = store.watch(key).listen((_) {
        final raw = store.read(key);
        if (raw != null) emit(raw);
      });
      try {
        emit(await store.revalidate(key, _fetchEncoded));
      } catch (e, st) {
        _logger.warning('Revalidate failed for $key', e, st);
        if (cached == null && !controller.isClosed) {
          controller.add(Left(ExceptionMapper.map(e, context: failureMessage)));
        }
      }
    }

    controller = StreamController<Either<Failure, T>>(
      onListen: start,
      onCancel: () async {
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  /// Pull-to-refresh: the open [watch] stream delivers any change to the UI.
  Future<Either<Failure, T>> refresh() async {
    try {
      final fetched = await store.revalidate(key, _fetchEncoded);
      final value = _decode(fetched);
      if (value == null) return Left(CacheFailure(failureMessage));
      return Right(value);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: failureMessage));
    }
  }

  Future<String> _fetchEncoded() async => jsonEncode(await fetchJson());

  T? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw) as Object);
    } catch (e, st) {
      _logger.warning('Dropping unreadable cache entry $key', e, st);
      unawaited(store.remove(key));
      return null;
    }
  }
}
