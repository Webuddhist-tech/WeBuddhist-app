import 'dart:io';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/data/models/user_model.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/entities/username_update_result.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/update_user_info_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/update_username_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('UserNotifier');

/// UserNotifier manages user state and provides reactive user data to app
///
/// This is single source of truth for user profile data.
/// Follows industry best practices:
/// - Separation of concerns (Auth != User Profile)
/// - Single source of truth
/// - Reactive state management
/// - Proper error handling
class UserNotifier extends StateNotifier<UserState> {
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final UpdateUserInfoUseCase _updateUserInfoUseCase;
  final UpdateUsernameUseCase _updateUsernameUseCase;
  final UploadAvatarUseCase _uploadAvatarUseCase;
  final LocalStorageService _localStorageService;

  /// Bumped by every load and by [clearUser] so a late response cannot win.
  int _loadGeneration = 0;

  UserNotifier({
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required UpdateUserInfoUseCase updateUserInfoUseCase,
    required UpdateUsernameUseCase updateUsernameUseCase,
    required UploadAvatarUseCase uploadAvatarUseCase,
    required LocalStorageService localStorageService,
  }) : _getCurrentUserUseCase = getCurrentUserUseCase,
       _updateUserInfoUseCase = updateUserInfoUseCase,
       _updateUsernameUseCase = updateUsernameUseCase,
       _uploadAvatarUseCase = uploadAvatarUseCase,
       _localStorageService = localStorageService,
       super(const UserState.initial());

  /// Initialize user data from API or local cache
  /// Call this after successful authentication
  Future<void> initializeUser() async {
    _logger.debug('Initializing user data');
    state = const UserState.loading();
    final generation = ++_loadGeneration;

    final userResult = await _getCurrentUserUseCase(const NoParams());
    if (generation != _loadGeneration) return;

    userResult.fold(
      (failure) {
        _logger.error('Error getting user from API: ${failure.message}');
        // Try local cache on error
        _loadFromLocalCache();
      },
      (user) {
        _logger.info('User data loaded from API: ${user.displayName}');
        state = UserState.loaded(user);
        _cacheUserLocally(user);
      },
    );
  }

  /// Refresh user data from API
  Future<void> refreshUser() async {
    final generation = ++_loadGeneration;
    final userResult = await _getCurrentUserUseCase(const NoParams());
    if (generation != _loadGeneration) return;

    userResult.fold(
      (failure) {
        _logger.error('Error refreshing user: ${failure.message}');
        // Keep current state on refresh error
        state = state.copyWith(errorMessage: 'Failed to refresh user data');
      },
      (user) {
        _logger.debug('User data refreshed: ${user.displayName}');
        state = UserState.loaded(user);
        _cacheUserLocally(user);
      },
    );
  }

  /// Update user data (optimistic update + API sync)
  Future<void> updateUser(User updatedUser) async {
    try {
      // Optimistic update
      state = UserState.loaded(updatedUser);

      // Cache locally
      await _cacheUserLocally(updatedUser);

      _logger.debug('User data updated: ${updatedUser.displayName}');
    } catch (e) {
      _logger.error('Error updating user', e);
      state = state.copyWith(errorMessage: 'Failed to update user data');
    }
  }

  /// Save profile changes to the backend (POST /users/info).
  ///
  /// Returns an error message on failure, or null on success.
  Future<String?> saveProfile({
    String? firstName,
    String? lastName,
    String? aboutMe,
    String? avatarUrl,
    String? title,
    String? organization,
    String? location,
    List<String>? educations,
    List<Map<String, String>>? socialProfiles,
  }) async {
    final result = await _updateUserInfoUseCase(
      UpdateUserInfoParams(
        firstName: firstName,
        lastName: lastName,
        aboutMe: aboutMe,
        avatarUrl: avatarUrl,
        title: title,
        organization: organization,
        location: location,
        educations: educations,
        socialProfiles: socialProfiles,
      ),
    );

    return result.fold(
      (failure) {
        _logger.error('Failed to update user info: ${failure.message}');
        return failure.message;
      },
      (updatedUser) {
        _logger.info('Profile saved: ${updatedUser.displayName}');
        state = UserState.loaded(updatedUser);
        _cacheUserLocally(updatedUser);
        return null;
      },
    );
  }

  /// Update username via PATCH /users/username.
  ///
  /// Returns [UsernameUpdateResult] on success/conflict, or null on network
  /// / auth failure.
  Future<UsernameUpdateResult?> updateUsername(String username) async {
    final result = await _updateUsernameUseCase(username);

    return result.fold(
      (failure) {
        _logger.error('Failed to update username: ${failure.message}');
        return null;
      },
      (usernameResult) {
        if (usernameResult.isAvailable && usernameResult.updatedUsername != null) {
          // Optimistically update local user state with the confirmed username.
          if (state.user != null) {
            final updated = state.user!.copyWith(
              username: usernameResult.updatedUsername,
            );
            state = UserState.loaded(updated);
            _cacheUserLocally(updated);
          }
        }
        return usernameResult;
      },
    );
  }

  /// Upload a local [file] as the user's avatar via POST /users/upload.
  ///
  /// Returns the hosted URL on success, or null on failure.
  /// The caller is responsible for passing the URL to [saveProfile] so that
  /// it is included in the POST /users/info request when the user taps Save.
  Future<({String? url, String? error})> uploadAvatar(File file) async {
    final uploadResult = await _uploadAvatarUseCase(file);

    return uploadResult.fold(
      (failure) {
        _logger.error('Failed to upload avatar: ${failure.message}');
        return (url: null, error: failure.message);
      },
      (avatarUrl) {
        _logger.info('Avatar uploaded: $avatarUrl');
        return (url: avatarUrl, error: null);
      },
    );
  }

  /// Clear user data (on logout)
  Future<void> clearUser() async {
    try {
      _loadGeneration++;
      state = const UserState.initial();

      // Clear local cache
      await _localStorageService.clearUserData();

      _logger.info('User data cleared');
    } catch (e) {
      _logger.error('Error clearing user', e);
    }
  }

  /// Load user from local cache
  Future<void> _loadFromLocalCache() async {
    try {
      final localUserData = await _localStorageService.getUserData();

      if (localUserData != null) {
        final userModel = UserModel.fromJson(localUserData);
        final user = userModel.toEntity();
        _logger.debug('Loaded user from cache: ${user.displayName}');
        state = UserState.loaded(user);
      } else {
        _logger.debug('No user data in cache');
        state = const UserState.error('No user data available');
      }
    } catch (e) {
      _logger.error('Error loading user from cache', e);
      state = const UserState.error('Failed to load user data from cache');
    }
  }

  /// Cache user data locally
  Future<void> _cacheUserLocally(User user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await _localStorageService.setUserData(userModel.toJson());
    } catch (e) {
      _logger.error('Error caching user data', e);
    }
  }
}
