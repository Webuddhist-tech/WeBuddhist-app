import 'package:flutter/widgets.dart' show StringCharacters;

/// A reason the member can pick when reporting a message.
///
/// The design offers six and `ChatMessageReportReason` on the wire has six,
/// but they do not line up: there is no off-topic value, and the enum's
/// `INAPPROPRIATE_LANGUAGE` is the profanity code the send path raises over
/// the socket rather than something a member would choose.
enum ChatReportReason {
  harassment,
  hateSpeech,
  sexualContent,
  spam,
  offTopic,
  somethingElse,
}

/// Presentation order, as drawn.
const List<ChatReportReason> kChatReportReasons = [
  ChatReportReason.harassment,
  ChatReportReason.hateSpeech,
  ChatReportReason.sexualContent,
  ChatReportReason.spam,
  ChatReportReason.offTopic,
  ChatReportReason.somethingElse,
];

/// The `ChatMessageReportReason` value sent for [reason].
String chatReportReasonWireValue(ChatReportReason reason) {
  switch (reason) {
    case ChatReportReason.harassment:
      return 'HARASSMENT';
    case ChatReportReason.hateSpeech:
      return 'HATE_SPEECH';
    case ChatReportReason.sexualContent:
      return 'INAPPROPRIATE';
    case ChatReportReason.spam:
      return 'SPAM';
    // No off-topic value exists, so both of these are OTHER on the wire and
    // the description is what tells them apart — see [chatReportDescription].
    case ChatReportReason.offTopic:
    case ChatReportReason.somethingElse:
      return 'OTHER';
  }
}

/// Whether picking [reason] asks for a note before it can be submitted.
bool chatReportNeedsNote(ChatReportReason reason) =>
    reason == ChatReportReason.somethingElse;

/// The longest note the sheet accepts, in characters as the member sees them
/// — grapheme clusters, the unit the field's formatter and counter use too.
/// The wire has no limit; this is the design's, so the counter and what is
/// sent can never disagree.
const int kChatReportNoteLimit = 200;

/// The `description` sent alongside the reason.
///
/// Null unless there is something to say. "Off-topic or disruptive" carries its
/// own label because it shares `OTHER` with "Something else": without it a
/// moderator sees two different complaints as one bucket. [offTopicLabel] is
/// passed in so the string stays localised.
String? chatReportDescription(
  ChatReportReason reason, {
  String? note,
  required String offTopicLabel,
}) {
  if (reason == ChatReportReason.offTopic) return offTopicLabel;

  final trimmed = note?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  // Cut on grapheme clusters, not code units: a stacked Tibetan syllable or
  // an emoji is one character to the member and the counter but several to
  // `String.length`, and a code-unit cut lands inside one.
  return trimmed.characters.take(kChatReportNoteLimit).toString();
}

/// Whether the sheet can submit yet.
///
/// Nothing chosen means nothing to send; "Something else" with an empty note
/// says no more than the reason already does.
bool canSubmitChatReport({required ChatReportReason? reason, String? note}) {
  if (reason == null) return false;
  if (!chatReportNeedsNote(reason)) return true;
  return (note?.trim() ?? '').isNotEmpty;
}
