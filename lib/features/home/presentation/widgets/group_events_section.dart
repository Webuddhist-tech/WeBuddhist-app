import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_event_card.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/home/presentation/providers/home_group_events_preview_provider.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_signal_providers.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/group_events_section_skeleton.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupEventsSection extends ConsumerWidget {
  const GroupEventsSection({super.key});

  static const _horizontalPadding = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Featuring and followed groups' event changes refresh the preview.
    ref.watch(featuredEventsSignalProvider);
    ref.watch(myFeedSignalsProvider);
    final eventsAsync = ref.watch(homeGroupEventsPreviewProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return _GroupEventsContent(events: events);
      },
      loading: () => const GroupEventsSectionSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _GroupEventsContent extends StatelessWidget {
  const _GroupEventsContent({required this.events});

  final List<GroupEvent> events;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTibetan = context.isTibetanLocale;
    final sectionTitleSize = getLocalizedFontSize(AppTextSize.bodyLarge);
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey100;
    final sectionContentGap = isTibetan ? 16.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GroupEventsSection._horizontalPadding,
            0,
            GroupEventsSection._horizontalPadding,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.home_group_events,
                  strutStyle: context.tibetanStrutStyle(
                    sectionTitleSize,
                    compact: true,
                  ),
                  style: TextStyle(
                    fontSize: sectionTitleSize,
                    fontWeight: FontWeight.w700,
                    height:
                        isTibetan ? AppFontConfig.tibetanCompactLineHeight : 1.2,
                    leadingDistribution:
                        isTibetan
                            ? AppFontConfig.tibetanLeadingDistribution
                            : null,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.pushNamed('home-group-events'),
                style: TextButton.styleFrom(
                  foregroundColor: subtitleColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.see_all,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: sectionContentGap),
        for (var i = 0; i < events.length; i++) ...[
          ConnectEventCard(event: events[i]),
          if (i < events.length - 1)
            Divider(height: 1, thickness: 1, color: dividerColor),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
