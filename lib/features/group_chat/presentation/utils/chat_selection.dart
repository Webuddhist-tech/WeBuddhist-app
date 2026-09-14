import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';

/// How many rows a selection may hold. One place to tune: the snackbar that
/// explains a refused tap reads the number from here too.
///
/// Bounded so a multi-delete stays a short run of sequential calls and a
/// multi-copy stays a sane clipboard.
const int kChatMaxSelection = 10;

/// Which header actions a selection offers.
///
/// A disabled action is hidden rather than greyed, the way the old menu
/// omitted Report and Delete when they did not apply.
class ChatSelectionGates {
  const ChatSelectionGates({
    required this.canReply,
    required this.canCopy,
    required this.showDelete,
    required this.canDelete,
    required this.canReport,
    required this.showPill,
  });

  /// Exactly one message: a reply quotes one original.
  final bool canReply;

  /// Any number: one copies the bare body, several copy a transcript.
  final bool canCopy;

  /// At least one of the viewer's own messages is selected, so the Delete
  /// icon is drawn. Whether it is *enabled* is [canDelete]: a mixed selection
  /// shows it greyed rather than hiding it, so the reason it cannot fire is
  /// visible.
  final bool showDelete;

  /// Every selected message is the viewer's own and still stands, and no
  /// delete is already running. Deletion is sender-only on the server; the
  /// gate is here because the API answers a non-sender attempt generically.
  final bool canDelete;

  /// Exactly one message, someone else's, and the viewer's identity is known
  /// — until the profile has loaded nothing can be told apart from "mine".
  final bool canReport;

  /// The quick-reaction pill: one message only, gone the moment a second row
  /// joins.
  final bool showPill;
}

/// Works out the gates for [selected] as seen by the signed-in viewer.
///
/// [currentUserId] is the **backend** user id, the same id space as
/// `sender_id`; see [isSelfChatMessage] for why the JWT `sub` must not be
/// passed here.
///
/// [deleteInFlight] greys Delete while a request for this selection is still
/// running: the dialog is gone by then, and a second tap would send the same
/// ids again on top of the first.
ChatSelectionGates chatSelectionGates(
  List<ChatMessageDTO> selected, {
  String? currentUserId,
  String? currentUserEmail,
  bool deleteInFlight = false,
}) {
  final count = selected.length;
  final viewerKnown = isChatViewerKnown(
    currentUserId: currentUserId,
    currentUserEmail: currentUserEmail,
  );
  bool isSelf(ChatMessageDTO message) => isSelfChatMessage(
    senderId: message.senderId,
    senderEmail: message.senderEmail,
    currentUserId: currentUserId,
    currentUserEmail: currentUserEmail,
  );
  final allStanding = selected.every((message) => message.deletedAt == null);
  final anyOwn = viewerKnown && selected.any(isSelf);
  final allOwn = anyOwn && selected.every(isSelf);

  return ChatSelectionGates(
    canReply: count == 1 && allStanding,
    canCopy: count >= 1,
    showDelete: anyOwn && allStanding,
    canDelete: allOwn && allStanding && !deleteInFlight,
    canReport:
        count == 1 && viewerKnown && allStanding && !isSelf(selected.single),
    showPill: count == 1 && allStanding,
  );
}

/// Whether [message] may be part of a selection at all.
///
/// A tombstone offers nothing: no words to copy or quote, nothing left to
/// delete or report.
bool chatMessageIsSelectable(ChatMessageDTO message) =>
    message.deletedAt == null;

/// The ids in [selectedIds] that no longer belong in a selection, against
/// [messages] as the thread holds them now.
///
/// A row leaves the selection the moment it stops being selectable: it was
/// tombstoned by a `message_deleted` broadcast (or by this member's own
/// delete), or a refresh restarted the window without it. Left in, the
/// header would keep offering Reply and Copy on a message that no longer has
/// a body to quote or copy, and its count would name rows nothing can act on.
Set<String> chatSelectionStaleIds(
  Iterable<String> selectedIds,
  List<ChatMessageDTO> messages,
) {
  final byId = {for (final message in messages) message.id: message};
  final stale = <String>{};
  for (final id in selectedIds) {
    final message = byId[id];
    if (message == null || !chatMessageIsSelectable(message)) stale.add(id);
  }
  return stale;
}

/// Whether one more row fits under [kChatMaxSelection].
bool chatSelectionHasRoom(int currentCount) =>
    currentCount < kChatMaxSelection;
