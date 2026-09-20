import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_client.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_live_notifier.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_live_sync_toggle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeChannel implements WebSocketChannel {
  final incoming = StreamController<dynamic>();

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  late final WebSocketSink sink = _FakeSink();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSink implements WebSocketSink {
  @override
  void add(dynamic data) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _sessionInfo =
    '{"type":"session_info","event_id":"ev1","is_operator":false}';
const _position =
    '{"type":"position","event_id":"ev1","text_id":"t1",'
    '"segment_id":"s1","revision":1,"round_number":1}';
const _ended = '{"type":"session_ended"}';

/// Pumps the button over a notifier whose socket the test feeds by hand.
Future<(RecitationLiveNotifier, _FakeChannel)> _pumpToggle(
  WidgetTester tester,
) async {
  final channel = _FakeChannel();
  final notifier = RecitationLiveNotifier(
    eventId: 'ev1',
    restBaseUrl: 'https://api.example.com/api/v1',
    getToken: () async => 'tok',
    clientFactory: () => RecitationLiveClient(connect: (_) => channel),
    observeLifecycle: false,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [recitationLiveProvider.overrideWith((ref, id) => notifier)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            actions: const [RecitationLiveSyncToggle(eventId: 'ev1')],
          ),
        ),
      ),
    ),
  );
  // Token resolves and the socket opens.
  await tester.pump();
  await _send(tester, channel, _sessionInfo);
  return (notifier, channel);
}

/// One pump delivers the frame; the next draws the rebuild it caused.
Future<void> _send(
  WidgetTester tester,
  _FakeChannel channel,
  String frame,
) async {
  channel.incoming.add(frame);
  await tester.pump();
  await tester.pump();
}

final Finder _icon = find.byIcon(AppAssets.arrowsClockwise);

Color? _iconColor(WidgetTester tester) => tester.widget<Icon>(_icon).color;

void main() {
  testWidgets('appears with the first position and lights up while following', (
    tester,
  ) async {
    final (notifier, channel) = await _pumpToggle(tester);
    expect(_icon, findsNothing);

    await _send(tester, channel, _position);

    expect(_icon, findsOneWidget);
    expect(find.byTooltip('Sync'), findsOneWidget);
    // Icon only: no label, no round number.
    expect(find.text('Sync'), findsNothing);
    expect(find.text('Round 1'), findsNothing);
    expect(_iconColor(tester), AppColors.eventOnlineChip);

    await tester.tap(_icon);
    await tester.pump();
    expect(notifier.state.followMode, RecitationLiveFollowMode.off);
    expect(_iconColor(tester), AppColors.grey500);

    // Turning it back on asks for a re-scroll to the live line.
    final requests = notifier.state.followRequest;
    await tester.tap(_icon);
    await tester.pump();
    expect(notifier.state.followMode, RecitationLiveFollowMode.following);
    expect(notifier.state.followRequest, requests + 1);
    expect(_iconColor(tester), AppColors.eventOnlineChip);

    // Scrolling away pauses following, which reads as off.
    notifier.pauseFollowing();
    await tester.pump();
    expect(_iconColor(tester), AppColors.grey500);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disappears once the session ends', (tester) async {
    final (_, channel) = await _pumpToggle(tester);
    await _send(tester, channel, _position);
    expect(_icon, findsOneWidget);

    await _send(tester, channel, _ended);
    expect(_icon, findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
