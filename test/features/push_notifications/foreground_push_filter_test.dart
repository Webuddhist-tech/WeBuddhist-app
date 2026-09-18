import 'package:flutter_pecha/features/push_notifications/application/foreground_push_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ForegroundPushFilter filter;

  const roomX = {'session_type': 'CHAT', 'room_id': 'x'};
  const roomY = {'session_type': 'CHAT', 'room_id': 'y'};

  bool isRoomX(Map<String, dynamic> data) => data['room_id'] == 'x';

  setUp(() => filter = ForegroundPushFilter());

  test('shows everything while nothing is claimed', () {
    expect(filter.shouldShow(roomX), isTrue);
    expect(filter.shouldShow(const {}), isTrue);
  });

  test('a matching claim suppresses, a non-matching push still shows', () {
    final owner = Object();
    filter.claim(owner, isRoomX);

    expect(filter.shouldShow(roomX), isFalse);
    expect(filter.shouldShow(roomY), isTrue);
  });

  test('release restores display', () {
    final owner = Object();
    filter.claim(owner, isRoomX);
    filter.release(owner);

    expect(filter.shouldShow(roomX), isTrue);
  });

  test('releasing an owner that never claimed is a no-op', () {
    filter.claim(Object(), isRoomX);
    filter.release(Object());

    expect(filter.shouldShow(roomX), isFalse);
  });

  test('two owners: releasing one leaves the other claim active', () {
    final lower = Object();
    final upper = Object();
    filter.claim(lower, isRoomX);
    filter.claim(upper, (data) => data['room_id'] == 'y');

    expect(filter.shouldShow(roomX), isFalse);
    expect(filter.shouldShow(roomY), isFalse);

    filter.release(upper);

    expect(filter.shouldShow(roomY), isTrue);
    expect(filter.shouldShow(roomX), isFalse);
  });

  test('claiming again under the same owner replaces the matcher', () {
    final owner = Object();
    filter.claim(owner, isRoomX);
    filter.claim(owner, (data) => data['room_id'] == 'y');

    expect(filter.shouldShow(roomX), isTrue);
    expect(filter.shouldShow(roomY), isFalse);
  });

  test('a matcher that throws does not suppress', () {
    filter.claim(Object(), (_) => throw StateError('broken'));

    expect(filter.shouldShow(roomX), isTrue);
  });

  test('a throwing matcher does not stop a later one from matching', () {
    filter.claim(Object(), (_) => throw StateError('broken'));
    filter.claim(Object(), isRoomX);

    expect(filter.shouldShow(roomX), isFalse);
  });
}
