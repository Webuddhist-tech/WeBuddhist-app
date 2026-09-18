import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_report_reason.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_test/flutter_test.dart';

const _offTopic = 'Off-topic or disruptive';

void main() {
  group('chatReportReasonWireValue', () {
    test('maps each reason to a value the API accepts', () {
      // The six the spec declares; anything else is a 422.
      const accepted = {
        'SPAM',
        'HARASSMENT',
        'HATE_SPEECH',
        'INAPPROPRIATE',
        'INAPPROPRIATE_LANGUAGE',
        'OTHER',
      };

      for (final reason in kChatReportReasons) {
        expect(accepted, contains(chatReportReasonWireValue(reason)));
      }
    });

    test('the four reasons with a value of their own keep it', () {
      expect(
        chatReportReasonWireValue(ChatReportReason.harassment),
        'HARASSMENT',
      );
      expect(
        chatReportReasonWireValue(ChatReportReason.hateSpeech),
        'HATE_SPEECH',
      );
      expect(
        chatReportReasonWireValue(ChatReportReason.sexualContent),
        'INAPPROPRIATE',
      );
      expect(chatReportReasonWireValue(ChatReportReason.spam), 'SPAM');
    });

    test('off-topic and something-else share OTHER', () {
      expect(chatReportReasonWireValue(ChatReportReason.offTopic), 'OTHER');
      expect(
        chatReportReasonWireValue(ChatReportReason.somethingElse),
        'OTHER',
      );
    });

    test('every reason in the picker is mapped', () {
      expect(kChatReportReasons, hasLength(ChatReportReason.values.length));
    });
  });

  group('chatReportDescription', () {
    test('off-topic carries its label, since OTHER alone loses it', () {
      // Without this a moderator sees off-topic and something-else as one
      // bucket, because the wire value is the same for both.
      expect(
        chatReportDescription(
          ChatReportReason.offTopic,
          offTopicLabel: _offTopic,
        ),
        _offTopic,
      );
    });

    test('the label wins even if a note somehow came along', () {
      expect(
        chatReportDescription(
          ChatReportReason.offTopic,
          note: 'ignored',
          offTopicLabel: _offTopic,
        ),
        _offTopic,
      );
    });

    test('a reason with nothing to add sends no description', () {
      expect(
        chatReportDescription(ChatReportReason.spam, offTopicLabel: _offTopic),
        isNull,
      );
      expect(
        chatReportDescription(
          ChatReportReason.somethingElse,
          note: '   ',
          offTopicLabel: _offTopic,
        ),
        isNull,
      );
    });

    test('a note is trimmed', () {
      expect(
        chatReportDescription(
          ChatReportReason.somethingElse,
          note: '  they keep insulting people  ',
          offTopicLabel: _offTopic,
        ),
        'they keep insulting people',
      );
    });

    test('a note longer than the cap is cut to it', () {
      // The field limits typing, but nothing may send more than the counter
      // claimed — an open IME composition can run past the formatter.
      final long = 'a' * (kChatReportNoteLimit + 50);

      expect(
        chatReportDescription(
          ChatReportReason.somethingElse,
          note: long,
          offTopicLabel: _offTopic,
        ),
        hasLength(kChatReportNoteLimit),
      );
    });

    test('the cap counts characters as the member and the counter do, not '
        'code units', () {
      // A stacked Tibetan syllable is four grapheme clusters but seven code
      // units. Forty of them read 160 on the counter and must go out whole.
      const syllable = 'བསྒྲུབས';
      final under = syllable * 40;
      expect(under.characters.length, 160);
      expect(under.length, greaterThan(kChatReportNoteLimit));
      expect(
        chatReportDescription(
          ChatReportReason.somethingElse,
          note: under,
          offTopicLabel: _offTopic,
        ),
        under,
      );

      // Sixty read 240: cut to 200 characters, on a syllable boundary, never
      // inside a cluster.
      final over = chatReportDescription(
        ChatReportReason.somethingElse,
        note: syllable * 60,
        offTopicLabel: _offTopic,
      )!;
      expect(over.characters.length, kChatReportNoteLimit);
      expect(over, syllable * 50);

      // Emoji are two code units each; 200 of them are exactly the cap.
      final emoji = '😀' * kChatReportNoteLimit;
      expect(
        chatReportDescription(
          ChatReportReason.somethingElse,
          note: emoji,
          offTopicLabel: _offTopic,
        ),
        emoji,
      );
    });
  });

  group('canSubmitChatReport', () {
    test('nothing chosen cannot be submitted', () {
      expect(canSubmitChatReport(reason: null), isFalse);
    });

    test('a plain reason submits on its own', () {
      expect(canSubmitChatReport(reason: ChatReportReason.spam), isTrue);
      expect(canSubmitChatReport(reason: ChatReportReason.offTopic), isTrue);
    });

    test('something else needs a note with something in it', () {
      expect(
        canSubmitChatReport(reason: ChatReportReason.somethingElse),
        isFalse,
      );
      expect(
        canSubmitChatReport(
          reason: ChatReportReason.somethingElse,
          note: '   \n ',
        ),
        isFalse,
      );
      expect(
        canSubmitChatReport(
          reason: ChatReportReason.somethingElse,
          note: 'because',
        ),
        isTrue,
      );
    });

    test('only something else asks for a note', () {
      for (final reason in kChatReportReasons) {
        expect(
          chatReportNeedsNote(reason),
          reason == ChatReportReason.somethingElse,
          reason: '$reason',
        );
      }
    });
  });
}
