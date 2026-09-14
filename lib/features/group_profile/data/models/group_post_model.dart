import 'package:flutter_pecha/features/group_profile/domain/entities/group_post_permission.dart';

class GroupPostPermissionModel {
  final String groupId;
  final bool hasPermission;
  final bool canCreateContent;
  final String? role;
  final bool isSuperAdmin;
  final String? authorId;

  const GroupPostPermissionModel({
    required this.groupId,
    this.hasPermission = false,
    this.canCreateContent = false,
    this.role,
    this.isSuperAdmin = false,
    this.authorId,
  });

  factory GroupPostPermissionModel.fromJson(Map<String, dynamic> json) {
    return GroupPostPermissionModel(
      groupId: json['group_id'] as String? ?? '',
      hasPermission: json['has_permission'] as bool? ?? false,
      canCreateContent: json['can_create_content'] as bool? ?? false,
      role: json['role'] as String?,
      isSuperAdmin: json['is_super_admin'] as bool? ?? false,
      authorId: json['author_id'] as String?,
    );
  }

  GroupPostPermission toEntity() {
    return GroupPostPermission(
      groupId: groupId,
      hasPermission: hasPermission,
      canCreateContent: canCreateContent,
      role: role,
      isSuperAdmin: isSuperAdmin,
      authorId: authorId,
    );
  }
}

/// `POST /cms/media/upload` response. Only [key] is sent back to the API.
class GroupMediaUploadResponse {
  final String key;
  final String? url;

  const GroupMediaUploadResponse({required this.key, this.url});

  factory GroupMediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return GroupMediaUploadResponse(
      key: json['key'] as String? ?? json['media_key'] as String? ?? '',
      url: json['url'] as String?,
    );
  }
}

class GroupPostMediaRequest {
  final String mediaType;
  final String mediaKey;
  final String? thumbnailKey;
  final int? width;
  final int? height;
  final int? durationMs;
  final int displayOrder;

  const GroupPostMediaRequest({
    this.mediaType = 'IMAGE',
    required this.mediaKey,
    this.thumbnailKey,
    this.width,
    this.height,
    this.durationMs,
    required this.displayOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'media_type': mediaType,
      'media_key': mediaKey,
      'thumbnail_key': thumbnailKey,
      'width': width,
      'height': height,
      'duration_ms': durationMs,
      'display_order': displayOrder,
    };
  }
}

class GroupPostLinkRequest {
  final String type;
  final String url;
  final String? label;
  final int displayOrder;

  const GroupPostLinkRequest({
    required this.type,
    required this.url,
    this.label,
    required this.displayOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      if (label != null && label!.isNotEmpty) 'label': label,
      'display_order': displayOrder,
    };
  }
}

class CreateGroupPostRequest {
  final String caption;
  final String status;
  final DateTime? publishedAt;
  final List<GroupPostMediaRequest> media;
  final List<GroupPostLinkRequest> links;

  const CreateGroupPostRequest({
    this.caption = '',
    this.status = 'PUBLISHED',
    this.publishedAt,
    this.media = const [],
    this.links = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'caption': caption,
      'status': status,
      if (publishedAt != null)
        'published_at': publishedAt!.toUtc().toIso8601String(),
      'media': media.map((item) => item.toJson()).toList(),
      'links': links.map((item) => item.toJson()).toList(),
    };
  }
}
