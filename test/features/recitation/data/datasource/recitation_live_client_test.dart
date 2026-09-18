import 'dart:convert';

import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecitationLiveClient.liveUri', () {
    test('uses wss and the event path under the REST base path', () {
      final uri = RecitationLiveClient.liveUri(
        restBaseUrl: 'https://api.example.com/api/v1',
        token: 'tok',
        eventId: 'ev1',
      );
      expect(uri.scheme, 'wss');
      expect(uri.host, 'api.example.com');
      expect(uri.path, '/api/v1/events/ev1/recitation/live');
      expect(uri.queryParameters, {'token': 'tok'});
    });

    test('maps http to ws and tolerates a trailing slash', () {
      final uri = RecitationLiveClient.liveUri(
        restBaseUrl: 'http://localhost:8000/api/v1/',
        token: 'tok',
        eventId: 'ev1',
      );
      expect(uri.scheme, 'ws');
      expect(uri.path, '/api/v1/events/ev1/recitation/live');
    });
  });

  group('RecitationLiveClient.parseFrame', () {
    test('parses session_info', () {
      final event = RecitationLiveClient.parseFrame(
        '{"type":"session_info","event_id":"ev1","is_operator":true}',
      );
      expect(event, isA<RecitationLiveSessionInfo>());
      final info = event! as RecitationLiveSessionInfo;
      expect(info.eventId, 'ev1');
      expect(info.isOperator, isTrue);
    });

    test('parses a full position frame', () {
      final event = RecitationLiveClient.parseFrame(
        '{"type":"position","event_id":"ev1","text_id":"t1",'
        '"segment_id":"s12","index":12,"round_number":3,'
        '"server_time":"2026-09-17T09:30:00Z","revision":57}',
      );
      expect(event, isA<RecitationLivePositionEvent>());
      final position = (event! as RecitationLivePositionEvent).position;
      expect(position.eventId, 'ev1');
      expect(position.textId, 't1');
      expect(position.segmentId, 's12');
      expect(position.index, 12);
      expect(position.roundNumber, 3);
      expect(position.serverTime, '2026-09-17T09:30:00Z');
      expect(position.revision, 57);
      expect(position.isValid, isTrue);
    });

    test('index and round_number are optional', () {
      final event = RecitationLiveClient.parseFrame(
        '{"type":"position","event_id":"ev1","text_id":"t1",'
        '"segment_id":"s1","revision":1}',
      );
      final position = (event! as RecitationLivePositionEvent).position;
      expect(position.index, isNull);
      expect(position.roundNumber, isNull);
      expect(position.isValid, isTrue);
    });

    test('a position without text or segment is not valid', () {
      final event = RecitationLiveClient.parseFrame(
        '{"type":"position","event_id":"ev1","revision":1}',
      );
      final position = (event! as RecitationLivePositionEvent).position;
      expect(position.isValid, isFalse);
    });

    test('parses session_ended and pong', () {
      expect(
        RecitationLiveClient.parseFrame('{"type":"session_ended"}'),
        isA<RecitationLiveSessionEnded>(),
      );
      expect(
        RecitationLiveClient.parseFrame('{"type":"pong"}'),
        isA<RecitationLivePong>(),
      );
    });

    test('parses error frames and flags the fatal ones', () {
      final fatal =
          RecitationLiveClient.parseFrame(
                '{"type":"error","code":"UNAUTHORIZED","message":"bad token"}',
              )!
              as RecitationLiveError;
      expect(fatal.code, 'UNAUTHORIZED');
      expect(fatal.message, 'bad token');
      expect(fatal.isFatal, isTrue);

      final transient =
          RecitationLiveClient.parseFrame(
                '{"type":"error","code":"SERVER_ERROR","message":"oops"}',
              )!
              as RecitationLiveError;
      expect(transient.isFatal, isFalse);
    });

    test('a bare detail body on connect is an error', () {
      final event =
          RecitationLiveClient.parseFrame('{"detail":"Not found","status":404}')!
              as RecitationLiveError;
      expect(event.code, '404');
      expect(event.message, 'Not found');
      expect(event.isFatal, isTrue);
    });

    test('unknown types and non-object payloads never throw', () {
      expect(
        RecitationLiveClient.parseFrame('{"type":"typing"}'),
        isA<RecitationLiveUnknown>(),
      );
      expect(RecitationLiveClient.parseFrame('not json'), isNull);
      expect(RecitationLiveClient.parseFrame('[1,2]'), isNull);
    });
  });

  test('encodePing is the documented ping frame', () {
    expect(jsonDecode(RecitationLiveClient.encodePing()), {'type': 'ping'});
  });

  test('positions order by revision, not by time', () {
    final older =
        (RecitationLiveClient.parseFrame(
                  '{"type":"position","text_id":"t","segment_id":"a",'
                  '"server_time":"2026-09-17T09:30:05Z","revision":5}',
                )!
                as RecitationLivePositionEvent)
            .position;
    final newer =
        (RecitationLiveClient.parseFrame(
                  '{"type":"position","text_id":"t","segment_id":"b",'
                  '"server_time":"2026-09-17T09:30:01Z","revision":6}',
                )!
                as RecitationLivePositionEvent)
            .position;
    expect(newer.isNewerThan(older), isTrue);
    expect(older.isNewerThan(newer), isFalse);
    expect(older.isNewerThan(null), isTrue);
  });
}
