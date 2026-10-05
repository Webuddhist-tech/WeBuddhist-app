import 'dart:async';

import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_client.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_live_position.dart';

/// Connects once and returns where the room already is.
///
/// Null means the session has not started, has ended, or the socket was
/// refused. A position that follows `session_info` is the snapshot of the
/// room; if none arrives within [snapshotGrace], the session is treated as
/// not started. The server sends the snapshot right behind `session_info`,
/// so the grace only has to cover one Redis read, not a round trip.
Future<RecitationLivePosition?> peekRecitationLivePosition({
  required RecitationLiveClient client,
  required Uri uri,
  Duration snapshotGrace = const Duration(milliseconds: 500),
  Duration timeout = const Duration(seconds: 6),
}) async {
  final done = Completer<RecitationLivePosition?>();
  Timer? grace;
  StreamSubscription<RecitationLiveEvent>? subscription;

  void finish(RecitationLivePosition? position) {
    grace?.cancel();
    if (!done.isCompleted) done.complete(position);
  }

  try {
    subscription = client.connect(uri).listen(
      (event) {
        switch (event) {
          case RecitationLiveSessionInfo():
            grace?.cancel();
            grace = Timer(snapshotGrace, () => finish(null));
          case RecitationLivePositionEvent(position: final position):
            if (position.isValid) finish(position);
          case RecitationLiveSessionEnded():
            finish(null);
          case RecitationLiveError(isFatal: final isFatal):
            if (isFatal) finish(null);
          case RecitationLivePong():
          case RecitationLiveUnknown():
            break;
        }
      },
      onError: (Object _) => finish(null),
      onDone: () => finish(null),
      cancelOnError: true,
    );
    return await done.future.timeout(timeout, onTimeout: () => null);
  } catch (_) {
    return null;
  } finally {
    grace?.cancel();
    await subscription?.cancel();
    // Not awaited: closing a socket whose connect is still pending waits on
    // the OS connect timeout, which would hold the caller well past [timeout].
    // A late close error has nobody left to report to, so it is dropped.
    client.dispose().ignore();
  }
}
