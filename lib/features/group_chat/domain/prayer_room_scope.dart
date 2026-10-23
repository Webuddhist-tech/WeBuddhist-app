import 'package:equatable/equatable.dart';

/// Whose prayer requests a sheet shows: an event's room or a space's room.
enum PrayerRoomKind { event, group }

/// Keys the prayer request providers; the same list, composer and socket
/// serve both an event and a space.
class PrayerRoomScope extends Equatable {
  const PrayerRoomScope.event(this.id) : kind = PrayerRoomKind.event;

  const PrayerRoomScope.group(this.id) : kind = PrayerRoomKind.group;

  final PrayerRoomKind kind;
  final String id;

  bool get isEvent => kind == PrayerRoomKind.event;

  bool get isGroup => kind == PrayerRoomKind.group;

  String? get eventId => isEvent ? id : null;

  String? get groupId => isGroup ? id : null;

  @override
  List<Object?> get props => [kind, id];
}
