import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/feedback/data/discord_feedback_client.dart';
import 'package:flutter_pecha/features/feedback/data/feedback_report.dart';
import 'package:flutter_test/flutter_test.dart';

FeedbackReport _report({FeedbackReporter? reporter, String message = 'Hi'}) {
  return FeedbackReport(
    message: message,
    imagePaths: const [],
    reporter: reporter,
    appVersion: '2.5.5 (120)',
    platform: 'ios 17.2',
    language: 'bo',
  );
}

Map<String, String> _fields(Map<String, dynamic> payload) {
  final embed = (payload['embeds'] as List).single as Map<String, dynamic>;
  return {
    for (final f in embed['fields'] as List)
      (f as Map)['name'] as String: f['value'] as String,
  };
}

void main() {
  group('DiscordFeedbackClient.buildPayload', () {
    test('suppresses every mention so user text cannot ping the channel', () {
      final payload = DiscordFeedbackClient.buildPayload(
        _report(message: '@everyone look'),
      );
      expect(payload['allowed_mentions'], {'parse': <String>[]});
    });

    test('guests are labelled and carry no identity fields', () {
      final payload = DiscordFeedbackClient.buildPayload(_report());
      final embed = (payload['embeds'] as List).single as Map;
      expect(embed.containsKey('timestamp'), isFalse);
      final fields = _fields(payload);
      expect(fields['User'], 'Guest');
      expect(fields.containsKey('Email'), isFalse);
      expect(fields.containsKey('User ID'), isFalse);
      expect(fields.containsKey('Environment'), isFalse);
      expect(fields['App version'], '2.5.5 (120)');
      expect(fields['Language'], 'bo');
    });

    test('signed-in users include name and email; blanks become a dash', () {
      final fields = _fields(
        DiscordFeedbackClient.buildPayload(
          _report(reporter: const FeedbackReporter(name: 'Tenzin')),
        ),
      );
      expect(fields['User'], 'Tenzin');
      expect(fields.containsKey('User ID'), isFalse);
      expect(fields['Email'], '—');
    });

    test('truncates the message to the embed description limit', () {
      final payload = DiscordFeedbackClient.buildPayload(
        _report(message: 'a' * 5000),
      );
      final embed = (payload['embeds'] as List).single as Map;
      expect((embed['description'] as String).length, 4096);
    });

    test('lists attachments with their ids and names', () {
      final payload = DiscordFeedbackClient.buildPayload(
        _report(),
        attachmentNames: ['feedback_1.jpg', 'feedback_2.png'],
      );
      expect(payload['attachments'], [
        {'id': 0, 'filename': 'feedback_1.jpg'},
        {'id': 1, 'filename': 'feedback_2.png'},
      ]);
    });
  });

  test('attachmentName keeps image extensions and falls back to jpg', () {
    expect(
      DiscordFeedbackClient.attachmentName(0, '/a/b/IMG.PNG'),
      'feedback_1.png',
    );
    expect(
      DiscordFeedbackClient.attachmentName(1, '/a/b/photo.heic'),
      'feedback_2.jpg',
    );
    expect(
      DiscordFeedbackClient.attachmentName(2, '/a/b/noext'),
      'feedback_3.jpg',
    );
  });

  test('send without a webhook fails as notConfigured', () async {
    final client = DiscordFeedbackClient(dio: Dio(), webhookUrl: null);
    await expectLater(
      client.send(_report()),
      throwsA(
        isA<FeedbackException>().having(
          (e) => e.failure,
          'failure',
          FeedbackFailure.notConfigured,
        ),
      ),
    );
  });
}
