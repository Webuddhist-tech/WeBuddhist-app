import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/track_first_value.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_analytics.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_member_menu.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_notification_settings_drawer.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupProfileScreen extends ConsumerWidget {
  final String groupId;

  const GroupProfileScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(groupProfileProvider(groupId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profileTitle = profileAsync.maybeWhen(
      data: (either) => either.fold((_) => null, (profile) => profile.title),
      orElse: () => null,
    );
    final loadedProfile = profileAsync.valueOrNull?.fold(
      (_) => null,
      (profile) => profile,
    );

    final scaffold = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(
              context,
              ref,
              groupId,
              profileTitle,
              loadedProfile,
              isDark,
            ),
            Expanded(
              child: profileAsync.when(
                skipLoadingOnReload: true,
                data: (either) {
                  return either.fold(
                    (failure) => Center(
                      child: ErrorStateWidget(
                        error: failure,
                        onRetry:
                            () => ref.invalidate(groupProfileProvider(groupId)),
                      ),
                    ),
                    (profile) =>
                        GroupProfileBody(profile: profile, isDark: isDark),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => Center(
                      child: ErrorStateWidget(
                        error: error,
                        onRetry:
                            () => ref.invalidate(groupProfileProvider(groupId)),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );

    return TrackFirstValue<GroupProfile>(
      value: loadedProfile,
      onFirstValue:
          (profile) => ref
              .read(groupAnalyticsProvider)
              .groupViewed(groupId: groupId, groupType: profile.groupType),
      child: scaffold,
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    String? title,
    GroupProfile? profile,
    bool isDark,
  ) {
    final showTitle = ref.watch(groupProfileAppBarTitleVisibleProvider(groupId));
    final resolvedTitle = title?.trim() ?? '';
    final hasTitle = resolvedTitle.isNotEmpty;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          Expanded(
            child: AnimatedOpacity(
              opacity: showTitle && hasTitle ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Text(
                resolvedTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
          ),
          if (profile != null)
            _MemberMenuButton(profile: profile)
          else
            const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }
}

/// The ⋮ that opens the member sheet, shown only to a confirmed member or
/// Page follower. Otherwise an empty slot of the same size keeps the fading
/// title where it is.
class _MemberMenuButton extends ConsumerWidget {
  final GroupProfile profile;

  const _MemberMenuButton({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followKey = GroupFollowKey(
      groupId: profile.id,
      groupType: profile.groupType,
    );
    final followState = ref.watch(groupFollowProvider(followKey));
    final auth = ref.watch(authProvider);
    final shows = showsGroupMemberMenu(
      followState: followState,
      signedIn: auth.isLoggedIn && !auth.isGuest,
    );
    if (!shows) return const SizedBox(width: 48, height: 48);

    return IconButton(
      icon: const Icon(AppAssets.dotsThreeVertical),
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      // Not while a join or leave is still in flight.
      onPressed:
          followState is GroupFollowLoading
              ? null
              : () => openGroupMemberMenu(
                context,
                profile,
                followKey: followKey,
              ),
    );
  }
}
