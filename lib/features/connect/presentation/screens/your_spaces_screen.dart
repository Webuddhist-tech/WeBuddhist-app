import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_space_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_landing_view.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/group_search_result_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The member's spaces, to switch which one the Connect tab shows, with
/// "Find a space" at the bottom.
class YourSpacesScreen extends ConsumerWidget {
  const YourSpacesScreen({super.key, required this.currentSpaceId});

  final String? currentSpaceId;

  /// Slides in from the left on the tab's own navigator, so the bottom
  /// navigation bar stays.
  static Future<void> show(BuildContext context, {String? currentSpaceId}) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: 'your-spaces'),
        pageBuilder:
            (_, _, _) => YourSpacesScreen(currentSpaceId: currentSpaceId),
        transitionsBuilder:
            (_, animation, _, child) => SlideTransition(
              position: Tween(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
              child: child,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(joinedSpacesProvider).spaces;
    final unread = ref.watch(unreadSpaceIdsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.connect_your_spaces,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: context.l10n.close,
                    icon: const Icon(AppAssets.x),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: spaces.length,
                itemBuilder: (context, index) {
                  final space = spaces[index];
                  return ColoredBox(
                    color:
                        space.id == currentSpaceId
                            ? (isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.grey100)
                            : Colors.transparent,
                    child: GroupSearchResultCard(
                      group: space,
                      trailing:
                          unread.contains(space.id)
                              ? const ConnectUnreadDot()
                              : null,
                      onTap: () {
                        ref
                            .read(connectLastSpaceProvider.notifier)
                            .select(space.id);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: dividerColor)),
              ),
              child: InkWell(
                onTap: () => ConnectSpaceSearchField.openSearch(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppAssets.exploreUnselected,
                        size: 20,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.l10n.connect_find_a_space,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The red dot for a space with unread chat messages.
class ConnectUnreadDot extends StatelessWidget {
  const ConnectUnreadDot({super.key, this.size = 9});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? AppColors.unreadBadgeDark
                : AppColors.unreadBadge,
        shape: BoxShape.circle,
        // Rings the dot in the background colour so it stays legible over
        // an icon.
        border: Border.all(color: theme.scaffoldBackgroundColor),
      ),
    );
  }
}
