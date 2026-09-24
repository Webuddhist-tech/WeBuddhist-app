import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Talks to Firebase Cloud Messaging and the backend, mapping the SDK's
/// `RemoteMessage` into the domain [PushMessage]. This is the only file in the
/// feature that imports firebase_messaging.
class PushMessagingRepositoryImpl implements PushMessagingRepository {
  /// Upsert endpoint for the device's push token. The base URL already carries
  /// the `/api/v1` prefix; auth is injected via the `/users/me/` rule in
  /// [ProtectedRoutes].
  static const String _deviceTokenPath = '/users/me/push-devices';

  final FirebaseMessaging _messaging;
  final Dio _dio;

  PushMessagingRepositoryImpl({required Dio dio, FirebaseMessaging? messaging})
    : _dio = dio,
      _messaging = messaging ?? FirebaseMessaging.instance;

  @override
  Future<bool> requestPermission() async {
    final status = (await _messaging.requestPermission()).authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  @override
  Future<bool> willPromptForPermission() async {
    final status =
        (await _messaging.getNotificationSettings()).authorizationStatus;
    return Platform.isAndroid
        ? status != AuthorizationStatus.authorized
        : status == AuthorizationStatus.notDetermined;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_toPushMessage);

  @override
  Stream<PushMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(_toPushMessage);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _toPushMessage(message);
  }

  @override
  Future<Either<Failure, String?>> registerDeviceToken(
    String token, {
    String? deviceId,
    Map<String, bool>? preferences,
  }) async {
    try {
      // Platform must be exactly "ANDROID" or "IOS" (case-sensitive).
      final response = await _dio.post(
        _deviceTokenPath,
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
          if (deviceId != null) 'device_id': deviceId,
          if (preferences != null) 'notification_preferences': preferences,
        },
      );
      final data = response.data;
      final id = data is Map<String, dynamic> ? data['id'] : null;
      return Right(id is String && id.isNotEmpty ? id : null);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'registerDeviceToken'));
    }
  }

  @override
  Future<Either<Failure, Unit>> unregisterDeviceToken(
    String pushDeviceId,
  ) async {
    try {
      await _dio.delete('$_deviceTokenPath/$pushDeviceId');
      return const Right(unit);
    } on DioException catch (e) {
      // Already gone (or never ours after a re-login): the goal, no pushes to
      // this registration, is met either way.
      if (e.response?.statusCode == 404) return const Right(unit);
      return Left(ExceptionMapper.map(e, context: 'unregisterDeviceToken'));
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'unregisterDeviceToken'));
    }
  }

  PushMessage _toPushMessage(RemoteMessage m) => PushMessage(
    title: m.notification?.title,
    body: m.notification?.body,
    data: m.data,
  );
}
