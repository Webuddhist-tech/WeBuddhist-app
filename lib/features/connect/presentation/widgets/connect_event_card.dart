import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_list_tile.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:go_router/go_router.dart';

class ConnectEventCard extends StatelessWidget {
  const ConnectEventCard({super.key, required this.event});

  final GroupEvent event;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);

    return GroupEventListTile(
      event: event,
      showGroup: true,
      isDark: isDark,
      lineHeight: getLineHeight(locale.languageCode),
      onTap: () => context.push('/home/events/${event.id}'),
    );
  }
}
