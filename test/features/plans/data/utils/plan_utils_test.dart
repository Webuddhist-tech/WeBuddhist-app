import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daysBetween counts calendar days, not elapsed hours', () {
    expect(
      PlanUtils.daysBetween(DateTime(2026, 9, 1, 23), DateTime(2026, 9, 2, 1)),
      1,
    );
    expect(
      PlanUtils.daysBetween(DateTime(2026, 9, 24), DateTime(2026, 9, 24)),
      0,
    );
    expect(
      PlanUtils.daysBetween(DateTime(2026, 8, 30), DateTime(2026, 9, 2)),
      3,
    );
    expect(
      PlanUtils.daysBetween(DateTime(2026, 9, 2), DateTime(2026, 9, 1)),
      -1,
    );
  });
}
