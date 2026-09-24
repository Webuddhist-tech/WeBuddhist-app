import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_member.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_post_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_nested_tab_scroll_view.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_remove_member_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupProfileMembersTab extends ConsumerStatefulWidget {
  final String groupId;
  final GroupType groupType;
  final bool isDark;
  final double? lineHeight;
  final String pageStorageKey;

  const GroupProfileMembersTab({
    super.key,
    required this.groupId,
    required this.groupType,
    required this.isDark,
    required this.pageStorageKey,
    this.lineHeight,
  });

  @override
  ConsumerState<GroupProfileMembersTab> createState() =>
      _GroupProfileMembersTabState();
}

class _GroupProfileMembersTabState
    extends ConsumerState<GroupProfileMembersTab> {
  bool _hasRequestedInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _loadInitialIfNeeded();
  }

  void _loadInitialIfNeeded() {
    if (_hasRequestedInitialLoad) return;
    _hasRequestedInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(groupMembersProvider(widget.groupId).notifier).loadInitial();
    });
  }

  bool _onScrollLoadMore(ScrollNotification notification) {
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 200) {
      ref.read(groupMembersProvider(widget.groupId).notifier).loadMore();
    }
    return false;
  }

  String _membersHeading(BuildContext context, int count) {
    return widget.groupType.isPage
        ? context.l10n.group_followers_heading(count)
        : context.l10n.group_members_heading(count);
  }

  bool _canRemoveMembers() {
    if (widget.groupType.isPage) return false;
    return ref
            .watch(groupMyPermissionProvider(widget.groupId))
            .valueOrNull
            ?.isGroupAdmin ??
        false;
  }

  Future<void> _removeMember(GroupMember member) async {
    final removed = await GroupRemoveMemberSheet.show(
      context,
      groupId: widget.groupId,
      member: member,
    );
    if (removed != true || !mounted) return;
    final name =
        member.fullname.trim().isNotEmpty
            ? member.fullname.trim()
            : member.username;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.group_remove_member_success(name))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(groupMembersProvider(widget.groupId));
    final canRemove = _canRemoveMembers();
    final currentUserId = ref.watch(userProvider).user?.id?.trim() ?? '';

    if (membersState.isLoading && membersState.members.isEmpty) {
      return GroupProfileNestedTabScrollView.centered(
        pageStorageKey: widget.pageStorageKey,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (membersState.error != null && membersState.members.isEmpty) {
      return GroupProfileNestedTabScrollView.centered(
        pageStorageKey: widget.pageStorageKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ErrorStateWidget(
            error: membersState.error!,
            onRetry:
                () =>
                    ref
                        .read(groupMembersProvider(widget.groupId).notifier)
                        .retry(),
            customMessage:
                widget.groupType.isPage
                    ? context.l10n.group_followers_load_error
                    : context.l10n.group_members_load_error,
          ),
        ),
      );
    }

    if (membersState.members.isEmpty) {
      return GroupProfileNestedTabScrollView(
        pageStorageKey: widget.pageStorageKey,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 16, bottom: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (!membersState.isLoading)
                  _MembersHeading(
                    title: _membersHeading(context, membersState.totalMembers),
                    isDark: widget.isDark,
                    lineHeight: widget.lineHeight,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Text(
                    widget.groupType.isPage
                        ? context.l10n.group_followers_empty
                        : context.l10n.group_members_empty,
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          widget.isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textSecondary,
                      height: widget.lineHeight,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      );
    }

    final itemCount =
        1 + membersState.members.length + (membersState.isLoadingMore ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollLoadMore,
      child: GroupProfileNestedTabScrollView(
        pageStorageKey: widget.pageStorageKey,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 16, bottom: 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == 0) {
                  return _MembersHeading(
                    title: _membersHeading(context, membersState.totalMembers),
                    isDark: widget.isDark,
                    lineHeight: widget.lineHeight,
                  );
                }

                final memberIndex = index - 1;
                if (memberIndex < membersState.members.length) {
                  final member = membersState.members[memberIndex];
                  final isSelf =
                      currentUserId.isNotEmpty && member.userId == currentUserId;
                  return _GroupMemberRow(
                    member: member,
                    isDark: widget.isDark,
                    lineHeight: widget.lineHeight,
                    showAdminBadge: member.isAdmin,
                    onRemove:
                        canRemove && member.canBeRemovedByAdmin && !isSelf
                            ? () => _removeMember(member)
                            : null,
                  );
                }

                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }, childCount: itemCount),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersHeading extends StatelessWidget {
  final String title;
  final bool isDark;
  final double? lineHeight;

  const _MembersHeading({
    required this.title,
    required this.isDark,
    this.lineHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          height: lineHeight,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _GroupMemberRow extends StatelessWidget {
  final GroupMember member;
  final bool isDark;
  final double? lineHeight;
  final bool showAdminBadge;
  final VoidCallback? onRemove;

  const _GroupMemberRow({
    required this.member,
    required this.isDark,
    this.lineHeight,
    this.showAdminBadge = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final displayName =
        member.fullname.trim().isNotEmpty
            ? member.fullname.trim()
            : member.username;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child:
                      member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageWidget(
                            key: ValueKey(member.avatarUrl),
                            imageUrl: member.avatarUrl,
                            fit: BoxFit.cover,
                            errorWidget: _buildAvatarFallback(isDark),
                          )
                          : _buildAvatarFallback(isDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: lineHeight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (member.username.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '@${member.username}',
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryColor,
                            height: lineHeight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (showAdminBadge) ...[
                const SizedBox(width: 8),
                _AdminBadge(isDark: isDark),
              ] else if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  tooltip: context.l10n.group_remove_member(displayName),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(
                    Icons.close,
                    size: 22,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAvatarFallback(bool isDark) {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.profile,
        size: 22,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  final bool isDark;

  const _AdminBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.chipBackgroundDark : AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.l10n.group_member_admin,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}
