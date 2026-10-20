import 'package:flutter_pecha/features/connect/presentation/utils/connect_post_link_utils.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_request_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_schedule_utils.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Turns the finished draft into the studio-shaped create request.
class GroupEventRequestBuilder {
  GroupEventRequestBuilder._();

  static bool _tzReady = false;

  /// [imageUrl] is the uploaded key or the group banner URL.
  static CreateGroupEventRequest build(
    GroupEventDraft draft, {
    required String groupId,
    String status = 'draft',
    String? imageUrl,
    String? locationId,
    DateTime? now,
  }) {
    final schedule = draft.schedule;
    final timezone = schedule.timezone;
    final metadata = [
      for (final m in draft.metadata)
        if (m.hasName)
          GroupEventMetadataRequest(
            language: apiLanguage(m.language),
            name: m.name.trim(),
            description:
                m.description.trim().isEmpty ? null : m.description.trim(),
          ),
    ];
    final language = metadata.isNotEmpty ? metadata.first.language : 'EN';

    final startTime =
        schedule.allDay
            ? GroupEventScheduleUtils.defaultStart
            : (schedule.startTime ?? GroupEventScheduleUtils.defaultStart);
    final endTime =
        schedule.allDay
            ? GroupEventScheduleUtils.defaultEnd
            : (schedule.endTime ?? GroupEventScheduleUtils.defaultEnd);

    String? startDate;
    String? endDate;
    GroupEventRecurrenceRequest? recurrence;
    final rule = schedule.recurrence;
    if (schedule.isRecurring && rule != null) {
      // Only the time of day matters; the rule supplies the dates.
      final anchor = now ?? DateTime.now();
      startDate = toBackendIso(anchor, startTime, timezone);
      endDate = toBackendIso(anchor, endTime, timezone);
      recurrence = GroupEventRecurrenceRequest(
        frequency: rule.frequency.name.toUpperCase(),
        dateSystem:
            rule.dateSystem == GroupEventDateSystem.tibetanLunar
                ? 'TIBETAN_LUNAR'
                : 'GREGORIAN',
        calendarType: rule.calendarType,
        month: rule.month,
        day: rule.day,
        dayOfWeek: rule.dayOfWeek,
        durationDays: rule.durationDays,
      );
    } else if (schedule.startDate != null) {
      final start = schedule.startDate!;
      final end = schedule.effectiveEndDate ?? start;
      startDate = toBackendIso(start, startTime, timezone);
      endDate = toBackendIso(end, endTime, timezone);
    }
    // No date yet: a draft can be saved without one.

    final links = <GroupEventLinkRequest>[];
    final youtube = <GroupEventYoutubeRequest>[];
    final liveLink =
        draft.format.needsLink
            ? GroupEventScheduleUtils.normalizeLiveLink(draft.liveLink)
            : null;
    if (liveLink != null) {
      if (GroupEventScheduleUtils.isYoutubeLink(liveLink)) {
        youtube.add(
          GroupEventYoutubeRequest(
            url: liveLink,
            language: language,
            displayOrder: 1,
          ),
        );
      } else {
        links.add(
          GroupEventLinkRequest(
            type: linkTypeFor(liveLink),
            url: liveLink,
            language: language,
            displayOrder: 1,
          ),
        );
      }
    }
    for (final video in draft.videos) {
      final title = video.title?.trim();
      links.add(
        GroupEventLinkRequest(
          type: 'video',
          url: video.url,
          label: title == null || title.isEmpty ? null : title,
          language: language,
          displayOrder: links.length + 1,
        ),
      );
    }

    String? planId;
    String? seriesId;
    String? collectionId;
    final accumulations = <GroupEventAccumulationRequest>[];
    for (final pick in draft.practices) {
      switch (pick.kind) {
        case GroupEventPracticeKind.plan:
          planId = pick.id;
        case GroupEventPracticeKind.series:
          seriesId = pick.id;
        case GroupEventPracticeKind.collection:
          collectionId = pick.id;
        case GroupEventPracticeKind.accumulator:
          accumulations.add(
            GroupEventAccumulationRequest(
              groupAccumulatorId: pick.id,
              eventFormat: pick.countMode.eventFormat,
              displayOrder: accumulations.length + 1,
              countMode: pick.countMode.countMode,
            ),
          );
      }
    }

    return CreateGroupEventRequest(
      groupId: groupId,
      status: status,
      startDate: startDate,
      endDate: endDate,
      timezone: timezone,
      metadata: metadata,
      links: links,
      youtube: youtube,
      imageUrl: imageUrl,
      planId: planId,
      seriesId: seriesId,
      groupRecitationCollectionId: collectionId,
      accumulations: accumulations,
      locationId: locationId,
      eventFormat: draft.format.apiValue,
      chatEnabled: draft.chatEnabled,
      notificationsEnabled: draft.notificationsEnabled,
      intentionIds: draft.intentionIds,
      recurrence: recurrence,
    );
  }

  /// Local codes are lowercase (`bo`); the CMS expects uppercase (`BO`).
  static String apiLanguage(String code) => code.trim().toUpperCase();

  /// The instant of [date] at [time] on the wall clock of [timezone], as UTC.
  static String toBackendIso(
    DateTime date,
    GroupEventTime time,
    String timezone,
  ) {
    if (!_tzReady) {
      tz_data.initializeTimeZones();
      _tzReady = true;
    }
    tz.Location location;
    try {
      location = tz.getLocation(timezone);
    } catch (_) {
      location = tz.UTC;
    }
    final local = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return local.toUtc().toIso8601String();
  }

  /// Today's calendar date in [timezone], UTC when the zone is unknown.
  static DateTime todayIn(String timezone) {
    if (!_tzReady) {
      tz_data.initializeTimeZones();
      _tzReady = true;
    }
    tz.Location location;
    try {
      location = tz.getLocation(timezone);
    } catch (_) {
      location = tz.UTC;
    }
    final now = tz.TZDateTime.now(location);
    return DateTime(now.year, now.month, now.day);
  }

  /// The wall-clock date and time of a stored UTC instant in [timezone].
  static (DateTime, GroupEventTime)? fromBackendIso(
    String? iso,
    String timezone,
  ) {
    if (iso == null || iso.isEmpty) return null;
    final instant = DateTime.tryParse(iso);
    if (instant == null) return null;
    if (!_tzReady) {
      tz_data.initializeTimeZones();
      _tzReady = true;
    }
    tz.Location location;
    try {
      location = tz.getLocation(timezone);
    } catch (_) {
      location = tz.UTC;
    }
    final local = tz.TZDateTime.from(instant.toUtc(), location);
    return (
      DateTime(local.year, local.month, local.day),
      GroupEventTime(local.hour, local.minute),
    );
  }

  /// Studio link types: Google Meet and Zoom by host, otherwise a website.
  static String linkTypeFor(String url) {
    final host = ConnectPostLinkUtils.hostOf(url) ?? '';
    if (host == 'meet.google.com') return 'google-meet';
    if (host == 'zoom.us' || host.endsWith('.zoom.us')) return 'zoom';
    return 'web';
  }
}
