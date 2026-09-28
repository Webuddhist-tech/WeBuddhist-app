import 'dart:async';

import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/no_op_analytics_service.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/domain/entities/auth_credentials.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/clear_guest_mode_and_onboarding_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/clear_guest_mode_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/continue_as_guest_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/get_credentials_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/has_valid_credentials_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/initialize_auth_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/is_guest_mode_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/update_user_info_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/update_username_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../reader/fakes/fake_local_storage.dart';
import 'auth_notifier_test.mocks.dart';

@GenerateMocks([
  LoginUseCase,
  InitializeAuthUseCase,
  HasValidCredentialsUseCase,
  GetCredentialsUseCase,
  ContinueAsGuestUseCase,
  IsGuestModeUseCase,
  ClearGuestModeUseCase,
  LogoutUseCase,
  ClearGuestModeAndOnboardingUseCase,
  ConnectivityService,
  OnboardingRepositoryImpl,
  GetCurrentUserUseCase,
  UpdateUserInfoUseCase,
  UpdateUsernameUseCase,
  UploadAvatarUseCase,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  provideDummy<Either<Failure, bool>>(const Left(UnknownFailure('dummy')));
  provideDummy<Either<Failure, void>>(const Left(UnknownFailure('dummy')));
  provideDummy<Either<Failure, AuthCredentials>>(
    const Left(UnknownFailure('dummy')),
  );
  provideDummy<Either<Failure, User>>(const Left(UnknownFailure('dummy')));

  late MockInitializeAuthUseCase initAuth;
  late MockHasValidCredentialsUseCase hasValid;
  late MockGetCredentialsUseCase getCreds;
  late MockIsGuestModeUseCase isGuest;
  late MockConnectivityService connectivity;
  late MockOnboardingRepositoryImpl onboardingRepo;
  late MockGetCurrentUserUseCase getUser;
  late FakeLocalStorage storage;
  late ProviderContainer container;

  setUp(() {
    initAuth = MockInitializeAuthUseCase();
    hasValid = MockHasValidCredentialsUseCase();
    getCreds = MockGetCredentialsUseCase();
    isGuest = MockIsGuestModeUseCase();
    connectivity = MockConnectivityService();
    onboardingRepo = MockOnboardingRepositoryImpl();
    getUser = MockGetCurrentUserUseCase();
    when(
      connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream<bool>.empty());
    when(initAuth(any)).thenAnswer((_) async => const Right(null));
    when(isGuest(any)).thenAnswer((_) async => const Right(false));
    // A known install skips the Android fresh-install credential clear.
    storage = FakeLocalStorage()..values[StorageKeys.firstLaunch] = true;
  });

  /// Builds the notifier and waits for the launch restore to settle.
  Future<AuthState> restore({
    Duration stepBudget = const Duration(seconds: 10),
  }) async {
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        connectivityServiceProvider.overrideWithValue(connectivity),
        analyticsServiceProvider.overrideWithValue(
          const NoOpAnalyticsService(),
        ),
        onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
        userProvider.overrideWith(
          (ref) => UserNotifier(
            getCurrentUserUseCase: getUser,
            updateUserInfoUseCase: MockUpdateUserInfoUseCase(),
            updateUsernameUseCase: MockUpdateUsernameUseCase(),
            uploadAvatarUseCase: MockUploadAvatarUseCase(),
            localStorageService: storage,
          ),
        ),
        authProvider.overrideWith(
          (ref) => AuthNotifier(
            loginUseCase: MockLoginUseCase(),
            initializeAuthUseCase: initAuth,
            hasValidCredentialsUseCase: hasValid,
            getCredentialsUseCase: getCreds,
            continueAsGuestUseCase: MockContinueAsGuestUseCase(),
            isGuestModeUseCase: isGuest,
            clearGuestModeUseCase: MockClearGuestModeUseCase(),
            localLogoutUseCase: MockLogoutUseCase(),
            clearGuestModeAndOnboardingUseCase:
                MockClearGuestModeAndOnboardingUseCase(),
            ref: ref,
            restoreStepBudget: stepBudget,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(authProvider.notifier);
    if (!notifier.state.isLoading) return notifier.state;
    // Before the fix these paths never left isLoading, so this is the detector.
    return notifier.stream
        .firstWhere((s) => !s.isLoading)
        .timeout(const Duration(seconds: 2));
  }

  test('credential check failure resolves to logged out', () async {
    when(
      hasValid(any),
    ).thenAnswer((_) async => const Left(UnknownFailure('boom')));

    final state = await restore();

    expect(state.isLoading, isFalse);
    expect(state.isLoggedIn, isFalse);
  });

  test('exception while restoring credentials resolves the state', () async {
    when(hasValid(any)).thenAnswer((_) async => const Right(true));
    when(getCreds(any)).thenThrow(StateError('native call blew up'));

    final state = await restore();

    expect(state.isLoading, isFalse);
    expect(state.isLoggedIn, isFalse);
  });

  test('exception during auth init resolves the state', () async {
    when(initAuth(any)).thenThrow(StateError('init exploded'));
    when(hasValid(any)).thenAnswer((_) async => const Right(false));

    final state = await restore();

    expect(state.isLoading, isFalse);
  });

  test('slow onboarding and profile fetches do not hold the splash', () async {
    when(hasValid(any)).thenAnswer((_) async => const Right(true));
    when(getCreds(any)).thenAnswer(
      (_) async => Right(
        AuthCredentials(
          accessToken: 'access',
          idToken: 'a.b.c',
          tokenType: 'Bearer',
          expiresIn: 3600,
          obtainedAt: DateTime.now(),
        ),
      ),
    );
    final onboarding = Completer<Either<Failure, bool>>();
    when(
      onboardingRepo.isOnboardingCompleted(),
    ).thenAnswer((_) => onboarding.future);
    final profile = Completer<Either<Failure, User>>();
    when(getUser(any)).thenAnswer((_) => profile.future);

    final state = await restore(stepBudget: const Duration(milliseconds: 50));

    expect(state.isLoading, isFalse);
    expect(state.isLoggedIn, isTrue);
    expect(state.hasCompletedOnboarding, isNull);

    // A profile that lands after logout must not resurrect the old account.
    await container.read(userProvider.notifier).clearUser();
    profile.complete(const Right(User(id: 'u1')));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(userProvider).user, isNull);
  });

  test('a late launch profile still loads after a failed refresh', () async {
    final launch = Completer<Either<Failure, User>>();
    final answers = <Future<Either<Failure, User>>>[
      launch.future,
      Future.value(const Left(UnknownFailure('offline'))),
    ];
    when(getUser(any)).thenAnswer((_) => answers.removeAt(0));
    final notifier = UserNotifier(
      getCurrentUserUseCase: getUser,
      updateUserInfoUseCase: MockUpdateUserInfoUseCase(),
      updateUsernameUseCase: MockUpdateUsernameUseCase(),
      uploadAvatarUseCase: MockUploadAvatarUseCase(),
      localStorageService: storage,
    );
    addTearDown(notifier.dispose);

    final launchLoad = notifier.initializeUser();
    await notifier.refreshUser();
    launch.complete(const Right(User(id: 'u1')));
    await launchLoad;

    expect(notifier.state.user?.id, 'u1');
  });

  test('a late launch profile does not replace a fresher refresh', () async {
    final launch = Completer<Either<Failure, User>>();
    final answers = <Future<Either<Failure, User>>>[
      launch.future,
      Future.value(const Right(User(id: 'u1', firstName: 'fresh'))),
    ];
    when(getUser(any)).thenAnswer((_) => answers.removeAt(0));
    final notifier = UserNotifier(
      getCurrentUserUseCase: getUser,
      updateUserInfoUseCase: MockUpdateUserInfoUseCase(),
      updateUsernameUseCase: MockUpdateUsernameUseCase(),
      uploadAvatarUseCase: MockUploadAvatarUseCase(),
      localStorageService: storage,
    );
    addTearDown(notifier.dispose);

    final launchLoad = notifier.initializeUser();
    await notifier.refreshUser();
    launch.complete(const Right(User(id: 'u1', firstName: 'stale')));
    await launchLoad;

    expect(notifier.state.user?.firstName, 'fresh');
  });

  test('stored guest session is restored', () async {
    when(hasValid(any)).thenAnswer((_) async => const Right(false));
    when(isGuest(any)).thenAnswer((_) async => const Right(true));

    final state = await restore();

    expect(state.isLoading, isFalse);
    expect(state.isLoggedIn, isTrue);
    expect(state.isGuest, isTrue);
  });
}