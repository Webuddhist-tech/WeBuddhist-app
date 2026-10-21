import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/network/interceptors/retry_interceptor.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/feedback_receipt.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/feedback_report.dart';

/// `POST /feedback`: stores the signed-in user's feedback. The backend then
/// forwards it to Discord, so the webhook stays on the server.
class FeedbackRemoteDatasource {
  FeedbackRemoteDatasource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('FeedbackRemoteDatasource');

  /// The backend's limit across all images, which is also Discord's upload
  /// cap.
  static const int maxTotalImageBytes = 10 * 1024 * 1024;

  /// [ValidationException.code] for images over [maxTotalImageBytes], whether
  /// caught here before uploading or answered by the backend with a 413.
  static const String tooLargeCode = 'feedback_too_large';

  /// Up to 10 MB of images on a slow connection needs more than the 30 s
  /// default.
  static const Duration _sendTimeout = Duration(seconds: 60);

  /// The backend stores the images in S3 and commits the row before it
  /// answers, and the tail of the upload can still be in flight when Dio
  /// starts this clock. Timing out after the commit would report a failure
  /// for saved feedback, and the user's resend would store it twice.
  static const Duration _receiveTimeout = Duration(seconds: 60);

  Future<FeedbackReceipt> submit(FeedbackReport report) async {
    var totalBytes = 0;
    for (final path in report.imagePaths) {
      totalBytes += await File(path).length();
    }
    if (totalBytes > maxTotalImageBytes) {
      throw const ValidationException(
        'Feedback images are too large',
        code: tooLargeCode,
      );
    }

    try {
      final response = await dio.post<Object?>(
        '/feedback',
        data: await buildForm(report),
        options: Options(
          sendTimeout: _sendTimeout,
          receiveTimeout: _receiveTimeout,
          // A timeout after the backend committed the row would store it, and
          // post it to Discord, a second time.
          extra: {RetryInterceptor.noRetryKey: true},
        ),
      );
      return receiptFrom(response.data);
    } on DioException catch (e) {
      _logger.error('Dio error in submit', e);
      // The error interceptor turns a 413 into a generic server error.
      if (e.response?.statusCode == 413) {
        throw const ValidationException(
          'Feedback images are too large',
          code: tooLargeCode,
        );
      }
      rethrow;
    }
  }

  /// Reads the 201 body. Only `room_id` is used, and the backend does not
  /// send it yet, so anything else — no body, no field, a non-string — is a
  /// receipt without a room rather than an error: the feedback is stored
  /// either way.
  static FeedbackReceipt receiptFrom(Object? data) {
    if (data is! Map) return const FeedbackReceipt();
    final roomId = data['room_id'];
    if (roomId is! String || roomId.trim().isEmpty) {
      return const FeedbackReceipt();
    }
    return FeedbackReceipt(roomId: roomId.trim());
  }

  /// The multipart body. Every image goes under the plain field name
  /// `images`, one part per file: the backend ignores `images[]` and
  /// `files[0]`. `topic` is a slug; a backend that does not know the field
  /// yet ignores it.
  static Future<FormData> buildForm(FeedbackReport report) async {
    final topic = report.topic;
    final form =
        FormData()
          ..fields.addAll([
            MapEntry('content', report.message),
            MapEntry('platform', report.platform),
            MapEntry('app_version', report.appVersion),
            if (topic != null) MapEntry('topic', topic.slug),
          ]);
    for (final (i, path) in report.imagePaths.indexed) {
      final name = attachmentName(i, path);
      form.files.add(
        MapEntry(
          'images',
          await MultipartFile.fromFile(
            path,
            filename: name,
            contentType: _mediaTypeFor(name),
          ),
        ),
      );
    }
    return form;
  }

  static String attachmentName(int index, String path) {
    final dot = path.lastIndexOf('.');
    final ext = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
    const known = {'jpg', 'jpeg', 'png', 'gif', 'webp'};
    return 'feedback_${index + 1}.${known.contains(ext) ? ext : 'jpg'}';
  }

  static DioMediaType _mediaTypeFor(String fileName) {
    final ext = fileName.substring(fileName.lastIndexOf('.') + 1);
    return DioMediaType('image', ext == 'jpg' ? 'jpeg' : ext);
  }
}
