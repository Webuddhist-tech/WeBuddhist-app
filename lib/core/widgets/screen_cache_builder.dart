import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Data wins even while reloading; skeleton only when nothing is loaded yet.
class ScreenCacheBuilder<T extends Object> extends StatelessWidget {
  const ScreenCacheBuilder({
    super.key,
    required this.value,
    required this.data,
    required this.skeleton,
    required this.onRetry,
    this.error,
  });

  final AsyncValue<Either<Failure, T>> value;
  final Widget Function(T data) data;
  final Widget skeleton;
  final VoidCallback onRetry;
  final Widget Function(Object error, VoidCallback onRetry)? error;

  /// Loaded data, or null while nothing has loaded yet.
  static T? loadedOf<T extends Object>(AsyncValue<Either<Failure, T>> value) =>
      value.valueOrNull?.fold<T?>((_) => null, (d) => d);

  @override
  Widget build(BuildContext context) {
    final loaded = loadedOf(value);
    if (loaded != null) return data(loaded);
    if (value.isLoading) return skeleton;
    final failure =
        value.valueOrNull?.fold<Object?>((f) => f, (_) => null) ??
        value.error ??
        Exception('Unknown error');
    final build = error;
    if (build != null) return build(failure, onRetry);
    return ErrorStateWidget(error: failure, onRetry: onRetry);
  }
}
