import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_requests_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Icon-only variant for a task screen's app bar; hidden until the event
/// says its chat room is on, and from anyone exploring it without joining,
/// as on the event page.
class PrayerRequestsIconButton extends ConsumerWidget {
  final String eventId;

  const PrayerRequestsIconButton({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = ref.watch(
      groupEventDetailProvider(eventId).select(
        (async) =>
            async.valueOrNull?.fold(
              (_) => false,
              (e) => e.chatEnabled && e.isJoined,
            ) ??
            false,
      ),
    );
    if (!shown) return const SizedBox.shrink();

    return IconButton(
      tooltip: context.l10n.event_prayer_requests,
      icon: const Icon(AppAssets.handsPraying),
      onPressed: () {
        final authState = ref.read(authProvider);
        if (authState.isGuest || !authState.isLoggedIn) {
          LoginDrawer.show(context, ref);
          return;
        }
        unawaited(PrayerRequestsSheet.show(context, eventId: eventId));
      },
    );
  }
}

/// Chip that opens the event's prayer requests, under the live stream or in
/// the app bar.
class PrayerRequestsButton extends ConsumerStatefulWidget {
  const PrayerRequestsButton({
    super.key,
    required this.eventId,
    required this.onTap,
    this.count = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.outlined = false,
  });

  final String eventId;
  final VoidCallback onTap;

  /// Count from the event fetch. Once the sheet has loaded, the live count
  /// it keeps takes over so a fresh request shows here straight away.
  final int count;
  final EdgeInsetsGeometry padding;

  /// White surface with a hairline border instead of the grey fill.
  final bool outlined;

  @override
  ConsumerState<PrayerRequestsButton> createState() =>
      _PrayerRequestsButtonState();
}

class _PrayerRequestsButtonState extends ConsumerState<PrayerRequestsButton> {
  @override
  void didUpdateWidget(PrayerRequestsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count == widget.count) return;
    // A fresh event fetch is newer than the count the sheet kept, so the
    // live count restarts from it. Deferred: providers can't change mid-build.
    final eventId = widget.eventId;
    final serverCount = widget.count;
    final seen = ref.read(prayerRequestCountProvider(eventId));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final live = ref.read(prayerRequestCountProvider(eventId).notifier);
      // It only moves while the sheet is open, and then it is the fresher
      // of the two; a request that landed this frame must not be undone.
      if (live.state != null && live.state == seen) live.state = serverCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final count =
        ref.watch(prayerRequestCountProvider(widget.eventId)) ?? widget.count;
    final label =
        count > 0
            ? context.l10n.event_prayer_request_count(count)
            : context.l10n.event_prayer_requests;

    return Padding(
      padding: widget.padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color:
              widget.outlined
                  ? (isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceWhite)
                  : (isDark ? AppColors.surfaceVariantDark : AppColors.grey100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side:
                widget.outlined
                    ? BorderSide(
                      color: isDark ? AppColors.grey800 : AppColors.grey300,
                    )
                    : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppAssets.handsPraying, size: 18, color: foreground),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    strutStyle: context.tibetanStrutStyle(13, compact: true),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
