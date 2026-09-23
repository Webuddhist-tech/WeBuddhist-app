import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';

class PresetTimerModel {
  const PresetTimerModel({
    required this.id,
    required this.name,
    required this.durationMs,
    this.userId,
    this.groupId,
    this.type = kPresetTimerTypePreset,
    this.description,
    this.ambientSoundId,
    this.bellAtStart = true,
    this.bellAtEnd = true,
    this.parentPresetId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final int durationMs;
  final String? userId;
  final String? groupId;
  final String type;
  final String? description;
  final String? ambientSoundId;
  final bool bellAtStart;
  final bool bellAtEnd;
  final String? parentPresetId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PresetTimerModel.fromJson(Map<String, dynamic> json) {
    return PresetTimerModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      durationMs: (json['duration'] as num?)?.toInt() ?? 0,
      userId: json['user_id'] as String?,
      groupId: json['group_id'] as String?,
      type: (json['type'] as String?) ?? kPresetTimerTypePreset,
      description: json['description'] as String?,
      ambientSoundId: json['ambient_sound_id'] as String?,
      bellAtStart: json['bell_at_start'] as bool? ?? true,
      bellAtEnd: json['bell_at_end'] as bool? ?? true,
      parentPresetId: json['parent_preset_id'] as String?,
      createdAt: _tryParseDate(json['created_at']),
      updatedAt: _tryParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'duration': durationMs,
    if (userId != null) 'user_id': userId,
    if (groupId != null) 'group_id': groupId,
    'type': type,
    if (description != null) 'description': description,
    if (ambientSoundId != null) 'ambient_sound_id': ambientSoundId,
    'bell_at_start': bellAtStart,
    'bell_at_end': bellAtEnd,
    if (parentPresetId != null) 'parent_preset_id': parentPresetId,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  PresetTimer toEntity() {
    return PresetTimer(
      id: id,
      name: name,
      durationMs: durationMs,
      userId: userId,
      groupId: groupId,
      type: type,
      description: description,
      ambientSoundId: ambientSoundId,
      bellAtStart: bellAtStart,
      bellAtEnd: bellAtEnd,
      parentPresetId: parentPresetId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _tryParseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class TimersResponseModel {
  const TimersResponseModel({
    required this.timers,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<PresetTimerModel> timers;
  final int total;
  final int skip;
  final int limit;

  factory TimersResponseModel.fromJson(Map<String, dynamic> json) {
    final timersJson = (json['timers'] as List<dynamic>?) ?? [];
    return TimersResponseModel(
      timers:
          timersJson
              .map((t) => PresetTimerModel.fromJson(t as Map<String, dynamic>))
              .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
    );
  }
}
