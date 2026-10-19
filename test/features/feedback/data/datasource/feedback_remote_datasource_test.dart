import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/network/interceptors/retry_interceptor.dart';
import 'package:flutter_pecha/features/feedback/data/datasource/feedback_remote_datasource.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/feedback_report.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/help_topic.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._onFetch);

  final Future<ResponseBody> Function(RequestOptions options) _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Read the body like a real adapter would, so the image files get closed
    // (Windows can't delete the temp dir while one is open).
    await requestStream?.drain<void>();
    return _onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Object data, {int statusCode = 201}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

FeedbackRemoteDatasource _datasource(
  Future<ResponseBody> Function(RequestOptions) onFetch,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = _FakeAdapter(onFetch);
  return FeedbackRemoteDatasource(dio: dio);
}

FeedbackReport _report({List<String> imagePaths = const []}) {
  return FeedbackReport(
    message: 'The timer stops when the screen locks.',
    imagePaths: imagePaths,
    appVersion: '2.5.5 (120)',
    platform: 'android 14',
  );
}

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('feedback_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  String image(String name, {int bytes = 16}) {
    final file = File('${tmp.path}${Platform.pathSeparator}$name')
      ..writeAsBytesSync(Uint8List(bytes));
    return file.path;
  }

  group('buildForm', () {
    test('sends the message and device context as text fields', () async {
      final form = await FeedbackRemoteDatasource.buildForm(_report());

      expect(Map.fromEntries(form.fields), {
        'content': 'The timer stops when the screen locks.',
        'platform': 'android 14',
        'app_version': '2.5.5 (120)',
      });
      expect(form.files, isEmpty);
    });

    test('puts every image under the plain name `images`', () async {
      final form = await FeedbackRemoteDatasource.buildForm(
        _report(
          imagePaths: [image('a.PNG'), image('b.jpg'), image('c.heic')],
        ),
      );

      expect(form.files.map((f) => f.key), ['images', 'images', 'images']);
      expect(form.files.map((f) => f.value.filename), [
        'feedback_1.png',
        'feedback_2.jpg',
        'feedback_3.jpg',
      ]);
      expect(form.files.map((f) => f.value.contentType?.mimeType), [
        'image/png',
        'image/jpeg',
        'image/jpeg',
      ]);
    });

    test('sends a picked Help & contact topic as its slug', () async {
      final form = await FeedbackRemoteDatasource.buildForm(
        const FeedbackReport(
          message: 'I translate into Nepali',
          imagePaths: [],
          appVersion: '2.5.5 (120)',
          platform: 'android 14',
          topic: HelpTopic.helpCollaborate,
        ),
      );

      expect(Map.fromEntries(form.fields)['topic'], 'help_collaborate');
    });
  });

  group('receiptFrom', () {
    test('reads the Team chat room the backend posted into', () {
      expect(
        FeedbackRemoteDatasource.receiptFrom({
          'id': 'f1',
          'room_id': ' r1 ',
        }).roomId,
        'r1',
      );
    });

    test('a body without a usable room_id is a receipt with no room', () {
      for (final data in <Object?>[
        null,
        'ok',
        {'id': 'f1'},
        {'room_id': ''},
        {'room_id': 42},
      ]) {
        expect(FeedbackRemoteDatasource.receiptFrom(data).roomId, isNull);
      }
    });
  });

  test('attachmentName keeps image extensions and falls back to jpg', () {
    expect(FeedbackRemoteDatasource.attachmentName(0, '/x/a.webp'),
        'feedback_1.webp');
    expect(FeedbackRemoteDatasource.attachmentName(1, '/x/b.GIF'),
        'feedback_2.gif');
    expect(FeedbackRemoteDatasource.attachmentName(2, '/x/no_extension'),
        'feedback_3.jpg');
  });

  group('submit', () {
    test('posts to /feedback without network retries', () async {
      late RequestOptions sent;
      final datasource = _datasource((options) async {
        sent = options;
        return _jsonBody({'id': 'f1'});
      });

      await datasource.submit(_report(imagePaths: [image('a.png')]));

      expect(sent.method, 'POST');
      expect(sent.path, '/feedback');
      expect(sent.data, isA<FormData>());
      expect(sent.extra[RetryInterceptor.noRetryKey], isTrue);
      expect(sent.sendTimeout, const Duration(seconds: 60));
      expect(sent.receiveTimeout, const Duration(seconds: 60));
    });

    test('returns the room id from the 201 body', () async {
      final datasource = _datasource(
        (_) async => _jsonBody({'id': 'f1', 'room_id': 'team-room'}),
      );

      final receipt = await datasource.submit(_report());

      expect(receipt.roomId, 'team-room');
    });

    test('refuses images over 10 MB before uploading anything', () async {
      var fetched = false;
      final datasource = _datasource((_) async {
        fetched = true;
        return _jsonBody({});
      });

      await expectLater(
        datasource.submit(
          _report(
            imagePaths: [
              image('a.jpg', bytes: 6 * 1024 * 1024),
              image('b.jpg', bytes: 4 * 1024 * 1024 + 1),
            ],
          ),
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            FeedbackRemoteDatasource.tooLargeCode,
          ),
        ),
      );
      expect(fetched, isFalse);
    });

    test('a 413 from the backend is reported as too large', () async {
      final datasource = _datasource(
        (_) async => _jsonBody({
          'detail': 'Attached images must be at most 10 MB in total.',
        }, statusCode: 413),
      );

      await expectLater(
        datasource.submit(_report()),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            FeedbackRemoteDatasource.tooLargeCode,
          ),
        ),
      );
    });

    test('other errors are rethrown for the repository to map', () async {
      final datasource = _datasource(
        (_) async => _jsonBody({
          'detail': "Attachment 'feedback_1.jpg' is not a valid image.",
        }, statusCode: 400),
      );

      await expectLater(
        datasource.submit(_report()),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });
  });
}
