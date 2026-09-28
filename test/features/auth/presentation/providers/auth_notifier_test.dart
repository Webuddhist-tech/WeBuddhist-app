import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/no_op_analytics_service.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/domain/entities/auth_credentials.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/clear_guest_mode_and_onboarding_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/clear_guest_mode_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/continue_as_guest_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/get_credentials_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/has_valid_credentials_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/initialize_auth_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/is_guest_mode_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
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
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  provideDummy<Either<Failure, bool>>(const Left(UnknownFailure('dummy')));
  provideDummy<Either<Failure, void>>(const Left(UnknownFailure('dummy')));
  provideDummy<Either<Failure, AuthCredentials>>(
    const Left(UnknownFailure('dummy')),
  );

  late MockInitializeAuthUseCase initAuth;
  late MockHasValidCredentialsUseCase hasValid;
  late MockGetCredentialsUseCase getCreds;
  late MockIsGuestModeUseCase isGuest;
  late MockConnectivityService connectivity;
  late FakeLocalStorage storage;

  setUp(() {
    initAuth = MockInitializeAuthUseCase();
    hasValid = MockHasValidCredentialsUseCase();
    getCreds = MockGetCredentialsUseCase();
    isGuest = MockIsGuestModeUseCase();
    connectivity = MockConnectivityService();
    when(
      connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream<bool>.empty());
    when(initAuth(any)).thenAnswer((_) async => const Right(null));
    when(isGuest(any)).thenAnswer((_) async => const Right(false));
    // A known install skips the Android fresh-install credential clear.
    storage = FakeLocalStorage()..values[StorageKeys.firstLaunch] = true;
  });

  /// Builds the notifier and waits for the launch restore to settle.
  Future<AuthState> restore() async {
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        connectivityServiceProvider.overrideWithValue(connectivity),
        analyticsServiceProvider.overrideWithValue(
          const NoOpAnalyticsService(),
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

  test('stored guest session is restored', () async {
    when(hasValid(any)).thenAnswer((_) async => const Right(false));
    when(isGuest(any)).thenAnswer((_) async => const Right(true));

    final state = await restore();

    expect(state.isLoading, isFalse);
    expect(state.isLoggedIn, isTrue);
    expect(state.isGuest, isTrue);
  });
}