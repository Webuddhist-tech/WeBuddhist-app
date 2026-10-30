import 'package:equatable/equatable.dart';

/// A part of an edition that a live recitation reads more than once: on
/// reaching [afterSegmentId] the room goes back to [toSegmentId], and the
/// verses between them are read [times] times in all.
class ReturnJump extends Equatable {
  const ReturnJump({
    required this.key,
    required this.afterSegmentId,
    required this.toSegmentId,
    required this.times,
    this.label = const {},
  });

  final String key;
  final String afterSegmentId;
  final String toSegmentId;

  /// How many rounds the part is read.
  final int times;

  /// The jump's name by language code.
  final Map<String, String> label;

  factory ReturnJump.fromJson(Map<String, dynamic> json) {
    final rawLabel = json['label'];
    final rawTimes = json['times'];
    return ReturnJump(
      key: json['key'] as String? ?? '',
      afterSegmentId: json['after_segment_id'] as String? ?? '',
      toSegmentId: json['to_segment_id'] as String? ?? '',
      times: rawTimes is num ? rawTimes.toInt() : 0,
      label: {
        if (rawLabel is Map)
          for (final entry in rawLabel.entries)
            if (entry.value is String) '${entry.key}': entry.value as String,
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'after_segment_id': afterSegmentId,
    'to_segment_id': toSegmentId,
    'times': times,
    'label': label,
  };

  @override
  List<Object?> get props => [key, afterSegmentId, toSegmentId, times, label];
}

/// One edition's live recitation settings, as far as the reader uses them.
class EditionLiveSettings extends Equatable {
  const EditionLiveSettings({
    required this.editionId,
    this.returnJumps = const [],
  });

  final String editionId;
  final List<ReturnJump> returnJumps;

  factory EditionLiveSettings.fromJson(Map<String, dynamic> json) {
    final rawJumps = json['return_jumps'];
    return EditionLiveSettings(
      editionId: json['edition_id'] as String? ?? '',
      returnJumps: [
        if (rawJumps is List)
          for (final jump in rawJumps)
            if (jump is Map<String, dynamic>) ReturnJump.fromJson(jump),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'edition_id': editionId,
    'return_jumps': [for (final jump in returnJumps) jump.toJson()],
  };

  @override
  List<Object?> get props => [editionId, returnJumps];
}
