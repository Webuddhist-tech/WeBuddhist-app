import 'dart:convert';

import 'package:flutter_pecha/features/recitation/data/models/recitation_live_position.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Frames received on `WS /events/{event_id}/recitation/live`.
sealed class RecitationLiveEvent {
  const RecitationLiveEvent();
}

/// First frame on connect. [isOperator] is true for whoever may publish.
class RecitationLiveSessionInfo extends RecitationLiveEvent {
  final String eventId;
  final bool isOperator;
  const RecitationLiveSessionInfo({
    required this.eventId,
    required this.isOperator,
  });
}

class RecitationLivePositionEvent extends RecitationLiveEvent {
  final RecitationLivePosition position;
  const RecitationLivePositionEvent({required this.position});
}

/// The operator ended the puja; the server closes the socket right after.
class RecitationLiveSessionEnded extends RecitationLiveEvent {
  const RecitationLiveSessionEnded();
}

class RecitationLivePong extends RecitationLiveEvent {
  const RecitationLivePong();
}

class RecitationLiveError extends RecitationLiveEvent {
  final String code;
  final String message;
  const RecitationLiveError({required this.code, required this.message});

  /// Codes that mean this socket will never serve positions: a rejected
  /// token, no such event, or an unpublished group. Not worth retrying.
  static const Set<String> fatalCodes = {
    'UNAUTHORIZED',
    'FORBIDDEN',
    'NOT_FOUND',
    '401',
    '403',
    '404',
  };

  bool get isFatal => fatalCodes.contains(code.toUpperCase());
}

class RecitationLiveUnknown extends RecitationLiveEvent {
  final Map<String, dynamic> raw;
  const RecitationLiveUnknown({required this.raw});
}

/// Builds and talks to the recitation live socket.
class RecitationLiveClient {
  RecitationLiveClient({WebSocketChannel Function(Uri uri)? connect})
    : _connect = connect ?? WebSocketChannel.connect;

  final WebSocketChannel Function(Uri uri) _connect;
  WebSocketChannel? _channel;

  static Uri liveUri({
    required String restBaseUrl,
    required String token,
    required String eventId,
  }) {
    final rest = Uri.parse(restBaseUrl);
    final scheme = rest.scheme == 'http' ? 'ws' : 'wss';
    final basePath = rest.path.replaceAll(RegExp(r'/+$'), '');
    return rest.replace(
      scheme: scheme,
      path: '$basePath/events/$eventId/recitation/live',
      queryParameters: {'token': token},
    );
  }

  /// Parses a server JSON frame. Unknown payloads become
  /// [RecitationLiveUnknown]; anything that is not a JSON object is null.
  static RecitationLiveEvent? parseFrame(String raw) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final json = Map<String, dynamic>.from(decoded);
    final type = json['type'] as String? ?? '';
    // A rejected connect can arrive as a bare `{"detail": ...}` body.
    if (type.isEmpty && json['detail'] != null) {
      return RecitationLiveError(
        code: (json['code'] ?? json['status'] ?? '').toString(),
        message: json['detail'].toString(),
      );
    }
    return switch (type) {
      'session_info' => RecitationLiveSessionInfo(
        eventId: json['event_id'] as String? ?? '',
        isOperator: json['is_operator'] as bool? ?? false,
      ),
      'position' => RecitationLivePositionEvent(
        position: RecitationLivePosition.fromJson(json),
      ),
      'session_ended' => const RecitationLiveSessionEnded(),
      'pong' => const RecitationLivePong(),
      'error' => RecitationLiveError(
        code: (json['code'] ?? '').toString(),
        message: (json['message'] ?? json['detail'] ?? '').toString(),
      ),
      _ => RecitationLiveUnknown(raw: json),
    };
  }

  static String encodePing() => jsonEncode({'type': 'ping'});

  Stream<RecitationLiveEvent> connect(Uri uri) {
    _channel = _connect(uri);
    return _channel!.stream.map((frame) {
      return parseFrame(frame.toString()) ??
          const RecitationLiveUnknown(raw: {});
    });
  }

  void sendPing() {
    _channel?.sink.add(encodePing());
  }

  Future<void> dispose() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
