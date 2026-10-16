import 'package:flutter_pecha/features/texts/data/models/segment.dart';

class Section {
  final String id;
  final String? title;

  /// [title] in every language the table of contents has it in, by code.
  final Map<String, String> titles;
  final int sectionNumber;
  final String? parentId;
  final List<Segment> segments;
  final List<Section>? sections;
  final String? createdDate;
  final String? updatedDate;
  final String? publishedDate;

  const Section({
    required this.id,
    this.title,
    this.titles = const {},
    required this.sectionNumber,
    this.parentId,
    required this.segments,
    this.sections,
    this.createdDate,
    this.updatedDate,
    this.publishedDate,
  });

  /// The title in [language], if the table of contents has one.
  String? titleIn(String language) {
    final code = language.trim().toLowerCase();
    for (final entry in titles.entries) {
      if (entry.key.trim().toLowerCase() == code && entry.value.isNotEmpty) {
        return entry.value;
      }
    }
    return null;
  }

  factory Section.fromJson(Map<String, dynamic> json) {
    final rawTitles = json['titles'];
    return Section(
      id: json['id'] as String,
      title: json['title'] as String?,
      titles:
          rawTitles is Map
              ? {
                for (final entry in rawTitles.entries)
                  if (entry.key is String && entry.value is String)
                    entry.key as String: entry.value as String,
              }
              : const {},
      sectionNumber:
          json['section_number'] is int
              ? json['section_number'] as int
              : int.tryParse(json['section_number'].toString()) ?? 0,
      parentId: json['parent_id'] as String?,
      segments:
          (json['segments'] as List<dynamic>)
              .map((e) => Segment.fromJson(e as Map<String, dynamic>))
              .toList(),
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map((e) => Section.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdDate: json['created_date'] as String?,
      updatedDate: json['updated_date'] as String?,
      publishedDate: json['published_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (titles.isNotEmpty) 'titles': titles,
      'section_number': sectionNumber,
      'parent_id': parentId,
      'segments': segments.map((e) => e.toJson()).toList(),
      'sections': sections?.map((e) => e.toJson()).toList(),
      'created_date': createdDate,
      'updated_date': updatedDate,
      'published_date': publishedDate,
    };
  }

  /// Creates a copy of this Section with the given fields replaced by new values.
  /// This is equivalent to the JavaScript spread operator {...existingSection, ...newValues}
  Section copyWith({
    String? id,
    String? title,
    Map<String, String>? titles,
    int? sectionNumber,
    String? parentId,
    List<Segment>? segments,
    List<Section>? sections,
    String? createdDate,
    String? updatedDate,
    String? publishedDate,
  }) {
    return Section(
      id: id ?? this.id,
      title: title ?? this.title,
      titles: titles ?? this.titles,
      sectionNumber: sectionNumber ?? this.sectionNumber,
      parentId: parentId ?? this.parentId,
      segments: segments ?? this.segments,
      sections: sections ?? this.sections,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      publishedDate: publishedDate ?? this.publishedDate,
    );
  }
}
