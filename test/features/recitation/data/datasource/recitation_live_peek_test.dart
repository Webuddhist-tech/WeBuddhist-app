import 'dart:async';

import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_client.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_peek.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_live_position.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeChannel implements WebSocketChannel {
  _FakeChannel({this.closeNeverCompletes = false, this.closeFails = false});

  final incoming = StreamController<dynamic>();
  bool sinkClosed = false;

  /// Mimics a socket whose connect is still pending: closing it waits on
  /// the OS connect timeout.
  final bool closeNeverCompletes;

  /// Mimics a socket that errors while closing.
  final bool closeFails;

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
  void add(dynamic data) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    channel.sinkClosed = true;
    if (channel.closeNeverCompletes) return Completer<void>().future;
    if (channel.closeFails) return Future.error(StateError('close failed'));
    return Future.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _sessionInfo =
    '{"type":"session_info","event_id":"ev1","is_operator":false}';

const _position =
    '{"type":"position","event_id":"ev1","text_id":"t1",'
    '"segment_id":"s9","revision":3}';

Future<RecitationLivePosition?> _peek(
  _FakeChannel channel, {
  Duration snapshotGrace = const Duration(milliseconds: 80),
  Duration timeout = const Duration(milliseconds: 400),
}) {
  return peekRecitationLivePosition(
    client: RecitationLiveClient(connect: (_) => channel),
    uri: Uri.parse('ws://localhost/live'),
    snapshotGrace: snapshotGrace,
    timeout: timeout,
  );
}

void main() {
  test('returns the position the room already has', () async {
    final channel = _FakeChannel();
    final future = _peek(channel);
    channel.incoming.add(_sessionInfo);
    channel.incoming.add(_position);

    final position = await future;
    expect(position?.textId, 't1');
    expect(position?.segmentId, 's9');
    expect(channel.sinkClosed, isTrue);
  });

  test('returns null when session info is not followed by a position', () async {
    final channel = _FakeChannel();
    final future = _peek(
      channel,
      snapshotGrace: const Duration(milliseconds: 30),
    );
    channel.incoming.add(_sessionInfo);

    expect(await future, isNull);
    expect(channel.sinkClosed, isTrue);
  });

  test('returns null when the session has ended', () async {
    final channel = _FakeChannel();
    final future = _peek(channel);
    channel.incoming.add('{"type":"session_ended"}');

    expect(await future, isNull);
  });

  test('returns null when the socket is refused', () async {
    final channel = _FakeChannel();
    final future = _peek(channel);
    channel.incoming.add('{"detail":"unauthorized"}');

    expect(await future, isNull);
  });

  test('returns null when nothing arrives before the timeout', () async {
    final channel = _FakeChannel();
    final future = _peek(
      channel,
      timeout: const Duration(milliseconds: 40),
    );

    expect(await future, isNull);
    expect(channel.sinkClosed, isTrue);
  });

  test('returns at the timeout even when closing the socket stalls', () async {
    final channel = _FakeChannel(closeNeverCompletes: true);
    final position = await _peek(
      channel,
      timeout: const Duration(milliseconds: 40),
    ).timeout(const Duration(seconds: 2), onTimeout: () => fail('hung'));

    expect(position, isNull);
    expect(channel.sinkClosed, isTrue);
  });

  test('drops an error from closing the socket', () async {
    final channel = _FakeChannel(closeFails: true);
    final future = _peek(channel);
    channel.incoming.add(_sessionInfo);
    channel.incoming.add(_position);

    expect((await future)?.textId, 't1');
    // Let the unawaited close settle; an escaped error fails the test.
    await Future<void>.delayed(Duration.zero);
    expect(channel.sinkClosed, isTrue);
  });
}
