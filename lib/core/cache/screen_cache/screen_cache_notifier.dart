import 'dart:async';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

typedef ScreenCacheSelect<T extends Object, S> =
    S Function(Either<Failure, T> result);

typedef ScreenCacheBuild<T extends Object, S> =
    FutureOr<S> Function(Ref ref, ScreenCacheBinder<T, S> bind);

typedef ScreenCacheFamilyBuild<T extends Object, S, Arg> =
    FutureOr<S> Function(Ref ref, Arg arg, ScreenCacheBinder<T, S> bind);

S _identity<T extends Object, S>(Either<Failure, T> result) => result as S;

/// Seeds the build result synchronously and feeds later events into state.
class ScreenCacheBinder<T extends Object, S> {
  ScreenCacheBinder._(this._ref, this._setState);

  final Ref _ref;
  final void Function(AsyncValue<S> value) _setState;

  /// Stored payload first, then the source stream.
  FutureOr<S> source(
    ScreenCacheSource<T> source, {
    ScreenCacheSelect<T, S>? select,
  }) {
    return _bindSource<T, S>(_ref, _setState, source, select);
  }

  /// For streams backed by another local store: [initial] is the stored value
  /// read synchronously, [updates] delivers the refreshed ones.
  FutureOr<S> stream(S? initial, Stream<S> updates) {
    return _bindStream<S>(_ref, _setState, initial, updates);
  }
}

FutureOr<S> _bindStream<S>(
  Ref ref,
  void Function(AsyncValue<S> value) setState,
  S? initial,
  Stream<S> updates,
) {
  var delivered = initial != null;
  final first = Completer<S>();
  final sub = updates.listen(
    (value) {
      if (delivered) {
        setState(AsyncData(value));
      } else {
        delivered = true;
        first.complete(value);
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      if (delivered) {
        setState(AsyncError(error, stackTrace));
      } else {
        delivered = true;
        first.completeError(error, stackTrace);
      }
    },
  );
  ref.onDispose(sub.cancel);
  if (initial == null) return first.future;
  return initial;
}

/// Stored value is the build result; later stream events go through [setState].
/// A first fetch resolves through [ScreenCacheSource.refresh] so a build that
/// is dropped before it settles (an awaited `.future`) still completes.
FutureOr<S> _bindSource<T extends Object, S>(
  Ref ref,
  void Function(AsyncValue<S> value) setState,
  ScreenCacheSource<T> source,
  ScreenCacheSelect<T, S>? select,
) {
  final pick = select ?? _identity<T, S>;
  final stored = source.read();
  // The stream starts by re-emitting what the build already delivered.
  var skipEcho = true;
  var delivered = stored != null;

  void push(Either<Failure, T> result) {
    if (skipEcho) {
      skipEcho = false;
      return;
    }
    if (!delivered) return;
    try {
      setState(AsyncData(pick(result)));
    } catch (e, st) {
      setState(AsyncError(e, st));
    }
  }

  final sub = source.watch().listen(
    push,
    onError: (Object error, StackTrace stackTrace) {
      if (delivered) setState(AsyncError(error, stackTrace));
    },
  );
  ref.onDispose(sub.cancel);

  if (stored != null) return pick(Right(stored));
  return source.refresh().then((result) {
    delivered = true;
    return pick(result);
  });
}

/// `AsyncNotifierProvider` whose first state is the stored screen payload.
class ScreenCacheNotifier<T extends Object, S> extends AsyncNotifier<S> {
  ScreenCacheNotifier(this._build) : _fixed = null, _pending = false;
  ScreenCacheNotifier.fixed(S value)
    : _build = null,
      _fixed = value,
      _pending = false;
  ScreenCacheNotifier.pending() : _build = null, _fixed = null, _pending = true;

  final ScreenCacheBuild<T, S>? _build;
  final S? _fixed;
  final bool _pending;


  ScreenCacheBinder<T, S> _binder() {
    return ScreenCacheBinder<T, S>._(ref, (value) => state = value);
  }

  @override
  FutureOr<S> build() {
    if (_pending) return Completer<S>().future;
    final build = _build;
    if (build == null) return _fixed as S;
    return build(ref, _binder());
  }
}

class ScreenCacheFamilyNotifier<T extends Object, S, Arg>
    extends FamilyAsyncNotifier<S, Arg>
{
  ScreenCacheFamilyNotifier(this._build) : _fixed = null, _pending = false;
  ScreenCacheFamilyNotifier.fixed(S value)
    : _build = null,
      _fixed = value,
      _pending = false;
  ScreenCacheFamilyNotifier.pending()
    : _build = null,
      _fixed = null,
      _pending = true;

  final ScreenCacheFamilyBuild<T, S, Arg>? _build;
  final S? _fixed;
  final bool _pending;


  ScreenCacheBinder<T, S> _binder() {
    return ScreenCacheBinder<T, S>._(ref, (value) => state = value);
  }

  @override
  FutureOr<S> build(Arg arg) {
    if (_pending) return Completer<S>().future;
    final build = _build;
    if (build == null) return _fixed as S;
    return build(ref, arg, _binder());
  }
}

class AutoDisposeScreenCacheNotifier<T extends Object, S>
    extends AutoDisposeAsyncNotifier<S>
{
  AutoDisposeScreenCacheNotifier(this._build)
    : _fixed = null,
      _pending = false;
  AutoDisposeScreenCacheNotifier.fixed(S value)
    : _build = null,
      _fixed = value,
      _pending = false;
  AutoDisposeScreenCacheNotifier.pending()
    : _build = null,
      _fixed = null,
      _pending = true;

  final ScreenCacheBuild<T, S>? _build;
  final S? _fixed;
  final bool _pending;


  ScreenCacheBinder<T, S> _binder() {
    return ScreenCacheBinder<T, S>._(ref, (value) => state = value);
  }

  @override
  FutureOr<S> build() {
    if (_pending) return Completer<S>().future;
    final build = _build;
    if (build == null) return _fixed as S;
    return build(ref, _binder());
  }
}

class AutoDisposeScreenCacheFamilyNotifier<T extends Object, S, Arg>
    extends AutoDisposeFamilyAsyncNotifier<S, Arg>
{
  AutoDisposeScreenCacheFamilyNotifier(this._build)
    : _fixed = null,
      _pending = false;
  AutoDisposeScreenCacheFamilyNotifier.fixed(S value)
    : _build = null,
      _fixed = value,
      _pending = false;
  AutoDisposeScreenCacheFamilyNotifier.pending()
    : _build = null,
      _fixed = null,
      _pending = true;

  final ScreenCacheFamilyBuild<T, S, Arg>? _build;
  final S? _fixed;
  final bool _pending;


  ScreenCacheBinder<T, S> _binder() {
    return ScreenCacheBinder<T, S>._(ref, (value) => state = value);
  }

  @override
  FutureOr<S> build(Arg arg) {
    if (_pending) return Completer<S>().future;
    final build = _build;
    if (build == null) return _fixed as S;
    return build(ref, arg, _binder());
  }
}
