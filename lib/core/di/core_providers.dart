import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/cache/cache_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_pecha/core/config/api_config.dart';
import 'package:flutter_pecha/core/network/auth_service_token_provider.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/network/dio_client.dart';
import 'package:flutter_pecha/core/network/interceptors/interceptors.dart';
import 'package:flutter_pecha/core/network/network_info.dart';
import 'package:flutter_pecha/core/network/token_provider.dart';
import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/secure_storage_impl.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/env.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';

// ============ Logger ============

/// Provider for AppLogger
final loggerProvider = Provider<AppLogger>((ref) => AppLogger('DI'));

// ============ Storage ============

/// Provider for secure storage (tokens, sensitive data)
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorageImpl();
});

/// Provider for general storage (preferences, settings)
final storageServiceProvider = Provider<StorageService>((ref) {
  return SharedPreferencesService.instance;
});

// ============ Network ============

/// Provider for ApiConfig
final apiConfigProvider = Provider<ApiConfig>((ref) => ApiConfig.current);

/// Provider for ConnectivityService (singleton)
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Provider for NetworkInfo interface
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return ref.watch(connectivityServiceProvider);
});

/// Provider for AuthService (singleton)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

// ============ Token Providers ============

/// Provider for AuthService-based TokenProvider (main API)
final authTokenProvider = Provider<TokenProvider>((ref) {
  return AuthServiceTokenProvider(
    ref.watch(authServiceProvider),
    ref.watch(loggerProvider),
  );
});

// ============ Interceptors ============

/// Provider for AuthInterceptor (uses AuthService-based TokenProvider)
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(
    ref.watch(authTokenProvider),
    ref.watch(loggerProvider),
  );
});

/// Provider for LoggingInterceptor
final loggingInterceptorProvider = Provider<LoggingInterceptor>((ref) {
  return LoggingInterceptor(ref.watch(loggerProvider));
});

/// Provider for ErrorInterceptor
final errorInterceptorProvider = Provider<ErrorInterceptor>((ref) {
  return ErrorInterceptor(ref.watch(loggerProvider));
});

/// Provider for TimezoneInterceptor (adds X-Timezone to all requests)
final timezoneInterceptorProvider = Provider<TimezoneInterceptor>((ref) {
  return TimezoneInterceptor(ref.watch(loggerProvider));
});

/// Callback invoked by a [RetryInterceptor] when a token renewal fails
/// *permanently* (refresh token gone/revoked). Flips auth state to logged-out
/// so the router redirects to login while preserving the intended route.
///
/// The notifier is read lazily (not watched) to avoid Riverpod circular-init:
/// the interceptor is part of the Dio client that the auth notifier ultimately
/// depends on, so it must not construct the notifier at provider-build time.
void Function() _authExpiredHandler(Ref ref) {
  final logger = ref.watch(loggerProvider);
  return () async {
    try {
      await ref.read(authProvider.notifier).handleSessionExpired();
    } catch (e) {
      logger.warning('Failed to handle session expiry', e);
    }
  };
}

/// Provider for RetryInterceptor (main API Dio client)
final retryInterceptorProvider = Provider<RetryInterceptor>((ref) {
  return RetryInterceptor(
    ref.watch(loggerProvider),
    ref.watch(authServiceProvider),
    _authExpiredHandler(ref),
  );
});

// ============ Dio Client ============

/// Provider for main DioClient BaseOptions
final _dioBaseOptionsProvider = Provider<BaseOptions>((ref) {
  final config = ref.watch(apiConfigProvider);
  return BaseOptions(
    baseUrl: config.baseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
    sendTimeout: config.sendTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
});

/// Provider for DioClient
///
/// This is the main HTTP client for the app. It includes all interceptors
/// for auth, logging, error handling, caching, and retry logic.
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    options: ref.watch(_dioBaseOptionsProvider),
    authInterceptor: ref.watch(authInterceptorProvider),
    timezoneInterceptor: ref.watch(timezoneInterceptorProvider),
    loggingInterceptor: ref.watch(loggingInterceptorProvider),
    errorInterceptor: ref.watch(errorInterceptorProvider),
    cacheInterceptor: ref.watch(cacheInterceptorProvider),
    retryInterceptor: ref.watch(retryInterceptorProvider),
  );
});

/// Provider for raw Dio instance (for datasources that need it directly)
final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).dio;
});

// ============ Library Dio Client ============

/// Public library (texts) API client: no auth, shared cache/error/logging.
final libraryDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.libraryApiUrl,
      connectTimeout: Env.apiTimeout,
      receiveTimeout: Env.apiTimeout,
      sendTimeout: Env.apiTimeout,
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.addAll([
    ref.watch(cacheInterceptorProvider),
    ref.watch(errorInterceptorProvider),
    ref.watch(loggingInterceptorProvider),
  ]);
  return dio;
});

// ============ Cache ============

/// Provider for CacheService (singleton)
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService.instance;
});

// ============ App Info ============

/// Resolves once and caches the result for the lifetime of the app.
/// Callers that only need the version string can use [appVersionLabelProvider].
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  try {
    return await PackageInfo.fromPlatform();
  } catch (_) {
    return PackageInfo(
      appName: '',
      packageName: '',
      version: '',
      buildNumber: '',
    );
  }
});

/// Human-readable label, e.g. "Version 2.5.5".
/// Returns an empty string until the info is available or on failure.
final appVersionLabelProvider = Provider<String>((ref) {
  return ref.watch(packageInfoProvider).maybeWhen(
    data: (info) => info.version.isNotEmpty ? 'Version ${info.version}' : '',
    orElse: () => '',
  );
});

