import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/env.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/feedback/data/discord_feedback_client.dart';
import 'package:flutter_pecha/features/feedback/data/feedback_report.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Standalone Dio: the shared app client would attach the user's auth token.
final _feedbackDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
});

final discordFeedbackClientProvider = Provider<DiscordFeedbackClient>((ref) {
  return DiscordFeedbackClient(
    dio: ref.watch(_feedbackDioProvider),
    webhookUrl: Env.discordFeedbackWebhookUrl,
  );
});

final sendFeedbackProvider = Provider<SendFeedback>(SendFeedback.new);

/// Attaches the current user, app and device context to a message and sends
/// it. Throws [FeedbackException] on failure.
class SendFeedback {
  SendFeedback(this._ref);

  final Ref _ref;

  Future<void> call({
    required String message,
    List<String> imagePaths = const [],
  }) async {
    final client = _ref.read(discordFeedbackClientProvider);
    await client.send(
      FeedbackReport(
        message: message,
        imagePaths: imagePaths,
        reporter: _reporter(),
        appVersion: await _appVersion(),
        platform: _platform(),
      ),
    );
  }

  FeedbackReporter? _reporter() {
    final auth = _ref.read(authProvider);
    final user = _ref.read(userProvider).user;
    if (!auth.isLoggedIn || auth.isGuest || user == null) return null;
    return FeedbackReporter(email: user.email);
  }

  Future<String> _appVersion() async {
    try {
      final info = await _ref.read(packageInfoProvider.future);
      if (info.version.isEmpty) return 'unknown';
      return info.buildNumber.isEmpty
          ? info.version
          : '${info.version} (${info.buildNumber})';
    } catch (_) {
      return 'unknown';
    }
  }

  String _platform() {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return 'unknown';
    }
  }
}
