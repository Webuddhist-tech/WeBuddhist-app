/// Document paths the backend writes signals to. Nothing can be listed, so
/// every listener names its document.
abstract final class SignalPaths {
  static String chatRoom(String roomId) => 'chat_rooms/$roomId';

  static String group(String groupId) => 'groups/$groupId';

  static String groupPost(String groupId, String postId) =>
      'groups/$groupId/posts/$postId';

  static const String featuredEvents = 'app/events';
}

abstract final class SignalFields {
  static const String messagesChangedAt = 'messages_changed_at';
  static const String reactionsChangedAt = 'reactions_changed_at';
  static const String prayersChangedAt = 'prayers_changed_at';
  static const String closedAt = 'closed_at';
  static const String postsChangedAt = 'posts_changed_at';
  static const String eventsChangedAt = 'events_changed_at';
  static const String commentsChangedAt = 'comments_changed_at';
  static const String featuredChangedAt = 'featured_changed_at';
}
