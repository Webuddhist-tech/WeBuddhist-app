import 'dart:math';

import 'package:flutter_pecha/features/practice/data/utils/collection_display_order_plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sends [patches] one at a time, as the edit screen does, to a server that
/// enforces the API rule that `display_order` is unique among active items.
/// Returns the keys sorted by their final `display_order`.
List<String> _saveLikeServer(
  Map<String, double> current,
  Iterable<MapEntry<String, double>> patches, {
  List<double> reserved = const [],
}) {
  final server = Map.of(current);
  for (final patch in patches) {
    final collides =
        reserved.contains(patch.value) ||
        server.entries.any(
          (item) => item.key != patch.key && item.value == patch.value,
        );
    if (collides) {
      fail('PATCH ${patch.key}=${patch.value} collides with an active item');
    }
    server[patch.key] = patch.value;
  }
  return server.keys.toList()..sort((a, b) => server[a]!.compareTo(server[b]!));
}

void main() {
  group('planDisplayOrderUpdates', () {
    test('sends nothing when the order is unchanged', () {
      final updates = planDisplayOrderUpdates(
        orderedKeys: ['a', 'b', 'c'],
        currentOrders: {'a': 1, 'b': 2, 'c': 3},
      );

      expect(updates, isEmpty);
    });

    test('moves only the dragged chant', () {
      const current = {'a': 1.0, 'b': 2.0, 'c': 3.0, 'd': 4.0};

      final toTop = planDisplayOrderUpdates(
        orderedKeys: ['d', 'a', 'b', 'c'],
        currentOrders: current,
      );
      final toEnd = planDisplayOrderUpdates(
        orderedKeys: ['b', 'c', 'd', 'a'],
        currentOrders: current,
      );
      final between = planDisplayOrderUpdates(
        orderedKeys: ['a', 'd', 'b', 'c'],
        currentOrders: current,
      );

      expect(toTop.keys, ['d']);
      expect(toTop['d'], lessThan(1));
      expect(toEnd, {'a': 5.0});
      expect(between, {'d': 1.5});
    });

    test('never reuses an order the server gave a newly added chant', () {
      // Edit: add "c", remove "z" (the last chant), drag "a" between "b" and
      // "c". Once the delete and the add are saved the server holds a=1, b=2
      // and gives "c" max + 1 = 3, so writing a=3 would break uniqueness.
      const saved = {'a': 1.0, 'b': 2.0, 'c': 3.0};

      final updates = planDisplayOrderUpdates(
        orderedKeys: ['b', 'a', 'c'],
        currentOrders: saved,
      );

      expect(updates, {'a': 2.5});
      expect(_saveLikeServer(saved, updates.entries), ['b', 'a', 'c']);
    });

    test('writes succeed in any order without a uniqueness clash', () {
      // "a" lands between "b" (2) and "d" (4). The plain midpoint 3 still
      // belongs to "c" until "c" itself is written, so it must be skipped.
      const current = {'a': 1.0, 'b': 2.0, 'c': 3.0, 'd': 4.0};
      const target = ['b', 'a', 'd', 'c'];

      final updates = planDisplayOrderUpdates(
        orderedKeys: target,
        currentOrders: current,
      );

      expect(updates.values, isNot(contains(3.0)));
      expect(_saveLikeServer(current, updates.entries), target);
      expect(
        _saveLikeServer(current, updates.entries.toList().reversed),
        target,
      );
    });

    test('skips values still held by chants outside the list', () {
      final updates = planDisplayOrderUpdates(
        orderedKeys: ['b', 'a'],
        currentOrders: {'a': 1, 'b': 2},
        reservedOrders: [3],
      );

      expect(updates, {'a': 4.0});
    });

    test('renumbers above the maximum once a gap is too narrow', () {
      // 1.0000000000000002 is the next double after 1.0: nothing fits between.
      const current = {'a': 1.0, 'b': 1.0000000000000002, 'c': 3.0, 'x': 10.0};
      const target = ['a', 'x', 'b', 'c'];

      final updates = planDisplayOrderUpdates(
        orderedKeys: target,
        currentOrders: current,
      );

      expect(updates, {'a': 11.0, 'x': 12.0, 'b': 13.0, 'c': 14.0});
      expect(_saveLikeServer(current, updates.entries), target);
    });

    test('rejects a chant with no current order', () {
      expect(
        () => planDisplayOrderUpdates(
          orderedKeys: ['a', 'b'],
          currentOrders: {'a': 1},
        ),
        throwsArgumentError,
      );
    });

    test('any rearrangement saves in the arranged order', () {
      final random = Random(7);
      for (var run = 0; run < 500; run++) {
        final count = 2 + random.nextInt(11);
        final keys = [for (var i = 0; i < count; i++) 'k$i'];
        // Mix whole and fractional orders, like repeated drops leave behind.
        final pool = <double>{};
        while (pool.length < count + 3) {
          pool.add(random.nextInt(4 * count) / (1 + random.nextInt(3)));
        }
        final values = pool.toList()..shuffle(random);
        final current = {for (var i = 0; i < count; i++) keys[i]: values[i]};
        final reserved = values.sublist(count);
        final target = [...keys]..shuffle(random);

        final updates = planDisplayOrderUpdates(
          orderedKeys: target,
          currentOrders: current,
          reservedOrders: reserved,
        );

        final reason = 'current=$current target=$target reserved=$reserved';
        expect(
          _saveLikeServer(current, updates.entries, reserved: reserved),
          target,
          reason: reason,
        );
        expect(
          _saveLikeServer(
            current,
            updates.entries.toList().reversed,
            reserved: reserved,
          ),
          target,
          reason: reason,
        );
      }
    });
  });
}
