import 'dart:io';

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

  group('401 with a refreshed token', () {
    test(
      'a no_retry multipart request (feedback) is resent once, whole, '
      'with the new token',
      () async {
        // The replay goes through the interceptor's own Dio, which uses the
        // platform adapter, so serve both sends from loopback.
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        final received = <({String? auth, List<int> body})>[];
        server.listen((request) async {
          final body = (await request.toList()).expand((c) => c).toList();
          final auth = request.headers.value(HttpHeaders.authorizationHeader);
          received.add((auth: auth, body: body));
          request.response.statusCode = auth == 'Bearer fresh.jwt' ? 201 : 401;
          await request.response.close();
        });

        final dio = Dio(
          BaseOptions(baseUrl: 'http://${server.address.host}:${server.port}'),
        )..interceptors.add(interceptor);
        interceptor.configure(dio);
        when(authService.forceRefreshAccessToken())
            .thenAnswer((_) async => 'fresh.jwt');

        final form = FormData()
          ..fields.addAll(const [
            MapEntry('content', 'The timer stops when the screen locks.'),
            MapEntry('platform', 'android 14'),
          ])
          ..files.add(
            MapEntry(
              'images',
              MultipartFile.fromBytes(
                List.filled(4096, 7),
                filename: 'feedback_1.png',
              ),
            ),
          );

        final response = await dio.post<void>(
          '/feedback',
          data: form,
          options: Options(
            headers: {'Authorization': 'Bearer stale.jwt'},
            extra: {RetryInterceptor.noRetryKey: true},
          ),
        );

        expect(response.statusCode, 201);
        verify(authService.forceRefreshAccessToken()).called(1);
        expect(authExpiredCalls, 0);
        expect(received.map((r) => r.auth), [
          'Bearer stale.jwt',
          'Bearer fresh.jwt',
        ]);
        // The clone keeps the boundary, so a complete replay is byte-equal.
        expect(received[1].body.length, greaterThan(4096));
        expect(received[1].body, received[0].body);
      },
    );
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
