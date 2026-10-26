import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/entities/auth_credentials.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/entities/username_update_result.dart';

/// Auth repository interface (Domain Layer)
///
/// Defines all authentication operations.
/// This abstraction allows easy swapping of auth providers (Auth0, Firebase, etc.)
abstract class AuthRepository {
  // ========== Initialization ==========

  /// Initialize auth (load config, setup provider)
  Future<Either<Failure, void>> initialize();

  // ========== Authentication Operations ==========

  /// Login with Google
  Future<Either<Failure, AuthCredentials>> loginWithGoogle();

  /// Login with Apple
  Future<Either<Failure, AuthCredentials>> loginWithApple();

  /// Login with a phone number (Auth0 passwordless SMS)
  Future<Either<Failure, AuthCredentials>> loginWithPhone();

  /// Logout (local - clears credentials from device)
  Future<Either<Failure, void>> localLogout();

  /// Check if user has valid credentials
  Future<Either<Failure, bool>> hasValidCredentials();

  /// Get current auth credentials
  Future<Either<Failure, AuthCredentials>> getCredentials();

  /// Check if a JWT (ID token, for identity) is expired
  bool isIdTokenExpired(String idToken);

  /// Get a valid access token (the API bearer); refreshes proactively if near
  /// expiry.
  Future<Either<Failure, String>> getValidAccessToken();

  /// Force a renewal and return a fresh access token (reactive 401 path).
  Future<Either<Failure, String>> forceRefreshAccessToken();

  // ========== Guest Mode Operations ==========

  /// Continue as guest mode
  Future<Either<Failure, void>> continueAsGuest();

  /// Check if in guest mode
  Future<Either<Failure, bool>> isGuestMode();

  /// Clear guest mode
  Future<Either<Failure, void>> clearGuestMode();

  // ========== User Data Operations ==========

  /// Get current user profile from backend
  Future<Either<Failure, User>> getCurrentUser();

  /// Update user profile on the backend (POST /users/info)
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
  });

  /// PATCH /users/username — saves username; returns conflict with suggestions on 409.
  Future<Either<Failure, UsernameUpdateResult>> updateUsername(String username);

  /// POST /users/upload — uploads [file] as avatar and returns the hosted URL.
  Future<Either<Failure, String>> uploadAvatar(File file);

  /// DELETE /users/info — permanently deletes the authenticated user's account.
  Future<Either<Failure, void>> deleteAccount();
}
