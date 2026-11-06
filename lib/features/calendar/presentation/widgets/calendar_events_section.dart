import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/calendar/presentation/calendar_l10n_utils.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/calendar_event_card.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/upcoming_events_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Above the grid: upcoming events, until a day is tapped. Then that day's
/// events, with a Today button that goes back.
class CalendarEventsSection extends ConsumerWidget {
  const CalendarEventsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = ref.watch(hasPickedCalendarDayProvider);
    return picked ? const _SelectedDayEvents() : const UpcomingEventsList();
  }
}

class _SelectedDayEvents extends ConsumerWidget {
  const _SelectedDayEvents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final day = ref.watch(selectedCalendarDayProvider);
    final events = ref.watch(dayEventsProvider(day));
    final title = DateFormat(
      'EEE d MMM',
      dateFormatLocale(context),
    ).format(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                strutStyle: context.tibetanStrutStyle(
                  theme.textTheme.titleMedium?.fontSize ?? 16,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => showCalendarToday(ref),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(color: theme.colorScheme.onSurface),
                shape: const StadiumBorder(),
              ),
              child: Text(l10n.calendar_today),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Text(
            l10n.calendar_no_events,
            strutStyle: context.tibetanStrutStyle(
              theme.textTheme.bodyMedium?.fontSize ?? 14,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          )
        else
          for (final event in events) ...[
            CalendarEventCard(event: event),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
