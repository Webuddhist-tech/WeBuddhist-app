import 'dart:convert';

/// `POST /cms/events` body, mirroring the studio's `CreateEventRequest`.
/// `PUT /cms/events/{id}` sends only the changes, see [toUpdateJson].
class CreateGroupEventRequest {
  final String groupId;

  /// `draft` or `published`.
  final String status;

  /// Null while a draft has no date yet; the API allows that.
  final String? startDate;
  final String? endDate;
  final String timezone;
  final List<GroupEventMetadataRequest> metadata;
  final List<GroupEventLinkRequest> links;
  final List<GroupEventYoutubeRequest> youtube;
  final String? imageUrl;
  final String? planId;
  final String? seriesId;
  final String? groupRecitationCollectionId;
  final List<GroupEventAccumulationRequest> accumulations;
  final String? locationId;
  final String eventFormat;
  final bool chatEnabled;
  final bool notificationsEnabled;
  final List<String> intentionIds;
  final GroupEventRecurrenceRequest? recurrence;

  const CreateGroupEventRequest({
    required this.groupId,
    this.status = 'draft',
    this.startDate,
    this.endDate,
    required this.timezone,
    required this.metadata,
    this.links = const [],
    this.youtube = const [],
    this.imageUrl,
    this.planId,
    this.seriesId,
    this.groupRecitationCollectionId,
    this.accumulations = const [],
    this.locationId,
    required this.eventFormat,
    this.chatEnabled = true,
    this.notificationsEnabled = true,
    this.intentionIds = const [],
    this.recurrence,
  });

  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    if (startDate != null) 'start_date': startDate,
    if (endDate != null) 'end_date': endDate,
    'timezone': timezone,
    'metadata': metadata.map((item) => item.toJson()).toList(),
    if (links.isNotEmpty) 'links': links.map((item) => item.toJson()).toList(),
    if (youtube.isNotEmpty)
      'youtube': youtube.map((item) => item.toJson()).toList(),
    if (imageUrl != null) 'image_url': imageUrl,
    if (planId != null) 'plan_id': planId,
    if (seriesId != null) 'series_id': seriesId,
    if (groupRecitationCollectionId != null)
      'group_recitation_collection_id': groupRecitationCollectionId,
    if (accumulations.isNotEmpty)
      'accumulations': accumulations.map((item) => item.toJson()).toList(),
    if (locationId != null) 'location_id': locationId,
    'event_format': eventFormat,
    'status': status,
    'chat_enabled': chatEnabled,
    'notifications_enabled': notificationsEnabled,
    if (intentionIds.isNotEmpty) 'intention_ids': intentionIds,
    if (recurrence != null) 'recurrence': recurrence!.toJson(),
  };

  /// `PUT /cms/events/{id}` body: only the fields that differ from
  /// [original], the event as it was loaded. The API leaves omitted fields
  /// alone and clears a field sent as null or an empty list, so a removed
  /// plan, link or venue has to be sent explicitly. Untouched fields are
  /// left out, which keeps studio data the app does not load (extra links,
  /// labels) intact.
  Map<String, dynamic> toUpdateJson(CreateGroupEventRequest original) {
    final next = _fullJson();
    final before = original._fullJson();
    final body = <String, dynamic>{
      for (final key in next.keys)
        if (key != 'group_id' &&
            jsonEncode(next[key]) != jsonEncode(before[key]))
          key: next[key],
    };
    // The API reads the schedule as one unit: turning a recurring event
    // into a one-time one needs its dates even when they did not change.
    const schedule = ['start_date', 'end_date', 'timezone', 'recurrence'];
    if (schedule.any(body.containsKey)) {
      for (final key in schedule) {
        body[key] = next[key];
      }
    }
    // The API cannot clear these, so a null would only be noise.
    for (final key in const ['image_url', 'start_date', 'end_date']) {
      if (body.containsKey(key) && body[key] == null) body.remove(key);
    }
    return body;
  }

  /// Every field, with explicit nulls and empty lists, for diffing.
  Map<String, dynamic> _fullJson() => {
    'group_id': groupId,
    'start_date': startDate,
    'end_date': endDate,
    'timezone': timezone,
    'metadata': metadata.map((item) => item.toJson()).toList(),
    'links': links.map((item) => item.toJson()).toList(),
    'youtube': youtube.map((item) => item.toJson()).toList(),
    'image_url': imageUrl,
    'plan_id': planId,
    'series_id': seriesId,
    'group_recitation_collection_id': groupRecitationCollectionId,
    'accumulations': accumulations.map((item) => item.toJson()).toList(),
    'location_id': locationId,
    'event_format': eventFormat,
    'status': status,
    'chat_enabled': chatEnabled,
    'notifications_enabled': notificationsEnabled,
    'intention_ids': intentionIds,
    'recurrence': recurrence?.toJson(),
  };
}

class GroupEventMetadataRequest {
  final String language;
  final String name;
  final String? description;

  const GroupEventMetadataRequest({
    required this.language,
    required this.name,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'language': language,
    'name': name,
    if (description != null) 'description': description,
  };
}

class GroupEventLinkRequest {
  final String type;
  final String url;
  final String? label;
  final String language;
  final int displayOrder;

  const GroupEventLinkRequest({
    required this.type,
    required this.url,
    this.label,
    required this.language,
    required this.displayOrder,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'url': url,
    if (label != null) 'label': label,
    'language': language,
    'display_order': displayOrder,
  };
}

class GroupEventYoutubeRequest {
  final String url;
  final String? label;
  final String language;
  final int displayOrder;

  const GroupEventYoutubeRequest({
    required this.url,
    this.label,
    required this.language,
    required this.displayOrder,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    if (label != null) 'label': label,
    'language': language,
    'display_order': displayOrder,
  };
}

class GroupEventAccumulationRequest {
  final String groupAccumulatorId;
  final String eventFormat;
  final int displayOrder;
  final String countMode;

  const GroupEventAccumulationRequest({
    required this.groupAccumulatorId,
    required this.eventFormat,
    required this.displayOrder,
    required this.countMode,
  });

  Map<String, dynamic> toJson() => {
    'group_accumulator_id': groupAccumulatorId,
    'event_format': eventFormat,
    'display_order': displayOrder,
    'count_mode': countMode,
  };
}

class GroupEventRecurrenceRequest {
  final String frequency;
  final String dateSystem;
  final String? calendarType;
  final int? month;
  final int? day;
  final int? dayOfWeek;
  final int durationDays;

  const GroupEventRecurrenceRequest({
    required this.frequency,
    required this.dateSystem,
    this.calendarType,
    this.month,
    this.day,
    this.dayOfWeek,
    required this.durationDays,
  });

  Map<String, dynamic> toJson() => {
    'frequency': frequency,
    'date_system': dateSystem,
    if (calendarType != null) 'calendar_type': calendarType,
    'month': month,
    'day': day,
    'day_of_week': dayOfWeek,
    'duration_days': durationDays,
  };
}

/// `POST /cms/author/groups/{id}/locations` body.
class CreateGroupLocationRequest {
  final String name;
  final double latitude;
  final double longitude;

  const CreateGroupLocationRequest({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
  };
}
