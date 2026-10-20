import 'dart:io';

/// Name and description of an event in one language.
class GroupEventDraftMetadata {
  final String language;
  final String name;
  final String description;

  const GroupEventDraftMetadata({
    required this.language,
    this.name = '',
    this.description = '',
  });

  bool get hasName => name.trim().isNotEmpty;

  GroupEventDraftMetadata copyWith({String? name, String? description}) {
    return GroupEventDraftMetadata(
      language: language,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}

/// Where the cover image comes from; a file is uploaded on submit.
sealed class GroupEventCover {
  const GroupEventCover();
}

class GroupEventCoverFile extends GroupEventCover {
  final File file;

  const GroupEventCoverFile(this.file);
}

class GroupEventCoverUrl extends GroupEventCover {
  final String url;

  const GroupEventCoverUrl(this.url);
}

/// What the composer has collected so far, carried across its steps.
class GroupEventDraft {
  /// Ordered as the language list from the API.
  final List<GroupEventDraftMetadata> metadata;
  final GroupEventCover? cover;
  final GroupEventScheduleDraft schedule;
  final GroupEventFormat format;
  final GroupEventVenueDraft? venue;
  final String liveLink;
  final List<GroupEventPracticePick> practices;
  final List<GroupEventVideoDraft> videos;
  final bool chatEnabled;
  final bool notificationsEnabled;

  /// Empty allows every intention.
  final List<String> intentionIds;

  const GroupEventDraft({
    this.metadata = const [],
    this.cover,
    this.schedule = const GroupEventScheduleDraft(),
    this.format = GroupEventFormat.offline,
    this.venue,
    this.liveLink = '',
    this.practices = const [],
    this.videos = const [],
    this.chatEnabled = true,
    this.notificationsEnabled = true,
    this.intentionIds = const [],
  });

  List<String> get languages => [for (final m in metadata) m.language];

  /// Languages without a name are dropped before sending.
  bool get hasName => metadata.any((m) => m.hasName);

  bool get hasContent =>
      cover != null ||
      schedule.startDate != null ||
      venue != null ||
      liveLink.trim().isNotEmpty ||
      practices.isNotEmpty ||
      videos.isNotEmpty ||
      metadata.any((m) => m.hasName || m.description.trim().isNotEmpty);

  GroupEventDraftMetadata? metadataFor(String language) =>
      metadata.where((m) => m.language == language).firstOrNull;

  GroupEventDraft copyWith({
    List<GroupEventDraftMetadata>? metadata,
    GroupEventCover? cover,
    bool clearCover = false,
    GroupEventScheduleDraft? schedule,
    GroupEventFormat? format,
    GroupEventVenueDraft? venue,
    bool clearVenue = false,
    String? liveLink,
    List<GroupEventPracticePick>? practices,
    List<GroupEventVideoDraft>? videos,
    bool? chatEnabled,
    bool? notificationsEnabled,
    List<String>? intentionIds,
  }) {
    return GroupEventDraft(
      metadata: metadata ?? this.metadata,
      cover: clearCover ? null : (cover ?? this.cover),
      schedule: schedule ?? this.schedule,
      format: format ?? this.format,
      venue: clearVenue ? null : (venue ?? this.venue),
      liveLink: liveLink ?? this.liveLink,
      practices: practices ?? this.practices,
      videos: videos ?? this.videos,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      intentionIds: intentionIds ?? this.intentionIds,
    );
  }
}

/// Wall-clock time in the event's timezone.
class GroupEventTime {
  final int hour;
  final int minute;

  const GroupEventTime(this.hour, this.minute);

  int get minutesSinceMidnight => hour * 60 + minute;

  /// "HH:mm" as the API expects.
  String get hhmm =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is GroupEventTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

enum GroupEventRecurrenceFrequency { weekly, monthly, yearly }

enum GroupEventDateSystem { gregorian, tibetanLunar }

/// Mirrors the studio's recurrence rule; `dayOfWeek` is 0 = Monday.
class GroupEventRecurrenceDraft {
  final GroupEventRecurrenceFrequency frequency;
  final GroupEventDateSystem dateSystem;
  final String? calendarType;
  final int? month;
  final int? day;
  final int? dayOfWeek;
  final int durationDays;

  const GroupEventRecurrenceDraft({
    required this.frequency,
    required this.dateSystem,
    this.calendarType,
    this.month,
    this.day,
    this.dayOfWeek,
    this.durationDays = 1,
  });

  bool get isLunar => dateSystem == GroupEventDateSystem.tibetanLunar;

  GroupEventRecurrenceDraft copyWith({int? durationDays}) {
    return GroupEventRecurrenceDraft(
      frequency: frequency,
      dateSystem: dateSystem,
      calendarType: calendarType,
      month: month,
      day: day,
      dayOfWeek: dayOfWeek,
      durationDays: durationDays ?? this.durationDays,
    );
  }

  /// Same rule regardless of duration.
  bool sameRule(GroupEventRecurrenceDraft other) =>
      frequency == other.frequency &&
      dateSystem == other.dateSystem &&
      calendarType == other.calendarType &&
      month == other.month &&
      day == other.day &&
      dayOfWeek == other.dayOfWeek;
}

/// Step 2 "When": dates are date-only, times are optional (null = all day).
class GroupEventScheduleDraft {
  final bool isRecurring;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isMultiDay;
  final bool allDay;
  final GroupEventTime? startTime;
  final GroupEventTime? endTime;
  final String timezone;
  final GroupEventRecurrenceDraft? recurrence;

  static const defaultTimezone = 'Asia/Kolkata';

  const GroupEventScheduleDraft({
    this.isRecurring = false,
    this.startDate,
    this.endDate,
    this.isMultiDay = false,
    this.allDay = false,
    this.startTime,
    this.endTime,
    this.timezone = defaultTimezone,
    this.recurrence,
  });

  /// End date the API gets: the start date unless the one-time event spans days.
  DateTime? get effectiveEndDate =>
      !isRecurring && isMultiDay ? endDate : startDate;

  GroupEventScheduleDraft copyWith({
    bool? isRecurring,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? isMultiDay,
    bool? allDay,
    GroupEventTime? startTime,
    bool clearStartTime = false,
    GroupEventTime? endTime,
    bool clearEndTime = false,
    String? timezone,
    GroupEventRecurrenceDraft? recurrence,
    bool clearRecurrence = false,
  }) {
    return GroupEventScheduleDraft(
      isRecurring: isRecurring ?? this.isRecurring,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      isMultiDay: isMultiDay ?? this.isMultiDay,
      allDay: allDay ?? this.allDay,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      timezone: timezone ?? this.timezone,
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
    );
  }
}

/// `event_format` on the API.
enum GroupEventFormat {
  offline('offline'),
  online('online'),
  hybrid('hybrid');

  const GroupEventFormat(this.apiValue);

  final String apiValue;

  bool get needsVenue => this != online;
  bool get needsLink => this != offline;
}

/// A venue picked on the map; created as a group location on submit.
class GroupEventVenueDraft {
  final String name;
  final double latitude;
  final double longitude;
  final String? address;

  const GroupEventVenueDraft({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  GroupEventVenueDraft copyWith({String? name}) => GroupEventVenueDraft(
    name: name ?? this.name,
    latitude: latitude,
    longitude: longitude,
    address: address,
  );
}

enum GroupEventPracticeKind { plan, series, collection, accumulator }

/// Who records an accumulation's count; maps to the row's `event_format`.
enum GroupEventCountMode {
  attendees('online', 'offline_participants'),
  admin('offline', 'manual_in_person');

  const GroupEventCountMode(this.eventFormat, this.countMode);

  final String eventFormat;
  final String countMode;
}

/// A practice linked to the event. Plans/series and chant collections are
/// single slots on the API; accumulations are a list.
class GroupEventPracticePick {
  final String id;
  final GroupEventPracticeKind kind;
  final String title;
  final String? imageUrl;
  final GroupEventCountMode countMode;

  const GroupEventPracticePick({
    required this.id,
    required this.kind,
    required this.title,
    this.imageUrl,
    this.countMode = GroupEventCountMode.admin,
  });

  bool get isContent =>
      kind == GroupEventPracticeKind.plan ||
      kind == GroupEventPracticeKind.series;

  GroupEventPracticePick copyWith({GroupEventCountMode? countMode}) {
    return GroupEventPracticePick(
      id: id,
      kind: kind,
      title: title,
      imageUrl: imageUrl,
      countMode: countMode ?? this.countMode,
    );
  }
}

/// A YouTube link shown on the event's About page (`links` type `video`).
class GroupEventVideoDraft {
  final String url;
  final String? title;
  final String? thumbnailUrl;

  const GroupEventVideoDraft({
    required this.url,
    this.title,
    this.thumbnailUrl,
  });
}

/// A prayer intention an event can be limited to.
class GroupEventIntention {
  final String id;
  final String slug;
  final String label;

  const GroupEventIntention({
    required this.id,
    required this.slug,
    required this.label,
  });
}
