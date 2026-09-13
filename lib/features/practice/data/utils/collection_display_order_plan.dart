/// Plans `display_order` writes for a personal chant collection.
///
/// The collection API sorts items by a fractional `display_order` that must be
/// unique among the collection's active items, and changes one item per call
/// (`PATCH .../items/{itemId}`). Keeping the rules for choosing those values in
/// a pure function lets them be unit-tested away from the edit screen.
library;

/// Returns the new `display_order` for every item in [orderedKeys] that has to
/// change so the server sorts the collection in exactly that order.
///
/// [currentOrders] must hold the server `display_order` of each item in
/// [orderedKeys], as it stands once removals and additions are saved.
/// [reservedOrders] are values still held by other active items; they are
/// never reused either.
///
/// * Items already in increasing order keep their value — the longest such
///   subsequence is kept, so the fewest writes are sent.
/// * No returned value equals a current value, a reserved value or another
///   returned value, so the writes can be sent one at a time, in any order,
///   without breaking uniqueness.
/// * When repeated drops have left a gap too narrow to fit an item between its
///   neighbours, every item is renumbered with whole numbers above the current
///   maximum instead.
///
/// Throws [ArgumentError] if a key in [orderedKeys] has no current order.
Map<String, double> planDisplayOrderUpdates({
  required List<String> orderedKeys,
  required Map<String, double> currentOrders,
  Iterable<double> reservedOrders = const [],
}) {
  final values = <double>[];
  for (final key in orderedKeys) {
    final order = currentOrders[key];
    if (order == null) {
      throw ArgumentError.value(
        key,
        'orderedKeys',
        'has no current display_order',
      );
    }
    values.add(order);
  }
  if (values.length < 2) return const {};

  final taken = {...values, ...reservedOrders};
  final orders =
      _placeAroundKept(values, _longestIncreasingSubsequence(values), taken) ??
      _renumberAbove(values.length, taken);

  return {
    for (var i = 0; i < orderedKeys.length; i++)
      if (orders[i] != values[i]) orderedKeys[i]: orders[i],
  };
}

/// Indices of a longest strictly increasing subsequence of [values].
Set<int> _longestIncreasingSubsequence(List<double> values) {
  final lengths = List.filled(values.length, 1);
  final previous = List.filled(values.length, -1);
  var end = 0;
  for (var i = 0; i < values.length; i++) {
    for (var j = 0; j < i; j++) {
      if (values[j] < values[i] && lengths[j] + 1 > lengths[i]) {
        lengths[i] = lengths[j] + 1;
        previous[i] = j;
      }
    }
    if (lengths[i] > lengths[end]) end = i;
  }
  return {for (var i = end; i != -1; i = previous[i]) i};
}

/// Gives every item outside [kept] a value between its kept neighbours, or
/// returns null when a gap is too narrow to hold the items that belong in it.
List<double>? _placeAroundKept(
  List<double> values,
  Set<int> kept,
  Set<double> taken,
) {
  final orders = List.of(values);
  var index = 0;
  while (index < values.length) {
    if (kept.contains(index)) {
      index++;
      continue;
    }
    final start = index;
    while (index < values.length && !kept.contains(index)) {
      index++;
    }
    // Runs are maximal, so both neighbours (when present) are kept items.
    final slots = _slotsBetween(
      lower: start > 0 ? values[start - 1] : null,
      upper: index < values.length ? values[index] : null,
      count: index - start,
      taken: taken,
    );
    if (slots == null) return null;
    orders.setRange(start, index, slots);
  }
  return orders;
}

/// [count] increasing values strictly between [lower] and [upper] that are not
/// [taken]. A missing bound means the run sits at that end of the list.
List<double>? _slotsBetween({
  required double? lower,
  required double? upper,
  required int count,
  required Set<double> taken,
}) {
  if (lower != null && upper != null) {
    return _divide(lower, upper, count, taken);
  }
  if (lower != null) return _stepAway(lower, 1, count, taken);
  return _stepAway(upper!, -1, count, taken)?.reversed.toList();
}

/// Whole steps up (or down) from [from], skipping [taken] values. Returns null
/// once the numbers are too large for a step to change them.
List<double>? _stepAway(
  double from,
  int direction,
  int count,
  Set<double> taken,
) {
  final slots = <double>[];
  var candidate = from;
  while (slots.length < count) {
    final next = candidate + direction;
    if (next == candidate) return null;
    candidate = next;
    if (!taken.contains(candidate)) slots.add(candidate);
  }
  return slots;
}

/// [count] values spread evenly inside the open gap (lower, upper), skipping
/// [taken] ones. Returns null once the gap is too narrow for doubles to hold
/// that many distinct values.
List<double>? _divide(
  double lower,
  double upper,
  int count,
  Set<double> taken,
) {
  // Each taken value inside the gap can block at most one grid point, so this
  // many divisions always leaves enough free points.
  final blockers = taken.where((value) => value > lower && value < upper);
  final maxDivisions = count + 1 + blockers.length;
  for (var divisions = count + 1; divisions <= maxDivisions; divisions++) {
    final free = <double>[];
    var previous = lower;
    for (var step = 1; step < divisions; step++) {
      final point = lower + (upper - lower) * step / divisions;
      if (point <= previous || point >= upper) return null;
      previous = point;
      if (!taken.contains(point)) free.add(point);
    }
    if (free.length >= count) {
      // Spread the picks across the whole gap rather than bunching them.
      return [
        for (var pick = 1; pick <= count; pick++)
          free[pick * (free.length + 1) ~/ (count + 1) - 1],
      ];
    }
  }
  return null;
}

/// Whole numbers above every taken value, one per item in list order. Each
/// one is above everything the server holds, so they stay unique however the
/// writes interleave, and the fresh spacing leaves room for future drops.
List<double> _renumberAbove(int count, Set<double> taken) {
  final highest = taken.reduce((a, b) => a > b ? a : b);
  final first = highest.floorToDouble() + 1;
  if (first <= highest || first + count == first + count - 1) {
    throw StateError('display_order values are too large to renumber');
  }
  return [for (var i = 0; i < count; i++) first + i];
}
