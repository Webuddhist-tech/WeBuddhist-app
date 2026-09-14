import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class GroupEventMetadataModel {
  final String id;
  final String name;
  final String? description;
  final String language;

  const GroupEventMetadataModel({
    required this.id,
    required this.name,
    this.description,
    required this.language,
  });

  factory GroupEventMetadataModel.fromJson(Map<String, dynamic> json) {
    return GroupEventMetadataModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      language: json['language'] as String? ?? '',
    );
  }
}

class GroupEventLinkModel {
  final String id;
  final String type;
  final String url;
  final String? label;
  final String? language;
  final int displayOrder;

  const GroupEventLinkModel({
    required this.id,
    required this.type,
    required this.url,
    this.label,
    this.language,
    this.displayOrder = 0,
  });

  factory GroupEventLinkModel.fromJson(Map<String, dynamic> json) {
    return GroupEventLinkModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
      label: json['label'] as String?,
      language: json['language'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  GroupEventLink toEntity() {
    return GroupEventLink(
      id: id,
      type: type,
      url: url,
      label: label,
      language: language,
      displayOrder: displayOrder,
    );
  }
}

class GroupEventParticipantModel {
  final String userId;
  final DateTime? createdAt;
  final String? username;
  final String? fullname;
  final String? avatarUrl;

  const GroupEventParticipantModel({
    required this.userId,
    this.createdAt,
    this.username,
    this.fullname,
    this.avatarUrl,
  });

  factory GroupEventParticipantModel.fromJson(Map<String, dynamic> json) {
    return GroupEventParticipantModel(
      userId: json['user_id'] as String? ?? '',
      createdAt: GroupEventModel._parseDate(json['created_at']),
      username: json['username'] as String?,
      fullname: json['fullname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  GroupEventParticipant toEntity() {
    return GroupEventParticipant(
      userId: userId,
      createdAt: createdAt,
      username: username,
      fullname: fullname,
      avatarUrl: avatarUrl,
    );
  }
}

class GroupEventLocationModel {
  final String id;
  final String groupId;
  final String name;
  final double? latitude;
  final double? longitude;

  const GroupEventLocationModel({
    required this.id,
    required this.groupId,
    required this.name,
    this.latitude,
    this.longitude,
  });

  factory GroupEventLocationModel.fromJson(Map<String, dynamic> json) {
    return GroupEventLocationModel(
      id: json['id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  GroupEventLocation toEntity() {
    return GroupEventLocation(
      id: id,
      groupId: groupId,
      name: name,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class GroupEventPracticeRefModel {
  final String id;
  final String name;
  final String? imageUrl;

  const GroupEventPracticeRefModel({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory GroupEventPracticeRefModel.fromJson(Map<String, dynamic> json) {
    return GroupEventPracticeRefModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
    );
  }

  GroupEventPracticeRef toEntity() {
    return GroupEventPracticeRef(id: id, name: name, imageUrl: imageUrl);
  }
}

class GroupEventRecurrenceModel {
  final String frequency;
  final String? dateSystem;
  final int? month;
  final int? day;
  final int? durationDays;

  const GroupEventRecurrenceModel({
    required this.frequency,
    this.dateSystem,
    this.month,
    this.day,
    this.durationDays,
  });

  factory GroupEventRecurrenceModel.fromJson(Map<String, dynamic> json) {
    return GroupEventRecurrenceModel(
      frequency: json['frequency'] as String? ?? '',
      dateSystem: json['date_system'] as String?,
      month: (json['month'] as num?)?.toInt(),
      day: (json['day'] as num?)?.toInt(),
      durationDays: (json['duration_days'] as num?)?.toInt(),
    );
  }

  GroupEventRecurrence toEntity() {
    return GroupEventRecurrence(
      frequency: frequency,
      dateSystem: dateSystem,
      month: month,
      day: day,
      durationDays: durationDays,
    );
  }
}

class GroupEventModel {
  final String id;
  final String groupId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isOneDay;
  final bool featured;
  final bool isRecurring;
  final GroupEventRecurrenceModel? recurrence;
  final DateTime? occurrenceDate;
  final GroupEventMetadataModel? metadata;
  final ResponsiveImage? image;
  final int participantCount;
  final bool isJoined;
  final List<GroupEventLinkModel> links;
  final List<GroupEventLinkModel> youtube;
  final String? planId;
  final String? seriesId;
  final String? accumulatorId;
  final String? groupAccumulatorId;
  final String? mantraId;
  final String? timerId;
  final String? groupRecitationCollectionId;
  final GroupEventPracticeRefModel? plan;
  final GroupEventPracticeRefModel? series;
  final GroupEventPracticeRefModel? accumulator;
  final GroupEventPracticeRefModel? groupAccumulator;
  final GroupEventPracticeRefModel? groupRecitationCollection;
  final String? groupName;
  final String? groupAvatarUrl;
  final String? locationId;
  final GroupEventLocationModel? location;
  final String? eventFormat;

  const GroupEventModel({
    required this.id,
    required this.groupId,
    this.startDate,
    this.endDate,
    this.isOneDay = false,
    this.featured = false,
    this.isRecurring = false,
    this.recurrence,
    this.occurrenceDate,
    this.metadata,
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

  factory GroupEventModel.fromJson(
    Map<String, dynamic> json, {
    String? language,
  }) {
    final imageJson = json['image'] as Map<String, dynamic>?;
    final locationJson = json['location'] as Map<String, dynamic>?;
    final recurrenceJson = json['recurrence'] as Map<String, dynamic>?;

    return GroupEventModel(
      id: json['id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? '',
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      isOneDay: json['is_one_day'] as bool? ?? false,
      featured: json['featured'] as bool? ?? false,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrence:
          recurrenceJson != null
              ? GroupEventRecurrenceModel.fromJson(recurrenceJson)
              : null,
      occurrenceDate: _parseDate(json['occurrence_date']),
      metadata: _parseMetadata(json['metadata'], language: language),
      image: imageJson != null ? ResponsiveImage.fromJson(imageJson) : null,
      participantCount: (json['participant_count'] as num?)?.toInt() ?? 0,
      isJoined: json['is_joined'] as bool? ?? false,
      links: _parseLinks(json['links']),
      youtube: _parseLinks(json['youtube']),
      planId: json['plan_id'] as String?,
      seriesId: json['series_id'] as String?,
      accumulatorId: json['accumulator_id'] as String?,
      groupAccumulatorId: json['group_accumulator_id'] as String?,
      mantraId: json['mantra_id'] as String?,
      timerId: json['timer_id'] as String?,
      groupRecitationCollectionId:
          json['group_recitation_collection_id'] as String?,
      plan: _parsePracticeRef(json['plan']),
      series: _parsePracticeRef(json['series']),
      accumulator: _parsePracticeRef(json['accumulator']),
      groupAccumulator: _parsePracticeRef(json['group_accumulator']),
      groupRecitationCollection: _parsePracticeRef(
        json['group_recitation_collection'],
      ),
      groupName: json['group_name'] as String?,
      groupAvatarUrl: json['group_avatar_url'] as String?,
      locationId: json['location_id'] as String?,
      location:
          locationJson != null
              ? GroupEventLocationModel.fromJson(locationJson)
              : null,
      eventFormat: json['event_format'] as String?,
    );
  }

  GroupEvent toEntity() {
    return GroupEvent(
      id: id,
      groupId: groupId,
      startDate: startDate,
      endDate: endDate,
      isOneDay: isOneDay,
      featured: featured,
      isRecurring: isRecurring,
      recurrence: recurrence?.toEntity(),
      occurrenceDate: occurrenceDate,
      title: metadata?.name ?? '',
      description: metadata?.description,
      language: metadata?.language,
      image: image,
      participantCount: participantCount,
      isJoined: isJoined,
      links: links.map((link) => link.toEntity()).toList(),
      youtube: youtube.map((link) => link.toEntity()).toList(),
      planId: planId,
      seriesId: seriesId,
      accumulatorId: accumulatorId,
      groupAccumulatorId: groupAccumulatorId,
      mantraId: mantraId,
      timerId: timerId,
      groupRecitationCollectionId: groupRecitationCollectionId,
      plan: plan?.toEntity(),
      series: series?.toEntity(),
      accumulator: accumulator?.toEntity(),
      groupAccumulator: groupAccumulator?.toEntity(),
      groupRecitationCollection: groupRecitationCollection?.toEntity(),
      groupName: groupName,
      groupAvatarUrl: groupAvatarUrl,
      locationId: locationId,
      location: location?.toEntity(),
      eventFormat: eventFormat,
    );
  }

  static List<GroupEventLinkModel> _parseLinks(Object? value) {
    if (value is! List<dynamic>) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(GroupEventLinkModel.fromJson)
        .toList();
  }

  static GroupEventPracticeRefModel? _parsePracticeRef(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final ref = GroupEventPracticeRefModel.fromJson(value);
    return ref.id.isEmpty ? null : ref;
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static GroupEventMetadataModel? _parseMetadata(
    Object? value, {
    String? language,
  }) {
    if (value is Map<String, dynamic>) {
      return GroupEventMetadataModel.fromJson(value);
    }
    if (value is List<dynamic>) {
      final items = value.whereType<Map<String, dynamic>>().toList();
      if (language != null && language.isNotEmpty) {
        final match = items
            .where((item) => item['language'] == language)
            .firstOrNull;
        if (match != null) {
          return GroupEventMetadataModel.fromJson(match);
        }
      }
      final metadataJson = items.firstOrNull;
      if (metadataJson != null) {
        return GroupEventMetadataModel.fromJson(metadataJson);
      }
    }
    return null;
  }
}

class GroupEventsPageModel {
  final List<GroupEventModel> events;
  final int total;
  final int skip;
  final int limit;

  const GroupEventsPageModel({
    required this.events,
    this.total = 0,
    this.skip = 0,
    this.limit = 20,
  });

  factory GroupEventsPageModel.fromJson(
    Map<String, dynamic> json, {
    String? language,
  }) {
    return GroupEventsPageModel(
      events:
          (json['events'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((item) => GroupEventModel.fromJson(item, language: language))
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );
  }

  GroupEventsPage toEntity() {
    return GroupEventsPage(
      events: events.map((event) => event.toEntity()).toList(),
      total: total,
      skip: skip,
      limit: limit,
    );
  }
}

class GroupEventParticipantsPageModel {
  final List<GroupEventParticipantModel> participants;
  final int skip;
  final int limit;
  final int total;

  const GroupEventParticipantsPageModel({
    required this.participants,
    this.skip = 0,
    this.limit = 20,
    this.total = 0,
  });

  factory GroupEventParticipantsPageModel.fromJson(Map<String, dynamic> json) {
    return GroupEventParticipantsPageModel(
      participants:
          (json['participants'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(GroupEventParticipantModel.fromJson)
              .toList() ??
          const [],
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  GroupEventParticipantsPage toEntity() {
    return GroupEventParticipantsPage(
      participants:
          participants.map((participant) => participant.toEntity()).toList(),
      skip: skip,
      limit: limit,
      total: total,
    );
  }
}
