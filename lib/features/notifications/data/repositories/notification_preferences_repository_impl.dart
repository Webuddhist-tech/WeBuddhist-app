import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/notifications/data/datasource/notification_preferences_remote_datasource.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_preferences.dart';
import 'package:flutter_pecha/features/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:fpdart/fpdart.dart';

class NotificationPreferencesRepositoryImpl
    implements NotificationPreferencesRepository {
  NotificationPreferencesRepositoryImpl({
    required NotificationPreferencesRemoteDatasource remote,
  }) : _remote = remote;

  final NotificationPreferencesRemoteDatasource _remote;

  @override
  Future<Either<Failure, NotificationPreferences>> get() async {
    try {
      return Right((await _remote.fetch()).toEntity());
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'getNotificationPreferences'),
      );
    }
  }

  @override
  Future<Either<Failure, NotificationPreferences>> update(
    Map<ConnectNotificationToggle, bool> changes,
  ) async {
    try {
      return Right((await _remote.update(changes)).toEntity());
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'updateNotificationPreferences'),
      );
    }
  }
}
