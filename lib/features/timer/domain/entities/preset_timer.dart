/// Raw value of the `preset` timer type as returned by `GET /timers`.
///
/// Used to distinguish preset timers (shown in the "Preset timers" grid)
/// from user-created ones (shown in "Your timers") once the backend starts
/// returning the latter.
const String kPresetTimerTypePreset = 'preset';

/// Raw value of the `user_created` timer type as returned by `GET /timers`.
///
/// These are the timers a user has created themselves (via `POST
/// /timers/user`) and are shown in the "Your timers" section.
const String kPresetTimerTypeUserCreated = 'user_created';

class PresetTimer {
  const PresetTimer({
    required this.id,
    required this.name,
    required this.durationMs,
    this.userId,
    this.groupId,
    this.type = kPresetTimerTypePreset,
    this.description,
    this.ambientSoundId,
    this.bellAtStart = true,
    this.bellAtEnd = true,
    this.parentPresetId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final int durationMs;

  /// Owner of the timer (present on user-created timers).
  final String? userId;

  /// Group this timer belongs to, if any.
  final String? groupId;

  /// e.g. `"preset"`. Kept as a raw string since the backend may introduce
  /// new values (e.g. `"custom"`) over time.
  final String type;

  final String? description;

  /// Id of the ambient sound to play during the session, if any. Resolving
  /// this to a playable asset/name requires a sound catalog that does not
  /// exist in the app yet.
  final String? ambientSoundId;

  final bool bellAtStart;
  final bool bellAtEnd;

  /// Id of the preset this timer was cloned/derived from, if any.
  final String? parentPresetId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Whether this is a stock preset (as opposed to a user-created timer).
  bool get isPreset => type == kPresetTimerTypePreset;

  /// Whether this is a timer the user created themselves.
  bool get isUserCreated => type == kPresetTimerTypeUserCreated;

  int get durationMinutes => durationMs ~/ 60000;

  int get displayMinutes {
    return durationMinutes;
  }
}
