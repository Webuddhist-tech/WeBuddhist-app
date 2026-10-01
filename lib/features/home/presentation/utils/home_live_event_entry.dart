import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// What the home live pill should open on top of the event page.
///
/// The event page is pushed first so Back from either destination returns
/// there.
sealed class HomeLiveEventEntry {
  const HomeLiveEventEntry();
}

/// Same screen "Join online" opens: the event's plan or series with the stream.
class HomeLiveEventOnlineEntry extends HomeLiveEventEntry {
  const HomeLiveEventOnlineEntry(this.event);

  final GroupEvent event;
}

/// The text the live recitation is currently on, with segment highlighting.
class HomeLiveEventInPersonEntry extends HomeLiveEventEntry {
  const HomeLiveEventInPersonEntry({
    required this.textId,
    required this.navigationContext,
  });

  final String textId;
  final NavigationContext navigationContext;
}
