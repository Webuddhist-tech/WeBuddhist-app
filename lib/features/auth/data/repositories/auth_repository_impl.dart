import 'dart:io';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:flutter_pecha/features/auth/domain/entities/auth_credentials.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/entities/username_update_result.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';

/// Auth repository implementation (Data Layer)
///
/// Wraps the working AuthService to provide repository interface.
/// This maintains all existing functionality while providing clean abstraction.
/// Converts between Auth0 Credentials and domain AuthCredentials.
class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({
    required AuthService authService,
    required AuthRemoteDataSource remoteDataSource,
  }) : _authService = authService,
       _remoteDataSource = remoteDataSource;

  /// Convert Auth0 Credentials to domain AuthCredentials
  AuthCredentials _toAuthCredentials(Credentials credentials) {
    final now = DateTime.now();
    final expiresAt = credentials.expiresAt;
    final expiresIn = expiresAt.difference(now).inSeconds;

    return AuthCredentials(
      accessToken: credentials.accessToken,
      idToken: credentials.idToken,
      tokenType: credentials.tokenType,
      expiresIn: expiresIn > 0 ? expiresIn : 3600,
      obtainedAt: now,
      refreshToken: credentials.refreshToken,
      scope: null, // Not exposed by Auth0 Credentials
    );
  }

  // ========== Initialization ==========

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      await _authService.initialize();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Failed to initialize auth: $e'));
    }
  }

  // ========== Authentication Operations ==========

  @override
  Future<Either<Failure, AuthCredentials>> loginWithGoogle() async {
    try {
      final credentials = await _authService.loginWithGoogle();
      if (credentials == null) {
        return const Left(AuthenticationFailure('Google login failed'));
      }
      return Right(_toAuthCredentials(credentials));
    } catch (e) {
      return Left(AuthenticationFailure('Google login failed: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthCredentials>> loginWithApple() async {
    try {
      final credentials = await _authService.loginWithApple();
      if (credentials == null) {
        return const Left(AuthenticationFailure('Apple login failed'));
      }
      return Right(_toAuthCredentials(credentials));
    } catch (e) {
      return Left(AuthenticationFailure('Apple login failed: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthCredentials>> loginWithPhone() async {
    try {
      final credentials = await _authService.loginWithPhone();
      if (credentials == null) {
        return const Left(AuthenticationFailure('Phone login failed'));
      }
      return Right(_toAuthCredentials(credentials));
    } catch (e) {
      return Left(AuthenticationFailure('Phone login failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> localLogout() async {
    try {
      await _authService.localLogout();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Logout failed: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasValidCredentials() async {
    try {
      final hasCredentials = await _authService.hasValidCredentials();
      return Right(hasCredentials);
    } catch (e) {
      return Left(UnknownFailure('Failed to check credentials: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthCredentials>> getCredentials() async {
    try {
      final credentials = await _authService.getCredentials();
      if (credentials == null) {
        return const Left(AuthenticationFailure('No credentials found'));
      }
      return Right(_toAuthCredentials(credentials));
    } catch (e) {
      return Left(_credentialFailure(e, 'Failed to get credentials'));
    }
  }

  /// Maps a credentials-operation error to a [Failure], distinguishing a
  /// permanently-lost session ([AuthenticationFailure] → re-login) from a
  /// transient/offline renewal failure ([NetworkFailure] → keep the session
  /// and retry). See [AuthService.isSessionPermanentlyLost].
  Failure _credentialFailure(Object error, String context) {
    return AuthService.isSessionPermanentlyLost(error)
        ? AuthenticationFailure('$context: $error')
        : NetworkFailure('$context: $error');
  }

  @override
  bool isIdTokenExpired(String idToken) {
    return _authService.isIdTokenExpired(idToken);
  }

  @override
  Future<Either<Failure, String>> getValidAccessToken() async {
    try {
      final accessToken = await _authService.getValidAccessToken();
      if (accessToken == null) {
        return const Left(AuthenticationFailure('No valid access token'));
      }
      return Right(accessToken);
    } catch (e) {
      return Left(_credentialFailure(e, 'Failed to get valid access token'));
    }
  }

  @override
  Future<Either<Failure, String>> forceRefreshAccessToken() async {
    try {
      final accessToken = await _authService.forceRefreshAccessToken();
      if (accessToken == null) {
        return const Left(
          AuthenticationFailure('Failed to refresh access token'),
        );
      }
      return Right(accessToken);
    } catch (e) {
      return Left(_credentialFailure(e, 'Failed to refresh access token'));
    }
  }

  // ========== Guest Mode Operations ==========

  @override
  Future<Either<Failure, void>> continueAsGuest() async {
    try {
      await _authService.continueAsGuest();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Failed to continue as guest: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isGuestMode() async {
    try {
      final isGuest = await _authService.isGuestMode();
      return Right(isGuest);
    } catch (e) {
      return Left(UnknownFailure('Failed to check guest mode: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearGuestMode() async {
    try {
      await _authService.clearGuestMode();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Failed to clear guest mode: $e'));
    }
  }

  // ========== User Data Operations ==========

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    // The bearer (access) token is attached by AuthInterceptor for protected
    // routes — no manual token prefetch needed here.
    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'getCurrentUser'));
    }
  }

  @override
  Future<Either<Failure, User>> updateUserInfo({
    String? firstName,
    String? lastName,
    String? displayName,
    String? title,
    String? organization,
    String? location,
    String? aboutMe,
    String? avatarUrl,
    List<String>? educations,
    List<Map<String, String>>? socialProfiles,
  }) async {
    final body = <String, dynamic>{
      if (firstName != null) 'firstname': firstName,
      if (lastName != null) 'lastname': lastName,
      if (displayName != null) 'display_name': displayName,
      if (title != null) 'title': title,
      if (organization != null) 'organization': organization,
      if (location != null) 'location': location,
      if (aboutMe != null) 'about_me': aboutMe,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'educations': educations ?? [],
      'social_profiles': socialProfiles ?? [],
    };

    try {
      final userModel = await _remoteDataSource.updateUserInfo(body);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'updateUserInfo'));
    }
  }

  @override
  Future<Either<Failure, UsernameUpdateResult>> updateUsername(
    String username,
  ) async {
    try {
      final result = await _remoteDataSource.updateUsername(username);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'updateUsername'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(File file) async {
    try {
      final url = await _remoteDataSource.uploadAvatar(file);
      return Right(url);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'uploadAvatar'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _remoteDataSource.deleteUser();
      return const Right(null);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'deleteAccount'));
    }
  }
}
