import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/core.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/presentation/calendar_l10n_utils.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/calendar_event_sources_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/personal_event_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// One event: its date, where it came from, its title and when it happens.
/// Space events open their page and personal events their edit sheet; lunar
/// events have nowhere to go, so they take no taps and show no chevron.
class CalendarEventCard extends ConsumerStatefulWidget {
  const CalendarEventCard({super.key, required this.event});

  final CalendarEvent event;

  @override
  ConsumerState<CalendarEventCard> createState() => _CalendarEventCardState();
}

class _CalendarEventCardState extends ConsumerState<CalendarEventCard> {
  /// True while a personal event's details load, before its sheet can open.
  bool _opening = false;

  Future<void> _open() async {
    final event = widget.event;
    final id = event.eventId;
    if (id == null || _opening) return;
    if (event.kind == CalendarEventKind.group) {
      context.push(AppRoutes.groupEventPath(id));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _opening = true);
    // The feed row lacks the first date, which the repeat options come from.
    final result = await ref
        .read(personalCalendarRepositoryProvider)
        .getEvent(id);
    if (!mounted) return;
    setState(() => _opening = false);
    final personalEvent = result.fold((_) => null, (value) => value);
    if (personalEvent == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.something_went_wrong)),
      );
      return;
    }
    final deleted = await PersonalEventSheet.show(
      context,
      date: event.date,
      event: personalEvent,
    );
    if (deleted == true) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.calendar_event_deleted)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final locale = dateFormatLocale(context);
    final radius = BorderRadius.circular(14);

    return Material(
      color: theme.cardTheme.color,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: event.isTappable ? _open : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: radius,
          ),
          child: Row(
            children: [
              _DateBlock(
                day: '${event.date.day}',
                weekday: DateFormat.E(locale).format(event.date).toUpperCase(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SourceRow(event: event, color: muted),
                    const SizedBox(height: 2),
                    Text(
                      eventTitle(context.l10n, event),
                      strutStyle: context.tibetanStrutStyle(
                        theme.textTheme.bodyLarge?.fontSize ?? 16,
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      eventDetailLine(context, event),
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              if (event.isTappable) ...[
                const SizedBox(width: 8),
                _opening
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Icon(AppAssets.caretRight, size: 20, color: muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.day, required this.weekday});

  final String day;
  final String weekday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            weekday,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Lunar calendar" with its icon, or the space or person with their avatar.
class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.event, required this.color});

  final CalendarEvent event;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isLunar = event.kind == CalendarEventKind.lunarPhase;
    final name =
        isLunar ? context.l10n.calendar_source_lunar : event.sourceName;
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    final avatarUrl = event.sourceAvatarUrl;

    final Widget fallback = Icon(
      isLunar ? AppAssets.calendarBlank : AppAssets.calendarDots,
      size: 16,
      color: color,
    );
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 16,
            height: 16,
            child:
                avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImageWidget(
                      imageUrl: avatarUrl,
                      width: 16,
                      height: 16,
                      fit: BoxFit.cover,
                      errorWidget: fallback,
                    )
                    : fallback,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
