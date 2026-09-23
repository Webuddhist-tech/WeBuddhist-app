/// A selectable ambient sound track for meditation timer sessions.
///
/// Fetched from `GET /ambient-sounds`. The `url`/`imageUrl` are short-lived
/// signed S3 links, so this should not be persisted long-term — fetch fresh
/// each time the picker is opened.
class AmbientSound {
  const AmbientSound({
    required this.id,
    required this.name,
    required this.url,
    this.imageUrl,
    this.isDefault = false,
    this.displayOrder = 0,
  });

  final String id;
  final String name;
  final String url;

  /// Present on the API response but not rendered in the UI yet — timer cards
  /// use the Phosphor waveform icon instead.
  final String? imageUrl;
  final bool isDefault;
  final int displayOrder;
}
