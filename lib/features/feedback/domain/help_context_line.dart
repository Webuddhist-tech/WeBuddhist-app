import 'package:flutter_pecha/features/feedback/domain/entities/help_topic.dart';

/// Where a message in the WeBuddhist Team chat came from.
class HelpContext {
  const HelpContext({this.topic, this.photoCount = 0});

  final HelpTopic? topic;

  /// Photos sent with it. Chat cannot carry images, so they only reach the
  /// team through `/feedback`; the count tells the team to look there.
  final int photoCount;
}

/// A Team chat message split into its context line and what the user wrote.
class HelpContextMessage {
  const HelpContextMessage({required this.context, required this.body});

  final HelpContext context;
  final String body;
}

/// Opens the first line the backend writes into the Team chat for a message
/// sent from Help & contact.
const String helpContextPrefix = 'Sent from Help & contact';

final RegExp _photoPart = RegExp(r'^(\d+)\s+photos?$', caseSensitive: false);

/// Splits a Help & contact message into its context line and its text, or
/// returns null for any other message.
///
/// The backend writes the line in English, so the app can show it in the
/// viewer's language and any other client still reads it:
///
/// ```text
/// Sent from Help & contact · Help or collaborate · 2 photos
///
/// I translate dharma texts into Nepali…
/// ```
///
/// The topic and photo parts are each optional. A part this app does not
/// recognise is skipped rather than shown, so a label the backend adds later
/// cannot leak English into a translated line.
HelpContextMessage? parseHelpContext(String body) {
  final newline = body.indexOf('\n');
  final firstLine = (newline == -1 ? body : body.substring(0, newline)).trim();

  final parts = firstLine.split('·').map((part) => part.trim()).toList();
  if (parts.first != helpContextPrefix) return null;

  HelpTopic? topic;
  var photoCount = 0;
  for (final part in parts.skip(1)) {
    final photos = _photoPart.firstMatch(part);
    if (photos != null) {
      // tryParse: anyone can type this line, and a count too large for an
      // int must not throw while a chat row or preview is being built.
      photoCount = int.tryParse(photos.group(1)!) ?? 0;
      continue;
    }
    topic ??= HelpTopic.fromCanonicalLabel(part);
  }

  final rest = newline == -1 ? '' : body.substring(newline + 1);
  return HelpContextMessage(
    context: HelpContext(topic: topic, photoCount: photoCount),
    body: rest.replaceFirst(RegExp(r'^\s*\n'), '').trimRight(),
  );
}
