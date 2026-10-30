import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_summary_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_room_scope.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/random_prayer_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

const _scope = PrayerRoomScope.event('e1');

ChatMessageDTO _prayer(String id, {String sender = 'u2'}) {
  return ChatMessageDTO(
    id: id,
    roomId: 'room-1',
    senderId: sender,
    senderEmail: '$sender@example.com',
    senderName: 'Tenzin $id',
    body: 'May all be well, $id',
    createdAt: '2026-09-11T10:04:00+00:00',
    messageType: ChatMessageDTO.typePrayer,
  );
}

class _FakeRepository extends Fake implements GroupChatRepository {
  _FakeRepository({required this.history});

  final List<ChatMessageDTO> history;
  final List<List<String>> randomExcludes = [];
  final List<List<String>> prayed = [];
  Failure? randomFailure;

  @override
  Future<Either<Failure, ChatRoomDTO>> getEventRoom(
    String eventId, {
    String? language,
  }) async {
    return const Right(
      ChatRoomDTO(
        id: 'room-1',
        createdBy: 'u1',
        kind: 'EVENT',
        eventId: 'e1',
        name: 'Tara',
        updatedAt: '',
      ),
    );
  }

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
    String? messageType,
    String? sort,
    String? intention,
    String? translationLanguage,
  }) async {
    return Right(
      ChatMessagesPage(
        messages: history,
        skip: 0,
        limit: limit,
        total: history.length,
      ),
    );
  }

  @override
  Future<Either<Failure, ChatMessageDTO>> pickRandomPrayerRequest(
    String roomId, {
    List<String> excludeIds = const [],
    String? translationLanguage,
  }) async {
    randomExcludes.add(excludeIds);
    final failure = randomFailure;
    if (failure != null) return Left(failure);
    final picked = history.where((m) => !excludeIds.contains(m.id)).first;
    return Right(picked);
  }

  @override
  Future<Either<Failure, List<ChatPrayerSummaryDTO>>> prayFor(
    String roomId, {
    required List<String> messageIds,
    int count = 1,
  }) async {
    prayed.add(messageIds);
    return Right([
      for (final id in messageIds)
        ChatPrayerSummaryDTO(
          messageId: id,
          prayerCount: 1,
          prayedByMe: true,
          myPrayerCount: count,
          created: true,
        ),
    ]);
  }
}

/// Shows the overlay once the room has resolved, as the sheet's button does.
class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prayerRequestsProvider(_scope));
    if (state.roomStatus != PrayerRoomStatus.ready) {
      return const SizedBox.shrink();
    }
    return const RandomPrayerOverlay(scope: _scope);
  }
}

Future<void> _pump(WidgetTester tester, _FakeRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        groupChatRepositoryProvider.overrideWithValue(repository),
        screenCacheStoreProvider.overrideWithValue(FakeScreenCacheStore()),
        prayerPacingProvider.overrideWithValue(
          const PrayerPacing(batchWindow: Duration.zero),
        ),
        prayerTranslationLanguageProvider.overrideWithValue('EN'),
        prayerMantraLanguageProvider.overrideWithValue('en'),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: _Host()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Lets the deal run; it settles in about three and a half seconds.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('deals until the answer is in, then shows the pick', (
    tester,
  ) async {
    final repository = _FakeRepository(
      history: [_prayer('a'), _prayer('b'), _prayer('c')],
    );
    await _pump(tester, repository);

    expect(find.text('Finding a prayer...'), findsOneWidget);
    expect(find.text('A prayer for you'), findsNothing);
    expect(repository.randomExcludes, [<String>[]]);

    // A fast answer still deals for a while.
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Finding a prayer...'), findsOneWidget);

    await _settle(tester);
    expect(find.text('A prayer for you'), findsOneWidget);
    expect(find.text('May all be well, a'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Be the first to pray'), findsOneWidget);
  });

  testWidgets('praying turns Skip into Next prayer, which excludes the card', (
    tester,
  ) async {
    final repository = _FakeRepository(
      history: [_prayer('a'), _prayer('b'), _prayer('c')],
    );
    await _pump(tester, repository);
    await _settle(tester);

    await tester.tap(find.text('Pray'));
    await tester.pump();
    expect(find.text('Next prayer'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    await _settle(tester);
    expect(repository.prayed, [
      ['a'],
    ]);

    await tester.tap(find.text('Next prayer'));
    await tester.pump();
    expect(find.text('Finding a prayer...'), findsOneWidget);
    expect(repository.randomExcludes.last, ['a']);

    await _settle(tester);
    expect(find.text('May all be well, b'), findsOneWidget);
  });

  testWidgets('nothing to pick for shows the empty note', (tester) async {
    final repository = _FakeRepository(history: [_prayer('a', sender: 'u1')])
      ..randomFailure = const NotFoundFailure('NO_PRAYER_REQUESTS');
    await _pump(tester, repository);
    await _settle(tester);

    expect(find.text('No prayers to find yet'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('a deleted card is swapped for another pick', (tester) async {
    final repository = _FakeRepository(
      history: [_prayer('a'), _prayer('b'), _prayer('c')],
    );
    await _pump(tester, repository);
    await _settle(tester);
    expect(find.text('May all be well, a'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(RandomPrayerOverlay)),
    );
    container.read(prayerRequestsProvider(_scope).notifier).applyDeletion('a');
    await tester.pump();
    expect(find.text('Finding a prayer...'), findsOneWidget);
    expect(repository.randomExcludes.last, ['a']);

    await _settle(tester);
    expect(find.text('May all be well, a'), findsNothing);
    expect(find.text('May all be well, b'), findsOneWidget);
  });
}
