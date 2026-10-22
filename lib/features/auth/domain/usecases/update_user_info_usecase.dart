import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

class UpdateUserInfoParams {
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? title;
  final String? organization;
  final String? location;
  final String? aboutMe;
  final String? avatarUrl;
  final List<String>? educations;
  final List<Map<String, String>>? socialProfiles;

  const UpdateUserInfoParams({
    this.firstName,
    this.lastName,
    this.displayName,
    this.title,
    this.organization,
    this.location,
    this.aboutMe,
    this.avatarUrl,
    this.educations,
    this.socialProfiles,
  });
}

/// Update the authenticated user's profile via POST /users/info.
class UpdateUserInfoUseCase extends UseCase<User, UpdateUserInfoParams> {
  final AuthRepository _repository;

  UpdateUserInfoUseCase(this._repository);

  @override
  Future<Either<Failure, User>> call(UpdateUserInfoParams params) {
    return _repository.updateUserInfo(
      firstName: params.firstName,
      lastName: params.lastName,
      displayName: params.displayName,
      title: params.title,
      organization: params.organization,
      location: params.location,
      aboutMe: params.aboutMe,
      avatarUrl: params.avatarUrl,
      educations: params.educations,
      socialProfiles: params.socialProfiles,
    );
  }
}
