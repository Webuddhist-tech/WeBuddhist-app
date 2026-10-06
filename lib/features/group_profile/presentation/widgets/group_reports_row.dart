import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_reports_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_reports_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_admin_queue_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin-only entry to the group's moderation queue, on public and private
/// groups alike. Hidden while there is nothing unresolved to review.
class GroupReportsRow extends ConsumerWidget {
  const GroupReportsRow({
    super.key,
    required this.groupId,
    required this.isDark,
    this.topSpacing = 8,
  });

  final String groupId;
  final bool isDark;

  /// Gap above the row, collapsed together with it when it is hidden.
  final double topSpacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportCount = ref.watch(
      groupReportsProvider(groupId).select((state) => state.total),
    );
    if (reportCount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: GroupAdminQueueRow(
        icon: AppAssets.warning,
        iconColor: AppColors.danger,
        label: context.l10n.group_reports_title,
        count: reportCount,
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GroupReportsScreen(groupId: groupId),
            ),
          );
        },
      ),
    );
  }
}
