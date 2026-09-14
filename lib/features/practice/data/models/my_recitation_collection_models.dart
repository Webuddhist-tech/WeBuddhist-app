// Models for user recitation-collection endpoints under
// `/users/me/recitation-collections`.
//
// Separate from group-scoped collections (`GroupRecitationCollectionModel`).

/// Request body for `POST /users/me/recitation-collections`.
class CreateMyRecitationCollectionRequest {
  final String name;

  /// Storage key returned by [MyRecitationCollectionImageUploadResponse.key].
  ///
  /// The API marks `img_url` required (non-nullable), so a collection created
  /// without a cover sends an empty string; readers treat empty as "no image".
  final String imgUrl;

  const CreateMyRecitationCollectionRequest({
    required this.name,
    required this.imgUrl,
  });

  Map<String, dynamic> toJson() => {'name': name, 'img_url': imgUrl};
}

/// Request body for `PUT /users/me/recitation-collections/{id}`.
///
/// [imgUrl] is the storage key from a prior upload. Omit when the cover is
/// unchanged so the API keeps the existing image.
class UpdateMyRecitationCollectionRequest {
  final String name;
  final String? imgUrl;

  const UpdateMyRecitationCollectionRequest({required this.name, this.imgUrl});

  Map<String, dynamic> toJson() => {
    'name': name,
    if (imgUrl != null && imgUrl!.isNotEmpty) 'img_url': imgUrl,
  };
}

/// Request body for
/// `PATCH /users/me/recitation-collections/{collectionId}/items/{itemId}`.
class UpdateMyRecitationCollectionItemDisplayOrderRequest {
  final double displayOrder;

  const UpdateMyRecitationCollectionItemDisplayOrderRequest({
    required this.displayOrder,
  });

  Map<String, dynamic> toJson() => {'display_order': displayOrder};
}

/// Nested image URLs from `POST .../upload-image`.
class MyRecitationCollectionUploadedImage {
  final String? thumbnail;
  final String? medium;
  final String? original;

  const MyRecitationCollectionUploadedImage({
    this.thumbnail,
    this.medium,
    this.original,
  });

  factory MyRecitationCollectionUploadedImage.fromJson(
    Map<String, dynamic> json,
  ) {
    return MyRecitationCollectionUploadedImage(
      thumbnail: json['thumbnail'] as String?,
      medium: json['medium'] as String?,
      original: json['original'] as String?,
    );
  }

  /// Best URL for local preview after upload.
  String? get displayUrl => medium ?? original ?? thumbnail;
}

/// Response from `POST /users/me/recitation-collections/upload-image` (201).
class MyRecitationCollectionImageUploadResponse {
  final MyRecitationCollectionUploadedImage? image;

  /// Pass this value as `img_url` when creating/updating a collection.
  final String key;
  final String? path;
  final String? message;

  const MyRecitationCollectionImageUploadResponse({
    required this.key,
    this.image,
    this.path,
    this.message,
  });

  factory MyRecitationCollectionImageUploadResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final imageJson = json['image'];
    return MyRecitationCollectionImageUploadResponse(
      key: json['key'] as String? ?? '',
      image:
          imageJson is Map<String, dynamic>
              ? MyRecitationCollectionUploadedImage.fromJson(imageJson)
              : null,
      path: json['path'] as String?,
      message: json['message'] as String?,
    );
  }
}

