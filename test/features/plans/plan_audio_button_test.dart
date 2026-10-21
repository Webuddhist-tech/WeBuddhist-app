import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_button.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_segment_audio_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controller whose button state the test sets directly, with no player.
class _FakeAudioController extends PlanSegmentAudioController {
  _FakeAudioController(this._state)
    : super(
        url: 'https://cdn/a.mp3',
        startMs: 0,
        endMs: null,
        onSegmentComplete: () {},
      );

  PlanAudioButtonState _state;

  @override
  PlanAudioButtonState get buttonState => _state;

  void emit(PlanAudioButtonState state) {
    _state = state;
    notifyListeners();
  }
}

void main() {
  testWidgets('follows a swapped-in controller', (tester) async {
    final key = GlobalKey();
    final first = _FakeAudioController(PlanAudioButtonState.pause);
    final second = _FakeAudioController(PlanAudioButtonState.loading);
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    Widget build(PlanSegmentAudioController controller) => MaterialApp(
      home: Scaffold(body: PlanAudioButton(key: key, controller: controller)),
    );

    await tester.pumpWidget(build(first));
    // Same key, new controller: what the reader does when the user picks
    // another recording from Audio versions.
    await tester.pumpWidget(build(second));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    second.emit(PlanAudioButtonState.pause);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(AnimatedIcon), findsOneWidget);
  });
}
