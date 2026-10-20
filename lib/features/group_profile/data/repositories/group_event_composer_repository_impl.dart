import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_event_composer_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_request_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_cms_item.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_event_composer_repository.dart';
import 'package:fpdart/fpdart.dart';

class GroupEventComposerRepositoryImpl
    implements GroupEventComposerRepositoryInterface {
  final GroupEventComposerRemoteDatasource remote;

  GroupEventComposerRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, List<GroupEventIntention>>> getIntentions() {
    return _guard(remote.fetchIntentions, 'Failed to load intentions');
  }

  @override
  Future<Either<Failure, String>> createLocation(
    String groupId,
    CreateGroupLocationRequest request,
  ) {
    return _guard(
      () => remote.createLocation(groupId, request),
      'Failed to create location',
    );
  }

  @override
  Future<Either<Failure, GroupEvent>> createEvent(
    CreateGroupEventRequest request,
  ) {
    return _guard(
      () async => (await remote.createEvent(request)).toEntity(),
      'Failed to create event',
    );
  }

  @override
  Future<Either<Failure, List<GroupEventCmsItem>>> getCmsEvents(
    String groupId,
  ) {
    return _guard(
      () => remote.fetchCmsEvents(groupId),
      'Failed to load events',
    );
  }

  @override
  Future<Either<Failure, GroupEvent>> updateEvent(
    String eventId,
    CreateGroupEventRequest request,
  ) {
    return _guard(
      () async => (await remote.updateEvent(eventId, request)).toEntity(),
      'Failed to update event',
    );
  }

  @override
  Future<Either<Failure, void>> deleteEvent(String eventId) {
    return _guard(() => remote.deleteEvent(eventId), 'Failed to delete event');
  }

  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() run,
    String label,
  ) async {
    try {
      return Right(await run());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('$label: $e'));
    }
  }
}
