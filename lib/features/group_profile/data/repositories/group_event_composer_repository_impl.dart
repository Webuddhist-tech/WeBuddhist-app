import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_event_composer_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_request_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_cms_item.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_in_person_count.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_event_composer_repository.dart';
import 'package:fpdart/fpdart.dart';

class GroupEventComposerRepositoryImpl
    implements GroupEventComposerRepositoryInterface {
  final GroupEventComposerRemoteDatasource remote;
  final ScreenCacheStore store;

  GroupEventComposerRepositoryImpl({required this.remote, required this.store});

  @override
  ScreenCacheSource<List<GroupEventCmsItem>> cmsEventsSource(
    String groupId, {
    required String language,
  }) {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.user(
        'group_cms_events',
        userId: store.currentUserIdSync,
        language: language,
        params: [groupId],
      ),
      fetchJson: () => remote.fetchCmsEventsJson(groupId),
      fromJson:
          (json) => GroupEventComposerRemoteDatasource.parseCmsEvents(
            (json as List).cast<Map<String, dynamic>>(),
            language: language,
          ),
      failureMessage: 'Failed to load events',
    );
  }

  @override
  Stream<Either<Failure, List<GroupEventCmsItem>>> watchCmsEvents(
    String groupId, {
    required String language,
  }) {
    return cmsEventsSource(groupId, language: language).watch();
  }

  @override
  Future<Either<Failure, List<GroupEventCmsItem>>> refreshCmsEvents(
    String groupId, {
    required String language,
  }) {
    return cmsEventsSource(groupId, language: language).refresh();
  }

  @override
  Future<Either<Failure, List<GroupEventIntention>>> getIntentions() {
    return _guard(remote.fetchIntentions, 'Failed to load intentions');
  }

  @override
  Future<Either<Failure, List<GroupEventPracticePick>>> getPracticeOptions(
    String groupId,
  ) {
    return _guard(
      () => remote.fetchPracticeOptions(groupId),
      'Failed to load practices',
    );
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
  Future<Either<Failure, GroupEventInPersonCountList>> getInPersonCounts(
    String eventId, {
    required String eventAccumulationId,
    int skip = 0,
    int limit = 20,
  }) {
    return _guard(
      () async =>
          (await remote.fetchInPersonCounts(
            eventId,
            eventAccumulationId: eventAccumulationId,
            skip: skip,
            limit: limit,
          )).toEntity(),
      'Failed to load in-person counts',
    );
  }

  @override
  Future<Either<Failure, GroupEventInPersonCount>> addInPersonCount(
    String eventId, {
    required String eventAccumulationId,
    required String day,
    required int count,
  }) {
    return _guard(
      () async =>
          (await remote.createInPersonCount(
            eventId,
            eventAccumulationId: eventAccumulationId,
            day: day,
            count: count,
          )).toEntity(),
      'Failed to add in-person count',
    );
  }

  @override
  Future<Either<Failure, GroupEventInPersonCount>> updateInPersonCount(
    String eventId,
    String countId, {
    required String eventAccumulationId,
    required String day,
    required int count,
  }) {
    return _guard(
      () async =>
          (await remote.updateInPersonCount(
            eventId,
            countId,
            eventAccumulationId: eventAccumulationId,
            day: day,
            count: count,
          )).toEntity(),
      'Failed to update in-person count',
    );
  }

  @override
  Future<Either<Failure, void>> deleteInPersonCount(
    String eventId,
    String countId, {
    required String eventAccumulationId,
  }) {
    return _guard(
      () => remote.deleteInPersonCount(
        eventId,
        countId,
        eventAccumulationId: eventAccumulationId,
      ),
      'Failed to delete in-person count',
    );
  }

  @override
  Future<Either<Failure, List<GroupEventCmsItem>>> getCmsEvents(
    String groupId, {
    required String language,
  }) {
    return _guard(
      () => remote.fetchCmsEvents(groupId, language: language),
      'Failed to load events',
    );
  }

  @override
  Future<Either<Failure, GroupEvent>> updateEvent(
    String eventId,
    CreateGroupEventRequest request, {
    CreateGroupEventRequest? original,
  }) {
    return _guard(
      () async =>
          (await remote.updateEvent(
            eventId,
            request,
            original: original,
          )).toEntity(),
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
