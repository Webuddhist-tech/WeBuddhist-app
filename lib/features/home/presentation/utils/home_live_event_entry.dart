import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';

/// What the home live pill should open on top of the event page.
///
/// The event page is pushed first so Back from either destination returns
/// there.
sealed class HomeLiveEventEntry {
  const HomeLiveEventEntry();
}

/// Pushed at once from the home pill. The event page loads the event, then
/// opens the live destination for a joined attendee, or stays put.
class HomeLiveEventResolveEntry extends HomeLiveEventEntry {
  const HomeLiveEventResolveEntry();
}

/// Same screen "Join online" opens: the event's plan or series with the stream.
class HomeLiveEventOnlineEntry extends HomeLiveEventEntry {
  const HomeLiveEventOnlineEntry(this.event);

  final GroupEvent event;
}

/// Today's plan, then the text the live recitation is on.
class HomeLiveEventInPersonEntry extends HomeLiveEventEntry {
  const HomeLiveEventInPersonEntry({
    required this.event,
    required this.liveTextId,
    required this.liveSegmentId,
  });

  final GroupEvent event;
  final String liveTextId;
  final String liveSegmentId;
}
