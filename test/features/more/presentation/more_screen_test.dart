import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/more/presentation/more_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User extends StateNotifier<UserState> implements UserNotifier {
  _User(User? user) : super(UserState(user: user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _signedIn = AuthState(isLoggedIn: true);

const _tenzin = User(
  id: 'me',
  displayName: 'Tenzin Dolma',
  username: 'tenzin',
  email: 'tenzin@example.com',
);

Future<void> _pumpSettings(
  WidgetTester tester, {
  required AuthState auth,
  User? user,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const MoreScreen()),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const Text('edit profile'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _Auth(auth)),
        userProvider.overrideWith((ref) => _User(user)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('profile card shows the username and email when signed in', (
    tester,
  ) async {
    await _pumpSettings(tester, auth: _signedIn, user: _tenzin);

    expect(find.text('tenzin'), findsOneWidget);
    expect(find.text('tenzin@example.com'), findsOneWidget);
    expect(find.text('Tenzin Dolma'), findsNothing);
  });

  testWidgets('profile card leaves out the email when there is none', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      auth: _signedIn,
      user: const User(id: 'me', username: 'tenzin'),
    );

    expect(find.text('tenzin'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('tapping the profile card opens Edit profile', (tester) async {
    await _pumpSettings(tester, auth: _signedIn, user: _tenzin);

    await tester.tap(find.text('tenzin'));
    await tester.pumpAndSettle();

    expect(find.text('edit profile'), findsOneWidget);
  });

  testWidgets('guests see no profile card', (tester) async {
    await _pumpSettings(
      tester,
      auth: const AuthState(isLoggedIn: true, isGuest: true),
      user: _tenzin,
    );

    expect(find.text('tenzin'), findsNothing);
    expect(find.text('tenzin@example.com'), findsNothing);
  });
}
