import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_request_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_cms_item.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_in_person_count.dart';
import 'package:fpdart/fpdart.dart';

abstract class GroupEventComposerRepositoryInterface {
  Future<Either<Failure, List<GroupEventIntention>>> getIntentions();

  Future<Either<Failure, List<GroupEventPracticePick>>> getPracticeOptions(
    String groupId,
  );

  Future<Either<Failure, String>> createLocation(
    String groupId,
    CreateGroupLocationRequest request,
  );

  Future<Either<Failure, GroupEvent>> createEvent(
    CreateGroupEventRequest request,
  );

  Future<Either<Failure, GroupEventInPersonCountList>> getInPersonCounts(
    String eventId, {
    required String eventAccumulationId,
    int skip = 0,
    int limit = 20,
  });

  Future<Either<Failure, GroupEventInPersonCount>> addInPersonCount(
    String eventId, {
    required String eventAccumulationId,
    required String day,
    required int count,
  });

  Future<Either<Failure, GroupEventInPersonCount>> updateInPersonCount(
    String eventId,
    String countId, {
    required String eventAccumulationId,
    required String day,
    required int count,
  });

  Future<Either<Failure, void>> deleteInPersonCount(
    String eventId,
    String countId, {
    required String eventAccumulationId,
  });

  Future<Either<Failure, List<GroupEventCmsItem>>> getCmsEvents(
    String groupId, {
    required String language,
  });

  Future<Either<Failure, GroupEvent>> updateEvent(
    String eventId,
    CreateGroupEventRequest request,
  );

  Future<Either<Failure, void>> deleteEvent(String eventId);
}
