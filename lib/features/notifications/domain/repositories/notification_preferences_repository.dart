import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_preferences.dart';
import 'package:fpdart/fpdart.dart';

abstract class NotificationPreferencesRepository {
  /// The user's account-wide push choices, resolved over the defaults.
  Future<Either<Failure, NotificationPreferences>> get();

  /// Writes only [changes] and returns everything the backend now holds.
  Future<Either<Failure, NotificationPreferences>> update(
    Map<ConnectNotificationToggle, bool> changes,
  );
}
