import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_supporters_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeRepository implements GroupChatRepository {
  _FakeRepository(this.supporters);

  final List<ChatPrayerUserDTO> supporters;

  @override
  Future<Either<Failure, ChatPrayersPage>> listPrayers(
    String messageId, {
    int skip = 0,
    int limit = 20,
  }) async {
    return Right(
      ChatPrayersPage(
        messageId: messageId,
        prayers: supporters,
        skip: skip,
        limit: limit,
        total: supporters.length,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ChatMessageDTO _request({required int count, required int total}) {
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
    totalPrayerCount: total,
  );
}

ChatPrayerUserDTO _supporter(String name, {int times = 0}) {
  return ChatPrayerUserDTO(
    userId: name.toLowerCase(),
    name: name,
    prayerCount: times,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required ChatMessageDTO request,
  required List<ChatPrayerUserDTO> supporters,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        groupChatRepositoryProvider.overrideWithValue(
          _FakeRepository(supporters),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrayerSupportersSheet(request: request)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows people and prayer totals with each person\'s count', (
    tester,
  ) async {
    await _pump(
      tester,
      request: _request(count: 2, total: 5),
      supporters: [_supporter('Tashi', times: 3), _supporter('Pema', times: 2)],
    );

    expect(find.text('2 people · 5 prayers'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.byIcon(AppAssets.handsPraying), findsNWidgets(2));
  });

  testWidgets('keeps the people-only wording when prayers are not counted', (
    tester,
  ) async {
    await _pump(
      tester,
      request: _request(count: 1, total: 0),
      supporters: [_supporter('Tashi')],
    );

    expect(find.text('1 person prayed'), findsOneWidget);
    expect(find.byIcon(AppAssets.handsPraying), findsNothing);
    expect(find.textContaining('+'), findsNothing);
  });
}
