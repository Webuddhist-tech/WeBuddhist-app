import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_time_utils.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum RoutineItemType {
  plan,
  series,
  recitation,
  timer,
  accumulator,
  groupRecitationCollection,
  myRecitationCollection,
  groupAccumulator,

  /// A session type this build doesn't recognise. Carried through the UI so
  /// re-syncing a block never silently deletes it.
  unknown,
}

class RoutineItem {
  final String id;
  final String title;
  final ResponsiveImage? coverImage;
  final RoutineItemType type;
  final DateTime? enrolledAt;
  final String? language;
  final DateTime? startDate;
  final String? currentPlanId;
  final String? currentPlanTitle;

  /// Duration in milliseconds — only present for [RoutineItemType.timer] items.
  final int? durationMs;

  /// Preview text for [RoutineItemType.recitation] items (from API or selection).
  final RecitationFirstSegmentModel? firstSegment;

  /// Number of chants — only present for recitation collection items.
  final int? itemCount;

  /// Original API `session_type` for [RoutineItemType.unknown] items.
  final String? rawSessionType;

  const RoutineItem({
    required this.id,
    required this.title,
    this.coverImage,
    required this.type,
    this.enrolledAt,
    this.language,
    this.startDate,
    this.currentPlanId,
    this.currentPlanTitle,
    this.durationMs,
    this.firstSegment,
    this.itemCount,
    this.rawSessionType,
  });

  /// Smallest cover URL — legacy persistence and notifications.
  String? get imageUrl => coverImage?.displayUrl;

  /// True when this session is the standalone plan [planId].
  ///
  /// Older payloads stored a plan as [RoutineItemType.series] with the plan
  /// id; those still match so duplicate-detection stays correct until refresh.
  bool representsStandalonePlan(String planId) {
    if (id != planId) return false;
    return type == RoutineItemType.plan || type == RoutineItemType.series;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (coverImage != null) 'coverImage': coverImage!.toJson(),
    'imageUrl': imageUrl,
    'type': type.name,
    'enrolledAt': enrolledAt?.toIso8601String(),
    if (language != null) 'language': language,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (currentPlanId != null) 'currentPlanId': currentPlanId,
    if (currentPlanTitle != null) 'currentPlanTitle': currentPlanTitle,
    if (durationMs != null) 'durationMs': durationMs,
    if (firstSegment != null) 'firstSegment': firstSegment!.toJson(),
    if (itemCount != null) 'itemCount': itemCount,
    if (rawSessionType != null) 'rawSessionType': rawSessionType,
  };

  /// Safely parses a [RoutineItem] from JSON with null checks and fallbacks.
  /// Returns null if required fields (id, title) are missing or invalid.
  static RoutineItem? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final id = json['id'];
    final title = json['title'];

    // Required fields must be non-null strings
    if (id is! String || id.isEmpty) return null;
    if (title is! String) return null;

