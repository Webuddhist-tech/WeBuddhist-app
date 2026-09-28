import 'package:equatable/equatable.dart';

/// One configured prayer intention from `GET /intentions`, also nested on a
/// `PRAYER` message.
class ChatPrayerIntentionDTO extends Equatable {
  final String slug;
  final String label;

  /// Hex like `#4A78C2`.
  final String color;
  final String description;
  final int displayOrder;

  const ChatPrayerIntentionDTO({
    required this.slug,
    required this.label,
    required this.color,
    this.description = '',
    this.displayOrder = 0,
  });

  factory ChatPrayerIntentionDTO.fromJson(Map<String, dynamic> json) {
    final order = json['display_order'];
    return ChatPrayerIntentionDTO(
      slug: json['slug'] as String? ?? '',
      label: json['label'] as String? ?? '',
      color: json['color'] as String? ?? '',
      description: json['description'] as String? ?? '',
      displayOrder: order is num ? order.toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'label': label,
      'color': color,
      'description': description,
      'display_order': displayOrder,
    };
  }

  @override
  List<Object?> get props => [slug, label, color, description, displayOrder];
}
