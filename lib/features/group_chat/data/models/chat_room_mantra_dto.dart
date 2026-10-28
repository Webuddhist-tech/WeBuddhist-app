import 'package:equatable/equatable.dart';

/// The mantra an event or space room floats up on each prayer.
class ChatRoomMantraDTO extends Equatable {
  final String id;
  final String? audioUrl;
  final String language;
  final String title;
  final String mantra;
  final String pronunciation;

  const ChatRoomMantraDTO({
    required this.id,
    this.audioUrl,
    this.language = '',
    this.title = '',
    this.mantra = '',
    this.pronunciation = '',
  });

  factory ChatRoomMantraDTO.fromJson(Map<String, dynamic> json) {
    return ChatRoomMantraDTO(
      id: json['id'] as String? ?? '',
      audioUrl: json['audio_url'] as String?,
      language: json['language'] as String? ?? '',
      title: json['title'] as String? ?? '',
      mantra: json['mantra'] as String? ?? '',
      pronunciation: json['pronunciation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (audioUrl != null) 'audio_url': audioUrl,
      'language': language,
      'title': title,
      'mantra': mantra,
      'pronunciation': pronunciation,
    };
  }

  @override
  List<Object?> get props => [
    id,
    audioUrl,
    language,
    title,
    mantra,
    pronunciation,
  ];
}
