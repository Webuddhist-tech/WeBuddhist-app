/// Elapsed time and length shown on the plan / recitation progress line.
///
/// Times are relative to the slice that actually plays. A plan task that
/// uses minutes 2–4 of a longer file is shown as a 2-minute piece, starting
/// at 0:00.
class PlanAudioProgress {
  final Duration position;
  final Duration? duration;

  const PlanAudioProgress({required this.position, this.duration});

  static const zero = PlanAudioProgress(position: Duration.zero);

  double get fraction {
    final total = duration?.inMilliseconds ?? 0;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is PlanAudioProgress &&
      other.position == position &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(position, duration);
}

/// Speeds offered by the playback picker, in order.
const List<double> planPlaybackSpeeds = <double>[
  0.5,
  0.75,
  1.0,
  1.25,
  1.5,
  2.0,
];

/// Maps a raw player position onto the slice from [startMs] to [endMs].
///
/// [position] and [fileDuration] are absolute times in the file. When [endMs]
/// is set, the slice length is `end - start` and does not depend on the file
/// length. Otherwise the slice runs from [startMs] to the end of the file,
/// once that length is known.
PlanAudioProgress describePlanAudioProgress({
  required Duration position,
  Duration? fileDuration,
  int? startMs,
  int? endMs,
}) {
  final start = Duration(milliseconds: startMs ?? 0);
  var elapsed = position - start;
  if (elapsed.isNegative) elapsed = Duration.zero;

  final Duration? length;
  if (endMs != null) {
    final window = Duration(milliseconds: endMs) - start;
    length = window.isNegative ? Duration.zero : window;
  } else if (fileDuration != null) {
    final window = fileDuration - start;
    length = window.isNegative ? Duration.zero : window;
  } else {
    length = null;
  }

  if (length != null && elapsed > length) elapsed = length;
  return PlanAudioProgress(position: elapsed, duration: length);
}

/// `0:54`, `2:40`, or `1:02:03` once the piece is an hour or longer.
String formatPlanAudioClock(Duration duration) {
  final clamped = duration.isNegative ? Duration.zero : duration;
  final hours = clamped.inHours;
  final minutes = clamped.inMinutes.remainder(60);
  final seconds = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}

/// `1.0×` for whole and half steps, `1.25×` when a quarter step is needed.
String formatPlaybackSpeed(double speed) {
  final hundredths = (speed * 100).round();
  final text =
      hundredths % 10 == 0
          ? (hundredths / 100).toStringAsFixed(1)
          : (hundredths / 100).toStringAsFixed(2);
  return '$text×';
}
