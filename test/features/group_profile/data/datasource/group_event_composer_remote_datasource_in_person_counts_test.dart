import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_event_composer_remote_datasource.dart';
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

GroupEventComposerRemoteDatasource _datasource(
  Future<ResponseBody> Function(RequestOptions) onFetch,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = _FakeAdapter(onFetch);
  return GroupEventComposerRemoteDatasource(dio: dio);
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

const _count = {
  'id': 'c1',
  'day': '2026-10-16',
  'count': 1000,
  'created_at': '2026-10-16T10:00:00Z',
};

void main() {
  group('GroupEventComposerRemoteDatasource in-person counts', () {
    test('lists a page of one accumulation', () async {
      late RequestOptions sent;
      final ds = _datasource((options) async {
        sent = options;
        return _json({
          'items': [_count],
          'total': 1,
          'skip': 0,
          'limit': 20,
          'total_count': 1000,
          'timezone': 'Asia/Kolkata',
        });
      });

      final list = await ds.fetchInPersonCounts(
        'e1',
        eventAccumulationId: 'ea1',
        skip: 20,
        limit: 20,
      );

      expect(sent.method, 'GET');
      expect(sent.path, '/cms/events/e1/in-person-counts');
      expect(sent.queryParameters, {
        'skip': 20,
        'limit': 20,
        'event_accumulation_id': 'ea1',
      });
      expect(list.items.single.count, 1000);
      expect(list.timezone, 'Asia/Kolkata');
    });

    test('a legacy accumulation without a link id sends no filter', () async {
      late RequestOptions sent;
      final ds = _datasource((options) async {
        sent = options;
        return _json(_count);
      });

      await ds.createInPersonCount(
        'e1',
        eventAccumulationId: '',
        day: '2026-10-16',
        count: 1000,
      );

      expect(sent.method, 'POST');
      expect(sent.queryParameters, isEmpty);
      expect(sent.data, {'day': '2026-10-16', 'count': 1000});
    });

    test('updates and deletes address the count by id', () async {
      final calls = <String>[];
      final ds = _datasource((options) async {
        calls.add(
          '${options.method} ${options.path}'
          ' ${options.queryParameters['event_accumulation_id']}',
        );
        return options.method == 'DELETE' ? _json({}, 204) : _json(_count);
      });

      await ds.updateInPersonCount(
        'e1',
        'c1',
        eventAccumulationId: 'ea1',
        day: '2026-10-16',
        count: 1200,
      );
      await ds.deleteInPersonCount('e1', 'c1', eventAccumulationId: 'ea1');

      expect(calls, [
        'PUT /cms/events/e1/in-person-counts/c1 ea1',
        'DELETE /cms/events/e1/in-person-counts/c1 ea1',
      ]);
    });

    test(
      'the API reason for a refused count is kept for the message',
      () async {
        final ds = _datasource(
          (options) async => _json({'detail': 'IN_PERSON_COUNT_EXISTS'}, 409),
        );

        await expectLater(
          ds.createInPersonCount(
            'e1',
            eventAccumulationId: 'ea1',
            day: '2026-10-16',
            count: 1,
          ),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              'IN_PERSON_COUNT_EXISTS',
            ),
          ),
        );
      },
    );
  });
}