    return RoutineItem(
      id: id,
      title: title,
      coverImage: _parseCoverImage(json),
      type: _parseRoutineItemType(json['type']),
      enrolledAt: _parseDateTime(json['enrolledAt']),
      language: json['language'] as String?,
      startDate: _parseDateTime(json['startDate']),
      currentPlanId: json['currentPlanId'] as String?,
      currentPlanTitle: json['currentPlanTitle'] as String?,
      durationMs: (json['durationMs'] as num?)?.toInt(),
      firstSegment: _parseFirstSegment(json),
      itemCount: (json['itemCount'] as num?)?.toInt(),
      rawSessionType: json['rawSessionType'] as String?,
    );
  }

  static RecitationFirstSegmentModel? _parseFirstSegment(
    Map<String, dynamic> json,
  ) {
    final raw = json['firstSegment'] ?? json['first_segment'];
    if (raw is! Map<String, dynamic>) return null;
    return RecitationFirstSegmentModel.fromJson(raw);
  }

  static ResponsiveImage? _parseCoverImage(Map<String, dynamic> json) {
    final dynamic rawCover = json['coverImage'];
    if (rawCover is Map<String, dynamic>) {
      return ResponsiveImage.fromJson(rawCover);
    }
    final String? legacyUrl = json['imageUrl'] as String?;
    if (legacyUrl != null && legacyUrl.isNotEmpty) {
      return ResponsiveImage.uniform(legacyUrl);
    }
    return null;
  }

  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    final item = tryFromJson(json);
    if (item == null) {
      throw FormatException('Invalid RoutineItem JSON: $json');
    }
    return item;
  }

  /// Safely parses [RoutineItemType] with fallback to [RoutineItemType.series].
  static RoutineItemType _parseRoutineItemType(dynamic value) {
    if (value is! String) return RoutineItemType.series;
    return switch (value) {
      'plan' => RoutineItemType.plan,
      'series' => RoutineItemType.series,
      'recitation' => RoutineItemType.recitation,
      'timer' => RoutineItemType.timer,
      'accumulator' => RoutineItemType.accumulator,
      'groupRecitationCollection' => RoutineItemType.groupRecitationCollection,
      'myRecitationCollection' => RoutineItemType.myRecitationCollection,
      'groupAccumulator' => RoutineItemType.groupAccumulator,
      'unknown' => RoutineItemType.unknown,
      _ => RoutineItemType.series,
    };
  }

  /// Safely parses a [DateTime] from an ISO 8601 string.
  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class RoutineBlock {
  /// Matches the backend `routine_time_blocks.title` VARCHAR(255) column.
  static const int titleMaxLength = 255;

  final String id;
  final TimeOfDay time;

  /// Optional user-given session title; null when unset.
  final String? title;
  final bool notificationEnabled;
  final List<RoutineItem> items;

  /// Server time-block id when this block exists on the API (null for new blocks).
  final String? apiTimeBlockId;

  /// Persisted notification ID for stable scheduling across app restarts.
  /// This is stored to ensure the same block always uses the same notification ID.
  final int? _persistedNotificationId;

  RoutineBlock({
    String? id,
    required this.time,
    this.title,
    this.notificationEnabled = true,
    this.items = const [],
    int? notificationId,
    this.apiTimeBlockId,
  })  : id = id ?? _uuid.v4(),
        _persistedNotificationId = notificationId;

  /// Trims [raw] and collapses blank input to null, mirroring the backend.
  static String? normalizeTitle(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  RoutineBlock copyWith({
    String? id,
    TimeOfDay? time,
    String? title,
    bool? notificationEnabled,
    List<RoutineItem>? items,
    int? notificationId,
    String? apiTimeBlockId,
  }) {
    return RoutineBlock(
      id: id ?? this.id,
      time: time ?? this.time,
      title: title ?? this.title,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      items: items ?? this.items,
      notificationId: _persistedNotificationId ?? notificationId,
      apiTimeBlockId: apiTimeBlockId ?? this.apiTimeBlockId,
    );
  }

  int get timeInMinutes => time.hour * 60 + time.minute;

  /// Unique notification ID for this block.
  ///
  /// Uses a stable algorithm that:
  /// 1. Persists the ID once generated (stored in JSON)
  /// 2. Falls back to a collision-resistant hash if not persisted
  ///
  /// Range: 1000-999999 to avoid collision with:
  /// - System IDs (0-99)
  /// - Legacy notification IDs (100-999)
  int get notificationId {
    if (_persistedNotificationId != null) {
      return _persistedNotificationId;
    }
    return _generateStableNotificationId(id);
  }

  /// Generates a stable notification ID from UUID string.
  /// Uses FNV-1a hash for better distribution than hashCode.
  static int _generateStableNotificationId(String uuid) {
    // FNV-1a 32-bit hash
    const int fnvPrime = 0x01000193;
    const int fnvOffset = 0x811c9dc5;

    int hash = fnvOffset;
    for (int i = 0; i < uuid.length; i++) {
      hash ^= uuid.codeUnitAt(i);
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }

    // Map to range 1000-999999 (998,999 possible values)
    return (hash.abs() % 998999) + 1000;
  }

  /// Returns the time formatted as "12:30 PM".
  String get formattedTime => formatRoutineTime(time);

  Map<String, dynamic> toJson() => {
    'id': id,
    'hour': time.hour,
    'minute': time.minute,
    if (title != null) 'title': title,
    'notificationEnabled': notificationEnabled,
    'notificationId': notificationId, // Persist for stability
    if (apiTimeBlockId != null) 'apiTimeBlockId': apiTimeBlockId,
    'items': items.map((i) => i.toJson()).toList(),
  };

  /// Safely parses a [RoutineBlock] from JSON with null checks and fallbacks.
  /// Returns null if required fields are missing or invalid.
  static RoutineBlock? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final id = json['id'];
    final hour = json['hour'];
    final minute = json['minute'];

    // Required fields validation
    if (id is! String || id.isEmpty) return null;
    if (hour is! int || hour < 0 || hour > 23) return null;
    if (minute is! int || minute < 0 || minute > 59) return null;

    // Parse items safely, filtering out invalid ones
    final itemsList = json['items'];
    final items = <RoutineItem>[];
    if (itemsList is List) {
      for (final itemJson in itemsList) {
        if (itemJson is Map<String, dynamic>) {
          final item = RoutineItem.tryFromJson(itemJson);
          if (item != null) {
            items.add(item);
          }
        }
      }
    }

    return RoutineBlock(
      id: id,
      time: TimeOfDay(hour: hour, minute: minute),
      title: normalizeTitle(json['title'] as String?),
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      notificationId: json['notificationId'] as int?,
      apiTimeBlockId: json['apiTimeBlockId'] as String?,
      items: items,
    );
  }

  factory RoutineBlock.fromJson(Map<String, dynamic> json) {
    final block = tryFromJson(json);
    if (block == null) {
      throw FormatException('Invalid RoutineBlock JSON: $json');
    }
    return block;
  }
}

