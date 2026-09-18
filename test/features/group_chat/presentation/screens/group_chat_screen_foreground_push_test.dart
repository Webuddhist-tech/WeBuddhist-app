import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/group_chat/presentation/screens/group_chat_screen.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/push_notifications/application/foreground_push_filter.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/providers/push_notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoUser extends StateNotifier<UserState> implements UserNotifier {
  _NoUser() : super(const UserState.initial());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Never emits. The tests ask the filter directly, so the stream only has to
/// exist for the subscription the screen opens in `initState`.
class _SilentPushRepository implements PushMessagingRepository {
  final _foreground = StreamController<PushMessage>.broadcast();

  @override
  Stream<PushMessage> get onForegroundMessage => _foreground.stream;

  Future<void> close() => _foreground.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _groupId = 'group-1';
const _thisGroup = {'session_type': 'CHAT', 'group_id': _groupId};
const _otherGroup = {'session_type': 'CHAT', 'group_id': 'group-2'};

/// Runs a page transition to its end, plus the frame in which the navigator
/// removes a popped route, so its screen is disposed.
Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

NavigatorState _navigator(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator));

/// Pushes the chat over a home page, the way the router does, with the group
/// profile left loading: the shell renders and claims its pushes, and never
/// resolves a room or opens a socket.
Future<ForegroundPushFilter> _pumpChat(
  WidgetTester tester,
  _SilentPushRepository pushes,
) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  addTearDown(
    () => tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    ),
  );

  final filter = ForegroundPushFilter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        userProvider.overrideWith((ref) => _NoUser()),
        groupProfileProvider.overrideWith(
          (ref, id) => Completer<Either<Failure, GroupProfile>>().future,
        ),
        pushMessagingRepositoryProvider.overrideWithValue(pushes),
        foregroundPushFilterProvider.overrideWithValue(filter),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Text('home')),
      ),
    ),
  );
  unawaited(
    _navigator(tester).push(
      MaterialPageRoute<void>(
        builder: (_) => const GroupChatScreen(groupId: _groupId),
      ),
    ),
  );
  await _settleRoute(tester);
  expect(find.byType(GroupChatScreen), findsOneWidget);
  return filter;
}

void main() {
  late _SilentPushRepository pushes;

  setUp(() => pushes = _SilentPushRepository());
  tearDown(() => pushes.close());

  testWidgets('the open chat claims pushes about its group only', (
    tester,
  ) async {
    final filter = await _pumpChat(tester, pushes);

    expect(filter.shouldShow(_thisGroup), isFalse);
    expect(filter.shouldShow(_otherGroup), isTrue);
    expect(filter.shouldShow(const {'type': 'PLAN'}), isTrue);
  });

  testWidgets('a route pushed on top hands the banner back', (tester) async {
    final filter = await _pumpChat(tester, pushes);

    unawaited(
      _navigator(tester).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('cover')),
        ),
      ),
    );
    await _settleRoute(tester);

    expect(filter.shouldShow(_thisGroup), isTrue);

    _navigator(tester).pop();
    await _settleRoute(tester);

    expect(filter.shouldShow(_thisGroup), isFalse);
  });

  testWidgets('a backgrounded app hands the banner back', (tester) async {
    final filter = await _pumpChat(tester, pushes);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(filter.shouldShow(_thisGroup), isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(filter.shouldShow(_thisGroup), isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(filter.shouldShow(_thisGroup), isFalse);
  });

  testWidgets('leaving the chat releases the claim', (tester) async {
    final filter = await _pumpChat(tester, pushes);

    _navigator(tester).pop();
    await _settleRoute(tester);

    expect(find.byType(GroupChatScreen), findsNothing);
    expect(filter.shouldShow(_thisGroup), isTrue);
  });
}
