import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
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

  const GroupProfileEventsTab({
    super.key,
    required this.groupId,
    required this.isDark,
    required this.pageStorageKey,
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
                customMessage: 'Unable to load events. Please try again.',
                onRetry: () => ref.invalidate(groupEventsProvider(groupId)),
              ),
            ),
          ),
          (page) {
            if (page.events.isEmpty) {
              return GroupProfileNestedTabScrollView(
                pageStorageKey: pageStorageKey,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'No events yet',
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textSecondary,
                          height: lineHeight,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return GroupProfileNestedTabScrollView(
              pageStorageKey: pageStorageKey,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final event = page.events[index];
                      return GroupEventListTile(
                        event: event,
                        showGroup: event.groupId != groupId,
                        isDark: isDark,
                        lineHeight: lineHeight,
                        onTap: () => context.push('/home/events/${event.id}'),
                      );
                    }, childCount: page.events.length),
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
                customMessage: 'Unable to load events. Please try again.',
                onRetry: () => ref.invalidate(groupEventsProvider(groupId)),
              ),
            ),
          ),
    );
  }
}
