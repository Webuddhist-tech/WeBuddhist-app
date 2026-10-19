import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_card_layout.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_list_tile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_nested_tab_scroll_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupProfileEventsTab extends ConsumerWidget {
  final String groupId;
  final bool isDark;
  final double? lineHeight;
  final String pageStorageKey;

  /// True when the signed-in user may create events in this group.
  final bool canCreate;
  final VoidCallback onCreateEvent;

  const GroupProfileEventsTab({
    super.key,
    required this.groupId,
    required this.isDark,
    required this.pageStorageKey,
    required this.canCreate,
    required this.onCreateEvent,
    this.lineHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(groupEventsProvider(groupId));

    return eventsAsync.when(
      data: (either) {
        return either.fold(
          (failure) => GroupProfileNestedTabScrollView.centered(
            pageStorageKey: pageStorageKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ErrorStateWidget(
                error: failure,
                customMessage: context.l10n.group_events_load_error,
                onRetry: () => ref.invalidate(groupEventsProvider(groupId)),
              ),
            ),
          ),
          (page) {
            if (page.events.isEmpty) {
              return GroupProfileNestedTabScrollView.centered(
                pageStorageKey: pageStorageKey,
                child: _EmptyEvents(
                  isDark: isDark,
                  lineHeight: lineHeight,
                  canCreate: canCreate,
                  onCreateEvent: onCreateEvent,
                ),
              );
            }

            return Stack(
              children: [
                GroupProfileNestedTabScrollView(
                  pageStorageKey: pageStorageKey,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        8,
                        0,
                        canCreate ? 96 : 32,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final event = page.events[index];
                          final isLast = index == page.events.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  isLast
                                      ? 0
                                      : ConnectFeedCardLayout.listItemGap,
                            ),
                            child: GroupEventListTile(
                              event: event,
                              showGroup: event.groupId != groupId,
                              isDark: isDark,
                              lineHeight: lineHeight,
                              onTap:
                                  () =>
                                      context.push('/home/events/${event.id}'),
                            ),
                          );
                        }, childCount: page.events.length),
                      ),
                    ),
                  ],
                ),
                if (canCreate)
                  Positioned(
                    right: 16,
                    bottom: 24,
                    child: _CreateEventFab(
                      isDark: isDark,
                      onTap: onCreateEvent,
                    ),
                  ),
              ],
            );
          },
        );
      },
      loading:
          () => GroupProfileNestedTabScrollView.centered(
            pageStorageKey: pageStorageKey,
            child: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, _) => GroupProfileNestedTabScrollView.centered(
            pageStorageKey: pageStorageKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ErrorStateWidget(
                error: error,
                customMessage: context.l10n.group_events_load_error,
                onRetry: () => ref.invalidate(groupEventsProvider(groupId)),
              ),
            ),
          ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents({
    required this.isDark,
    required this.lineHeight,
    required this.canCreate,
    required this.onCreateEvent,
  });

  final bool isDark;
  final double? lineHeight;
  final bool canCreate;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.group_events_empty,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: titleColor,
                height: lineHeight,
              ),
            ),
            if (canCreate) ...[
              const SizedBox(height: 6),
              Text(
                l10n.group_events_empty_message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryColor,
                  height: lineHeight,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onCreateEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                  foregroundColor:
                      isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  l10n.group_event_create_button,
                  strutStyle: context.tibetanStrutStyle(15),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateEventFab extends StatelessWidget {
  const _CreateEventFab({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: context.l10n.group_event_new_title,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              AppAssets.plus,
              size: 26,
              color: isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
            ),
          ),
        ),
      ),
    );
  }
}
