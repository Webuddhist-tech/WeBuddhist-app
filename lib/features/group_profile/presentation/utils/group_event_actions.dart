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
}

/// The event page's buttons, in display order. Before joining, the view
/// buttons explore the plan read-only and Join attends; once joined, the
/// practice buttons open it. After the event, everyone gets those view
/// buttons and Join is gone. Leaving lives in the ⋮ menu.
List<GroupEventAction> groupEventActionsFor(
  GroupEvent event, {
  required bool isAttending,
  required bool isPast,
}) {
  final hybrid = isGroupEventHybrid(event);
  final online = hybrid || isGroupEventOnline(event);
  final inPerson = hybrid || !isGroupEventOnline(event);

  if (isPast) {
    return [
      if (event.hasPuja && inPerson) GroupEventAction.viewInPerson,
      if (event.hasPuja && online) GroupEventAction.viewOnline,
    ];
  }

  if (isAttending) {
    if (!event.hasPuja) return const [];
    return [
      if (inPerson) GroupEventAction.practiceInPerson,
      if (online) GroupEventAction.practiceOnline,
    ];
  }
  return [
    if (event.hasPuja && inPerson) GroupEventAction.viewInPerson,
    if (event.hasPuja && online) GroupEventAction.viewOnline,
    GroupEventAction.join,
  ];
}

/// The ⋮ menu only holds "Leave event", which the page allows while the
/// event is still on.
bool showsGroupEventMenu({required bool isAttending, required bool isPast}) =>
    isAttending && !isPast;
