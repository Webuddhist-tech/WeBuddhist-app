import 'package:flutter_pecha/features/auth/domain/entities/user.dart';

/// Social profile model for JSON serialization
class SocialProfileModel {
  final String account;
  final String url;

  SocialProfileModel({required this.account, required this.url});

  factory SocialProfileModel.fromJson(Map<String, dynamic> json) {
    return SocialProfileModel(
      account: json['account']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'account': account, 'url': url};
  }

  SocialProfile toEntity() {
    return SocialProfile(account: account, url: url);
  }

  factory SocialProfileModel.fromEntity(SocialProfile profile) {
    return SocialProfileModel(account: profile.account, url: profile.url);
  }
}

/// User model for JSON serialization
///
/// This handles conversion between JSON and the User domain entity.
class UserModel {
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
  final List<SocialProfileModel>? socialProfiles;

  // from local storage
  final bool onboardingCompleted;

  UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(),
      email: json['email']?.toString(),
      firstName: json['firstname']?.toString(),
      lastName: json['lastname']?.toString(),
      displayName: json['display_name']?.toString(),
      username: json['username']?.toString(),
      title: json['title']?.toString(),
      organization: json['organization']?.toString(),
      location: json['location']?.toString(),
      aboutMe: json['about_me']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      educations:
          (json['educations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
      followers: json['followers'] as int?,
      following: json['following'] as int?,
      socialProfiles:
          (json['social_profiles'] as List<dynamic>?)
              ?.map(
                (e) => SocialProfileModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      // Note: onboarding_completed is NOT sent by backend API
      // It's managed locally only - will be set by UserNotifier
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstname': firstName,
      'lastname': lastName,
      'display_name': displayName,
      'username': username,
      'title': title,
      'organization': organization,
      'location': location,
      'about_me': aboutMe,
      'avatar_url': avatarUrl,
      'educations': educations,
      'followers': followers,
      'following': following,
      'social_profiles': socialProfiles?.map((e) => e.toJson()).toList() ?? [],
      'onboarding_completed': onboardingCompleted,
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      displayName: displayName,
      username: username,
      title: title,
      organization: organization,
      location: location,
      aboutMe: aboutMe,
      avatarUrl: avatarUrl,
      educations: educations,
      followers: followers,
      following: following,
      socialProfiles: socialProfiles?.map((e) => e.toEntity()).toList(),
      onboardingCompleted: onboardingCompleted,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      displayName: user.displayName,
      username: user.username,
      title: user.title,
      organization: user.organization,
      location: user.location,
      aboutMe: user.aboutMe,
      avatarUrl: user.avatarUrl,
      educations: user.educations,
      followers: user.followers,
      following: user.following,
      socialProfiles:
          user.socialProfiles
              ?.map((e) => SocialProfileModel.fromEntity(e))
              .toList(),
      onboardingCompleted: user.onboardingCompleted,
    );
  }
}
