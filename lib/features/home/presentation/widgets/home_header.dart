import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/home/domain/entities/today_event.dart';
import 'package:flutter_pecha/features/home/presentation/providers/streak_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/today_events_provider.dart';
import 'package:flutter_pecha/features/home/presentation/utils/home_live_event_navigation.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/today_event_badge.dart';
import 'package:flutter_pecha/features/more/presentation/providers/user_stats_provider.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/streak_share_sheet.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_pecha/shared/widgets/main_tab_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Home tab app bar with greeting and quick actions.
class HomeTabAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeTabAppBar({
    super.key,
    required this.toolbarHeight,
    required this.firstName,
  });

  final double toolbarHeight;
  final String? firstName;

  static const double tibetanGreetingTopPadding = 6;
  // Shorter than the default bar so the event badge sits closer to the greeting.
  static const double _toolbarHeight = 44;
  static const double _actionsReserveWidth = 148;
  static const double _tibetanNameLineSpacing = 2;

  static double toolbarHeightFor({
    required BuildContext context,
    required bool hasName,
  }) {
    final isTwoLineTibetanGreeting = context.isTibetanLocale && hasName;
    if (!isTwoLineTibetanGreeting) {
      return _toolbarHeight;
    }

    final fontSize = getLocalizedFontSize(AppTextSize.body);
    final lineHeightPx = fontSize * AppFontConfig.tibetanCompactLineHeight;
    return tibetanGreetingTopPadding +
        lineHeightPx +
        _tibetanNameLineSpacing +
        lineHeightPx;
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakCount = ref
        .watch(streakFutureProvider)
        .maybeWhen(
          data: (either) => either.getOrElse((_) => 0),
          orElse: () => 0,
        );

    return MainTabAppBar(
      toolbarHeight: toolbarHeight,
      titleWidget: _Greeting(
        firstName: firstName,
        maxWidth:
            MediaQuery.sizeOf(context).width -
            MainTabAppBar.titleSpacing -
            HomeTabAppBar._actionsReserveWidth,
      ),
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.calendar),
          icon: Icon(
            AppAssets.calendarDots,
            size: 24,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        _StreakBadge(count: streakCount),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Optional today-event banner shown below the home tab app bar.
class HomeEventBanner extends ConsumerStatefulWidget {
  const HomeEventBanner({super.key});

  @override
  ConsumerState<HomeEventBanner> createState() => _HomeEventBannerState();
}

class _HomeEventBannerState extends ConsumerState<HomeEventBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Re-evaluates the daily window while the screen stays open.
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final events = ref
        .watch(todayEventsFutureProvider)
        .maybeWhen(
          data:
              (eventsEither) => eventsEither.fold(
                (_) => const <TodayEvent>[],
                (events) => events,
              ),
          orElse: () => const <TodayEvent>[],
        );

    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = [
      for (final event in events)
        TodayEventBadgeItem(
          id: event.id,
          name: event.name,
          avatarUrl: event.groupAvatarUrl,
          isLive: event.isActiveAt(now),
        ),
    ];
    // Live events lead so the collapsed pill shows one that is on now.
    final liveFirst = [
      ...items.where((item) => item.isLive),
      ...items.where((item) => !item.isLive),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: TodayEventBadge(
        events: liveFirst,
        onSelect: (eventId) => openHomeLiveEvent(context, eventId),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName, required this.maxWidth});

  final String? firstName;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final greetingFontSize = getLocalizedFontSize(
      context.isTibetanLocale ? AppTextSize.body : AppTextSize.title,
    );
    final greetingStyle = MainTabAppBar.titleStyle(
      context,
    ).copyWith(color: colorScheme.onSurface, fontSize: greetingFontSize);
    final strutStyle = context.tibetanStrutStyle(
      greetingFontSize,
      compact: true,
    );
    final displayName = firstName?.isNotEmpty == true ? firstName : null;

    final Widget greetingContent;
    if (context.isTibetanLocale) {
      greetingContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localizations.home_hello_prefix.trim(),
            style: greetingStyle,
            strutStyle: strutStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (displayName != null) ...[
            const SizedBox(height: 2),
            Text(
              displayName,
              style: greetingStyle,
              strutStyle: strutStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
    } else {
      final greeting =
          displayName != null
              ? '${localizations.home_hello_prefix}$displayName'
              : localizations.home_hello_prefix.trim();
      greetingContent = Text(
        greeting,
        style: greetingStyle,
        strutStyle: strutStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return SizedBox(
      width: maxWidth,
      child: Padding(
        padding: EdgeInsets.only(
          top:
              context.isTibetanLocale
                  ? HomeTabAppBar.tibetanGreetingTopPadding
                  : 0,
        ),
        child: greetingContent,
      ),
    );
  }
}

class _StreakBadge extends ConsumerStatefulWidget {
  const _StreakBadge({required this.count});

  final int count;

  @override
  ConsumerState<_StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends ConsumerState<_StreakBadge> {
  static const _flameColor = Color(0xFFE8630A);
  bool _isOpening = false;

  Future<void> _onStreakTap() async {
    if (_isOpening) return;

    setState(() => _isOpening = true);

    try {
      final either = await ref.read(userStatsFutureProvider.future);
      if (!mounted) return;

      either.fold(
        (_) {},
        (stats) => showStreakShareSheet(context, stats.streak),
      );
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _onStreakTap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppAssets.flame, size: 24, color: _flameColor),
          const SizedBox(width: 4),
          Text(
            '${widget.count}',
            style: TextStyle(
              fontFamily: getSystemFontFamily(AppConfig.englishLanguageCode),
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
