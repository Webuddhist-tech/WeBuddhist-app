import 'package:equatable/equatable.dart';

/// Social profile information
class SocialProfile extends Equatable {
  final String account;
  final String url;

  const SocialProfile({required this.account, required this.url});

  @override
  List<Object?> get props => [account, url];
}

/// User domain entity - Pure entity with no framework dependencies
///
/// This is the domain entity used throughout the app.
/// JSON serialization is handled by UserModel in the data layer.
class User extends Equatable {
  // from api response
  final String? id;
  final String? firstName;
  final String? email;
  final String? lastName;
  final String? displayName;
  final String? username;
  final String? title;
  final String? organization;
  final String? location;
  final String? aboutMe;
  final String? avatarUrl;
  final List<String>? educations;
  final int? followers;
  final int? following;
  final List<SocialProfile>? socialProfiles;

  // from local storage
  final bool onboardingCompleted;

  const User({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.displayName,
    this.username,
    this.title,
    this.organization,
    this.location,
    this.aboutMe,
    this.avatarUrl,
    this.educations,
    this.followers,
    this.following,
    this.socialProfiles,
    this.onboardingCompleted = false,
  });

  User copyWith({
    String? id,
    String? firstName,
    String? email,
    String? lastName,
    String? displayName,
    String? username,
    String? title,
    String? organization,
    String? location,
    String? aboutMe,
    String? avatarUrl,
    List<String>? educations,
    int? followers,
    int? following,
    List<SocialProfile>? socialProfiles,
    bool? onboardingCompleted,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      location: location ?? this.location,
      aboutMe: aboutMe ?? this.aboutMe,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      educations: educations ?? this.educations,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      socialProfiles: socialProfiles ?? this.socialProfiles,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  /// Name shown in the UI. Prefers `display_name`, then first and last name
  /// for profiles saved before that field existed.
  String get visibleName {
    final named = displayName?.trim();
    if (named != null && named.isNotEmpty) return named;
    return [
      firstName?.trim() ?? '',
      lastName?.trim() ?? '',
    ].where((part) => part.isNotEmpty).join(' ');
  }

  String? get visibleNameOrNull {
    final name = visibleName;
    return name.isEmpty ? null : name;
  }

  /// Get user's full name
  String get fullName {
    final named = visibleName;
    if (named.isNotEmpty) return named;
    return username ?? email ?? 'User';
  }

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    displayName,
    username,
    title,
    organization,
    location,
    aboutMe,
    avatarUrl,
    educations,
    followers,
    following,
    socialProfiles,
    onboardingCompleted,
  ];

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, firstName: $firstName, lastName: $lastName, username: $username)';
  }
}
