import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// (⋮) sheet on the event page: leave the event.
class GroupEventMoreSheet extends StatelessWidget {
  const GroupEventMoreSheet({super.key, required this.onLeave});

  /// Runs once the sheet has closed, so it can open the confirmation.
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(AppAssets.signOut, color: AppColors.danger),
            title: Text(
              context.l10n.connect_event_leave,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.danger,
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              onLeave();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

void showGroupEventMoreSheet(
  BuildContext context, {
  required VoidCallback onLeave,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    useRootNavigator: true,
    builder: (_) => GroupEventMoreSheet(onLeave: onLeave),
  );
}