class RoutineData {
  /// Maximum number of time blocks allowed per routine.
  static const int maxBlocks = 20;

  final List<RoutineBlock> blocks;

  /// Server routine id when loaded from or created via API.
  final String? apiRoutineId;

  const RoutineData({this.blocks = const [], this.apiRoutineId});

  bool get isEmpty => blocks.isEmpty;
  bool get hasItems => blocks.any((b) => b.items.isNotEmpty);

  /// Whether the maximum block limit has been reached.
  bool get isAtMaxBlocks => blocks.length >= maxBlocks;

  /// Returns a new RoutineData with blocks sorted by time ascending.
  RoutineData get sortedByTime {
    final sorted = List<RoutineBlock>.from(blocks)
      ..sort((a, b) => a.timeInMinutes.compareTo(b.timeInMinutes));
    return RoutineData(blocks: sorted, apiRoutineId: apiRoutineId);
  }

  Map<String, dynamic> toJson() => {
    'blocks': blocks.map((b) => b.toJson()).toList(),
    if (apiRoutineId != null) 'apiRoutineId': apiRoutineId,
  };

  /// Safely parses [RoutineData] from JSON with null checks.
  /// Invalid blocks are filtered out rather than causing a crash.
  static RoutineData? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final blocksList = json['blocks'];
    if (blocksList is! List) {
      return RoutineData(apiRoutineId: json['apiRoutineId'] as String?);
    }

    final blocks = <RoutineBlock>[];
    for (final blockJson in blocksList) {
      if (blockJson is Map<String, dynamic>) {
        final block = RoutineBlock.tryFromJson(blockJson);
        if (block != null) {
          blocks.add(block);
        }
      }
    }

    return RoutineData(
      blocks: blocks,
      apiRoutineId: json['apiRoutineId'] as String?,
    );
  }

  factory RoutineData.fromJson(Map<String, dynamic> json) {
    return tryFromJson(json) ?? const RoutineData();
  }
}
