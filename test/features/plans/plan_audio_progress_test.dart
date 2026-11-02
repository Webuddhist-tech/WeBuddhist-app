import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a timed slice is shown from 0, not from its place in the file', () {
    final progress = describePlanAudioProgress(
      position: const Duration(milliseconds: 90000),
      startMs: 60000,
      endMs: 180000,
    );

    expect(progress.position, const Duration(seconds: 30));
    expect(progress.duration, const Duration(seconds: 120));
    expect(progress.fraction, 0.25);
  });

  test('elapsed time stays inside the slice', () {
    final before = describePlanAudioProgress(
      position: const Duration(seconds: 10),
      startMs: 60000,
      endMs: 180000,
    );
    final after = describePlanAudioProgress(
      position: const Duration(seconds: 200),
      startMs: 60000,
      endMs: 180000,
    );

    expect(before.position, Duration.zero);
    expect(after.position, const Duration(seconds: 120));
  });

  test('without an end, the slice runs to the end of the file', () {
    final unknown = describePlanAudioProgress(
      position: Duration.zero,
      startMs: 10000,
    );
    final known = describePlanAudioProgress(
      position: const Duration(milliseconds: 40000),
      fileDuration: const Duration(milliseconds: 100000),
      startMs: 10000,
    );

    expect(unknown.duration, isNull);
    expect(known.position, const Duration(seconds: 30));
    expect(known.duration, const Duration(seconds: 90));
  });

  test('clock and speed labels match the player', () {
    expect(formatPlanAudioClock(const Duration(seconds: 54)), '0:54');
    expect(
      formatPlanAudioClock(const Duration(minutes: 2, seconds: 40)),
      '2:40',
    );
    expect(
      formatPlanAudioClock(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(formatPlaybackSpeed(1), '1.0×');
    expect(formatPlaybackSpeed(0.75), '0.75×');
    expect(formatPlaybackSpeed(2), '2.0×');
  });
}
