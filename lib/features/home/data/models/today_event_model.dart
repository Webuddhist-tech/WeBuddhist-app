import 'package:flutter_pecha/features/home/domain/entities/today_event.dart';

class TodayEventMetadataModel {
  final String id;
  final String name;
  final String? description;
  final String language;

  TodayEventMetadataModel({
    required this.id,
    required this.name,
    this.description,
    required this.language,
  });

  factory TodayEventMetadataModel.fromJson(Map<String, dynamic> json) {
    return TodayEventMetadataModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      language: (json['language'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'language': language,
    };
  }
}

class TodayEventModel {
  final String id;
  final TodayEventMetadataModel metadata;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? timezone;
  final String? startTime;
  final String? endTime;

  TodayEventModel({
    required this.id,
    required this.metadata,
    this.startDate,
    this.endDate,
    this.timezone,
    this.startTime,
    this.endTime,
  });

  factory TodayEventModel.fromJson(Map<String, dynamic> json) {
    return TodayEventModel(
      id: (json['id'] as String?) ?? '',
      metadata: TodayEventMetadataModel.fromJson(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      timezone: json['timezone'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'metadata': metadata.toJson(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'timezone': timezone,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  TodayEvent toEntity() {
    return TodayEvent(
      id: id,
      name: metadata.name,
      description: metadata.description,
      startDate: startDate,
      endDate: endDate,
      timezone: timezone,
      startTime: startTime,
      endTime: endTime,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

class TodayEventsResponseModel {
  final List<TodayEventModel> events;

  TodayEventsResponseModel({required this.events});

  factory TodayEventsResponseModel.fromJson(Map<String, dynamic> json) {
    final eventsJson = json['events'] as List<dynamic>? ?? const [];
    return TodayEventsResponseModel(
      events:
          eventsJson
              .map(
                (event) =>
                    TodayEventModel.fromJson(event as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  List<TodayEvent> toEntities() =>
      events.map((event) => event.toEntity()).toList();
}
