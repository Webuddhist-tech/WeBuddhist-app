import 'package:flutter_pecha/features/feedback/domain/entities/help_topic.dart';
import 'package:flutter_pecha/features/feedback/domain/help_context_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseHelpContext', () {
    test('reads the topic, the photo count and the message', () {
      final parsed = parseHelpContext(
        'Sent from Help & contact · Help or collaborate · 2 photos\n'
        '\n'
        'I translate dharma texts into Nepali.',
      );

      expect(parsed, isNotNull);
      expect(parsed!.context.topic, HelpTopic.helpCollaborate);
      expect(parsed.context.photoCount, 2);
      expect(parsed.body, 'I translate dharma texts into Nepali.');
    });

    test('the topic and the photos are each optional', () {
      final bare = parseHelpContext('Sent from Help & contact\n\nHello');
      expect(bare!.context.topic, isNull);
      expect(bare.context.photoCount, 0);
      expect(bare.body, 'Hello');

      final onePhoto = parseHelpContext(
        'Sent from Help & contact · 1 photo\n\nScreen goes blank',
      );
      expect(onePhoto!.context.topic, isNull);
      expect(onePhoto.context.photoCount, 1);
    });

    test('maps every topic label back to its topic', () {
      for (final topic in HelpTopic.values) {
        final parsed = parseHelpContext(
          'Sent from Help & contact · ${topic.canonicalLabel}\n\nx',
        );
        expect(parsed!.context.topic, topic);
      }
    });

    test('skips a part it does not know rather than failing', () {
      final parsed = parseHelpContext(
        'Sent from Help & contact · Billing · Report a problem\n\nx',
      );
      expect(parsed!.context.topic, HelpTopic.reportProblem);
    });

    test('keeps the message lines, and works without the blank line', () {
      final parsed = parseHelpContext(
        'Sent from Help & contact · Idea or feedback\r\nLine one\nLine two\n',
      );
      expect(parsed!.body, 'Line one\nLine two');
    });

    test('a context line with nothing under it has an empty body', () {
      expect(parseHelpContext('Sent from Help & contact')!.body, '');
    });

    test('any other message is not a Help & contact message', () {
      expect(parseHelpContext('Thank you, Tenzin!'), isNull);
      expect(parseHelpContext(''), isNull);
      // Only the first line counts.
      expect(parseHelpContext('Hi\nSent from Help & contact'), isNull);
      // A user quoting the phrase mid-sentence is not a context line.
      expect(parseHelpContext('Sent from Help & contact, I think?'), isNull);
    });

    test('a photo count too large for an int reads as none', () {
      final parsed = parseHelpContext(
        'Sent from Help & contact · 99999999999999999999 photos\n\nHi',
      );
      expect(parsed!.context.photoCount, 0);
      expect(parsed.body, 'Hi');
    });
  });
}
