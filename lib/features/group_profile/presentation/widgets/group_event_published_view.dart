import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_review_step.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Shown in place of the wizard once the event exists.
class GroupEventPublishedView extends ConsumerWidget {
  final GroupEvent event;
  final GroupEventDraft draft;
  final String groupTitle;
  final VoidCallback onViewEvent;
  final VoidCallback onClose;

  const GroupEventPublishedView({
    super.key,
    required this.event,
    required this.draft,
    required this.groupTitle,
    required this.onViewEvent,
    required this.onClose,
  });

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final longUrl = DeepLinkUrlBuilder.eventLink(eventId: event.id).toString();
    final shareUrl = await resolveShareUrlRef(ref, longUrl);
    if (!context.mounted) return;
    final result = await SharePlus.instance.share(
      ShareParams(
        text: shareUrl,
        sharePositionOrigin: getSharePositionOrigin(context: context),
      ),
    );
    if (ShareAnalytics.wasUsed(result)) {
      ref
          .read(shareAnalyticsProvider)
          .contentShared(
            surface: ShareSurface.event,
            targetId: event.id,
            format: 'text',
            groupId: event.groupId,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final name =
        event.title.trim().isNotEmpty
            ? event.title.trim()
            : GroupEventReviewStep.eventName(draft);
    final cover = draft.cover;

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                l10n.group_event_published_title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Positioned(
                right: 4,
                child: IconButton(
                  onPressed: onClose,
                  tooltip: l10n.cancel,
                  icon: Icon(AppAssets.x, color: secondaryColor),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                if (cover != null) ...[
                  GroupEventCoverImage(cover: cover, isDark: isDark),
                  const SizedBox(height: 24),
                ] else
                  const SizedBox(height: 40),
                const Icon(
                  AppAssets.checkCircle,
                  size: 32,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.group_event_published_headline(name),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  draft.notificationsEnabled
                      ? l10n.group_event_published_message(groupTitle)
                      : l10n.group_event_published_message_silent,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: secondaryColor),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onViewEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                      foregroundColor:
                          isDark
                              ? AppColors.textPrimary
                              : AppColors.surfaceWhite,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.group_event_view_event,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _share(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                      side: BorderSide(
                        color: isDark ? AppColors.grey800 : AppColors.grey400,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      l10n.share,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
