import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_notification_preferences.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Flips one or both of a member's push toggles for a group.
class UpdateGroupNotificationPreferencesUseCase
    extends
        UseCase<
          GroupNotificationPreferences,
          UpdateGroupNotificationPreferencesParams
        > {
  final GroupProfileRepositoryInterface _repository;

  UpdateGroupNotificationPreferencesUseCase(this._repository);

  @override
  Future<Either<Failure, GroupNotificationPreferences>> call(
    UpdateGroupNotificationPreferencesParams params,
  ) {
    return _repository.updateGroupNotificationPreferences(
      params.groupId,
      chat: params.chat,
      content: params.content,
    );
  }
}

class UpdateGroupNotificationPreferencesParams {
  final String groupId;

  /// Leave a flag null to keep its current value.
  final bool? chat;
  final bool? content;

  const UpdateGroupNotificationPreferencesParams({
    required this.groupId,
    this.chat,
    this.content,
  }) : assert(
         chat != null || content != null,
         'At least one preference must change',
       );
}