/// Response from `POST /users/me/recitation-collections` (201).
class MyRecitationCollectionModel {
  final String id;
  final String name;
  final String? imgUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MyRecitationCollectionModel({
    required this.id,
    required this.name,
    this.imgUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory MyRecitationCollectionModel.fromJson(Map<String, dynamic> json) {
    return MyRecitationCollectionModel(
      id: json['id'] as String? ?? json['collection_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imgUrl: json['img_url'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

/// Response from `GET /users/me/recitation-collections/{id}` (200).
class MyRecitationCollectionDetailModel {
  final String id;
  final String name;
  final String? imgUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<MyRecitationCollectionItemModel> items;

  const MyRecitationCollectionDetailModel({
    required this.id,
    required this.name,
    this.imgUrl,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  factory MyRecitationCollectionDetailModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final items =
        rawItems
            .whereType<Map<String, dynamic>>()
            .map(MyRecitationCollectionItemModel.fromJson)
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return MyRecitationCollectionDetailModel(
      id: json['id'] as String? ?? json['collection_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imgUrl: json['img_url'] as String?,
      createdAt: MyRecitationCollectionModel._parseDate(json['created_at']),
      updatedAt: MyRecitationCollectionModel._parseDate(json['updated_at']),
      items: items,
    );
  }
}

/// Request body for `POST /users/me/recitation-collections/{id}/items`.
class AddMyRecitationCollectionItemsRequest {
  final List<String> textIds;

  const AddMyRecitationCollectionItemsRequest({required this.textIds});

  Map<String, dynamic> toJson() => {'text_ids': textIds};
}

/// Request body for `POST /users/me/recitation-collections/{id}/complete`.
class CompleteMyRecitationCollectionChantRequest {
  final String chantId;

  const CompleteMyRecitationCollectionChantRequest({required this.chantId});

  Map<String, dynamic> toJson() => {'chant_id': chantId};
}

/// Response from
/// `GET /users/me/recitation-collections/{id}/complete/today` (200).
class MyRecitationCollectionTodayCompletionsResponse {
  final Set<String> completedChantIds;
  final DateTime? date;

  const MyRecitationCollectionTodayCompletionsResponse({
    this.completedChantIds = const {},
    this.date,
  });

  factory MyRecitationCollectionTodayCompletionsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return MyRecitationCollectionTodayCompletionsResponse(
      completedChantIds:
          (json['completed_chant_ids'] as List<dynamic>?)
              ?.whereType<String>()
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toSet() ??
          const {},
      date: MyRecitationCollectionModel._parseDate(json['date']),
    );
  }
}

/// Response from
/// `GET /users/me/recitation-collections/{id}/complete/days-count` (200).
class MyRecitationCollectionCompletionDaysCountResponse {
  final String collectionId;
  final int dayCount;

  const MyRecitationCollectionCompletionDaysCountResponse({
    required this.collectionId,
    required this.dayCount,
  });

  factory MyRecitationCollectionCompletionDaysCountResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return MyRecitationCollectionCompletionDaysCountResponse(
      collectionId: json['collection_id'] as String? ?? '',
      dayCount: (json['day_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A chant row returned after adding items to a collection.
class MyRecitationCollectionItemModel {
  final String id;
  final String textId;
  final String? title;
  final String? language;
  final String? type;
  final double displayOrder;

  const MyRecitationCollectionItemModel({
    required this.id,
    required this.textId,
    this.title,
    this.language,
    this.type,
    this.displayOrder = 0,
  });

  factory MyRecitationCollectionItemModel.fromJson(Map<String, dynamic> json) {
    return MyRecitationCollectionItemModel(
      id: json['id'] as String? ?? json['chant_id'] as String? ?? '',
      textId: json['text_id'] as String? ?? '',
      title: json['title'] as String?,
      language: json['language'] as String?,
      type: json['type'] as String?,
      displayOrder: (json['display_order'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Response from `POST /users/me/recitation-collections/{id}/items` (201).
class AddMyRecitationCollectionItemsResponse {
  final String collectionId;
  final int addedCount;
  final List<MyRecitationCollectionItemModel> items;

  const AddMyRecitationCollectionItemsResponse({
    required this.collectionId,
    required this.addedCount,
    this.items = const [],
  });

  factory AddMyRecitationCollectionItemsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return AddMyRecitationCollectionItemsResponse(
      collectionId: json['collection_id'] as String? ?? '',
      addedCount: (json['added_count'] as num?)?.toInt() ?? 0,
      items:
          rawItems
              .whereType<Map<String, dynamic>>()
              .map(MyRecitationCollectionItemModel.fromJson)
              .toList(),
    );
  }
}
