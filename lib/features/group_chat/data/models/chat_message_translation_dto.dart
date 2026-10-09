import 'package:equatable/equatable.dart';

/// A message body in the language the list was requested with.
class ChatMessageTranslationDTO extends Equatable {
  static const String statusReady = 'ready';
  static const String statusPending = 'pending';

  final String targetLanguage;
  final String status;

  /// Null while [status] is still `pending`.
  final String? body;

  const ChatMessageTranslationDTO({
    required this.targetLanguage,
    required this.status,
    this.body,
  });

  bool get isReady => status == statusReady && (body?.isNotEmpty ?? false);

  factory ChatMessageTranslationDTO.fromJson(Map<String, dynamic> json) {
    return ChatMessageTranslationDTO(
      targetLanguage: json['target_language'] as String? ?? '',
      status: json['status'] as String? ?? '',
      body: json['body'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'target_language': targetLanguage, 'status': status, 'body': body};
  }

  @override
  List<Object?> get props => [targetLanguage, status, body];
}
