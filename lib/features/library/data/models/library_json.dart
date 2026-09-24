/// Lenient JSON helpers for library API payloads.
List<String> stringListFromJson(Object? raw) {
  if (raw is! List) return const [];
  return raw.whereType<String>().toList(growable: false);
}

Map<String, String> stringMapFromJson(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final entry in raw.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
}
