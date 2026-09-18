import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/network/reconnect_backoff.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_client.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_live_position.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RecitationLiveConnection {
  idle,
  connecting,
  connected,
  reconnecting,

  /// The operator ended the puja. Shown briefly, then back to [idle].
  ended,

  /// The socket was refused (no token, 401/403/404) — nothing to follow.
  unavailable,
}

/// What the reader does with a position frame. Only a client-side choice:
/// the socket stays open in every mode so opting back in is instant.
enum RecitationLiveFollowMode {
  /// Scroll to and highlight each new position.
  following,

  /// The user scrolled away; highlight only, until they turn Sync back on.
  paused,

  /// The user opted out; neither scroll nor highlight.
  off,
}

class RecitationLiveState {
  final RecitationLiveConnection connection;
  final RecitationLiveFollowMode followMode;
  final RecitationLivePosition? position;
  final bool isOperator;

  /// The reader could not place [position] in the text it has loaded.
  final bool outOfSync;

  /// Bumped by [RecitationLiveNotifier.resumeFollowing] so the reader
  /// re-scrolls even when [position] itself did not change.
  final int followRequest;

  const RecitationLiveState({
    this.connection = RecitationLiveConnection.idle,
    this.followMode = RecitationLiveFollowMode.following,
    this.position,
    this.isOperator = false,
    this.outOfSync = false,
    this.followRequest = 0,
  });

  bool get isFollowing => followMode == RecitationLiveFollowMode.following;
  bool get isOff => followMode == RecitationLiveFollowMode.off;
  bool get hasPosition => position != null;
  bool get isReconnecting =>
      connection == RecitationLiveConnection.reconnecting;
  bool get isEnded => connection == RecitationLiveConnection.ended;

  /// The live chrome appears once the room has a position, and lingers for
  /// the end-of-session notice.
  bool get isVisible => position != null || isEnded;

