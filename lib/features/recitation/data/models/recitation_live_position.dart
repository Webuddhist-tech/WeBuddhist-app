/// One `position` frame: where the operator is in the event's recitation.
///
/// [segmentId] is the key to render by; [index] is advisory only. [revision]
/// orders frames — `server_time` comes from whichever instance served the
/// operator and two instances' clocks need not agree.
class RecitationLivePosition {
  final String eventId;
  final String textId;
  final String segmentId;
  final int? index;
  final int? roundNumber;
  final String? serverTime;
  final int revision;

  const RecitationLivePosition({
    required this.eventId,
    required this.textId,
    required this.segmentId,
    this.index,
    this.roundNumber,
    this.serverTime,
    required this.revision,
  });

  factory RecitationLivePosition.fromJson(Map<String, dynamic> json) {
    int? asInt(Object? value) => value is num ? value.toInt() : null;
    return RecitationLivePosition(
      eventId: json['event_id'] as String? ?? '',
      textId: json['text_id'] as String? ?? '',
      segmentId: json['segment_id'] as String? ?? '',
      index: asInt(json['index']),
      roundNumber: asInt(json['round_number']),
      serverTime: json['server_time'] as String?,
      revision: asInt(json['revision']) ?? 0,
    );
  }

  bool get isValid => textId.isNotEmpty && segmentId.isNotEmpty;

  /// True when this frame is newer than [other] (or [other] is null).
  bool isNewerThan(RecitationLivePosition? other) =>
      other == null || revision > other.revision;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecitationLivePosition &&
        other.eventId == eventId &&
        other.textId == textId &&
        other.segmentId == segmentId &&
        other.roundNumber == roundNumber &&
        other.revision == revision;
  }

  @override
  int get hashCode =>
      Object.hash(eventId, textId, segmentId, roundNumber, revision);

  @override
  String toString() =>
      'RecitationLivePosition(text: $textId, segment: $segmentId, '
      'round: $roundNumber, revision: $revision)';
}
