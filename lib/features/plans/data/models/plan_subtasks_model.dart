import 'package:flutter_pecha/features/plans/data/models/plan_group_accumulation_ref.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

class PlanSubtasksModel {
  final String id;
  final String? label;
  final String contentType;
  final String? content;
  final int? displayOrder;
  final String? duration;
  final String? audioUrl;
  final String? sourceTextId;
  final String? pechaSegmentId;
  final List<String>? segmentIds;
  final int? startMs;
  final int? endMs;
  final String? referenceId;
  final PlanGroupAccumulationRef? reference;

  const PlanSubtasksModel({
    required this.id,
    this.label,
    required this.contentType,
    this.content,
    this.displayOrder,
    this.duration,
    this.audioUrl,
    this.sourceTextId,
    this.pechaSegmentId,
    this.segmentIds,
    this.startMs,
    this.endMs,
    this.referenceId,
    this.reference,
  });

  /// True when this subtask carries its own audio file. A subtask-level
  /// [audioUrl] takes precedence over the day-level audio track.
  bool get hasOwnAudio => audioUrl != null;

  /// Group accumulation id when this is a GROUP_ACCUMULATION subtask.
  String? get groupAccumulationId {
    if (contentType.trim().toUpperCase() !=
        PlanContentTypes.groupAccumulation) {
      return null;
    }
    final id = reference?.id ?? referenceId;
    return (id == null || id.isEmpty) ? null : id;
  }

  factory PlanSubtasksModel.fromJson(Map<String, dynamic> json) {
    return PlanSubtasksModel(
      id: json['id'] as String,
      label: json['label'] as String?,
      contentType: json['content_type'] as String,
      content: json['content'] as String?,
      displayOrder: json['display_order'] as int?,
      duration: json['duration'] as String?,
      audioUrl: json['audio_url'] as String?,
      sourceTextId: json['source_text_id'] as String?,
      pechaSegmentId: json['pecha_segment_id'] as String?,
      segmentIds: (json['segment_ids'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      startMs: json['start_ms'] as int?,
      endMs: json['end_ms'] as int?,
      referenceId: json['reference_id'] as String?,
      reference:
          json['reference'] is Map<String, dynamic>
              ? PlanGroupAccumulationRef.fromJson(
                json['reference'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'content_type': contentType,
      'content': content,
      'display_order': displayOrder,
      'duration': duration,
      'audio_url': audioUrl,
      'source_text_id': sourceTextId,
      'pecha_segment_id': pechaSegmentId,
      'segment_ids': segmentIds,
      'start_ms': startMs,
      'end_ms': endMs,
      'reference_id': referenceId,
      'reference': reference?.toJson(),
    };
  }

  PlanSubtasksModel copyWith({
    String? id,
    String? label,
    String? contentType,
    String? content,
    int? displayOrder,
    String? duration,
    String? audioUrl,
    String? sourceTextId,
    String? pechaSegmentId,
    List<String>? segmentIds,
    int? startMs,
    int? endMs,
    String? referenceId,
    PlanGroupAccumulationRef? reference,
  }) {
    return PlanSubtasksModel(
      id: id ?? this.id,
      label: label ?? this.label,
      contentType: contentType ?? this.contentType,
      content: content ?? this.content,
      displayOrder: displayOrder ?? this.displayOrder,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      sourceTextId: sourceTextId ?? this.sourceTextId,
      pechaSegmentId: pechaSegmentId ?? this.pechaSegmentId,
      segmentIds: segmentIds ?? this.segmentIds,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      referenceId: referenceId ?? this.referenceId,
      reference: reference ?? this.reference,
    );
  }
}
