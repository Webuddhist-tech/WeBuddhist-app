import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pray calls still going out after their sheet closed. Sign-out waits on
/// them, since clearing credentials mid-send would drop prayers already shown.
class PendingPrayerSends {
  final Set<Future<void>> _active = {};

  void add(Future<void> send) {
    final safe = send.catchError((_) {});
    _active.add(safe);
    safe.whenComplete(() => _active.remove(safe));
  }

  /// Completes once every send under way has landed, or after [timeout].
  Future<void> settle({Duration timeout = const Duration(seconds: 5)}) {
    if (_active.isEmpty) return Future.value();
    return Future.wait(_active.toList())
        .then<void>((_) {})
        .timeout(timeout, onTimeout: () {});
  }
}

final pendingPrayerSendsProvider = Provider<PendingPrayerSends>(
  (_) => PendingPrayerSends(),
);
