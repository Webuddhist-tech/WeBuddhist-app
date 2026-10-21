import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_request_builder.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_schedule_utils.dart';

/// A CMS event opened for editing: the draft plus what the server already
/// holds, so unchanged parts are not resent or recreated.
class GroupEventEditSource {
  final String eventId;
  final GroupEventDraft draft;
  final String? locationId;
  final GroupEventVenueDraft? venue;
  final String? imageUrl;

  /// Intentions arrive as slugs; the composer resolves them to ids.
  final List<String> intentionSlugs;

  /// A live event: saving keeps it published and closing never drafts it.
  final bool isPublished;

  const GroupEventEditSource({
    required this.eventId,
    required this.draft,
    this.locationId,
    this.venue,
    this.imageUrl,
    this.intentionSlugs = const [],
    this.isPublished = false,
  });

  bool sameVenue(GroupEventVenueDraft? other) {
    final mine = venue;
    if (mine == null || other == null) return false;
    return mine.name == other.name &&
        mine.latitude == other.latitude &&
        mine.longitude == other.longitude;
  }
}

/// Reads a CMS event payload back into the composer's draft.
class GroupEventDraftMapper {
  GroupEventDraftMapper._();

  static GroupEventEditSource fromJson(Map<String, dynamic> json) {
    final timezone =
        (json['timezone'] as String?)?.trim().isNotEmpty == true
            ? (json['timezone'] as String).trim()
            : GroupEventScheduleDraft.defaultTimezone;

    final metadata = <GroupEventDraftMetadata>[];
    final rawMetadata = json['metadata'];
    final rows =
        rawMetadata is List
            ? rawMetadata.whereType<Map<String, dynamic>>()
            : rawMetadata is Map<String, dynamic>
            ? [rawMetadata]
            : const <Map<String, dynamic>>[];
    for (final row in rows) {
      final code = (row['language'] as String? ?? '').trim().toLowerCase();
      if (code.isEmpty) continue;
      metadata.add(
        GroupEventDraftMetadata(
          language: code,
          name: (row['name'] as String? ?? '').trim(),
          description: (row['description'] as String? ?? '').trim(),
        ),
      );
    }

    final imageUrl = _imageUrl(json);
    final start = GroupEventRequestBuilder.fromBackendIso(
      json['start_date'] as String?,
      timezone,
    );
    final end = GroupEventRequestBuilder.fromBackendIso(
      json['end_date'] as String?,
      timezone,
    );
    final isRecurring = json['is_recurring'] as bool? ?? false;
    final recurrence = _recurrence(json['recurrence']);
    final startDate = start?.$1;
    final endDate = end?.$1;
    final isMultiDay =
        !isRecurring &&
        startDate != null &&
        endDate != null &&
        !endDate.isAtSameMomentAs(startDate);
    final allDay =
        start?.$2 == GroupEventScheduleUtils.defaultStart &&
        end?.$2 == GroupEventScheduleUtils.defaultEnd;

    final format =
        GroupEventFormat.values
            .where((f) => f.apiValue == json['event_format'])
            .firstOrNull ??
        GroupEventFormat.hybrid;

    GroupEventVenueDraft? venue;
    final location = json['location'];
    if (location is Map<String, dynamic>) {
      final lat = (location['latitude'] as num?)?.toDouble();
      final lng = (location['longitude'] as num?)?.toDouble();
      final name = (location['name'] as String? ?? '').trim();
      if (lat != null && lng != null && name.isNotEmpty) {
        venue = GroupEventVenueDraft(name: name, latitude: lat, longitude: lng);
      }
    }

    final videos = <GroupEventVideoDraft>[];
    String liveLink = '';
    for (final link in _sortedLinks(json['youtube'])) {
      final url = (link['url'] as String? ?? '').trim();
      if (url.isNotEmpty && liveLink.isEmpty) liveLink = url;
    }
    for (final link in _sortedLinks(json['links'])) {
      final url = (link['url'] as String? ?? '').trim();
      if (url.isEmpty) continue;
      final type = (link['type'] as String? ?? '').trim().toLowerCase();
      if (type == 'video') {
        videos.add(
          GroupEventVideoDraft(url: url, title: link['label'] as String?),
        );
      } else if (liveLink.isEmpty) {
        liveLink = url;
      }
    }

    final practices = <GroupEventPracticePick>[];
    void addRef(Object? ref, String? id, GroupEventPracticeKind kind) {
      final map = ref is Map<String, dynamic> ? ref : null;
      final pickId = (map?['id'] as String?) ?? id;
      if (pickId == null || pickId.isEmpty) return;
      practices.add(
        GroupEventPracticePick(
          id: pickId,
          kind: kind,
          title: (map?['name'] as String? ?? '').trim(),
          imageUrl: map?['image_url'] as String?,
        ),
      );
    }

    addRef(
      json['plan'],
      json['plan_id'] as String?,
      GroupEventPracticeKind.plan,
    );
    addRef(
      json['series'],
      json['series_id'] as String?,
      GroupEventPracticeKind.series,
    );
    addRef(
      json['group_recitation_collection'],
      json['group_recitation_collection_id'] as String?,
      GroupEventPracticeKind.collection,
    );
    final accumulations =
        (json['accumulations'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList()
          ..sort(
            (a, b) => ((a['display_order'] as num?) ?? 0).compareTo(
              (b['display_order'] as num?) ?? 0,
            ),
          );
    for (final row in accumulations) {
      final ref = row['group_accumulator'];
      final map = ref is Map<String, dynamic> ? ref : null;
      final id =
          (map?['id'] as String?) ?? row['group_accumulator_id'] as String?;
      if (id == null || id.isEmpty) continue;
      practices.add(
        GroupEventPracticePick(
          id: id,
          kind: GroupEventPracticeKind.accumulator,
          title: (map?['name'] as String? ?? '').trim(),
          imageUrl: map?['image_url'] as String?,
          countMode:
              row['event_format'] == 'online'
                  ? GroupEventCountMode.attendees
                  : GroupEventCountMode.admin,
        ),
      );
    }

    final intentionSlugs =
        (json['intentions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((row) => (row['slug'] as String? ?? '').trim())
            .where((slug) => slug.isNotEmpty)
            .toList();

    return GroupEventEditSource(
      eventId: json['id'] as String? ?? '',
      isPublished:
          (json['status'] as String? ?? 'published').toLowerCase() !=
          'draft',
      locationId: json['location_id'] as String?,
      venue: venue,
      imageUrl: imageUrl,
      intentionSlugs: intentionSlugs,
      draft: GroupEventDraft(
        metadata: metadata,
        cover: imageUrl == null ? null : GroupEventCoverUrl(imageUrl),
        schedule: GroupEventScheduleDraft(
          isRecurring: isRecurring && recurrence != null,
          startDate: startDate,
          endDate: isMultiDay ? endDate : null,
          isMultiDay: isMultiDay,
          allDay: allDay,
          startTime: allDay ? null : start?.$2,
          endTime: allDay ? null : end?.$2,
          timezone: timezone,
          recurrence: recurrence,
        ),
        format: format,
        venue: venue,
        liveLink: liveLink,
        practices: practices,
        videos: videos,
        chatEnabled: json['chat_enabled'] as bool? ?? true,
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      ),
    );
  }

  static String? _imageUrl(Map<String, dynamic> json) {
    final image = json['image'];
    if (image is Map<String, dynamic>) {
      for (final key in const ['original', 'medium', 'thumbnail']) {
        final value = (image[key] as String?)?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    final raw = (json['image_url'] as String?)?.trim();
    return raw != null && raw.startsWith('http') ? raw : null;
  }

  static GroupEventRecurrenceDraft? _recurrence(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final frequency =
        GroupEventRecurrenceFrequency.values
            .where(
              (f) =>
                  f.name.toUpperCase() == (value['frequency'] as String? ?? ''),
            )
            .firstOrNull;
    if (frequency == null) return null;
    final lunar = value['date_system'] == 'TIBETAN_LUNAR';
    return GroupEventRecurrenceDraft(
      frequency: frequency,
      dateSystem:
          lunar
              ? GroupEventDateSystem.tibetanLunar
              : GroupEventDateSystem.gregorian,
      calendarType: value['calendar_type'] as String?,
      month: (value['month'] as num?)?.toInt(),
      day: (value['day'] as num?)?.toInt(),
      dayOfWeek: (value['day_of_week'] as num?)?.toInt(),
      durationDays: (value['duration_days'] as num?)?.toInt() ?? 1,
    );
  }

  static List<Map<String, dynamic>> _sortedLinks(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList()..sort(
      (a, b) => ((a['display_order'] as num?) ?? 0).compareTo(
        (b['display_order'] as num?) ?? 0,
      ),
    );
  }
}
