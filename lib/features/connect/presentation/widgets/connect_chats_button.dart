import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/your_spaces_screen.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/chat_rooms_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Opens the chats list, with a dot when anything is unread. The Connect
/// tab's only way to a member's direct chats.
///
/// Watching `chatRoomsProvider` here is what loads it: there is no unread
/// endpoint, so the dot can only come from the rooms list.
class ConnectChatsButton extends ConsumerWidget {
  const ConnectChatsButton({super.key, this.color});

  /// Icon colour; defaults to the theme's, e.g. white over the landing photo.
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Guests have no rooms and the route is guest-blocked. Decided before
    // anything below is watched, so a guest never loads the rooms list.
    final isMember = ref.watch(
      authProvider.select((auth) => auth.isLoggedIn && !auth.isGuest),
    );
    if (!isMember) return const SizedBox.shrink();

    // Keeps the push and signal listeners alive while the dot is on screen.
    ref.watch(chatRoomsPushRefreshProvider);
    ref.watch(chatRoomsSignalsProvider);
    final hasUnread = ref.watch(chatRoomsProvider).hasUnread;

    return IconButton(
      onPressed: () => context.push(AppRoutes.chats),
      tooltip: context.l10n.chats_title,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            AppAssets.chatCircleDots,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
          if (hasUnread)
            const Positioned(top: -1, right: -1, child: ConnectUnreadDot()),
        ],
      ),
    );
  }
}
