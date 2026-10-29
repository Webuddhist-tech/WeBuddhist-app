import 'dart:async';

import 'package:flutter_pecha/core/realtime/realtime_providers.dart';
import 'package:flutter_pecha/core/realtime/realtime_signals.dart';
import 'package:flutter_pecha/core/realtime/retry_permission_denied.dart';
import 'package:flutter_pecha/core/realtime/signal_field_diff.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('SignalListener');

/// Runs [onChange] whenever one of [fields] on [path] moves, for the life of
/// the provider that owns [ref]. Nothing happens until Firebase is signed in;
/// the provider rebuilds when it is. A refusal that outlives
/// [permissionRetries] is logged once and the screen keeps fetching as it
/// does today. [coalesce] folds a burst into one call per field.
void listenSignal(
  Ref ref, {
  required String path,
  required Set<String> fields,
  required void Function(SignalChange change) onChange,
  int permissionRetries = 0,
  Duration coalesce = Duration.zero,
}) {
  final signals = ref.watch(liveSignalsProvider);
  if (signals == null) return;

  final pending = <String, SignalChange>{};
  Timer? timer;

  void flush() {
    timer = null;
    final changes = pending.values.toList();
    pending.clear();
    changes.forEach(onChange);
  }

  final sub = retryPermissionDenied(
    () => watchFieldChanges(signals, path, fields),
    attempts: permissionRetries,
  ).listen(
    (change) {
      if (coalesce <= Duration.zero) {
        onChange(change);
        return;
      }
      pending[change.field] = change;
      timer ??= Timer(coalesce, flush);
    },
    onError:
        (Object error) => _logger.debug('No live updates for $path: $error'),
  );

  ref.onDispose(() {
    timer?.cancel();
    sub.cancel();
  });
}
