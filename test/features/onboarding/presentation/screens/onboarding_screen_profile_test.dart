import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
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
  late int nextCalls;

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
              localStorageService: FakeLocalStorage(),
            ),
          ),
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
}
