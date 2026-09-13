import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _listPadding = EdgeInsets.fromLTRB(16, 16, 16, 32);

/// Signed-in user's own count for one accumulation.
///
/// [embedded] lays it out inline for a parent scroll view.
class GroupAccumulatorMyContributionsList extends StatefulWidget {
  final GroupAccumulatorDetail detail;
  final bool isDark;
  final bool embedded;

  const GroupAccumulatorMyContributionsList({
    super.key,
    required this.detail,
    required this.isDark,
    this.embedded = false,
  });

  @override
  State<GroupAccumulatorMyContributionsList> createState() =>
      _GroupAccumulatorMyContributionsListState();
}

class _GroupAccumulatorMyContributionsListState
    extends State<GroupAccumulatorMyContributionsList> {
  GroupAccumulatorMemberSort _sort = GroupAccumulatorMemberSort.total;

  @override
  Widget build(BuildContext context) {
    final user = widget.detail.user;
    final secondaryColor =
        widget.isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final numberFormat = NumberFormat.decimalPattern(
      intlFormatLocaleOf(context),
    );

    if (user == null) {
      final empty = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Text(
          context.l10n.group_accumulator_contributions_empty,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: secondaryColor),
        ),
      );
      return widget.embedded ? empty : Center(child: empty);
    }

    final count =
        _sort == GroupAccumulatorMemberSort.today
            ? user.todayCount
            : user.totalCount;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _RecitedLabel(isDark: widget.isDark),
            const Spacer(),
            GroupAccumulatorSortToggle(
              sort: _sort,
              isDark: widget.isDark,
              onChanged: (sort) => setState(() => _sort = sort),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            GroupAccumulatorMemberAvatar(
              avatarUrl: user.imageUrl,
              isDark: widget.isDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.displayName,
                style: _nameStyle(widget.isDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(numberFormat.format(count), style: _nameStyle(widget.isDark)),
          ],
        ),
      ],
    );

    if (widget.embedded) return content;
    return ListView(padding: _listPadding, children: [content]);
  }
}

/// Paginated leaderboard for one accumulation.
///
/// [embedded] lays it out inline for a parent scroll view and swaps the
/// scroll-driven pagination for a "show more" tail.
class GroupAccumulatorLeaderboardList extends ConsumerStatefulWidget {
  final String accumulatorId;
  final bool isDark;
  final bool embedded;

  const GroupAccumulatorLeaderboardList({
    super.key,
    required this.accumulatorId,
    required this.isDark,
    this.embedded = false,
  });

  @override
  ConsumerState<GroupAccumulatorLeaderboardList> createState() =>
      _GroupAccumulatorLeaderboardListState();
}

