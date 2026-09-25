/// A user recitation collection row shown at the top of chant lists.
class MyRecitationListCollectionModel {
  final String type;
  final String name;
  final String collectionId;
  final String? imageUrl;
  final int itemCount;

  const MyRecitationListCollectionModel({
    required this.type,
    required this.name,
    required this.collectionId,
    this.imageUrl,
    this.itemCount = 0,
  });

  factory MyRecitationListCollectionModel.fromJson(Map<String, dynamic> json) {
    return MyRecitationListCollectionModel(
      type: json['type'] as String? ?? 'RECITATION_COLLECTION',
      name: json['name'] as String? ?? '',
      collectionId: json['collection_id'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyRecitationListCollectionModel &&
          collectionId == other.collectionId;

  @override
  int get hashCode => collectionId.hashCode;
}
