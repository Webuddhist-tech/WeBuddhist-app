import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/entities/username_update_result.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/update_user_info_usecase.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../auth/presentation/providers/auth_notifier_test.mocks.dart';
import '../../../reader/fakes/fake_local_storage.dart';

void main() {
  late MockGetCurrentUserUseCase getUser;
  late MockUpdateUserInfoUseCase updateUserInfo;
  late MockUpdateUsernameUseCase updateUsername;
  late MockConnectivityService connectivity;
  late FakeLocalStorage storage;
  late int nextCalls;

  const userId = 'sms|1';

  // What Auth0's account creation left: a placeholder name and handle.
  const generated = User(
    id: 'u1',
    firstName: 'WeBuddhist',
    lastName: 'User',
    displayName: 'WeBuddhist User',
    username: 'abigail_4821',
  );

  provideDummy<Either<Failure, User>>(const Left(UnknownFailure('dummy')));
  provideDummy<Either<Failure, UsernameUpdateResult>>(
    const Left(UnknownFailure('dummy')),
  );

  setUp(() {
    getUser = MockGetCurrentUserUseCase();
    updateUserInfo = MockUpdateUserInfoUseCase();
    updateUsername = MockUpdateUsernameUseCase();
    connectivity = MockConnectivityService();
    storage = FakeLocalStorage()..values[StorageKeys.currentUserId] = userId;
    nextCalls = 0;
    when(getUser(any)).thenAnswer((_) async => const Right(generated));
    when(connectivity.checkConnectivity()).thenAnswer((_) async => true);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith(
            (ref) => UserNotifier(
              getCurrentUserUseCase: getUser,
              updateUserInfoUseCase: updateUserInfo,
              updateUsernameUseCase: updateUsername,
              uploadAvatarUseCase: MockUploadAvatarUseCase(),
              localStorageService: storage,
            ),
          ),
          localStorageServiceProvider.overrideWithValue(storage),
          connectivityServiceProvider.overrideWithValue(connectivity),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreenProfile(onNext: () => nextCalls++),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> fillIn(
    WidgetTester tester, {
    String displayName = 'Tenzin Dhakar',
    String username = 'tenzin',
  }) async {
    await tester.enterText(find.byType(TextField).at(0), displayName);
    await tester.enterText(find.byType(TextField).at(1), username);
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the design copy', (tester) async {
    await pumpScreen(tester);

    expect(find.text('What should we call you?'), findsOneWidget);
    expect(
      find.text('This is how others will see you in the community'),
      findsOneWidget,
    );
    expect(
      find.text('You can change this anytime in Settings.'),
      findsOneWidget,
    );
    expect(find.text('Display name'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
  });

  testWidgets('both fields are required', (tester) async {
    await pumpScreen(tester);

    await tapContinue(tester);

    expect(find.text('Enter a display name'), findsOneWidget);
    expect(find.text('Username must be at least 3 characters'), findsOneWidget);
    verifyNever(updateUsername(any));
    verifyNever(updateUserInfo(any));
    expect(nextCalls, 0);
  });

  testWidgets('a taken username shows suggestions and saves nothing else', (
    tester,
  ) async {
    when(updateUsername(any)).thenAnswer(
      (_) async => Right(UsernameUpdateResult.conflict(['tenzin_42'])),
    );
    await pumpScreen(tester);
    await fillIn(tester);

    await tapContinue(tester);

    expect(find.text('tenzin_42'), findsOneWidget);
    verifyNever(updateUserInfo(any));
    expect(nextCalls, 0);
  });

  testWidgets('saves the username, then the display name, then moves on', (
    tester,
  ) async {
    when(
      updateUsername(any),
    ).thenAnswer((_) async => Right(UsernameUpdateResult.success('tenzin')));
    when(updateUserInfo(any)).thenAnswer(
      (_) async => Right(generated.copyWith(displayName: 'Tenzin Dhakar')),
    );
    await pumpScreen(tester);
    await fillIn(tester, displayName: '  Tenzin   Dhakar ');

    await tapContinue(tester);

    verify(updateUsername('tenzin')).called(1);
    final params =
        verify(updateUserInfo(captureAny)).captured.single
            as UpdateUserInfoParams;
    expect(params.displayName, 'Tenzin Dhakar');
    // The generated first and last name are kept, not blanked.
    expect(params.firstName, 'WeBuddhist');
    expect(params.lastName, 'User');
    expect(nextCalls, 1);
  });

  testWidgets('a retry after a failed save does not claim the username again', (
    tester,
  ) async {
    when(
      updateUsername(any),
    ).thenAnswer((_) async => Right(UsernameUpdateResult.success('tenzin')));
    when(
      updateUserInfo(any),
    ).thenAnswer((_) async => const Left(ServerFailure('down')));
    await pumpScreen(tester);
    await fillIn(tester);

    await tapContinue(tester);
    expect(
      find.text("Couldn't save your changes. Please try again"),
      findsOneWidget,
    );
    expect(nextCalls, 0);

    when(updateUserInfo(any)).thenAnswer((_) async => const Right(generated));
    await tapContinue(tester);

    verify(updateUsername('tenzin')).called(1);
    expect(nextCalls, 1);
  });

  testWidgets('remembers each successful save for a relaunch', (tester) async {
    when(
      updateUsername(any),
    ).thenAnswer((_) async => Right(UsernameUpdateResult.success('tenzin')));
    when(
      updateUserInfo(any),
    ).thenAnswer((_) async => const Left(ServerFailure('down')));
    await pumpScreen(tester);
    await fillIn(tester);

    await tapContinue(tester);
    expect(
      jsonDecode(storage.values[StorageKeys.onboardingProfileSaved] as String),
      {'userId': userId, 'username': 'tenzin'},
    );

    when(updateUserInfo(any)).thenAnswer((_) async => const Right(generated));
    await tapContinue(tester);
    expect(
      jsonDecode(storage.values[StorageKeys.onboardingProfileSaved] as String),
      {'userId': userId, 'username': 'tenzin', 'displayName': 'Tenzin Dhakar'},
    );
  });

  testWidgets('a relaunch restores the saved values and claims nothing twice', (
    tester,
  ) async {
    storage.values[StorageKeys.onboardingProfileSaved] = jsonEncode({
      'userId': userId,
      'username': 'tenzin',
      'displayName': 'Tenzin Dhakar',
    });
    when(updateUserInfo(any)).thenAnswer((_) async => const Right(generated));
    await pumpScreen(tester);
    await tester.pump();

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.map((f) => f.controller!.text), ['Tenzin Dhakar', 'tenzin']);

    await tapContinue(tester);

    verifyNever(updateUsername(any));
    final params =
        verify(updateUserInfo(captureAny)).captured.single
            as UpdateUserInfoParams;
    expect(params.displayName, 'Tenzin Dhakar');
    expect(nextCalls, 1);
  });

  testWidgets('a new username after a relaunch keeps the saved display name', (
    tester,
  ) async {
    storage.values[StorageKeys.onboardingProfileSaved] = jsonEncode({
      'userId': userId,
      'username': 'tenzin',
      'displayName': 'Tenzin Dhakar',
    });
    when(
      updateUsername(any),
    ).thenAnswer((_) async => Right(UsernameUpdateResult.success('tenzin_d')));
    when(
      updateUserInfo(any),
    ).thenAnswer((_) async => const Left(ServerFailure('down')));
    await pumpScreen(tester);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'tenzin_d');

    await tapContinue(tester);

    expect(
      jsonDecode(storage.values[StorageKeys.onboardingProfileSaved] as String),
      {
        'userId': userId,
        'username': 'tenzin_d',
        'displayName': 'Tenzin Dhakar',
      },
    );
  });

  testWidgets('another account\'s saved values are not restored', (
    tester,
  ) async {
    storage.values[StorageKeys.onboardingProfileSaved] = jsonEncode({
      'userId': 'sms|2',
      'username': 'someone',
      'displayName': 'Someone Else',
    });
    await pumpScreen(tester);
    await tester.pump();

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.map((f) => f.controller!.text), ['', '']);
  });

  testWidgets('offline shows a message and sends nothing', (tester) async {
    when(connectivity.checkConnectivity()).thenAnswer((_) async => false);
    await pumpScreen(tester);
    await fillIn(tester);

    await tapContinue(tester);

    expect(
      find.text("You're offline. Connect to the internet and try again"),
      findsOneWidget,
    );
    verifyNever(updateUsername(any));
    expect(nextCalls, 0);
  });

  testWidgets('saves nothing when the profile cannot be loaded', (
    tester,
  ) async {
    // Without the stored first and last name, saving would blank them.
    when(
      getUser(any),
    ).thenAnswer((_) async => const Left(ServerFailure('down')));
    await pumpScreen(tester);
    await fillIn(tester);

    await tapContinue(tester);

    expect(
      find.text("Couldn't save your changes. Please try again"),
      findsOneWidget,
    );
    verifyNever(updateUsername(any));
    verifyNever(updateUserInfo(any));
    expect(nextCalls, 0);
  });

  testWidgets('a second tap during the connectivity check saves once', (
    tester,
  ) async {
    final online = Completer<bool>();
    when(connectivity.checkConnectivity()).thenAnswer((_) => online.future);
    when(
      updateUsername(any),
    ).thenAnswer((_) async => Right(UsernameUpdateResult.success('tenzin')));
    when(updateUserInfo(any)).thenAnswer((_) async => const Right(generated));
    await pumpScreen(tester);
    await fillIn(tester);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pump();
    online.complete(true);
    await tester.pumpAndSettle();

    verify(connectivity.checkConnectivity()).called(1);
    verify(updateUsername('tenzin')).called(1);
    expect(nextCalls, 1);
  });

  testWidgets('both fields are locked while saving', (tester) async {
    final claim = Completer<Either<Failure, UsernameUpdateResult>>();
    when(updateUsername(any)).thenAnswer((_) => claim.future);
    when(updateUserInfo(any)).thenAnswer((_) async => const Right(generated));
    await pumpScreen(tester);
    await fillIn(tester);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.map((field) => field.enabled), [false, false]);

    claim.complete(Right(UsernameUpdateResult.success('tenzin')));
    await tester.pumpAndSettle();
    expect(nextCalls, 1);
  });

  testWidgets('fits a small phone with the keyboard open', (tester) async {
    // iPhone SE (375 × 667) with a keyboard and suggestion bar.
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);

    await pumpScreen(tester);
    await tester.showKeyboard(find.byType(TextField).at(0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Continue'), findsOneWidget);
  });
}
