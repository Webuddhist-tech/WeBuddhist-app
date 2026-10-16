import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/network/interceptors/retry_interceptor.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'retry_interceptor_test.mocks.dart';

@GenerateMocks([AuthService, ErrorInterceptorHandler])
void main() {
  late MockAuthService authService;
  late MockErrorInterceptorHandler handler;
  late int authExpiredCalls;
  late RetryInterceptor interceptor;

  DioException authError({
    int statusCode = 401,
    String? bearer,
    String path = '/users/me/plans',
  }) {
    final options = RequestOptions(
      path: path,
      headers: {if (bearer != null) 'Authorization': 'Bearer $bearer'},
    );
    return DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: statusCode),
      type: DioExceptionType.badResponse,
    );
  }

  DioException unauthorized() => authError();

  setUp(() {
    authService = MockAuthService();
    handler = MockErrorInterceptorHandler();
    authExpiredCalls = 0;
    interceptor = RetryInterceptor(
      AppLogger('RetryInterceptorTest'),
      authService,
      () => authExpiredCalls++,
    );
  });

  group('401 with positive evidence the session is gone', () {
    test('missing credentials end the session for a signed-in user', () async {
      when(authService.forceRefreshAccessToken()).thenThrow(
        const CredentialsManagerException('NO_CREDENTIALS', 'none', {}),
      );
      when(authService.isGuestMode()).thenAnswer((_) async => false);

      final err = unauthorized();
      interceptor.onError(err, handler);
      await untilCalled(handler.next(any));

      expect(authExpiredCalls, 1);
      verify(handler.next(err)).called(1);
      verifyNever(handler.resolve(any));
    });

    test('a missing refresh token ends the session', () async {
      when(authService.forceRefreshAccessToken()).thenThrow(
        const CredentialsManagerException('NO_REFRESH_TOKEN', 'none', {}),
      );
      when(authService.isGuestMode()).thenAnswer((_) async => false);

      final err = unauthorized();
      interceptor.onError(err, handler);
      await untilCalled(handler.next(any));

      expect(authExpiredCalls, 1);
      verify(handler.next(err)).called(1);
    });

    test('an opaque (pre-audience) token ends the session', () async {
      when(authService.forceRefreshAccessToken()).thenThrow(
        AuthException(
          'Opaque access token; re-authentication required',
          code: AuthService.opaqueAccessTokenCode,
        ),
      );
      when(authService.isGuestMode()).thenAnswer((_) async => false);

      final err = unauthorized();
      interceptor.onError(err, handler);
      await untilCalled(handler.next(any));

      expect(authExpiredCalls, 1);
      verify(handler.next(err)).called(1);
      verifyNever(handler.resolve(any));
    });

    test('a rejected renewal (RENEW_FAILED while online) ends the session',
        () async {
      when(authService.forceRefreshAccessToken()).thenThrow(
        const CredentialsManagerException('RENEW_FAILED', 'rejected', {}),
      );
      when(authService.isGuestMode()).thenAnswer((_) async => false);

      final err = unauthorized();
      interceptor.onError(err, handler);
      await untilCalled(handler.next(any));

      expect(authExpiredCalls, 1);
      verify(handler.next(err)).called(1);
    });

    test('does not end the session for a guest', () async {
      when(authService.forceRefreshAccessToken()).thenThrow(
        const CredentialsManagerException('NO_CREDENTIALS', 'none', {}),
      );
      when(authService.isGuestMode()).thenAnswer((_) async => true);

      final err = unauthorized();
      interceptor.onError(err, handler);
      await untilCalled(handler.next(any));

      expect(authExpiredCalls, 0);
      verify(handler.next(err)).called(1);
    });
  });

  group('401 with an indeterminate credential failure', () {
    test('an untyped exception keeps the session (no logout)', () async {
      when(authService.forceRefreshAccessToken())
          .thenThrow(Exception('keystore read failed'));

      final err = unauthorized();
      interceptor.onError(err, handler);
      await untilCalled(handler.next(any));

      expect(authExpiredCalls, 0);
      verify(handler.next(err)).called(1);
      verifyNever(authService.isGuestMode());
    });

    test('a transient AuthException keeps the session', () async {
      when(authService.forceRefreshAccessToken())
          .thenThrow(AuthException('offline'));

      final err = unauthorized();
      interceptor.onError(err, handler);
      await untilCalled(handler.next(any));

      expect(authExpiredCalls, 0);
      verify(handler.next(err)).called(1);
    });
  });

  group('403 handling', () {
    test(
      'treats a 403 on a request sent WITHOUT a bearer as an auth failure '
      '(FastAPI missing-header quirk)',
      () async {
        when(authService.forceRefreshAccessToken()).thenThrow(
          const CredentialsManagerException('NO_CREDENTIALS', 'none', {}),
        );
        when(authService.isGuestMode()).thenAnswer((_) async => false);

        final err = authError(statusCode: 403);
        interceptor.onError(err, handler);
        await untilCalled(handler.next(any));

        expect(authExpiredCalls, 1);
        verify(handler.next(err)).called(1);
      },
    );

    test(
      'leaves a 403 on a PUBLIC endpoint (no bearer expected) as a genuine '
      'denial — no refresh, no logout',
      () async {
        final err = authError(statusCode: 403, path: '/languages');
        interceptor.onError(err, handler);
        await untilCalled(handler.next(any));

        expect(authExpiredCalls, 0);
        verify(handler.next(err)).called(1);
        verifyNever(authService.forceRefreshAccessToken());
      },
    );

    test(
      'leaves a 403 on a request that DID carry a bearer as a genuine '
      'permissions error — no refresh, no logout',
      () async {
        final err = authError(statusCode: 403, bearer: 'some.valid.jwt');
        interceptor.onError(err, handler);
        await untilCalled(handler.next(any));

        expect(authExpiredCalls, 0);
        verify(handler.next(err)).called(1);
        verifyNever(authService.forceRefreshAccessToken());
      },
    );
  });

  group('network retries', () {
    test('a request marked no_retry fails at once instead of resending',
        () async {
      final options = RequestOptions(
        path: '/feedback',
        method: 'POST',
        extra: {RetryInterceptor.noRetryKey: true},
      );
      final err = DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );

      interceptor.onError(err, handler);
      await untilCalled(handler.next(any));

      verify(handler.next(err)).called(1);
      verifyNever(handler.resolve(any));
      expect(options.extra['retry_count'], isNull);
    });
  });
}
