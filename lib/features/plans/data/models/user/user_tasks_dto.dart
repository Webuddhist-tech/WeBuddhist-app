import 'package:flutter_pecha/features/plans/data/models/task_settings.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';

class UserTasksDto {
  final String id;
  final String title;
  final int? estimatedTime;
  final int displayOrder;
  final bool isCompleted;
  final List<UserSubtasksDto> subTasks;
  final TaskSettings? settings;

  UserTasksDto({
    required this.id,
    required this.title,
    required this.estimatedTime,
    required this.displayOrder,
    required this.isCompleted,
    required this.subTasks,
    this.settings,
  });

  factory UserTasksDto.fromJson(Map<String, dynamic> json) {
    return UserTasksDto(
      id: json['id'] as String,
      title: json['title'] as String,
      estimatedTime: json['estimated_time'] as int?,
      displayOrder: json['display_order'] as int,
      isCompleted: json['is_completed'] as bool,
      subTasks:
          (json['sub_tasks'] as List<dynamic>)
              .map(
                (subtask) =>
                    UserSubtasksDto.fromJson(subtask as Map<String, dynamic>),
              )
              .toList(),
      settings: TaskSettings.tryParse(json['settings']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'estimated_time': estimatedTime,
      'display_order': displayOrder,
      'is_completed': isCompleted,
      'sub_tasks': subTasks.map((e) => e.toJson()).toList(),
      if (settings != null) 'settings': settings!.toJson(),
    };
  }

  UserTasksDto copyWith({
    String? id,
    String? title,
    int? estimatedTime,
    int? displayOrder,
    bool? isCompleted,
    List<UserSubtasksDto>? subTasks,
    TaskSettings? settings,
  }) {
    return UserTasksDto(
      id: id ?? this.id,
      title: title ?? this.title,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      displayOrder: displayOrder ?? this.displayOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
      settings: settings ?? this.settings,
    );
  }
}
