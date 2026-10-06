import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_join_requests_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_admin_queue_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin-only entry on a private group: pending join requests, shown under
/// the messages / joined / invite row when `role` is `ADMIN`.
class GroupJoinRequestsRow extends ConsumerWidget {
  const GroupJoinRequestsRow({
    super.key,
    required this.groupId,
    required this.isDark,
  });

  final String groupId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestCount = ref.watch(groupJoinRequestsProvider(groupId)).total;

    return GroupAdminQueueRow(
      icon: AppAssets.usercard,
      label: context.l10n.group_join_requests_title,
      count: requestCount,
      isDark: isDark,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GroupJoinRequestsScreen(groupId: groupId),
          ),
        );
      },
    );
  }
}
