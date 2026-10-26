import 'package:flutter_pecha/features/auth/domain/entities/user.dart';

/// User state for managing user data throughout the app
class UserState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  const UserState({this.user, this.isLoading = false, this.errorMessage});

  /// Initial state (no user, not loading)
  const UserState.initial()
    : user = null,
      isLoading = false,
      errorMessage = null;

  /// Loading state
  const UserState.loading()
    : user = null,
      isLoading = true,
      errorMessage = null;

  /// Loaded state with user data
  UserState.loaded(User this.user) : isLoading = false, errorMessage = null;

  /// Error state
  const UserState.error(String this.errorMessage)
    : user = null,
      isLoading = false;

  /// Copy with method for partial updates
  UserState copyWith({User? user, bool? isLoading, String? errorMessage}) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Check if user is authenticated (has user data)
  bool get isAuthenticated => user != null;

  /// Check if user has completed onboarding
  bool get hasCompletedOnboarding => user?.onboardingCompleted ?? false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserState &&
        other.user == user &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(user, isLoading, errorMessage);

  @override
  String toString() {
    return 'UserState(user: ${user?.fullName ?? 'null'}, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}
