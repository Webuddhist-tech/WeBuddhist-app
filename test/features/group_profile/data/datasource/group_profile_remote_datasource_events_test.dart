import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
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
}
