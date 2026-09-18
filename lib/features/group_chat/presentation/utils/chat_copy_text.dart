import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_message_time.dart';

/// What a Copy on [messages] puts on the clipboard.
///
/// One message copies its bare body, as before. Several copy a transcript in
/// WhatsApp's shape, oldest first, one line each:
///
/// ```
/// [12:00 PM] Pema: hello everyone
/// [12:01 PM] You: thank you
/// ```
///
/// [timeOf] and [nameOf] are injected so this stays free of `BuildContext`:
/// the caller formats the time exactly as the bubble paints it and labels the
/// viewer's own rows "You".
String chatCopyText(
  List<ChatMessageDTO> messages, {
  required String Function(ChatMessageDTO message) timeOf,
  required String Function(ChatMessageDTO message) nameOf,
}) {
  if (messages.isEmpty) return '';
  if (messages.length == 1) return messages.single.body;

  final oldestFirst = [...messages]
    ..sort((a, b) => a.createdAtLocal.compareTo(b.createdAtLocal));
  return oldestFirst
      .map((message) => '[${timeOf(message)}] ${nameOf(message)}: ${message.body}')
      .join('\n');
}
