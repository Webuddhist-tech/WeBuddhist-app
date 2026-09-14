import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class GroupEventLink {
  final String id;
  final String type;
  final String url;
  final String? label;
  final String? language;
  final int displayOrder;

  const GroupEventLink({
    required this.id,
    required this.type,
    required this.url,
    this.label,
    this.language,
    this.displayOrder = 0,
  });
}

class GroupEventParticipant {
  final String userId;
  final DateTime? createdAt;
  final String? username;
  final String? fullname;
  final String? avatarUrl;

  const GroupEventParticipant({
    required this.userId,
    this.createdAt,
    this.username,
    this.fullname,
    this.avatarUrl,
  });

  String get displayName {
    final name = fullname?.trim();
    if (name != null && name.isNotEmpty) return name;
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) return handle;
    return 'Participant';
  }
}

class GroupEventLocation {
  final String id;
  final String groupId;
  final String name;
  final double? latitude;
  final double? longitude;

  const GroupEventLocation({
    required this.id,
    required this.groupId,
    required this.name,
    this.latitude,
    this.longitude,
  });
}

/// Plan, series, accumulator or recitation collection attached to an event.
class GroupEventPracticeRef {
  final String id;
  final String name;
  final String? imageUrl;

  const GroupEventPracticeRef({
    required this.id,
    required this.name,
    this.imageUrl,
  });
}

class GroupEventRecurrence {
  /// "DAILY", "WEEKLY", "MONTHLY" or "YEARLY".
  final String frequency;
  final String? dateSystem;
  final int? month;
  final int? day;
  final int? durationDays;

  const GroupEventRecurrence({
    required this.frequency,
    this.dateSystem,
    this.month,
    this.day,
    this.durationDays,
  });
}

class GroupEvent {
  final String id;
  final String groupId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isOneDay;
  final bool featured;
  final bool isRecurring;
  final GroupEventRecurrence? recurrence;
  final DateTime? occurrenceDate;
  final String title;
  final String? description;
  final String? language;
  final ResponsiveImage? image;
  final int participantCount;
  final bool isJoined;
  final List<GroupEventLink> links;
  final List<GroupEventLink> youtube;
  final String? planId;
  final String? seriesId;
  final String? accumulatorId;
  final String? groupAccumulatorId;
  final String? mantraId;
  final String? timerId;
  final String? groupRecitationCollectionId;
  final GroupEventPracticeRef? plan;
  final GroupEventPracticeRef? series;
  final GroupEventPracticeRef? accumulator;
  final GroupEventPracticeRef? groupAccumulator;
  final GroupEventPracticeRef? groupRecitationCollection;
  final String? groupName;
  final String? groupAvatarUrl;
  final String? locationId;
  final GroupEventLocation? location;

  /// `event_format` from the API: "online", "offline" or "hybrid".
  final String? eventFormat;

  const GroupEvent({
    required this.id,
    required this.groupId,
    this.startDate,
    this.endDate,
    this.isOneDay = false,
    this.featured = false,
    this.isRecurring = false,
    this.recurrence,
    this.occurrenceDate,
    this.title = '',
    this.description,
    this.language,
    this.image,
    this.participantCount = 0,
    this.isJoined = false,
    this.links = const [],
    this.youtube = const [],
    this.planId,
    this.seriesId,
    this.accumulatorId,
    this.groupAccumulatorId,
    this.mantraId,
    this.timerId,
    this.groupRecitationCollectionId,
    this.plan,
    this.series,
    this.accumulator,
    this.groupAccumulator,
    this.groupRecitationCollection,
    this.groupName,
    this.groupAvatarUrl,
    this.locationId,
    this.location,
    this.eventFormat,
  });

  /// A plan or a series (never both) marks the event as a puja to enter.
  bool get hasPuja => plan != null || series != null;

  /// First YouTube stream by display order, or null when the event has none.
  GroupEventLink? get liveYoutubeLink {
    final playable = youtube.where((link) => link.url.trim().isNotEmpty);
    if (playable.isEmpty) return null;
    return playable.reduce((a, b) => b.displayOrder < a.displayOrder ? b : a);
  }
}

class GroupEventParticipantsPage {
  final List<GroupEventParticipant> participants;
  final int skip;
  final int limit;
  final int total;

  const GroupEventParticipantsPage({
    required this.participants,
    this.skip = 0,
    this.limit = 20,
    this.total = 0,
  });

  bool get hasMore => skip + participants.length < total;
}
