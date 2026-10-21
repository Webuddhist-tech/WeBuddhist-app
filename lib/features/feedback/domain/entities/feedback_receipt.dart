/// What the backend says back about a message it stored.
class FeedbackReceipt {
  const FeedbackReceipt({this.roomId});

  /// The WeBuddhist Team chat the backend posted the message into, so "Open
  /// chat" can go straight there. Null until the backend sends it, and then
  /// the Chats list is the way in.
  final String? roomId;
}