  RecitationLiveState copyWith({
    RecitationLiveConnection? connection,
    RecitationLiveFollowMode? followMode,
    RecitationLivePosition? position,
    bool? isOperator,
    bool? outOfSync,
    int? followRequest,
    bool clearPosition = false,
  }) {
    return RecitationLiveState(
      connection: connection ?? this.connection,
      followMode: followMode ?? this.followMode,
      position: clearPosition ? null : (position ?? this.position),
      isOperator: isOperator ?? this.isOperator,
      outOfSync: outOfSync ?? this.outOfSync,
      followRequest: followRequest ?? this.followRequest,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecitationLiveState &&
        other.connection == connection &&
        other.followMode == followMode &&
        other.position == position &&
        other.isOperator == isOperator &&
        other.outOfSync == outOfSync &&
        other.followRequest == followRequest;
  }

  @override
  int get hashCode => Object.hash(
    connection,
    followMode,
    position,
    isOperator,
    outOfSync,
    followRequest,
  );
}

/// Holds the event's recitation socket for as long as a reader is on screen.
///
/// Reconnects with backoff after a drop, pings every 30s so a sleeping phone
/// is noticed, and drops the socket while the app is in the background. The
/// follow mode is the user's choice and never touches the connection.
class RecitationLiveNotifier extends StateNotifier<RecitationLiveState>
    with WidgetsBindingObserver {
  RecitationLiveNotifier({
    required this.eventId,
    required Future<String?> Function() getToken,
    required String restBaseUrl,
    RecitationLiveClient Function()? clientFactory,
    bool observeLifecycle = true,
    Duration Function(int attempt) backoff = reconnectDelay,
    this.snapshotGrace = const Duration(seconds: 2),
    this.endedNoticeDuration = const Duration(seconds: 4),
  }) : _getToken = getToken,
       _restBaseUrl = restBaseUrl,
       _clientFactory = clientFactory ?? RecitationLiveClient.new,
       _observeLifecycle = observeLifecycle,
       _backoff = backoff,
       super(const RecitationLiveState()) {
    if (_observeLifecycle) WidgetsBinding.instance.addObserver(this);
    unawaited(connect());
  }

  static const Duration pingInterval = Duration(seconds: 30);

  /// Consecutive closes before any frame arrived, after which the socket is
  /// treated as refused rather than flaky.
  static const int maxRefusals = 3;

  /// How long after `session_info` to wait for the position snapshot before
  /// concluding the room has none and dropping a position kept from before
  /// a reconnect.
  final Duration snapshotGrace;
  final Duration endedNoticeDuration;

  final String eventId;
  final Future<String?> Function() _getToken;
  final String _restBaseUrl;
  final RecitationLiveClient Function() _clientFactory;
  final bool _observeLifecycle;
  final Duration Function(int attempt) _backoff;
  final _logger = AppLogger('RecitationLive');

  RecitationLiveClient? _client;
  StreamSubscription<RecitationLiveEvent>? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _snapshotTimer;
  Timer? _endedTimer;
  int _reconnectAttempt = 0;
  int _refusals = 0;
  bool _receivedFrame = false;
  bool _connecting = false;
  bool _stopped = false;
  bool _suspended = false;
  bool _disposed = false;

  /// Never throws: the reconnect timer and the lifecycle observer call this
  /// without an error handler.
  Future<void> connect() async {
    if (_disposed ||
        _stopped ||
        _suspended ||
        _client != null ||
        _connecting) {
      return;
    }
    // Set before the first await so a racing caller backs off instead of
    // opening a second socket that would orphan this one.
    _connecting = true;
    state = state.copyWith(
      connection:
          state.position != null || _reconnectAttempt > 0
              ? RecitationLiveConnection.reconnecting
              : RecitationLiveConnection.connecting,
    );

    final String? token;
    try {
      token = await _getToken();
    } catch (_) {
      _connecting = false;
      _scheduleReconnect();
      return;
    }
    if (_disposed || _suspended) {
      _connecting = false;
      return;
    }
    if (token == null) {
      // Not signed in: nothing to authorise the socket with.
      _connecting = false;
      _stopped = true;
      state = state.copyWith(connection: RecitationLiveConnection.unavailable);
      return;
    }

    final uri = RecitationLiveClient.liveUri(
      restBaseUrl: _restBaseUrl,
      token: token,
      eventId: eventId,
    );
    final client = _clientFactory();
    _client = client;
    _connecting = false;
    _receivedFrame = false;
    try {
      _sub = client
          .connect(uri)
          .listen(
            _onEvent,
            onError: (_) => _onClosed(),
            onDone: _onClosed,
            cancelOnError: true,
          );
    } catch (e) {
      _logger.debug('Recitation live connect failed: $e');
      _client = null;
      _scheduleReconnect();
      return;
    }
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) => _client?.sendPing());
  }

  void _onEvent(RecitationLiveEvent event) {
    if (_disposed) return;
    _receivedFrame = true;
    _reconnectAttempt = 0;
    _refusals = 0;

    switch (event) {
      case RecitationLiveSessionInfo(isOperator: final isOperator):
        state = state.copyWith(
          connection: RecitationLiveConnection.connected,
          isOperator: isOperator,
        );
        // The snapshot, if the room has one, follows right behind. When none
        // comes, a position kept across a reconnect is stale.
        _snapshotTimer?.cancel();
        _snapshotTimer = Timer(snapshotGrace, () {
          if (_disposed || state.position == null) return;
          state = state.copyWith(clearPosition: true, outOfSync: false);
        });
      case RecitationLivePositionEvent(position: final position):
        _snapshotTimer?.cancel();
        if (!position.isValid || !position.isNewerThan(state.position)) return;
        state = state.copyWith(
          connection: RecitationLiveConnection.connected,
          position: position,
          outOfSync: false,
        );
      case RecitationLiveSessionEnded():
        _snapshotTimer?.cancel();
        _pingTimer?.cancel();
        _stopped = true;
        state = state.copyWith(
          connection: RecitationLiveConnection.ended,
          clearPosition: true,
          outOfSync: false,
        );
        _endedTimer = Timer(endedNoticeDuration, () {
          if (_disposed) return;
          state = state.copyWith(connection: RecitationLiveConnection.idle);
        });
      case RecitationLiveError(code: final code, isFatal: final isFatal):
        _logger.debug('Recitation live error: $code');
        if (!isFatal) return;
        _stopped = true;
        state = state.copyWith(
          connection: RecitationLiveConnection.unavailable,
          clearPosition: true,
        );
        unawaited(_tearDown());
      case RecitationLivePong():
      case RecitationLiveUnknown():
        break;
    }
  }

  /// The server closed the socket, or the stream errored. A cancelled
  /// subscription never lands here, so this is only ever the far end.
  void _onClosed() {
    if (_disposed) return;
    unawaited(_tearDown());
    if (_stopped || _suspended) return;
    if (!_receivedFrame) {
      _refusals++;
      if (_refusals >= maxRefusals) {
        _stopped = true;
        state = state.copyWith(
          connection: RecitationLiveConnection.unavailable,
          clearPosition: true,
        );
        return;
      }
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _stopped || _suspended) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    state = state.copyWith(connection: RecitationLiveConnection.reconnecting);
    _reconnectTimer = Timer(_backoff(_reconnectAttempt), () {
      if (_disposed) return;
      unawaited(connect());
    });
  }

  /// Clears the fields before the first await so a reconnect firing while
  /// the old socket is still closing sees it gone.
  Future<void> _tearDown() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    _snapshotTimer?.cancel();
    final sub = _sub;
    final client = _client;
    _sub = null;
    _client = null;
    await sub?.cancel();
    await client?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || _stopped) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _suspended = true;
        _reconnectTimer?.cancel();
        unawaited(_tearDown());
      case AppLifecycleState.resumed:
        if (!_suspended) return;
        _suspended = false;
        _reconnectAttempt = 0;
        unawaited(connect());
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// Scroll to wherever the operator is now and keep following.
  void resumeFollowing() {
    if (_disposed) return;
    state = state.copyWith(
      followMode: RecitationLiveFollowMode.following,
      outOfSync: false,
      followRequest: state.followRequest + 1,
    );
  }

  /// The reader scrolled away on its own: keep the highlight, stop scrolling.
  void pauseFollowing() {
    if (_disposed || !state.isFollowing) return;
    state = state.copyWith(followMode: RecitationLiveFollowMode.paused);
  }

  /// Opt out. The socket stays up so opting back in lands on the live line.
  void stopFollowing() {
    if (_disposed) return;
    state = state.copyWith(followMode: RecitationLiveFollowMode.off);
  }

  void setOutOfSync(bool value) {
    if (_disposed || state.outOfSync == value) return;
    state = state.copyWith(outOfSync: value);
  }

  @override
  void dispose() {
    _disposed = true;
    if (_observeLifecycle) WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _endedTimer?.cancel();
    _snapshotTimer?.cancel();
    unawaited(_tearDown());
    super.dispose();
  }
}

/// One socket per event, shared by every reader screen opened for it.
///
/// Kept alive for a few seconds after the last reader leaves so a text switch
/// (which replaces the reader route) does not drop and reopen the socket.
final recitationLiveProvider = StateNotifierProvider.autoDispose
    .family<RecitationLiveNotifier, RecitationLiveState, String>((
      ref,
      eventId,
    ) {
      KeepAliveLink? link = ref.keepAlive();
      Timer? graceTimer;
      ref.onCancel(() {
        graceTimer?.cancel();
        graceTimer = Timer(const Duration(seconds: 5), () {
          link?.close();
          link = null;
        });
      });
      ref.onResume(() {
        graceTimer?.cancel();
        link ??= ref.keepAlive();
      });
      ref.onDispose(() => graceTimer?.cancel());

      return RecitationLiveNotifier(
        eventId: eventId,
        getToken: () => ref.read(authServiceProvider).getValidAccessToken(),
        restBaseUrl: ref.read(apiConfigProvider).baseUrl,
      );
    });
