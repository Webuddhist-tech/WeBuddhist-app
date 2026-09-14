import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

enum SessionType {
  plan,
  series,
  recitation,
  timer,
  accumulator,
  groupRecitationCollection,
  recitationCollection,
  groupAccumulator,

  /// A session type this build doesn't know. Kept so a routine written by a
  /// newer app version still parses here; the original wire value rides along
  /// on [SessionDTO.rawSessionType] so re-syncing echoes it back untouched.
  unknown;

  String toJson() => switch (this) {
    SessionType.plan => 'PLAN',
    SessionType.series => 'SERIES',
    SessionType.recitation => 'RECITATION',
    SessionType.timer => 'TIMER',
    SessionType.accumulator => 'ACCUMULATOR',
    SessionType.groupRecitationCollection => 'GROUP_RECITATION_COLLECTION',
    SessionType.recitationCollection => 'RECITATION_COLLECTION',
    SessionType.groupAccumulator => 'GROUP_ACCUMULATOR',
    SessionType.unknown => 'UNKNOWN',
  };

  static SessionType fromJson(String value) => switch (value.toUpperCase()) {
    'PLAN' => SessionType.plan,
    'SERIES' => SessionType.series,
    'RECITATION' => SessionType.recitation,
    'TIMER' => SessionType.timer,
    'ACCUMULATOR' => SessionType.accumulator,
    'GROUP_RECITATION_COLLECTION' => SessionType.groupRecitationCollection,
    'RECITATION_COLLECTION' => SessionType.recitationCollection,
    'GROUP_ACCUMULATOR' => SessionType.groupAccumulator,
    // Never throws: one unrecognised session would otherwise fail the whole
    // routine response, blanking every block the user has.
    _ => SessionType.unknown,
  };
}

// ─── Request models ───

class SessionRequest {
  final SessionType sessionType;
  final String sourceId;
  final int displayOrder;

  /// Wire value to send instead of [sessionType]'s own. Set only for sessions
  /// that arrived with a type this build doesn't know, so a PUT — which
  /// replaces every session in the block — gives them back verbatim rather
  /// than dropping them.
  final String? rawSessionType;

  /// Required by the API when [sessionType] is [SessionType.timer].
  final int? durationMs;

  const SessionRequest({
    required this.sessionType,
    required this.sourceId,
    required this.displayOrder,
    this.durationMs,
    this.rawSessionType,
  });

  Map<String, dynamic> toJson() => {
    'session_type': rawSessionType ?? sessionType.toJson(),
    if (sessionType == SessionType.accumulator)
      'accumulator_id': sourceId
    else if (sessionType == SessionType.groupAccumulator)
      'group_accumulator_id': sourceId
    else if (sessionType != SessionType.timer)
      'source_id': sourceId,
    'display_order': displayOrder,
    if (durationMs != null) 'duration_ms': durationMs,
  };
}

/// Unified request body for both creating and updating a time block.
/// Used by [createRoutineWithTimeBlock], [createTimeBlock], and [updateTimeBlock].
class TimeBlockRequest {
  final String time;
  final int timeInt;

  /// Optional session title. PUT is a full replace, so null clears it.
  final String? title;
  final bool notificationEnabled;
  final List<SessionRequest> sessions;

  const TimeBlockRequest({
    required this.time,
    required this.timeInt,
    this.title,
    this.notificationEnabled = true,
    required this.sessions,
  });

  Map<String, dynamic> toJson() => {
    'time': time,
    'time_int': timeInt,
    if (title != null) 'title': title,
    'notification_enabled': notificationEnabled,
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };
}

// ─── Response models ───

class SessionDTO {
  final String id;
  final SessionType sessionType;
  final String sourceId;
  final String title;
  final String language;
  final ImageModel? image;
  final int displayOrder;
  final int? durationMs;
  final DateTime? startDate;
  final DateTime? startedAt;
  final String? currentPlanId;
  final String? currentPlanTitle;
  final RecitationFirstSegmentModel? firstSegment;

  /// Number of chants in a chant-collection session.
  final int? itemCount;

  /// The `session_type` exactly as the API sent it. Only needed when
  /// [sessionType] is [SessionType.unknown], to echo it back on re-sync.
  final String? rawSessionType;

  const SessionDTO({
    required this.id,
    required this.sessionType,
    required this.sourceId,
    required this.title,
    required this.language,
    this.image,
    required this.displayOrder,
    this.durationMs,
    this.startDate,
    this.startedAt,
    this.currentPlanId,
    this.currentPlanTitle,
    this.firstSegment,
    this.itemCount,
    this.rawSessionType,
  });

  String? get imageUrl => image?.displayUrl;

  ResponsiveImage? get coverImage => image?.toResponsiveImage();

