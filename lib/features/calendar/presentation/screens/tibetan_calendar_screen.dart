import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/core.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/calendar_event_sources_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/calendar_header_card.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/calendar_month_nav.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/tibetan_calendar_grid.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/upcoming_events_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Tibetan calendar screen: current lunar date, this month's events, and a
/// month-navigable grid showing the Gregorian + Tibetan lunar day per cell.
///
/// Stateful so it can keep "today" current: the selected day and focused month
/// are (re)synced to the real current date when the screen opens and when the
/// app resumes on a later calendar day — so a process left alive across
/// midnight still shows today's lunar date and fetches the current month.
class TibetanCalendarScreen extends ConsumerStatefulWidget {
  const TibetanCalendarScreen({super.key});

  @override
  ConsumerState<TibetanCalendarScreen> createState() =>
      _TibetanCalendarScreenState();
}

class _TibetanCalendarScreenState extends ConsumerState<TibetanCalendarScreen>
    with WidgetsBindingObserver {
  /// The calendar day "today" was last snapped to, to detect a date rollover.
  DateTime? _lastSyncedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fresh entry to the screen always shows today.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncToToday();
      // Events change while the app runs; old ones show until this lands.
      if (mounted) ref.invalidate(calendarFeedProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On returning to the foreground, refresh only if the calendar day has
    // actually changed — a quick app-switch shouldn't disturb in-session
    // browsing, but resuming on a new day should snap back to today.
    if (state == AppLifecycleState.resumed) {
      final today = dateOnly(DateTime.now());
      if (_lastSyncedDay == null || today != _lastSyncedDay) {
        _syncToToday();
      }
    }
  }

  /// Points the selected day at today and the grid at the current month.
  void _syncToToday() {
    if (!mounted) return;
    final today = dateOnly(DateTime.now());
    _lastSyncedDay = today;
    ref.read(selectedCalendarDayProvider.notifier).state = today;
    ref.read(focusedCalendarMonthProvider.notifier).state = DateTime(
      today.year,
      today.month,
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft, size: 24),
          tooltip: l10n.back,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          l10n.calendar_title,
          strutStyle: context.tibetanStrutStyle(
            theme.textTheme.titleLarge?.fontSize ?? 22,
          ),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              CalendarHeaderCard(),
              SizedBox(height: 24),
              UpcomingEventsList(),
              SizedBox(height: 16),
              CalendarMonthNav(),
              SizedBox(height: 8),
              TibetanCalendarGrid(),
            ],
          ),
        ),
      ),
    );
  }
}