class _GroupAccumulatorLeaderboardListState
    extends ConsumerState<GroupAccumulatorLeaderboardList> {
  final ScrollController _scrollController = ScrollController();
  bool _hasRequestedInitialLoad = false;
  GroupAccumulatorMemberSort _sort = GroupAccumulatorMemberSort.total;

  GroupAccumulatorMembersKey get _membersKey => GroupAccumulatorMembersKey(
    accumulatorId: widget.accumulatorId,
    sortBy: _sort,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialIfNeeded();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialIfNeeded({bool force = false}) {
    if (_hasRequestedInitialLoad && !force) return;
    _hasRequestedInitialLoad = true;
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(groupAccumulatorMembersProvider(_membersKey).notifier)
          .loadInitial(force: force);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    ref.read(groupAccumulatorMembersProvider(_membersKey).notifier).loadMore();
  }

  void _onSortChanged(GroupAccumulatorMemberSort sort) {
    if (_sort == sort) return;
    setState(() => _sort = sort);
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(groupAccumulatorMembersProvider(_membersKey).notifier)
          .loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(
      groupAccumulatorMembersProvider(_membersKey),
    );
    final secondaryColor =
        widget.isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final numberFormat = NumberFormat.decimalPattern(
      intlFormatLocaleOf(context),
    );

    if ((membersState.isLoading || !membersState.hasLoadedOnce) &&
        membersState.members.isEmpty &&
        membersState.error == null) {
      if (!membersState.isLoading) {
        Future.microtask(() {
          if (!mounted) return;
          ref
              .read(groupAccumulatorMembersProvider(_membersKey).notifier)
              .loadInitial();
        });
      }
      return _wrapStatus(const CircularProgressIndicator());
    }

    if (membersState.error != null && membersState.members.isEmpty) {
      return _wrapStatus(
        ErrorStateWidget(
          error: membersState.error!,
          onRetry:
              () =>
                  ref
                      .read(
                        groupAccumulatorMembersProvider(_membersKey).notifier,
                      )
                      .retry(),
        ),
      );
    }

    final sortedMembers =
        sortAccumulatorMembers(membersState.members, _sort).where((member) {
          return _countOf(member) > 0;
        }).toList();

    final hasAnyPositive = membersState.members.any(
      (member) => _countOf(member) > 0,
    );

    final showEmptyMessage =
        membersState.hasLoadedOnce &&
        !hasAnyPositive &&
        !membersState.isLoading &&
        !membersState.isLoadingMore &&
        membersState.error == null;
    final showMoreButton =
        widget.embedded &&
        !showEmptyMessage &&
        membersState.hasMore &&
        !membersState.isLoadingMore;

    return ListView.builder(
      controller: widget.embedded ? null : _scrollController,
      shrinkWrap: widget.embedded,
      physics: widget.embedded ? const NeverScrollableScrollPhysics() : null,
      padding: widget.embedded ? EdgeInsets.zero : _listPadding,
      itemCount:
          1 +
          (showEmptyMessage ? 1 : sortedMembers.length) +
          (membersState.isLoadingMore ? 1 : 0) +
          (showMoreButton ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                _RecitedLabel(isDark: widget.isDark),
                const Spacer(),
                GroupAccumulatorSortToggle(
                  sort: _sort,
                  isDark: widget.isDark,
                  onChanged: _onSortChanged,
                ),
              ],
            ),
          );
        }

        if (showEmptyMessage && index == 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              context.l10n.group_accumulator_leaderboard_empty,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: secondaryColor),
            ),
          );
        }

        final memberIndex = index - 1 - (showEmptyMessage ? 1 : 0);
        if (memberIndex < sortedMembers.length) {
          final member = sortedMembers[memberIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${memberIndex + 1}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GroupAccumulatorMemberAvatar(
                  avatarUrl: member.avatarUrl,
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.displayName,
                    style: _nameStyle(widget.isDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  numberFormat.format(_countOf(member)),
                  style: _nameStyle(widget.isDark),
                ),
              ],
            ),
          );
        }

        if (showMoreButton && memberIndex == sortedMembers.length) {
          return Center(
            child: TextButton(
              onPressed: _loadMore,
              child: Text(
                context.l10n.show_more,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
            ),
          );
        }

        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  int _countOf(GroupAccumulatorMember member) =>
      _sort == GroupAccumulatorMemberSort.today
          ? member.todayCount
          : member.totalCount;

  Widget _wrapStatus(Widget child) {
    if (!widget.embedded) return Center(child: child);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: child),
    );
  }
}

TextStyle _nameStyle(bool isDark) => TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w600,
  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
);

class _RecitedLabel extends StatelessWidget {
  final bool isDark;

  const _RecitedLabel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.group_accumulator_recited,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
    );
  }
}

class GroupAccumulatorSortToggle extends StatelessWidget {
  final GroupAccumulatorMemberSort sort;
  final bool isDark;
  final ValueChanged<GroupAccumulatorMemberSort> onChanged;

  const GroupAccumulatorSortToggle({
    super.key,
    required this.sort,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SortToggleChip(
            label: context.l10n.home_today,
            isSelected: sort == GroupAccumulatorMemberSort.today,
            isDark: isDark,
            onTap: () => onChanged(GroupAccumulatorMemberSort.today),
          ),
          _SortToggleChip(
            label: context.l10n.group_accumulator_total,
            isSelected: sort == GroupAccumulatorMemberSort.total,
            isDark: isDark,
            onTap: () => onChanged(GroupAccumulatorMemberSort.total),
          ),
        ],
      ),
    );
  }
}

class _SortToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SortToggleChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (isDark ? AppColors.surfaceWhite : AppColors.textPrimary)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                isSelected
                    ? (isDark ? AppColors.textPrimary : AppColors.surfaceWhite)
                    : (isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class GroupAccumulatorMemberAvatar extends StatelessWidget {
  final String? avatarUrl;
  final bool isDark;

  const GroupAccumulatorMemberAvatar({
    super.key,
    required this.avatarUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child:
            avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  errorWidget: _placeholder(),
                )
                : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.profile,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}
