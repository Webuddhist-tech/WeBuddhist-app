/// Group accumulation referenced by a GROUP_ACCUMULATION subtask.
class PlanGroupAccumulationRef {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String groupId;

  const PlanGroupAccumulationRef({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.groupId,
  });

  factory PlanGroupAccumulationRef.fromJson(Map<String, dynamic> json) {
    return PlanGroupAccumulationRef(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      subtitle: json['subtitle'] as String?,
      imageUrl: json['image_url'] as String?,
      groupId: (json['group_id'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'group_id': groupId,
    };
  }
}
