import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/your_spaces_screen.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_chats_button.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/chat_rooms_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Rooms extends StateNotifier<ChatRoomsState>
    implements ChatRoomsNotifier {
  _Rooms(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ChatRoomDTO _room({int unreadCount = 0}) => ChatRoomDTO(
  id: 'r1',
  createdBy: 'u9',
  kind: 'direct',
  name: 'r1',
  updatedAt: '2026-09-01T10:00:00Z',
  unreadCount: unreadCount,
);

Future<void> _pump(
  WidgetTester tester, {
  required AuthState auth,
  ChatRoomsState rooms = const ChatRoomsState(),
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _Auth(auth)),
        chatRoomsProvider.overrideWith((ref) => _Rooms(rooms)),
        chatRoomsPushRefreshProvider.overrideWith((ref) {}),
        chatRoomsSignalsProvider.overrideWith((ref) {}),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ConnectChatsButton()),
      ),
    ),
  );
}

void main() {
  testWidgets('guests get no chats button', (tester) async {
    await _pump(tester, auth: const AuthState(isLoggedIn: true, isGuest: true));
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('members get the button, without a dot when all is read', (
    tester,
  ) async {
    await _pump(
      tester,
      auth: const AuthState(isLoggedIn: true),
      rooms: ChatRoomsState(rooms: [_room()]),
    );
    expect(find.byType(IconButton), findsOneWidget);
    expect(find.byType(ConnectUnreadDot), findsNothing);
  });

  testWidgets('an unread chat dots the button', (tester) async {
    await _pump(
      tester,
      auth: const AuthState(isLoggedIn: true),
      rooms: ChatRoomsState(rooms: [_room(unreadCount: 3)]),
    );
    expect(find.byType(ConnectUnreadDot), findsOneWidget);
  });
}