  factory SessionDTO.fromJson(Map<String, dynamic> json) {
    final rawSessionType = json['session_type'] as String;
    final sessionType = SessionType.fromJson(rawSessionType);
    final durationMs =
        (json['duration_ms'] as num?)?.toInt() ??
        (json['duration'] as num?)?.toInt();

    return SessionDTO(
      id: json['id'] as String,
      sessionType: sessionType,
      sourceId: _sourceIdFromJson(json, sessionType),
      title: (json['title'] as String?) ?? '',
      language: (json['language'] as String?) ?? '',
      image: ImageModel.fromJsonMap(json),
      displayOrder: json['display_order'] as int,
      durationMs: durationMs,
      startDate:
          json['start_date'] != null
              ? DateTime.tryParse(json['start_date'] as String)
              : null,
      startedAt:
          json['started_at'] != null
              ? DateTime.tryParse(json['started_at'] as String)
              : null,
      currentPlanId: json['current_plan_id'] as String?,
      currentPlanTitle: json['current_plan_title'] as String?,
      firstSegment:
          json['first_segment'] is Map<String, dynamic>
              ? RecitationFirstSegmentModel.fromJson(
                json['first_segment'] as Map<String, dynamic>,
              )
              : null,
      itemCount: (json['item_count'] as num?)?.toInt(),
      rawSessionType:
          sessionType == SessionType.unknown ? rawSessionType : null,
    );
  }

  /// Preset/content id used when re-syncing this session to the API.
  ///
  /// Accumulator sessions expose [accumulator_id] (preset id) and group
  /// accumulator sessions [group_accumulator_id] rather than [source_id].
  /// Falling back to the session [id] would break PUT updates.
  static String _sourceIdFromJson(
    Map<String, dynamic> json,
    SessionType sessionType,
  ) {
    if (sessionType == SessionType.accumulator) {
      final accumulatorId = json['accumulator_id'] as String?;
      if (accumulatorId != null && accumulatorId.isNotEmpty) {
        return accumulatorId;
      }
    }
    if (sessionType == SessionType.groupAccumulator) {
      final groupAccumulatorId = json['group_accumulator_id'] as String?;
      if (groupAccumulatorId != null && groupAccumulatorId.isNotEmpty) {
        return groupAccumulatorId;
      }
    }

    final sourceId = json['source_id'] as String?;
    if (sourceId != null && sourceId.isNotEmpty) return sourceId;

    final planId = json['plan_id'] as String?;
    if (planId != null && planId.isNotEmpty) return planId;

    return json['id'] as String;
  }
}

class TimeBlockDTO {
  final String id;
  final String time;
  final int timeInt;
  final String? title;
  final bool notificationEnabled;
  final List<SessionDTO> sessions;

  const TimeBlockDTO({
    required this.id,
    required this.time,
    required this.timeInt,
    this.title,
    required this.notificationEnabled,
    required this.sessions,
  });

  factory TimeBlockDTO.fromJson(Map<String, dynamic> json) {
    return TimeBlockDTO(
      id: json['id'] as String,
      time: json['time'] as String,
      timeInt: json['time_int'] as int,
      title: json['title'] as String?,
      notificationEnabled: json['notification_enabled'] as bool,
      sessions:
          (json['sessions'] as List<dynamic>)
              .map((s) => SessionDTO.fromJson(s as Map<String, dynamic>))
              .toList(),
    );
  }
}

class RoutineWithTimeBlocksResponse {
  final String id;
  final List<TimeBlockDTO> timeBlocks;

  const RoutineWithTimeBlocksResponse({
    required this.id,
    required this.timeBlocks,
  });

  factory RoutineWithTimeBlocksResponse.fromJson(Map<String, dynamic> json) {
    return RoutineWithTimeBlocksResponse(
      id: json['id'] as String,
      timeBlocks:
          (json['time_blocks'] as List<dynamic>)
              .map((tb) => TimeBlockDTO.fromJson(tb as Map<String, dynamic>))
              .toList(),
    );
  }
}

class RoutineResponse {
  final String id;
  final List<TimeBlockDTO> timeBlocks;
  final int skip;
  final int limit;
  final int total;

  const RoutineResponse({
    required this.id,
    required this.timeBlocks,
    required this.skip,
    required this.limit,
    required this.total,
  });

  factory RoutineResponse.fromJson(Map<String, dynamic> json) {
    return RoutineResponse(
      id: json['id'] as String,
      timeBlocks:
          (json['time_blocks'] as List<dynamic>)
              .map((tb) => TimeBlockDTO.fromJson(tb as Map<String, dynamic>))
              .toList(),
      skip: json['skip'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
    );
  }
}

class ErrorResponse {
  final String error;
  final String message;

  const ErrorResponse({required this.error, required this.message});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    final detail = json['detail'];
    if (detail is Map<String, dynamic>) {
      return ErrorResponse(
        error: detail['error'] as String,
        message: detail['message'] as String,
      );
    }
    return ErrorResponse(
      error: json['error'] as String,
      message: json['message'] as String,
    );
  }
}
