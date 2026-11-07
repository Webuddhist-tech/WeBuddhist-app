import 'dart:async';
import 'dart:io';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/error/error_message_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMessageMapper', () {
    group('getDisplayMessage', () {
      const generic = 'An unexpected error occurred. Please try again.';

      test('handles null error', () {
        expect(ErrorMessageMapper.getDisplayMessage(null), generic);
      });

      group('Failure objects', () {
        // Failures already carry the message to show; it is passed through.
        test('passes each failure message through', () {
          const failures = <Failure>[
            NetworkFailure('Unable to connect.'),
            ServerFailure('Service unavailable.'),
            AuthenticationFailure('Session expired.'),
            AuthorizationFailure('No permission.'),
            ValidationFailure('Name is required'),
            RateLimitFailure('Slow down'),
            NotFoundFailure('Not found'),
            CacheFailure('Cache error'),
            UnknownFailure('Unknown error'),
          ];
          for (final failure in failures) {
            expect(
              ErrorMessageMapper.getDisplayMessage(failure),
              failure.message,
              reason: failure.runtimeType.toString(),
            );
          }
        });
      });

      group('Exception objects', () {
        test('handles TimeoutException', () {
          expect(
            ErrorMessageMapper.getDisplayMessage(TimeoutException('slow')),
            'Request timed out. Please try again.',
          );
        });

        test('handles SocketException', () {
          expect(
            ErrorMessageMapper.getDisplayMessage(
              const SocketException('Failed host lookup'),
            ),
            'No internet connection. Please check your network settings.',
          );
        });

        test('handles FormatException', () {
          expect(
            ErrorMessageMapper.getDisplayMessage(const FormatException('bad')),
            'Invalid data format. Please try again.',
          );
        });

        test('handles HttpException', () {
          expect(
            ErrorMessageMapper.getDisplayMessage(
              const HttpException('Status code: 500'),
            ),
            'Service error. Please try again later.',
          );
        });

        test('maps app exceptions by type', () {
          expect(
            ErrorMessageMapper.getDisplayMessage(
              const NetworkException('offline'),
            ),
            'No internet connection. Please check your network settings.',
          );
          expect(
            ErrorMessageMapper.getDisplayMessage(const ServerException('boom')),
            'Server error. Please try again later.',
          );
          expect(
            ErrorMessageMapper.getDisplayMessage(
              const RateLimitException('429'),
            ),
            'Too many requests. Please wait a moment and try again.',
          );
        });
      });

      test('falls back to the generic message for anything else', () {
        expect(
          ErrorMessageMapper.getDisplayMessage('500 Server Error'),
          generic,
        );
        expect(ErrorMessageMapper.getDisplayMessage(42), generic);
      });
    });

    group('isNetworkError', () {
      test('returns true for SocketException', () {
        final exception = SocketException('Connection failed');
        expect(ErrorMessageMapper.isNetworkError(exception), isTrue);
      });

      test('returns true for NetworkFailure', () {
        const failure = NetworkFailure('Network error');
        expect(ErrorMessageMapper.isNetworkError(failure), isTrue);
      });

      test('returns true for network-related strings', () {
        expect(ErrorMessageMapper.isNetworkError('socket error'), isTrue);
        expect(ErrorMessageMapper.isNetworkError('network error'), isTrue);
        expect(ErrorMessageMapper.isNetworkError('connection failed'), isTrue);
        expect(ErrorMessageMapper.isNetworkError('unreachable'), isTrue);
        expect(ErrorMessageMapper.isNetworkError('no internet'), isTrue);
      });

      test('returns false for non-network errors', () {
        expect(ErrorMessageMapper.isNetworkError('timeout'), isFalse);
        expect(ErrorMessageMapper.isNetworkError('status 500'), isFalse);
      });
    });

    group('isTimeoutError', () {
      test('returns true for TimeoutException', () {
        final exception = TimeoutException('Timeout');
        expect(ErrorMessageMapper.isTimeoutError(exception), isTrue);
      });

      test('returns true for timeout strings', () {
        expect(ErrorMessageMapper.isTimeoutError('timeout'), isTrue);
        expect(ErrorMessageMapper.isTimeoutError('timed out'), isTrue);
      });

      test('returns false for non-timeout errors', () {
        expect(ErrorMessageMapper.isTimeoutError('network error'), isFalse);
        expect(ErrorMessageMapper.isTimeoutError('status 500'), isFalse);
      });
    });

    group('isAuthError', () {
      test('returns true for AuthenticationFailure', () {
        const failure = AuthenticationFailure('Auth error');
        expect(ErrorMessageMapper.isAuthError(failure), isTrue);
      });

      test('returns true for auth-related strings', () {
        expect(ErrorMessageMapper.isAuthError('status 401'), isTrue);
        expect(ErrorMessageMapper.isAuthError('unauthorized'), isTrue);
        expect(ErrorMessageMapper.isAuthError('authentication failed'), isTrue);
        expect(ErrorMessageMapper.isAuthError('token expired'), isTrue);
        expect(ErrorMessageMapper.isAuthError('session expired'), isTrue);
      });

      test('returns false for non-auth errors', () {
        expect(ErrorMessageMapper.isAuthError('network error'), isFalse);
        expect(ErrorMessageMapper.isAuthError('status 500'), isFalse);
      });
    });

    group('isRetryable', () {
      test('returns true for NetworkFailure', () {
        const failure = NetworkFailure('Network error');
        expect(ErrorMessageMapper.isRetryable(failure), isTrue);
      });

      test('returns true for ServerFailure', () {
        const failure = ServerFailure('Server error');
        expect(ErrorMessageMapper.isRetryable(failure), isTrue);
      });

      test('returns true for TimeoutException', () {
        final exception = TimeoutException('Timeout');
        expect(ErrorMessageMapper.isRetryable(exception), isTrue);
      });

      test('returns true for SocketException', () {
        final exception = SocketException('Connection failed');
        expect(ErrorMessageMapper.isRetryable(exception), isTrue);
      });

      test('returns true for exceptions that read as retryable', () {
        for (final text in [
          'timeout',
          'network error',
          'connection failed',
          'status 500',
          'status 502',
          'status 503',
          'status 504',
        ]) {
          expect(ErrorMessageMapper.isRetryable(Exception(text)), isTrue);
        }
      });

      test('returns false for non-retryable errors', () {
        expect(ErrorMessageMapper.isRetryable('status 400'), isFalse);
        expect(ErrorMessageMapper.isRetryable('status 401'), isFalse);
        expect(ErrorMessageMapper.isRetryable('status 404'), isFalse);
        expect(ErrorMessageMapper.isRetryable('validation error'), isFalse);
      });
    });
  });
}
