/// Capped exponential backoff for a dropped socket: 1s, 2s, 4s, 8s, 16s, then
/// 30s forever. [attempt] is 1 for the first retry after a drop.
Duration reconnectDelay(int attempt) {
  if (attempt <= 1) return const Duration(seconds: 1);
  const cap = Duration(seconds: 30);
  final exponent = attempt - 1 > 5 ? 5 : attempt - 1;
  final delay = Duration(seconds: 1 << exponent);
  return delay > cap ? cap : delay;
}
