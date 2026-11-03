import 'package:flutter/material.dart';
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

Future<void> _pumpSettings(
  WidgetTester tester, {
  required AuthState auth,
  User? user,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _Auth(auth)),
        userProvider.overrideWith((ref) => _User(user)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MoreScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the email in the account section when signed in', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      auth: const AuthState(isLoggedIn: true),
      user: const User(id: 'me', email: 'tenzin@example.com'),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('tenzin@example.com'), findsOneWidget);
  });

  testWidgets('hides the email row when the account has no email', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      auth: const AuthState(isLoggedIn: true),
      user: const User(id: 'me', username: 'tenzin'),
    );

    expect(find.text('Email'), findsNothing);
  });

  testWidgets('hides the email row for guests', (tester) async {
    await _pumpSettings(
      tester,
      auth: const AuthState(isLoggedIn: true, isGuest: true),
      user: const User(id: 'me', email: 'tenzin@example.com'),
    );

    expect(find.text('Email'), findsNothing);
    expect(find.text('tenzin@example.com'), findsNothing);
  });
}
