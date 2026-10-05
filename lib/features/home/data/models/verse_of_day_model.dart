import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';

class VerseOfDayModel {
  final String id;
  final String verse;
  final String imageUrl;
  final String refId;
  final String refType;
  final String date;
  final String source;

  VerseOfDayModel({
    required this.id,
    required this.verse,
    required this.imageUrl,
    required this.refId,
    required this.refType,
    required this.date,
    this.source = '',
  });

  factory VerseOfDayModel.fromJson(Map<String, dynamic> json) {
    final vodJson = json['verse_of_day'] as Map<String, dynamic>? ?? json;

    return VerseOfDayModel(
      id: (vodJson['id'] as String?) ?? '',
      verse: (vodJson['verse'] as String?) ?? '',
      imageUrl: (vodJson['image_url'] as String?) ?? '',
      refId: (vodJson['ref_id'] as String?) ?? '',
      refType: (vodJson['ref_type'] as String?) ?? '',
      date: (vodJson['date'] as String?) ?? '',
      source: (vodJson['source'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'verse': verse,
      'image_url': imageUrl,
      'ref_id': refId,
      'ref_type': refType,
      'date': date,
      'source': source,
    };
  }

  VerseOfDay toEntity() {
    return VerseOfDay(
      id: id,
      verse: verse,
      imageUrl: imageUrl,
      date: date,
      source: source,
    );
  }
}
