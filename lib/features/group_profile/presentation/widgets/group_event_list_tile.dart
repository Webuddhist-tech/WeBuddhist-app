import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:intl/intl.dart';

/// Compact event row shared by the group profile and Connect event lists.
class GroupEventListTile extends StatelessWidget {
  final GroupEvent event;
  final bool showGroup;
  final bool isDark;
  final double? lineHeight;
  final VoidCallback? onTap;

  const GroupEventListTile({
    super.key,
    required this.event,
    required this.showGroup,
    required this.isDark,
    this.lineHeight,
    this.onTap,
  });

  static const _imageSize = 112.0;

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final title =
        event.title.trim().isNotEmpty
            ? event.title.trim()
            : context.l10n.connect_event_fallback_title;
    final groupName = event.groupName?.trim() ?? '';
    final dateLabel = _formatDateLabel(context, event);
    final chips = _buildChips(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _imageSize),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _imageSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      event.image != null && !event.image!.isEmpty
                          ? ResponsiveCoverImage(
                            image: event.image,
                            fit: BoxFit.cover,
                          )
                          : ColoredBox(
                            color:
                                isDark
                                    ? AppColors.surfaceVariantDark
                                    : AppColors.grey100,
                            child: Icon(
                              AppAssets.calendarDots,
                              size: 32,
                              color:
                                  isDark
                                      ? AppColors.grey500
                                      : AppColors.grey600,
                            ),
                          ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: _imageSize + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showGroup && groupName.isNotEmpty) ...[
                      _buildGroupRow(groupName, secondaryColor),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: lineHeight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryColor,
                          height: lineHeight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 6, children: chips),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupRow(String groupName, Color color) {
    final avatarUrl = event.groupAvatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 18,
            height: 18,
            child:
                hasAvatar
                    ? CachedNetworkImageWidget(
                      imageUrl: avatarUrl,
                      width: 18,
                      height: 18,
                      fit: BoxFit.cover,
                      errorWidget: _buildGroupAvatarFallback(),
                    )
                    : _buildGroupAvatarFallback(),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            groupName,
            style: TextStyle(fontSize: 13, color: color, height: lineHeight),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupAvatarFallback() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.usersThree,
        size: 11,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }

  List<Widget> _buildChips(BuildContext context) {
    final locationName = event.location?.name.trim() ?? '';
    final isOnline = isGroupEventOnline(event);
    final isHybrid = isGroupEventHybrid(event);
    final showLocation = !isOnline && locationName.isNotEmpty;
    final showOnline = isOnline || isHybrid;

    return [
      if (showLocation)
        _EventChip(
          icon: AppAssets.mapPin,
          label: locationName,
          color:
              isDark
                  ? AppColors.eventInPersonChipDark
                  : AppColors.eventInPersonChip,
          lineHeight: lineHeight,
        ),
      if (showOnline)
        _EventChip(
          icon: AppAssets.videoCamera,
          label: context.l10n.connect_online,
          color:
              isDark
                  ? AppColors.eventOnlineChipDark
                  : AppColors.eventOnlineChip,
          lineHeight: lineHeight,
        ),
    ];
  }

  String? _formatDateLabel(BuildContext context, GroupEvent event) {
    final start = event.startDate?.toLocal();
    if (start == null) return null;

    final locale = intlFormatLocaleOf(context);
    final time = DateFormat.jm(locale).format(start).toLowerCase();
    final now = DateTime.now();
    final dayPattern = start.year == now.year ? 'd MMM' : 'd MMM y';
    final dayFormat = DateFormat(dayPattern, locale);

    final recurrenceLabel = _recurrenceLabel(context, event, start, locale);
    if (recurrenceLabel != null) return '$recurrenceLabel · $time';

    final end = event.endDate?.toLocal();
    final isMultiDay =
        end != null && !DateUtils.isSameDay(start, end);
    if (isMultiDay) {
      return '${dayFormat.format(start)} - ${dayFormat.format(end)}';
    }
    return '${dayFormat.format(start)} · $time';
  }

  String? _recurrenceLabel(
    BuildContext context,
    GroupEvent event,
    DateTime start,
    String locale,
  ) {
    final recurrence = event.recurrence;
    if (!event.isRecurring || recurrence == null) return null;

    final occurrence = event.occurrenceDate?.toLocal() ?? start;
    return switch (recurrence.frequency.toUpperCase()) {
      'DAILY' => context.l10n.connect_event_every_day,
      'WEEKLY' => context.l10n.connect_event_every_weekday(
        DateFormat.E(locale).format(occurrence),
      ),
      'MONTHLY' => context.l10n.connect_event_every_month,
      'YEARLY' => context.l10n.connect_event_every_date(
        DateFormat('d MMM', locale).format(occurrence),
      ),
      _ => null,
    };
  }
}

class _EventChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double? lineHeight;

  const _EventChip({
    required this.icon,
    required this.label,
    required this.color,
    this.lineHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
              height: lineHeight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
