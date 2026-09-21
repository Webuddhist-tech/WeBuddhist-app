import 'package:flutter_pecha/core/utils/audio_url.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_video_model.dart';

class PlanDaysModel {
  final String id;
  final int dayNumber;
  final String? title;
  final List<PlanTasksModel>? tasks;
  final String? audioUrl;
  final int? audioDurationMs;
  final String? thumbnailUrl;
  final String? shareableImageUrl;
  final List<PlanVideoModel> videos;

  PlanDaysModel({
    required this.id,
    required this.dayNumber,
    this.title,
    this.tasks,
    this.audioUrl,
    this.audioDurationMs,
    this.thumbnailUrl,
    this.shareableImageUrl,
    this.videos = const [],
  });

  bool get hasAudio => hasPlayableAudio(audioUrl);

  factory PlanDaysModel.fromJson(Map<String, dynamic> json) {
    return PlanDaysModel(
      id: json['id'] as String,
      dayNumber: json['day_number'] as int,
      title: json['title'] as String?,
      tasks:
          json['tasks'] != null
              ? (json['tasks'] as List<dynamic>)
                  .map(
                    (e) => PlanTasksModel.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
              : null,
      audioUrl: json['audio_url'] as String?,
      audioDurationMs: json['audio_duration_ms'] as int?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      shareableImageUrl: json['shareable_image_url'] as String?,
      videos:
          json['videos'] != null
              ? (json['videos'] as List<dynamic>)
                  .map(
                    (e) => PlanVideoModel.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
              : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_number': dayNumber,
      'title': title,
      'tasks': tasks?.map((e) => e.toJson()).toList(),
      'audio_url': audioUrl,
      'audio_duration_ms': audioDurationMs,
      'thumbnail_url': thumbnailUrl,
      'shareable_image_url': shareableImageUrl,
      'videos': videos.map((e) => e.toJson()).toList(),
    };
  }

  PlanDaysModel copyWith({
    String? id,
    int? dayNumber,
    String? title,
    List<PlanTasksModel>? tasks,
    String? audioUrl,
    int? audioDurationMs,
    String? thumbnailUrl,
    String? shareableImageUrl,
    List<PlanVideoModel>? videos,
  }) {
    return PlanDaysModel(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      tasks: tasks ?? this.tasks,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDurationMs: audioDurationMs ?? this.audioDurationMs,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      shareableImageUrl: shareableImageUrl ?? this.shareableImageUrl,
      videos: videos ?? this.videos,
    );
  }

  bool get isDeleted => false;
  bool get isActive => !isDeleted;
  String get dayLabel => 'Day $dayNumber';
  bool get isFirstDay => dayNumber == 1;
  bool get isValidDayNumber => dayNumber > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanDaysModel &&
        other.id == id &&
        other.dayNumber == dayNumber;
  }

  @override
  int get hashCode => Object.hash(id, dayNumber);

  @override
  String toString() =>
      'PlanDaysModel(id: $id, dayNumber: $dayNumber, hasAudio: $hasAudio)';
}
