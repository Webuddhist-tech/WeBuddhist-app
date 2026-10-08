import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';

/// A button in the event page's action row.
enum GroupEventAction {
  /// Opens the in-person plan page read-only, without joining.
  viewInPerson,

  /// Opens the online plan page (live stream on top) read-only.
  viewOnline,

  join,
  practiceInPerson,
  practiceOnline,

  /// After the event: opens the plan the way the attendee already picked.
  practiceNow,
}

/// The event page's buttons, in display order. Before joining, the view
/// buttons explore the plan read-only and Join attends; once joined, the
/// practice buttons open it. Leaving lives in the ⋮ menu.
List<GroupEventAction> groupEventActionsFor(
  GroupEvent event, {
  required bool isAttending,
  required bool isPast,
}) {
  final hybrid = isGroupEventHybrid(event);
  final online = hybrid || isGroupEventOnline(event);
  final inPerson = hybrid || !isGroupEventOnline(event);

  if (isAttending) {
    if (!event.hasPuja) return const [];
    if (isPast) return const [GroupEventAction.practiceNow];
    return [
      if (inPerson) GroupEventAction.practiceInPerson,
      if (online) GroupEventAction.practiceOnline,
    ];
  }
  return [
    if (event.hasPuja && inPerson) GroupEventAction.viewInPerson,
    if (event.hasPuja && online) GroupEventAction.viewOnline,
    // Attending is closed once the event is over; exploring is not.
    if (!isPast) GroupEventAction.join,
  ];
}

/// The ⋮ menu only holds "Leave event", which the page allows while the
/// event is still on.
bool showsGroupEventMenu({required bool isAttending, required bool isPast}) =>
    isAttending && !isPast;
