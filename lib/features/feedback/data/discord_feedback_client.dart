import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/feedback/data/feedback_report.dart';

enum FeedbackFailure { notConfigured, offline, rateLimited, tooLarge, failed }

class FeedbackException implements Exception {
  const FeedbackException(this.failure, [this.cause]);

  final FeedbackFailure failure;
  final Object? cause;

  @override
  String toString() => 'FeedbackException($failure, $cause)';
}

/// Posts [FeedbackReport]s to a Discord channel through an incoming webhook.
///
/// The [Dio] passed in must not carry the app's auth interceptors: the
/// request goes to discord.com and must never include the user's API token.
class DiscordFeedbackClient {
  DiscordFeedbackClient({required Dio dio, required String? webhookUrl})
    : _dio = dio,
      _webhookUrl = webhookUrl;

  final Dio _dio;
  final String? _webhookUrl;

  /// Discord rejects uploads above 10 MB per message on unboosted servers.
  static const int maxTotalUploadBytes = 10 * 1024 * 1024;

  static const int _maxDescription = 4096;
  static const int _maxFieldValue = 1024;
  static const int _embedColor = 0xF1B24A;

  bool get isConfigured => _webhookUrl != null;

  Future<void> send(FeedbackReport report) async {
    final url = _webhookUrl;
    if (url == null) {
      throw const FeedbackException(FeedbackFailure.notConfigured);
    }

    final fileNames = [
      for (final (i, path) in report.imagePaths.indexed)
        attachmentName(i, path),
    ];

    var totalBytes = 0;
    final files = <MapEntry<String, MultipartFile>>[];
    for (final (i, path) in report.imagePaths.indexed) {
      totalBytes += await File(path).length();
      files.add(
        MapEntry(
          'files[$i]',
          await MultipartFile.fromFile(
            path,
            filename: fileNames[i],
            contentType: _mediaTypeFor(fileNames[i]),
          ),
        ),
      );
    }
    if (totalBytes > maxTotalUploadBytes) {
      throw const FeedbackException(FeedbackFailure.tooLarge);
    }

    final form =
        FormData()
          ..fields.add(
            MapEntry(
              'payload_json',
              jsonEncode(buildPayload(report, attachmentNames: fileNames)),
            ),
          )
          ..files.addAll(files);

    try {
      await _dio.post<void>(
        url,
        data: form,
        queryParameters: const {'wait': 'true'},
      );
    } on DioException catch (e) {
      throw FeedbackException(_classify(e), e);
    }
  }

  /// Discord webhook body. Attachments are listed so their filenames are kept
  /// and they render as images under the embed.
  static Map<String, dynamic> buildPayload(
    FeedbackReport report, {
    List<String> attachmentNames = const [],
  }) {
    final reporter = report.reporter;
    return {
      // User-written text must never ping @everyone / roles / users.
      'allowed_mentions': {'parse': <String>[]},
      'embeds': [
        {
          'description': _truncate(report.message, _maxDescription),
          'color': _embedColor,
          'fields': [
            if (reporter != null) _field('Email', reporter.email),
            _field('App version', report.appVersion),
            _field('Platform', report.platform),
          ],
        },
      ],
      if (attachmentNames.isNotEmpty)
        'attachments': [
          for (final (i, name) in attachmentNames.indexed)
            {'id': i, 'filename': name},
        ],
    };
  }

  static String attachmentName(int index, String path) {
    final dot = path.lastIndexOf('.');
    final ext = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
    const known = {'jpg', 'jpeg', 'png', 'gif', 'webp'};
    return 'feedback_${index + 1}.${known.contains(ext) ? ext : 'jpg'}';
  }

  static Map<String, dynamic> _field(String name, String? value) {
    final text = value == null || value.trim().isEmpty ? '—' : value.trim();
    return {
      'name': name,
      'value': _truncate(text, _maxFieldValue),
      'inline': true,
    };
  }

  static String _truncate(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max - 1)}…';

  static DioMediaType _mediaTypeFor(String fileName) {
    final ext = fileName.substring(fileName.lastIndexOf('.') + 1);
    return DioMediaType('image', ext == 'jpg' ? 'jpeg' : ext);
  }

  static FeedbackFailure _classify(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return FeedbackFailure.offline;
      case DioExceptionType.badResponse:
        return switch (e.response?.statusCode) {
          429 => FeedbackFailure.rateLimited,
          413 => FeedbackFailure.tooLarge,
          _ => FeedbackFailure.failed,
        };
      default:
        return e.error is SocketException
            ? FeedbackFailure.offline
            : FeedbackFailure.failed;
    }
  }
}
