import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/core.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/calendar_event_sources_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/calendar_events_section.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/calendar_header_card.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/calendar_month_nav.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/personal_event_sheet.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/tibetan_calendar_grid.dart';
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
    showCalendarToday(ref);
  }

  void _addEvent() {
    final auth = ref.read(authProvider);
    if (auth.isGuest || !auth.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }
    PersonalEventSheet.show(
      context,
      date: ref.read(selectedCalendarDayProvider),
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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.calendar_title,
              strutStyle: context.tibetanStrutStyle(
                theme.textTheme.titleLarge?.fontSize ?? 22,
              ),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              l10n.calendar_subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(AppAssets.plus, size: 24),
            tooltip: l10n.calendar_add_event,
            onPressed: _addEvent,
          ),
        ],
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
              CalendarEventsSection(),
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
