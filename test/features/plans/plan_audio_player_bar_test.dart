import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_player_bar.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_progress.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_segment_audio_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PlanSegmentAudioController controller;

  setUp(() {
    PlanSegmentAudioController.preferredSpeed = 1.0;
    controller = PlanSegmentAudioController(
      url: 'https://cdn/a.mp3',
      startMs: 0,
      endMs: null,
      onSegmentComplete: () {},
    );
  });

  tearDown(() async {
    PlanSegmentAudioController.preferredSpeed = 1.0;
    controller.dispose();
  });

  testWidgets('plan tasks show the times and speed, without a title pill', (
    tester,
  ) async {
    controller.progress.value = const PlanAudioProgress(
      position: Duration(seconds: 54),
      duration: Duration(minutes: 2, seconds: 40),
    );

    await tester.pumpWidget(_host(PlanAudioPlayerBar(controller: controller)));

    expect(find.text('0:54'), findsOneWidget);
    expect(find.text('2:40'), findsOneWidget);
    expect(find.text('1.0×'), findsOneWidget);
    expect(find.byIcon(AppAssets.speakerSimpleHigh), findsNothing);
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('dragging the line does not move playback', (tester) async {
    controller.progress.value = const PlanAudioProgress(
      position: Duration(seconds: 54),
      duration: Duration(minutes: 2, seconds: 40),
    );
    await tester.pumpWidget(_host(PlanAudioPlayerBar(controller: controller)));

    await tester.drag(find.text('0:54'), const Offset(120, 0));
    await tester.pump();

    expect(controller.progress.value.position, const Duration(seconds: 54));
    expect(find.text('0:54'), findsOneWidget);
  });

  testWidgets('a long recording title is ellipsized', (tester) async {
    const title = 'Tibetan · Monk chanting recorded at the monastery hall';
    await tester.pumpWidget(
      _host(
        PlanAudioPlayerBar(
          controller: controller,
          versionTitle: title,
          onVersionTap: () {},
        ),
        width: 320,
      ),
    );

    final text = tester.widget<Text>(find.text(title));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(find.byIcon(AppAssets.caretUp), findsOneWidget);
    expect(find.text('1.0×'), findsOneWidget);
  });

  testWidgets('the speed control opens a picker', (tester) async {
    await tester.pumpWidget(_host(PlanAudioPlayerBar(controller: controller)));

    await tester.tap(find.text('1.0×'));
    await tester.pumpAndSettle();

    expect(find.text('Playback speed'), findsOneWidget);
    await tester.tap(find.text('1.25×'));
    await tester.pumpAndSettle();

    expect(controller.speed, 1.25);
    expect(find.text('1.25×'), findsOneWidget);
    expect(find.text('Playback speed'), findsNothing);
  });
}

Widget _host(Widget child, {double width = 400}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
  );
}
