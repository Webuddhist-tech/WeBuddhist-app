import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_request_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_cms_item.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:fpdart/fpdart.dart';

abstract class GroupEventComposerRepositoryInterface {
  Future<Either<Failure, List<GroupEventIntention>>> getIntentions();

  Future<Either<Failure, String>> createLocation(
    String groupId,
    CreateGroupLocationRequest request,
  );

  Future<Either<Failure, GroupEvent>> createEvent(
    CreateGroupEventRequest request,
  );

  Future<Either<Failure, List<GroupEventCmsItem>>> getCmsEvents(String groupId);

  Future<Either<Failure, GroupEvent>> updateEvent(
    String eventId,
    CreateGroupEventRequest request,
  );

  Future<Either<Failure, void>> deleteEvent(String eventId);
}
