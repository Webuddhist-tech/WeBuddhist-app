import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_request_tile.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessageDTO _prayer({required int count, required bool prayedByMe}) {
  return ChatMessageDTO(
    id: 'a',
    roomId: 'room-1',
    senderId: 'u1',
    senderEmail: 'u1@example.com',
    senderName: 'Tenzin',
    body: 'May all be well',
    createdAt: '2026-09-11T10:04:00+00:00',
    messageType: ChatMessageDTO.typePrayer,
    prayerCount: count,
    prayedByMe: prayedByMe,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required int count,
  required bool prayedByMe,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PrayerRequestTile(
          request: _prayer(count: count, prayedByMe: prayedByMe),
          displayName: 'Tenzin',
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('nobody praying yet reads Pray', (tester) async {
    await _pump(tester, count: 0, prayedByMe: false);
    expect(find.text('Pray'), findsOneWidget);
  });

  testWidgets('others praying counts them even before I join', (
    tester,
  ) async {
    await _pump(tester, count: 3, prayedByMe: false);
    expect(find.text('3 · Praying'), findsOneWidget);
  });

  testWidgets('my own prayer counts as one praying', (tester) async {
    await _pump(tester, count: 1, prayedByMe: true);
    expect(find.text('1 · Praying'), findsOneWidget);
  });
}
