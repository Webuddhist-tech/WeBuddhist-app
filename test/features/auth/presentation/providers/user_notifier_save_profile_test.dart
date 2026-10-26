import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/update_user_info_usecase.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../reader/fakes/fake_local_storage.dart';
import 'auth_notifier_test.mocks.dart';

void main() {
  late MockGetCurrentUserUseCase getUser;
  late MockUpdateUserInfoUseCase updateUserInfo;
  late UserNotifier notifier;

  provideDummy<Either<Failure, User>>(const Left(UnknownFailure('dummy')));

  setUp(() {
    getUser = MockGetCurrentUserUseCase();
    updateUserInfo = MockUpdateUserInfoUseCase();
    notifier = UserNotifier(
      getCurrentUserUseCase: getUser,
      updateUserInfoUseCase: updateUserInfo,
      updateUsernameUseCase: MockUpdateUsernameUseCase(),
      uploadAvatarUseCase: MockUploadAvatarUseCase(),
      localStorageService: FakeLocalStorage(),
    );
  });

  tearDown(() => notifier.dispose());

  UpdateUserInfoParams sentParams() =>
      verify(updateUserInfo(captureAny)).captured.single
          as UpdateUserInfoParams;

  test('saving a display name keeps the first and last name', () async {
    const user = User(id: 'u1', firstName: 'Tenzin', lastName: 'Dhakar');
    when(getUser(any)).thenAnswer((_) async => const Right(user));
    when(updateUserInfo(any)).thenAnswer(
      (_) async => Right(user.copyWith(displayName: 'Tenzin')),
    );
    await notifier.initializeUser();

    final error = await notifier.saveProfile(displayName: 'Tenzin');

    expect(error, isNull);
    final params = sentParams();
    expect(params.firstName, 'Tenzin');
    expect(params.lastName, 'Dhakar');
    expect(params.displayName, 'Tenzin');
  });

  test('a user without first and last name sends empty strings', () async {
    const user = User(id: 'u1');
    when(getUser(any)).thenAnswer((_) async => const Right(user));
    when(updateUserInfo(any)).thenAnswer((_) async => const Right(user));
    await notifier.initializeUser();

    await notifier.saveProfile(displayName: 'Tenzin');

    final params = sentParams();
    expect(params.firstName, '');
    expect(params.lastName, '');
  });
}
