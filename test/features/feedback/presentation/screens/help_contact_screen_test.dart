import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/feedback_receipt.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/feedback_report.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/help_topic.dart';
import 'package:flutter_pecha/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:flutter_pecha/features/feedback/presentation/providers/feedback_providers.dart';
import 'package:flutter_pecha/features/feedback/presentation/screens/help_contact_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tenzin extends StateNotifier<UserState> implements UserNotifier {
  _Tenzin()
    : super(
        const UserState(
          user: User(
            id: 'me',
            firstName: 'Tenzin',
            email: 'tenzin@example.com',
          ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepository implements FeedbackRepository {
  _FakeRepository([this.failure]);

  final Failure? failure;
  final sent = <FeedbackReport>[];

  /// When set, a send waits for it, so a test can act while it is in flight.
  Completer<void>? gate;

  @override
  Future<Either<Failure, FeedbackReceipt>> submit(FeedbackReport report) async {
    sent.add(report);
    await gate?.future;
    final failure = this.failure;
    return failure == null
        ? const Right(FeedbackReceipt(roomId: 'dm-1'))
        : Left(failure);
  }
}

const _openLabel = 'Open help';

/// A home page whose button opens Help & contact the way Settings does, and
/// stub chat routes for "Open chat" to land on.
Future<void> _pumpApp(
  WidgetTester tester,
  _FakeRepository repository, {
  HelpTopic? topic,
}) async {
  tester.view.physicalSize = const Size(480, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder:
            (context, state) => Scaffold(
              body: Consumer(
                builder:
                    (context, ref, _) => TextButton(
                      onPressed:
                          () => HelpContactScreen.open(
                            context,
                            ref,
                            topic: topic,
                          ),
                      child: const Text(_openLabel),
                    ),
              ),
            ),
      ),
      GoRoute(
        path: AppRoutes.helpContact,
        builder:
            (context, state) => HelpContactScreen(
              initialTopic:
                  state.extra is HelpTopic ? state.extra! as HelpTopic : null,
            ),
      ),
      GoRoute(
        path: AppRoutes.directChat,
        builder:
            (context, state) =>
                Text('direct chat ${state.pathParameters['roomId']}'),
      ),
      GoRoute(
        path: AppRoutes.chats,
        builder: (context, state) => const Text('chats list'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        userProvider.overrideWith((ref) => _Tenzin()),
        feedbackRepositoryProvider.overrideWithValue(repository),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'WeBuddhist',
            packageName: 'org.pecha.app',
            version: '2.5.5',
            buildNumber: '120',
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );

  await tester.tap(find.text(_openLabel));
  await tester.pumpAndSettle();
}

ElevatedButton _sendButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Send'),
        matching: find.byType(ElevatedButton),
      ),
    );

void main() {
  testWidgets('shows the form, with Send off until there is a message', (
    tester,
  ) async {
    await _pumpApp(tester, _FakeRepository());

    expect(find.text('Help & contact'), findsOneWidget);
    expect(find.text('0 / 1000'), findsOneWidget);
    expect(find.text('Photos or screenshots (optional)'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    for (final label in [
      'Report a problem',
      'Idea or feedback',
      'Suggest content',
      'Help or collaborate',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.text('Replies come from the WeBuddhist Team in your Chats.'),
      findsOneWidget,
    );
    expect(_sendButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'The reader crashes');
    await tester.pump();

    expect(_sendButton(tester).onPressed, isNotNull);
    expect(find.text('18 / 1000'), findsOneWidget);
  });

  testWidgets('the placeholder follows the picked topic', (tester) async {
    await _pumpApp(tester, _FakeRepository());

    expect(find.text('What would you like to tell us?'), findsOneWidget);

    await tester.tap(find.text('Report a problem'));
    await tester.pump();
    expect(
      find.text(
        'What happened, and what were you doing just before? '
        'A screenshot helps.',
      ),
      findsOneWidget,
    );

    // Tapping the picked topic again clears it: the topic is optional.
    await tester.tap(find.text('Report a problem'));
    await tester.pump();
    expect(find.text('What would you like to tell us?'), findsOneWidget);
  });

  testWidgets('opens with the topic its entry point picked', (tester) async {
    await _pumpApp(tester, _FakeRepository(), topic: HelpTopic.ideaFeedback);

    expect(
      find.text('What would make WeBuddhist more helpful for your practice?'),
      findsOneWidget,
    );
  });

  testWidgets('a send confirms, then Open chat goes to the Team chat', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pumpApp(tester, repository);

    await tester.enterText(
      find.byType(TextField),
      'I translate dharma texts into Nepali.',
    );
    await tester.tap(find.text('Help or collaborate'));
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    final report = repository.sent.single;
    expect(report.message, 'I translate dharma texts into Nepali.');
    expect(report.topic, HelpTopic.helpCollaborate);

    // Back on the page that opened it, under the sheet.
    expect(find.byType(HelpContactScreen), findsNothing);
    expect(find.text('Message sent'), findsOneWidget);
    expect(find.textContaining('Thanks, Tenzin.'), findsOneWidget);
    expect(find.text('Help or collaborate'), findsOneWidget);
    expect(
      find.text('“I translate dharma texts into Nepali.”'),
      findsOneWidget,
    );

    await tester.tap(find.text('Open chat'));
    await tester.pumpAndSettle();

    expect(find.text('Message sent'), findsNothing);
    expect(find.text('direct chat dm-1'), findsOneWidget);
  });

  testWidgets('a failed send stays on the form with the reason', (
    tester,
  ) async {
    await _pumpApp(tester, _FakeRepository(const NetworkFailure('offline')));

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(find.byType(HelpContactScreen), findsOneWidget);
    expect(find.text("You're offline. Please try again later"), findsOneWidget);
    expect(find.text('Message sent'), findsNothing);
  });

  testWidgets('cannot be left while a send is in flight', (tester) async {
    final repository = _FakeRepository()..gate = Completer<void>();
    await _pumpApp(tester, repository);

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pump();

    // The app bar's back button is off, and a system back is swallowed.
    final back = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      ),
    );
    expect(back.onPressed, isNull);
    await tester.binding.handlePopRoute();
    // Not pumpAndSettle: the send spinner never settles.
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HelpContactScreen), findsOneWidget);

    // Once the send lands, the screen closes into the confirmation as usual.
    repository.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(HelpContactScreen), findsNothing);
    expect(find.text('Message sent'), findsOneWidget);
    expect(repository.sent, hasLength(1));
  });

  testWidgets('can be left again after a failed send', (tester) async {
    await _pumpApp(tester, _FakeRepository(const NetworkFailure('offline')));

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HelpContactScreen), findsNothing);
    expect(find.text(_openLabel), findsOneWidget);
  });
}
