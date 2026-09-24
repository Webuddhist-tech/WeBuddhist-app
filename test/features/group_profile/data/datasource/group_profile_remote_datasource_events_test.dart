import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._onFetch);

  final Future<ResponseBody> Function(RequestOptions options) _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _onFetch(options);

  @override
  void close({bool force = false}) {}
}

GroupProfileRemoteDatasource _datasource(
  Future<ResponseBody> Function(RequestOptions) onFetch,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = _FakeAdapter(onFetch);
  return GroupProfileRemoteDatasource(dio: dio);
}

void main() {
  group('GroupProfileRemoteDatasource joinGroupEvent', () {
    test('sends the participation type when one is chosen', () async {
      Object? sent;
      final ds = _datasource((options) async {
        sent = options.data;
        expect(options.method, 'POST');
        expect(options.path, '/events/e1/participants');
        return ResponseBody.fromString('', 204);
      });

      await ds.joinGroupEvent(
        'e1',
        participationType: GroupEventParticipationType.offline,
      );

      expect(sent, {'participation_type': 'offline'});
    });

    test('sends no body when nothing was chosen', () async {
      Object? sent = 'unset';
      final ds = _datasource((options) async {
        sent = options.data;
        return ResponseBody.fromString('', 204);
      });

      await ds.joinGroupEvent('e1');

      expect(sent, isNull);
    });

    test('surfaces a rejected participation type', () async {
      final ds = _datasource(
        (options) async => ResponseBody.fromString(
          '{"detail":"Event is online-only"}',
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      expect(
        () => ds.joinGroupEvent(
          'e1',
          participationType: GroupEventParticipationType.offline,
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('GroupProfileRemoteDatasource approveGroupJoinRequest', () {
    test('posts to the approve path and parses APPROVED', () async {
      final ds = _datasource((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/cms/author/groups/g1/join-requests/r1/approve');
        return ResponseBody.fromString(
          '{"id":"r1","status":"APPROVED"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final decision = await ds.approveGroupJoinRequest('g1', requestId: 'r1');

      expect(decision.id, 'r1');
      expect(decision.status, GroupJoinRequestStatus.approved);
    });
  });

  group('GroupProfileRemoteDatasource rejectGroupJoinRequest', () {
    test('posts to the reject path and parses REJECTED', () async {
      final ds = _datasource((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/cms/author/groups/g1/join-requests/r1/reject');
        return ResponseBody.fromString(
          '{"id":"r1","status":"REJECTED"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final decision = await ds.rejectGroupJoinRequest('g1', requestId: 'r1');

      expect(decision.id, 'r1');
      expect(decision.status, GroupJoinRequestStatus.rejected);
    });
  });

  group('GroupProfileRemoteDatasource removeJoinedUser', () {
    test('posts the ban duration and reason', () async {
      Object? sent;
      final ds = _datasource((options) async {
        sent = options.data;
        expect(options.method, 'POST');
        expect(
          options.path,
          '/cms/author/groups/g1/joined-users/u1/remove',
        );
        return ResponseBody.fromString('{}', 200);
      });

      await ds.removeJoinedUser(
        'g1',
        userId: 'u1',
        banDurationDays: 7,
        reason: '  testing...  ',
      );

      expect(sent, {'ban_duration_days': 7, 'reason': 'testing...'});
    });

    test('sends a null reason when the note is blank', () async {
      Object? sent;
      final ds = _datasource((options) async {
        sent = options.data;
        return ResponseBody.fromString('{}', 200);
      });

      await ds.removeJoinedUser(
        'g1',
        userId: 'u1',
        banDurationDays: 365,
        reason: '   ',
      );

      expect(sent, {'ban_duration_days': 365, 'reason': null});
    });
  });

  group('groupJoinBanMessage', () {
    test('reads the ban message from a GROUP_BANNED body', () {
      expect(
        groupJoinBanMessage({
          'detail': {
            'error': 'GROUP_BANNED',
            'message':
                'You were removed from this group and cannot rejoin until 25 Sep 2026',
            'expires_at': '2026-09-25T10:11:15.952092+00:00',
          },
        }),
        'You were removed from this group and cannot rejoin until 25 Sep 2026',
      );
    });

    test('ignores other errors and a blank message', () {
      expect(
        groupJoinBanMessage({
          'detail': {'error': 'OTHER', 'message': 'nope'},
        }),
        isNull,
      );
      expect(
        groupJoinBanMessage({
          'detail': {'error': 'GROUP_BANNED', 'message': '  '},
        }),
        isNull,
      );
      expect(groupJoinBanMessage({'detail': 'Group not found'}), isNull);
    });
  });

  group('GroupProfileRemoteDatasource submitJoinRequest', () {
    test('throws the ban message on GROUP_BANNED', () async {
      final ds = _datasource(
        (options) async => ResponseBody.fromString(
          '{"detail":{"error":"GROUP_BANNED","message":"Cannot rejoin until 25 Sep 2026"}}',
          403,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      expect(
        () => ds.submitJoinRequest('g1', message: 'let me back'),
        throwsA(
          isA<AuthorizationException>().having(
            (error) => error.message,
            'message',
            'Cannot rejoin until 25 Sep 2026',
          ),
        ),
      );
    });
  });
}
