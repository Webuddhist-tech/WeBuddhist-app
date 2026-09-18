import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/chat_rooms_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/chat_room_tile.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_error_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Every group chat the viewer belongs to, most recently active first.
class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final ScrollController _scrollController = ScrollController();

  /// How close to the bottom the list gets before the next page is asked for.
  static const double _loadMoreThreshold = 400;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Whatever opened this screen may have loaded the list minutes ago.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(chatRoomsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(chatRoomsProvider.notifier).loadMore();
    }
  }

  /// Asks for the next page when the list is too short to scroll.
  ///
  /// Paging is driven by the scroll position, and a list that fits on screen
  /// never scrolls — so a viewer with a few group chats and more pages behind
  /// them would sit on a list that never grows. Runs after each build; once
  /// the list overflows, the scroll listener takes over. Not while an error
  /// is showing: a rebuild on every failure would turn that into a retry loop.
  void _fillViewport(ChatRoomsState state) {
    if (!mounted || !_scrollController.hasClients) return;
    if (!state.hasMore || state.isLoadingMore || state.error != null) return;
    if (_scrollController.position.maxScrollExtent > 0) return;
    ref.read(chatRoomsProvider.notifier).loadMore();
  }

  Future<void> _openRoom(ChatRoomDTO room) async {
    final groupId = room.groupId;
    if (groupId == null || groupId.isEmpty) return;

    await context.push(AppRoutes.groupChatPath(groupId));
    // Reading a thread clears its unread count server side, and messages may
    // have arrived in other rooms meanwhile.
    if (mounted) await ref.read(chatRoomsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatRoomsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          context.l10n.chats_title,
          strutStyle: context.tibetanStrutStyle(20, compact: true),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: _body(state),
    );
  }

  Widget _body(ChatRoomsState state) {
    if (!state.hasLoaded && state.rooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.rooms.isEmpty && state.error != null) {
      return GroupChatErrorState(
        onRetry: () => ref.read(chatRoomsProvider.notifier).retry(),
      );
    }

    if (state.rooms.isEmpty) {
      // Still pull-to-refresh: a viewer just added to their first group has
      // no other way to ask for the list again without leaving the screen.
      return RefreshIndicator(
        onRefresh: () => ref.read(chatRoomsProvider.notifier).refresh(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: const _EmptyChats(),
              ),
            );
          },
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _fillViewport(state));

    return RefreshIndicator(
      onRefresh: () => ref.read(chatRoomsProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.rooms.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.rooms.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final room = state.rooms[index];
          return ChatRoomTile(room: room, onTap: () => _openRoom(room));
        },
      ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppAssets.chatCircleDots,
              size: 40,
              color: isDark ? AppColors.grey600 : AppColors.grey400,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.chats_empty_title,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(16, compact: true),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.chats_empty_body,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(14),
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
