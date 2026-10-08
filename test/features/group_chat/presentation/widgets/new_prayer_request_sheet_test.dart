import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/new_prayer_request_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _defaultHint = 'How can we pray for you today?';

const _calm = ChatPrayerIntentionDTO(
  slug: 'calm',
  label: 'Calm',
  color: '#FFFFFF',
  description: 'Illness · Conflict · Stress',
);

const _overcome = ChatPrayerIntentionDTO(
  slug: 'overcome',
  label: 'Overcome',
  color: '#4A78C2',
  description: 'Danger · Harm · Enemies',
);

const _blank = ChatPrayerIntentionDTO(
  slug: 'blank',
  label: 'Blank',
  color: '#E8A33D',
);

ChatMessageDTO _editing(ChatPrayerIntentionDTO intention) {
  return ChatMessageDTO(
    id: 'a',
    roomId: 'room-1',
    senderId: 'u1',
    senderEmail: 'u1@example.com',
    senderName: 'Tenzin',
    body: 'May all be well',
    createdAt: '2026-09-11T10:04:00+00:00',
    messageType: ChatMessageDTO.typePrayer,
    intention: intention,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Future<List<ChatPrayerIntentionDTO>> catalog,
  ChatMessageDTO? editing,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [prayerIntentionsProvider.overrideWith((ref) => catalog)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NewPrayerRequestSheet(eventId: 'event-1', editing: editing),
        ),
      ),
    ),
  );
}

String? _hint(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).decoration?.hintText;

void main() {
  testWidgets('the hint follows the selected intention', (tester) async {
    await _pump(tester, catalog: Future.value([_calm, _overcome]));
    await tester.pumpAndSettle();

    expect(_hint(tester), _defaultHint);

    await tester.tap(find.text('Calm'));
    await tester.pump();
    expect(_hint(tester), 'Share a prayer about Illness · Conflict · Stress');

    await tester.tap(find.text('Overcome'));
    await tester.pump();
    expect(_hint(tester), 'Share a prayer about Danger · Harm · Enemies');
  });

  testWidgets('an edited request takes its description from the catalog', (
    tester,
  ) async {
    final catalog = Completer<List<ChatPrayerIntentionDTO>>();
    await _pump(
      tester,
      catalog: catalog.future,
      editing: _editing(
        const ChatPrayerIntentionDTO(
          slug: 'calm',
          label: 'Calm',
          color: '#FFFFFF',
        ),
      ),
    );
    await tester.pump();

    expect(_hint(tester), _defaultHint);

    catalog.complete([_calm, _overcome]);
    await tester.pumpAndSettle();
    expect(_hint(tester), 'Share a prayer about Illness · Conflict · Stress');
  });

  testWidgets('an intention without a description keeps the default hint', (
    tester,
  ) async {
    await _pump(tester, catalog: Future.value([_calm, _blank]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Blank'));
    await tester.pump();
    expect(_hint(tester), _defaultHint);
  });
}
