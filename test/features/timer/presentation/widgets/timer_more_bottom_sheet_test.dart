import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/timer_more_bottom_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

/// share_plus forwards every share to this channel; holding its reply lets
/// the test close the sheet before the share result comes back.
const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

const _shortUrl = 'https://short.example/timer-1';
const _shareMessage =
    'I wanted to share this meditation timer from WeBuddhist with you. '
    'It makes it easy to build a meditation practice.';

const _timer = PresetTimer(
  id: 'timer-1',
  name: 'Morning sit',
  durationMs: 600000,
  groupId: 'group-1',
);

class _FakeShareUrlService implements ShareUrlService {
  @override
  Future<String> shorten(String longUrl) async => _shortUrl;
}

/// Opens the sheet and taps Share. The share reply is held in [shareResult],
/// so the sheet pops and is disposed while the share is still in flight.
Future<RecordingAnalyticsService> _tapShare(
  WidgetTester tester, {
  required Completer<String> shareResult,
  required List<MethodCall> shareCalls,
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_shareChannel, (call) {
        shareCalls.add(call);
        return shareResult.future;
      });
  final service = RecordingAnalyticsService();
  late BuildContext hostContext;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shareUrlServiceProvider.overrideWithValue(_FakeShareUrlService()),
        analyticsServiceProvider.overrideWithValue(service),
        isBookmarkedProvider.overrideWith((ref, target) => false),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    ),
  );

  showTimerMoreBottomSheet(hostContext, timer: _timer);
  await tester.pumpAndSettle();
  expect(find.byType(TimerMoreBottomSheet), findsOneWidget);

  await tester.tap(find.text('Share'));
  await tester.pumpAndSettle();

  // The sheet is gone before the share sheet reports anything back.
  expect(find.byType(TimerMoreBottomSheet), findsNothing);
  expect(shareCalls, hasLength(1));
  expect(service.events, isEmpty);
  return service;
}

void main() {
  final shareCalls = <MethodCall>[];

  setUp(shareCalls.clear);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, null);
  });

  testWidgets('shares the timer message with its short link', (tester) async {
    final shareResult = Completer<String>();
    await _tapShare(tester, shareResult: shareResult, shareCalls: shareCalls);
    shareResult.complete('dev.fluttercommunity.plus/share/success');
    await tester.pump();

    final args = shareCalls.single.arguments as Map<Object?, Object?>;
    expect(args['text'], '$_shareMessage\n\n$_shortUrl');
  });

  testWidgets('records one content_shared after the sheet is disposed', (
    tester,
  ) async {
    final shareResult = Completer<String>();
    final service = await _tapShare(
      tester,
      shareResult: shareResult,
      shareCalls: shareCalls,
    );

    shareResult.complete('dev.fluttercommunity.plus/share/success');
    await tester.pump();

    expect(service.eventNames, [AnalyticsEvents.contentShared]);
    expect(service.events.single.properties, {
      'surface': 'timer',
      'target_id': 'timer-1',
      'language': 'en',
      'format': 'text',
      'method': null,
      'group_id': 'group-1',
    });
  });

  testWidgets('records nothing when the share sheet is dismissed', (
    tester,
  ) async {
    final shareResult = Completer<String>();
    final service = await _tapShare(
      tester,
      shareResult: shareResult,
      shareCalls: shareCalls,
    );

    // share_plus reports a dismissed sheet as an empty result.
    shareResult.complete('');
    await tester.pump();

    expect(service.events, isEmpty);
  });
}
