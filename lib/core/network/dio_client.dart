import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/cache_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/error_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/logging_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/retry_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/timezone_interceptor.dart';

/// Dio HTTP client with interceptors.
///
/// This client wraps Dio with all necessary interceptors for:
/// - Authentication (adding auth tokens)
/// - Timezone (X-Timezone header for date-sensitive endpoints)
/// - Logging (request/response logging)
/// - Error handling (centralized error conversion)
/// - Caching (GET request caching)
/// - Retry (automatic retry on failure)
class DioClient {
  DioClient({
    required BaseOptions options,
    required AuthInterceptor authInterceptor,
    required TimezoneInterceptor timezoneInterceptor,
    required LoggingInterceptor loggingInterceptor,
    required ErrorInterceptor errorInterceptor,
    required CacheInterceptor cacheInterceptor,
    required RetryInterceptor retryInterceptor,
  }) : _dio = Dio(options) {
    // Add interceptors in order
    // IMPORTANT: Order matters! Each interceptor processes the request/response in sequence
    _dio.interceptors.addAll([
      authInterceptor,      // 1. Add auth headers first
      timezoneInterceptor,  // 2. Add X-Timezone before cache reads the header
      cacheInterceptor,     // 3. Check cache for GET requests
      retryInterceptor,     // 4. Handle 401 token refresh & network retries
      errorInterceptor,     // 5. Convert DioExceptions to typed exceptions
      loggingInterceptor,   // 6. Log the FINAL friendly exception (not raw DioException)
    ]);

    // Configure retry interceptor with parent Dio's options for safe retries
    retryInterceptor.configure(_dio);
  }

  final Dio _dio;

  /// Get the underlying Dio instance
  Dio get dio => _dio;

  /// Close the client and release resources
  void close({bool force = false}) {
    _dio.close(force: force);
  }
}
