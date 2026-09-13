import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupEventParticipantsDrawer extends ConsumerStatefulWidget {
  const GroupEventParticipantsDrawer({
    super.key,
    required this.eventId,
    required this.totalAttending,
  });

  final String eventId;
  final int totalAttending;

  static Future<void> show(
    BuildContext context, {
    required String eventId,
    required int totalAttending,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder:
          (_) => GroupEventParticipantsDrawer(
            eventId: eventId,
            totalAttending: totalAttending,
          ),
    );
  }

  @override
  ConsumerState<GroupEventParticipantsDrawer> createState() =>
      _GroupEventParticipantsDrawerState();
}

class _GroupEventParticipantsDrawerState
    extends ConsumerState<GroupEventParticipantsDrawer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(groupEventParticipantsProvider(widget.eventId).notifier)
          .loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final participantsState = ref.watch(
      groupEventParticipantsProvider(widget.eventId),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.l10n.connect_event_participants_attending(
                      widget.totalAttending,
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
              ),
              Flexible(
                child: _buildParticipantsBody(context, participantsState, isDark),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsBody(
    BuildContext context,
    GroupEventParticipantsState participantsState,
    bool isDark,
  ) {
    if (participantsState.isLoading && participantsState.participants.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (participantsState.error != null &&
        participantsState.participants.isEmpty) {
      return Center(
        child: ErrorStateWidget(
          error: participantsState.error!,
          onRetry:
              () => ref
                  .read(groupEventParticipantsProvider(widget.eventId).notifier)
                  .retry(),
        ),
      );
    }

    return _ParticipantsList(
      participants: participantsState.participants,
      isDark: isDark,
      scrollController: _scrollController,
      isLoadingMore: participantsState.isLoadingMore,
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ParticipantsList extends StatelessWidget {
  const _ParticipantsList({
    required this.participants,
    required this.isDark,
    required this.scrollController,
    required this.isLoadingMore,
  });

  final List<GroupEventParticipant> participants;
  final bool isDark;
  final ScrollController scrollController;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.connect_event_participants_empty,
            style: TextStyle(
              color:
                  isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final itemCount = participants.length + (isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= participants.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final participant = participants[index];
        return Column(
          children: [
            if (index > 0)
              Divider(
                height: 1,
                color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
              ),
            _ParticipantTile(participant: participant, isDark: isDark),
          ],
        );
      },
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant, required this.isDark});

  final GroupEventParticipant participant;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final username = participant.username?.trim();
    final showUsername =
        username != null &&
        username.isNotEmpty &&
        username != participant.displayName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _ParticipantAvatar(participant: participant, isDark: isDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showUsername) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({required this.participant, required this.isDark});

  final GroupEventParticipant participant;
  final bool isDark;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = participant.avatarUrl;

    return ClipOval(
      child:
          avatarUrl != null && avatarUrl.isNotEmpty
              ? CachedNetworkImageWidget(
                imageUrl: avatarUrl,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                errorWidget: _avatarFallback(),
              )
              : _avatarFallback(),
    );
  }

  Widget _avatarFallback() {
    final name = participant.displayName;
    final initials = _getInitials(name);

    return ColoredBox(
      color: AppColors.primary,
      child: SizedBox(
        width: _size,
        height: _size,
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDarkest,
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0].characters.first}${parts[1].characters.first}'
          .toUpperCase();
    }
    return name.characters.take(2).toString().toUpperCase();
  }
}
