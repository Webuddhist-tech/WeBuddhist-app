import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_list_tile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(initializeDateFormatting);

  String upcomingLabel(DateTime when) {
    final day = DateFormat('d MMM y', 'en').format(when);
    final time = DateFormat.jm('en').format(when).toLowerCase();
    return '$day · $time';
  }

  Future<String?> labelFor(WidgetTester tester, GroupEvent event) async {
    String? label;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            label = GroupEventListTile.formatDateLabel(context, event);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return label;
  }

  testWidgets('a repeating event shows the upcoming occurrence', (
    tester,
  ) async {
    final upcoming = DateTime(2026, 11, 8, 17, 30);
    final label = await labelFor(
      tester,
      GroupEvent(
        id: 'event-1',
        groupId: 'group-1',
        isRecurring: true,
        recurrence: const GroupEventRecurrence(frequency: 'MONTHLY'),
        startDate: DateTime(2026, 10, 9, 17, 30),
        occurrenceDate: upcoming,
      ),
    );

    expect(label, upcomingLabel(upcoming));
  });

  testWidgets('a repeating event falls back to the start when there is no '
      'occurrence', (tester) async {
    final start = DateTime(2026, 11, 8, 17, 30);
    final label = await labelFor(
      tester,
      GroupEvent(
        id: 'event-1',
        groupId: 'group-1',
        isRecurring: true,
        recurrence: const GroupEventRecurrence(frequency: 'WEEKLY'),
        startDate: start,
      ),
    );

    expect(label, upcomingLabel(start));
  });
}
