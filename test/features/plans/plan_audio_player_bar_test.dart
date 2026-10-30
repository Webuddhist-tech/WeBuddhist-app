import 'dart:ui' as ui;

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
    PlanSegmentAudioController.preferredRepeat = false;
    controller = PlanSegmentAudioController(
      url: 'https://cdn/a.mp3',
      startMs: 0,
      endMs: null,
      onSegmentComplete: () {},
    );
  });

  tearDown(() async {
    PlanSegmentAudioController.preferredSpeed = 1.0;
    PlanSegmentAudioController.preferredRepeat = false;
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
    expect(find.byIcon(AppAssets.repeat), findsOneWidget);
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

  testWidgets('the speed control opens a picker that applies live', (
    tester,
  ) async {
    await tester.pumpWidget(_host(PlanAudioPlayerBar(controller: controller)));

    await tester.tap(find.text('1.0×'));
    await tester.pumpAndSettle();

    expect(find.text('Playback speed'), findsOneWidget);
    expect(find.text('1.00×'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);

    await tester.tap(find.text('1.25'));
    await tester.pump();

    expect(controller.speed, 1.25);
    // The sheet's reading, and the bar's label behind it.
    expect(find.text('1.25×'), findsNWidgets(2));
    expect(find.text('Playback speed'), findsOneWidget);

    await tester.tap(find.byIcon(AppAssets.x));
    await tester.pumpAndSettle();

    expect(find.text('1.25×'), findsOneWidget);
    expect(find.text('Playback speed'), findsNothing);
  });

  testWidgets('plus and minus step the speed by 0.01', (tester) async {
    await tester.pumpWidget(_host(PlanAudioPlayerBar(controller: controller)));

    await tester.tap(find.text('1.0×'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppAssets.plus));
    await tester.pump();
    expect(controller.speed, closeTo(1.01, 0.001));
    // The sheet's reading, and the bar's label behind it.
    expect(find.text('1.01×'), findsNWidgets(2));
    expect(find.text('Playback speed'), findsOneWidget);

    await tester.tap(find.byIcon(AppAssets.minus));
    await tester.pump();
    expect(controller.speed, closeTo(1.0, 0.001));
    expect(find.text('1.00×'), findsOneWidget);
  });

  testWidgets('repeat starts off and loops until tapped again', (tester) async {
    await tester.pumpWidget(_host(PlanAudioPlayerBar(controller: controller)));

    final context = tester.element(find.byType(PlanAudioPlayerBar));
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;

    Icon repeatIcon() => tester.widget<Icon>(find.byIcon(AppAssets.repeat));

    expect(controller.repeat, isFalse);
    expect(repeatIcon().color, onSurface);

    await tester.tap(find.byIcon(AppAssets.repeat));
    await tester.pump();

    expect(controller.repeat, isTrue);
    expect(repeatIcon().color, surface);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
      findsOneWidget,
    );

    final next = PlanSegmentAudioController(
      url: 'https://cdn/b.mp3',
      startMs: 0,
      endMs: null,
      onSegmentComplete: () {},
    );
    addTearDown(next.dispose);
    expect(next.repeat, isTrue);

    await tester.tap(find.byIcon(AppAssets.repeat));
    await tester.pump();

    expect(controller.repeat, isFalse);
    expect(next.repeat, isFalse);
    expect(repeatIcon().color, onSurface);
  });

  testWidgets('repeat is remembered before a recording has started', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const PlanAudioPlayerBar(controller: null)));

    await tester.tap(find.byIcon(AppAssets.repeat));
    await tester.pump();

    expect(PlanSegmentAudioController.preferredRepeat, isTrue);
    expect(controller.repeat, isTrue);
  });

  testWidgets('a narrow track still paints when the clocks take the width', (
    tester,
  ) async {
    controller.progress.value = const PlanAudioProgress(
      position: Duration(hours: 10, minutes: 10, seconds: 10),
      duration: Duration(hours: 12, minutes: 34, seconds: 56),
    );

    await tester.pumpWidget(
      _host(
        PlanAudioPlayerBar(controller: controller),
        width: 280,
        textScaler: const TextScaler.linear(2.5),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('10:10:10'), findsOneWidget);
    expect(find.text('12:34:56'), findsOneWidget);

    final painted = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(PlanAudioPlayerBar),
        matching: find.byType(CustomPaint),
      ),
    );
    final canvas = Canvas(ui.PictureRecorder());
    expect(
      () => painted.painter!.paint(canvas, const Size(4, 16)),
      returnsNormally,
    );
    expect(() => painted.painter!.paint(canvas, Size.zero), returnsNormally);
  });

  testWidgets('the speed sheet scrolls on a short screen', (tester) async {
    tester.view.physicalSize = const Size(800, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        PlanAudioPlayerBar(controller: controller),
        textScaler: const TextScaler.linear(2.5),
      ),
    );

    await tester.tap(find.text('1.0×'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Playback speed'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Normal'),
      40,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Normal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _host(
  Widget child, {
  double width = 400,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      );
    },
    home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
  );
}
