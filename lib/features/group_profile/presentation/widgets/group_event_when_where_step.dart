import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_schedule_utils.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_date_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_repeats_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_time_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_timezone_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_venue_sheet.dart';
import 'package:intl/intl.dart';

/// Step 2 of the event composer: schedule and format/venue/live link.
class GroupEventWhenWhereStep extends StatelessWidget {
  final GroupEventDraft draft;
  final GroupProfile profile;
  final TextEditingController liveLinkController;
  final ValueChanged<GroupEventScheduleDraft> onScheduleChanged;
  final ValueChanged<GroupEventFormat> onFormatChanged;
  final ValueChanged<GroupEventVenueDraft?> onVenueChanged;

  const GroupEventWhenWhereStep({
    super.key,
    required this.draft,
    required this.profile,
    required this.liveLinkController,
    required this.onScheduleChanged,
    required this.onFormatChanged,
    required this.onVenueChanged,
  });

  GroupEventScheduleDraft get _schedule => draft.schedule;

  static String formatDate(DateTime date, String locale) =>
      DateFormat('EEE d MMM yyyy', locale).format(date);

  static String formatTime(GroupEventTime time, String locale) {
    final now = DateTime.now();
    final value = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat.jm(locale).format(value).toLowerCase();
  }

  Future<void> _pickDate(BuildContext context, {required bool isEnd}) async {
    final l10n = context.l10n;
    final schedule = _schedule;
    final title =
        isEnd
            ? l10n.group_event_end_date
            : schedule.isRecurring
            ? l10n.group_event_first_date
            : schedule.isMultiDay
            ? l10n.group_event_start_date
            : l10n.group_event_date;
    final picked = await GroupEventDateSheet.show(
      context,
      title: title,
      selected: isEnd ? schedule.endDate : schedule.startDate,
      minDate: isEnd ? schedule.startDate : null,
    );
    if (picked == null) return;
    if (isEnd) {
      onScheduleChanged(schedule.copyWith(endDate: picked));
      return;
    }
    final end = schedule.endDate;
    // A recurrence rule belongs to the date it was derived from.
    onScheduleChanged(
      schedule.copyWith(
        startDate: picked,
        clearEndDate: end != null && end.isBefore(picked),
        clearRecurrence: true,
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, {required bool isEnd}) async {
    final l10n = context.l10n;
    final locale = intlFormatLocaleOf(context);
    final schedule = _schedule;
    final current =
        isEnd
            ? (schedule.endTime ?? const GroupEventTime(19, 0))
            : (schedule.startTime ?? const GroupEventTime(18, 0));
    final date = schedule.startDate;
    final subtitle =
        date == null
            ? null
            : '${formatDate(date, locale)} · ${isEnd ? l10n.group_event_time_ends(formatTime(current, locale)) : l10n.group_event_time_starts(formatTime(current, locale))}';
    final picked = await GroupEventTimeSheet.show(
      context,
      title: isEnd ? l10n.group_event_end_time : l10n.group_event_start_time,
      initial: current,
      subtitle: subtitle,
    );
    if (picked == null) return;
    onScheduleChanged(
      isEnd
          ? schedule.copyWith(endTime: picked)
          : schedule.copyWith(startTime: picked),
    );
  }

  Future<void> _pickTimezone(BuildContext context) async {
    final picked = await GroupEventTimezoneSheet.show(
      context,
      selected: _schedule.timezone,
    );
    if (picked == null) return;
    onScheduleChanged(_schedule.copyWith(timezone: picked));
  }

  Future<void> _pickRepeats(BuildContext context) async {
    final first = _schedule.startDate;
    if (first == null) {
      await _pickDate(context, isEnd: false);
      return;
    }
    final picked = await GroupEventRepeatsSheet.show(
      context,
      firstDate: first,
      selected: _schedule.recurrence,
    );
    if (picked == null) return;
    onScheduleChanged(_schedule.copyWith(recurrence: picked));
  }

  void _setDuration(int days) {
    final rule = _schedule.recurrence;
    if (rule == null || days < 1) return;
    onScheduleChanged(
      _schedule.copyWith(recurrence: rule.copyWith(durationDays: days)),
    );
  }

  Future<void> _pickVenue(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final venue = await GroupEventVenueSheet.pick(
      context,
      current: draft.venue,
    );
    if (venue == null) return;
    onVenueChanged(venue);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = intlFormatLocaleOf(context);
    final schedule = _schedule;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(l10n.group_event_when, isDark: isDark),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: _Segmented(
              labels: [l10n.group_event_one_time, l10n.group_event_recurring],
              selected: schedule.isRecurring ? 1 : 0,
              isDark: isDark,
              onChanged:
                  (index) => onScheduleChanged(
                    schedule.copyWith(isRecurring: index == 1),
                  ),
            ),
          ),
          _Row(
            icon: AppAssets.calendarBlank,
            label:
                schedule.isRecurring
                    ? l10n.group_event_first_date
                    : schedule.isMultiDay
                    ? l10n.group_event_start_date
                    : l10n.group_event_date,
            value:
                schedule.startDate == null
                    ? null
                    : formatDate(schedule.startDate!, locale),
            placeholder: l10n.group_event_choose_date,
            onTap: () => _pickDate(context, isEnd: false),
          ),
          if (schedule.isRecurring) ...[
            _Row(
              icon: AppAssets.arrowsClockwise,
              label: l10n.group_event_repeats,
              value:
                  schedule.recurrence == null || schedule.startDate == null
                      ? null
                      : recurrenceRuleLabel(
                        schedule.recurrence!,
                        schedule.startDate!,
                        l10n,
                        locale,
                      ),
              placeholder: l10n.group_event_choose_repeats,
              onTap: () => _pickRepeats(context),
            ),
            _Row(
              icon: AppAssets.hourglass,
              label: l10n.group_event_duration,
              value: l10n.group_event_duration_days(
                schedule.recurrence?.durationDays ?? 1,
              ),
              placeholder: '',
              trailing: _Stepper(
                isDark: isDark,
                enabled: schedule.recurrence != null,
                onDecrement:
                    () => _setDuration(
                      (schedule.recurrence?.durationDays ?? 1) - 1,
                    ),
                onIncrement:
                    () => _setDuration(
                      (schedule.recurrence?.durationDays ?? 1) + 1,
                    ),
              ),
            ),
          ] else ...[
            _ToggleRow(
              label: l10n.group_event_multi_day,
              value: schedule.isMultiDay,
              onChanged:
                  (value) =>
                      onScheduleChanged(schedule.copyWith(isMultiDay: value)),
            ),
            if (schedule.isMultiDay)
              _Row(
                icon: AppAssets.calendarBlank,
                label: l10n.group_event_end_date,
                value:
                    schedule.endDate == null
                        ? null
                        : formatDate(schedule.endDate!, locale),
                placeholder: l10n.group_event_choose_date,
                onTap: () => _pickDate(context, isEnd: true),
              ),
          ],
          _ToggleRow(
            label: l10n.group_event_all_day,
            value: schedule.allDay,
            hint: schedule.allDay ? l10n.group_event_all_day_hint : null,
            onChanged:
                (value) => onScheduleChanged(schedule.copyWith(allDay: value)),
          ),
          if (!schedule.allDay) ...[
            _Row(
              icon: AppAssets.clock,
              label: l10n.group_event_start_time,
              value:
                  schedule.startTime == null
                      ? null
                      : formatTime(schedule.startTime!, locale),
              placeholder: l10n.group_event_add_start_time,
              onTap: () => _pickTime(context, isEnd: false),
            ),
            _Row(
              icon: AppAssets.clock,
              label: l10n.group_event_end_time,
              value:
                  schedule.endTime == null
                      ? null
                      : formatTime(schedule.endTime!, locale),
              placeholder: l10n.group_event_add_end_time,
              isError:
                  GroupEventScheduleUtils.validateSchedule(schedule) ==
                  GroupEventScheduleIssue.endTimeBeforeStart,
              onTap: () => _pickTime(context, isEnd: true),
            ),
          ],
          _Row(
            icon: AppAssets.globe,
            label: l10n.group_event_timezone,
            value: GroupEventTimezoneOption.labelFor(schedule.timezone),
            placeholder: '',
            onTap: () => _pickTimezone(context),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _SectionLabel(l10n.group_event_where, isDark: isDark),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: _Segmented(
              labels: [
                l10n.group_event_in_person,
                l10n.group_event_live,
                l10n.group_event_both,
              ],
              selected: GroupEventFormat.values.indexOf(draft.format),
              isDark: isDark,
              onChanged:
                  (index) => onFormatChanged(GroupEventFormat.values[index]),
            ),
          ),
          if (draft.format.needsVenue)
            draft.venue == null
                ? _Row(
                  icon: AppAssets.mapPin,
                  label: l10n.group_event_venue,
                  value: null,
                  placeholder: l10n.group_event_add_venue,
                  onTap: () => _pickVenue(context),
                )
                : _VenueCard(
                  venue: draft.venue!,
                  isDark: isDark,
                  onChange: () => _pickVenue(context),
                ),
          if (draft.format.needsLink)
            _LiveLinkField(
              controller: liveLinkController,
              channelLiveUrl: GroupEventScheduleUtils.channelLiveUrl(
                profile.socialLinks,
              ),
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.accentGold : AppColors.accentGoldDarkest,
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.labels,
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final bool isDark;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final inactiveColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final (index, label) in labels.indexed)
            Expanded(
              child: Material(
                color:
                    index == selected
                        ? (isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceWhite)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                elevation: index == selected ? 1 : 0,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                child: InkWell(
                  onTap: () => onChanged(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            index == selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                        color: index == selected ? activeColor : inactiveColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    this.onTap,
    this.trailing,
    this.isError = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final valueColor =
        isError
            ? AppColors.danger
            : value == null
            ? secondaryColor
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: dividerColor)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: secondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: secondaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? placeholder,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: valueColor),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(AppAssets.caretRight, size: 18, color: secondaryColor),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(48, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 16)),
              ),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                hint!,
                style: TextStyle(fontSize: 12, color: secondaryColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.isDark,
    required this.enabled,
    required this.onDecrement,
    required this.onIncrement,
  });

  final bool isDark;
  final bool enabled;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    Widget button(IconData icon, VoidCallback onTap, String tooltip) {
      return Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: 40,
              height: 36,
              child: Icon(
                icon,
                size: 18,
                color:
                    enabled
                        ? (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary)
                        : AppColors.grey400,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(AppAssets.minus, onDecrement, '-'),
        const SizedBox(width: 8),
        button(AppAssets.plus, onIncrement, '+'),
      ],
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.venue,
    required this.isDark,
    required this.onChange,
  });

