import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/track_first_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget build(String? value, List<String> seen) => TrackFirstValue<String>(
    value: value,
    onFirstValue: seen.add,
    child: const SizedBox.shrink(),
  );

  testWidgets('fires once, as soon as the value is available', (tester) async {
    final List<String> seen = [];

    await tester.pumpWidget(build(null, seen));
    expect(seen, isEmpty);

    await tester.pumpWidget(build('series-1', seen));
    await tester.pumpWidget(build('series-1', seen));
    await tester.pumpWidget(build('series-2', seen));

    expect(seen, ['series-1']);
  });

  testWidgets('fires on the first build when the value is already known', (
    tester,
  ) async {
    final List<String> seen = [];

    await tester.pumpWidget(build('series-1', seen));

    expect(seen, ['series-1']);
  });
}
