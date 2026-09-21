import 'dart:async';

import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_client.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_live_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A socket the test drives by hand: frames go in through [incoming], what
/// the client sends lands in [sent], and closing [incoming] plays the server
/// hanging up.
class _FakeChannel implements WebSocketChannel {
  final incoming = StreamController<dynamic>();
  final sent = <dynamic>[];
  bool sinkClosed = false;
  late final Uri uri;

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  late final WebSocketSink sink = _FakeSink(this);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this.channel);
  final _FakeChannel channel;

  @override
  void add(dynamic data) => channel.sent.add(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    channel.sinkClosed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Harness {
  final channels = <_FakeChannel>[];
  late final RecitationLiveNotifier notifier;

  /// The attempt number handed to the backoff on each reconnect.
  final backoffAttempts = <int>[];

  _Harness({
    String? token = 'tok',
    Duration snapshotGrace = const Duration(milliseconds: 40),
    Duration endedNotice = const Duration(milliseconds: 40),
    Duration backoff = const Duration(milliseconds: 20),
  }) {
    notifier = RecitationLiveNotifier(
      eventId: 'ev1',
      restBaseUrl: 'https://api.example.com/api/v1',
      getToken: () async => token,
      clientFactory:
          () => RecitationLiveClient(
            connect: (uri) {
              final channel = _FakeChannel()..uri = uri;
              channels.add(channel);
              return channel;
            },
          ),
      observeLifecycle: false,
      backoff: (attempt) {
        backoffAttempts.add(attempt);
        return backoff;
      },
      snapshotGrace: snapshotGrace,
      endedNoticeDuration: endedNotice,
    );
  }

  _FakeChannel get channel => channels.last;

  /// Lets the token future and the stream subscription settle.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Polls until [condition] holds; real timers make fixed waits flaky.
  Future<void> waitFor(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('condition not met within $timeout');
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<void> waitForChannels(int count) =>
      waitFor(() => channels.length >= count);

  Future<void> push(String frame) async {
    channel.incoming.add(frame);
    await settle();
  }

  Future<void> serverCloses() async {
    await channel.incoming.close();
    await settle();
  }
}

const _sessionInfo =
    '{"type":"session_info","event_id":"ev1","is_operator":false}';

String _position(
  String segment,
  int revision, {
  String text = 't1',
  int? round,
}) =>
    '{"type":"position","event_id":"ev1","text_id":"$text",'
    '"segment_id":"$segment","revision":$revision'
    '${round == null ? '' : ',"round_number":$round'}}';

void main() {
  test('connects with the token and lands on the snapshot', () async {
    final h = _Harness();
    await h.settle();
    expect(h.channels, hasLength(1));
    expect(h.channel.uri.queryParameters['token'], 'tok');
    expect(h.channel.uri.path, '/api/v1/events/ev1/recitation/live');
    expect(h.notifier.state.connection, RecitationLiveConnection.connecting);

    await h.push(_sessionInfo);
    expect(h.notifier.state.connection, RecitationLiveConnection.connected);
    expect(h.notifier.state.isVisible, isFalse);

    await h.push(_position('s1', 10, round: 2));
    final state = h.notifier.state;
    expect(state.position?.segmentId, 's1');
    expect(state.position?.roundNumber, 2);
    expect(state.isVisible, isTrue);
    expect(state.isFollowing, isTrue);
    h.notifier.dispose();
  });

  test(
    'flags the connect snapshot, but not the operator moving after it',
    () async {
      // The reader may not navigate a user off the text they just opened just
      // because the room was already elsewhere; a later `set` is a real move.
      final h = _Harness();
      await h.settle();
      await h.push(_sessionInfo);
      await h.push(_position('s1', 10));
      expect(h.notifier.state.positionIsSnapshot, isTrue);

      await h.push(_position('s2', 11));
      expect(h.notifier.state.positionIsSnapshot, isFalse);
      h.notifier.dispose();
    },
  );

  test('drops frames older than the one it holds', () async {
    final h = _Harness();
    await h.settle();
    await h.push(_sessionInfo);
    await h.push(_position('s5', 5));
    await h.push(_position('s3', 3));
    expect(h.notifier.state.position?.segmentId, 's5');
    await h.push(_position('s6', 6));
    expect(h.notifier.state.position?.segmentId, 's6');
    h.notifier.dispose();
  });

  test('follow mode is a client choice and never touches the socket', () async {
    final h = _Harness();
    await h.settle();
    await h.push(_sessionInfo);
    await h.push(_position('s1', 1));

    h.notifier.pauseFollowing();
    expect(h.notifier.state.followMode, RecitationLiveFollowMode.paused);
    h.notifier.stopFollowing();
    expect(h.notifier.state.followMode, RecitationLiveFollowMode.off);
    // Positions keep flowing while opted out.
    await h.push(_position('s2', 2));
    expect(h.notifier.state.position?.segmentId, 's2');
    expect(h.channel.sinkClosed, isFalse);

    final before = h.notifier.state.followRequest;
    h.notifier.setOutOfSync(true);
    h.notifier.resumeFollowing();
    expect(h.notifier.state.followMode, RecitationLiveFollowMode.following);
    expect(h.notifier.state.followRequest, before + 1);
    expect(h.notifier.state.outOfSync, isFalse);
    // Pausing only applies while following.
    h.notifier.stopFollowing();
    h.notifier.pauseFollowing();
    expect(h.notifier.state.followMode, RecitationLiveFollowMode.off);
    h.notifier.dispose();
  });

  test(
    'session_ended clears the position, shows the notice, and stays down',
    () async {
      final h = _Harness();
      await h.settle();
      await h.push(_sessionInfo);
      await h.push(_position('s1', 1));
      await h.push('{"type":"session_ended"}');
      expect(h.notifier.state.connection, RecitationLiveConnection.ended);
      expect(h.notifier.state.position, isNull);
      expect(h.notifier.state.isVisible, isTrue);

      await h.serverCloses();
      await h.waitFor(
        () => h.notifier.state.connection == RecitationLiveConnection.idle,
      );
      expect(h.channels, hasLength(1), reason: 'no reconnect after end');
      expect(h.notifier.state.isVisible, isFalse);
      h.notifier.dispose();
    },
  );

  test('a dropped socket reconnects and resyncs from the snapshot', () async {
    final h = _Harness();
    await h.settle();
    await h.push(_sessionInfo);
    await h.push(_position('s1', 1));

    await h.serverCloses();
    expect(h.notifier.state.connection, RecitationLiveConnection.reconnecting);
    expect(
      h.notifier.state.position?.segmentId,
      's1',
      reason: 'held across the gap',
    );
    await h.waitForChannels(2);

    await h.push(_sessionInfo);
    await h.push(_position('s4', 4));
    expect(h.notifier.state.connection, RecitationLiveConnection.connected);
    expect(h.notifier.state.position?.segmentId, 's4');
    h.notifier.dispose();
  });

  test('a reconnect with no snapshot drops the stale position', () async {
    final h = _Harness();
    await h.settle();
    await h.push(_sessionInfo);
    await h.push(_position('s1', 1));
    await h.serverCloses();
    await h.waitForChannels(2);
    await h.push(_sessionInfo);
    expect(h.notifier.state.position?.segmentId, 's1');
    await h.waitFor(() => h.notifier.state.position == null);
    expect(h.notifier.state.isVisible, isFalse);
    h.notifier.dispose();
  });

  test('a fatal error frame gives up for good', () async {
    final h = _Harness();
    await h.settle();
    await h.push('{"type":"error","code":"UNAUTHORIZED","message":"no"}');
    expect(h.notifier.state.connection, RecitationLiveConnection.unavailable);
    expect(h.channel.sinkClosed, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(h.channels, hasLength(1));
    h.notifier.dispose();
  });

  test(
    'closes before any frame keep reconnecting with growing backoff',
    () async {
      final h = _Harness();
      await h.settle();
      // An outage that outlasts a few retries must not disable sync for good.
      for (var i = 1; i <= 4; i++) {
        await h.serverCloses();
        expect(
          h.notifier.state.connection,
          RecitationLiveConnection.reconnecting,
        );
        await h.waitForChannels(i + 1);
      }
      expect(h.backoffAttempts, [1, 2, 3, 4]);

      // Once the server is back, the session resumes as normal.
      await h.push(_sessionInfo);
      expect(h.notifier.state.connection, RecitationLiveConnection.connected);
      h.notifier.dispose();
    },
  );

  test('a signed-out user gets no socket', () async {
    final h = _Harness(token: null);
    await h.settle();
    expect(h.channels, isEmpty);
    expect(h.notifier.state.connection, RecitationLiveConnection.unavailable);
    h.notifier.dispose();
  });

  test('dispose closes the socket', () async {
    final h = _Harness();
    await h.settle();
    await h.push(_sessionInfo);
    h.notifier.dispose();
    await h.settle();
    expect(h.channel.sinkClosed, isTrue);
  });
}