  final GroupEventVenueDraft venue;
  final bool isDark;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final address = venue.address?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                AppAssets.mapPinFill,
                size: 28,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.group_event_venue,
                    style: TextStyle(fontSize: 12, color: secondaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (address.isNotEmpty)
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: secondaryColor),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: onChange,
              child: Text(
                l10n.group_event_change_cover,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentGoldDarkest,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveLinkField extends StatelessWidget {
  const _LiveLinkField({
    required this.controller,
    required this.channelLiveUrl,
    required this.isDark,
  });

  final TextEditingController controller;
  final String? channelLiveUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final raw = controller.text.trim();
    final normalized = GroupEventScheduleUtils.normalizeLiveLink(raw);
    final isInvalid = raw.isNotEmpty && normalized == null;
    final help =
        isInvalid
            ? l10n.group_event_live_link_invalid
            : normalized == null
            ? null
            : GroupEventScheduleUtils.isYoutubeLink(normalized)
            ? l10n.group_event_live_link_youtube_help
            : l10n.group_event_live_link_custom_help;
    final outline = isInvalid ? AppColors.danger : borderColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.group_event_live_link,
            style: TextStyle(fontSize: 13, color: secondaryColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: l10n.group_event_live_link_hint,
                    hintStyle: TextStyle(fontSize: 15, color: secondaryColor),
                    filled: true,
                    fillColor:
                        isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceWhite,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            isInvalid
                                ? AppColors.danger
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
              if (channelLiveUrl != null && normalized != channelLiveUrl) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    controller.value = TextEditingValue(
                      text: channelLiveUrl!,
                      selection: TextSelection.collapsed(
                        offset: channelLiveUrl!.length,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    l10n.group_event_use_channel_link,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (help != null) ...[
            const SizedBox(height: 6),
            Text(
              help,
              style: TextStyle(
                fontSize: 12,
                color: isInvalid ? AppColors.danger : secondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
