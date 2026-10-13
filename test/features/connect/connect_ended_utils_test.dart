import 'package:flutter_pecha/features/connect/presentation/utils/connect_ended_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 12, 12);

  test('a missing end date is not finished', () {
    expect(isPastEndDate(null, now), isFalse);
  });

  test('an end date still ahead is not finished', () {
    expect(isPastEndDate(DateTime.utc(2026, 10, 15), now), isFalse);
  });

  test('the exact end instant counts as finished', () {
    expect(isPastEndDate(now, now), isTrue);
  });

  test('an end date already passed is finished', () {
    expect(isPastEndDate(DateTime.utc(2026, 7, 1, 9), now), isTrue);
  });
}
